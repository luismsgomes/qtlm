#
# June 2015, Luís Gomes <luismsgomes@gmail.com>
#

function install {
    local now=$(date '+%Y%m%d_%H%M%S')
    local errors=$(tempfile)
    local missing=$(tempfile)

    while true; do
        $TMT_ROOT/treex/bin/treex -d \
            $(find $QTLM_ROOT/scen -name '*.scen') \
            > /dev/null 2> $errors || true
        perl -ne "/^Can't locate (.*\.pm) in \@INC/ && print \"\$1\n\";" \
            < $errors > $missing
        if ! test -s $missing; then
            break
        fi
        echo "Installing $(cat $missing)" >&2
        xargs -r sudo cpanm < $missing || xargs -r sudo cpanm --force < $missing
    done
    rm -f $errors $missing
}

