"""
A module for reading and writing TSV files.

2015 Luís Gomes <luismsgomes@gmail.com>
"""

import collections
import sys


def _skip_comments(file, comment_prefix):
    return filter(lambda line: not line.startswith(comment_prefix), file)


def _read(file):
    for line in file:
        line = line.rstrip('\n')
        yield line.split('\t') if line else None


def _parse(rows, fn):
    for row in rows:
        if row:
            row = fn(row)
        yield row


def _group(rows):
    group = []
    for row in rows:
        if row:
            group.append(row)
        else:
            yield group
            group = []
    if group:
        yield group


def read(file, comment_prefix=None, blanks=False, group=False, parsefn=None):
    if comment_prefix:
        file = _skip_comments(file, comment_prefix)
    rows = _read(file)
    if parsefn:
        rows = _parse(rows, parsefn)
    return _group(rows) if group else rows if blanks else filter(None, rows)


def _handle_empty_list(col):
    assert not col
    return list()


def _handle_empty_tuple(col):
    assert not col
    return tuple()


def read_namedtuples(classname, file=sys.stdin, blanks=False, group=False, typedcols=False):
    '''Reads a tsv file, yielding one named tuple for each line.

    If typedcols is True the first line must contain column types and names in the
     form coltype:colname.  If typedcols is False, then the first line must contain
     the column names.
    Valid basic types are: int, real, bool, str.
    When you have a multi-valued column using spaces as separators you may use
     the following list types: [int,], [real,], [bool,], and [str,].
    Similarly you can use parentheses to get tuples instead of lists: (int,)
    Names must be valid Python identifiers.
    '''
    handlers = {
        'int': int,
        'float': float,
        'bool': bool,
        'str': str,
        '[int,]': lambda s: [int(v) for v in s.split()],
        '[float,]': lambda s: [float(v) for v in s.split()],
        '[bool,]': lambda s: [bool(v) for v in s.split()],
        '[str,]': str.split,
        '(int,)': lambda s: tuple(map(int, s.split())),
        '(float,)': lambda s: tuple(map(float, s.split())),
        '(bool,)': lambda s: tuple(map(bool, s.split())),
        '(str,)': lambda s: tuple(s.split()),
        # HACK for reading back TSVs written with write() function below
        '[]': _handle_empty_list,
        '()': _handle_empty_tuple,
    }
    header = next(read(file), None)
    if header is None:
        return []
    if typedcols:
        colnames = []
        colhandlers = []
        for colspec in header:
            coltype, _, colname = colspec.partition(':')
            colhandlers.append(handlers[coltype])
            colnames.append(colname)
    else:
        colnames = header
    class_ = collections.namedtuple(classname, colnames)
    if typedcols:
        def parse(row):
            values = [handler(value) for handler, value in zip(colhandlers, row)]
            return class_(*values)
    else:
        parse = class_._make
    return read(file, blanks=blanks, group=group, parsefn=parse)


def _flatten(groups):
    for group in groups:
        for row in group:
            yield row
        yield tuple()


def _col_to_str(col):
    if isinstance(col, list) or isinstance(col, tuple):
        return ' '.join([str(elem) for elem in col])
    elif col is None:
        return ""
    else:
        return str(col)


def _write(rows, file):
    flush = True if file == sys.stdout else False
    for row in rows:
        print(*[_col_to_str(col) for col in row], sep='\t', flush=flush, file=file)


def write(rows, file=sys.stdout, group=False):
    if group:
        rows = _flatten(rows)
    _write(rows, file)


def _get_coltype(col, previous_type=None):
    if isinstance(col, list):
        if len(col) == 0:
            return '[]' if previous_type is None else previous_type
        else:
            return '[{},]'.format(col[0].__class__.__name__)
    elif isinstance(col, tuple):
        if len(col) == 0:
            return '()' if previous_type is None else previous_type
        else:
            return '({},)'.format(col[0].__class__.__name__)
    elif col is None:
        return "str" if previous_type is None else previous_type
    else:
        return col.__class__.__name__


def _write_with_header(rows, file, typedcols):
    held = []
    coltypes = None
    colnames = None
    for row in rows:
        held.append(row)
        if not row:
            continue
        colnames = row._fields
        if not typedcols:
            break
        if coltypes is None:
            coltypes = [_get_coltype(col) for col in row]
        else:
            coltypes = [_get_coltype(col, t) for col, t in zip(row, coltypes)]
        if all('[]' != t != '()' for t in coltypes):
            break
    else:
        if colnames is None: # no rows at all or all rows are empty
            return
        badcols = [t+':'+n for t, n in zip(coltypes, colnames)
                   if t in ('[]', '()')]
        msg = 'warning: could not determine type of column(s) with empty sequence(s): {}'
        print(msg.format(', '.join(badcols)), flush=True, file=sys.stderr)
    if typedcols:
        colspecs = [t+':'+n for t, n in zip(coltypes, colnames)]
    else:
        colspecs = colnames
    print(*colspecs, sep='\t', flush=True, file=file)
    _write(held, file)
    _write(rows, file)


def write_namedtuples(rows, file=sys.stdout, group=False, typedcols=False):
    if group:
        rows = _flatten(rows)
    _write_with_header(rows, file, typedcols)
