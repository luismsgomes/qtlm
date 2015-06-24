# QTLeap Manager Development Roadmap

1. fix `save_code_snapshot` (GN)
    (it worked for old tectomt SVN repository, has to be updated for github)

    1. also, make `save_code_snapshot` optional (LG)

1. use XMLRPC to communicate with LX-Suite instead of plain sockets (SN;LG)

1. qtlm should use multiple processors for `qtlm evaluate`

1. qtlm evaluate and translate should not need a dataset configuration file (GN)
    (setting QTLM_CONF should be enough)

1. allow use of different scenarios for training and testing (GN)

1. add hooks for saving snapshots of dependency repositories (such as LX-Suite)

1. `ReverseAlignment` is no longer needed (though it works as it is) (GN)

1. update documentation about TectoMT installation (it still refers to the svn repo)
