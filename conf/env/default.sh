
export QTLM_ROOT=${QTLM_ROOT:-$HOME/code/qtlm}
export TMT_ROOT=${TMT_ROOT:-$HOME/code/tectomt}
export TREEX_CONFIG=$QTLM_ROOT/conf/treex/$USER
export PATH=$QTLM_ROOT/bin:$TMT_ROOT/treex/bin:$TMT_ROOT/tools/general:$PATH
export PERL5LIB=$QTLM_ROOT/lib/perl5:$TMT_ROOT/treex/lib:$TMT_ROOT/libs/other:$TMT_ROOT/libs/core:$PERL5LIB
export PYTHONDONTWRITEBYTECODE=1
