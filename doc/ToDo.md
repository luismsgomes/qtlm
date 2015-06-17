# QTLeap Manager Development Roadmap

1. (GN) fix `save_code_snapshot` (it worked for old tectomt SVN repository, has to be updated for github)

    1. (LG) also, make `save_code_snapshot` optional

1. (SN;LG) use XMLRPC to communicate with LX-Suite instead of plain sockets

1. (GN) qtlm evaluate and translate should not need a dataset configuration file
    (setting QTLM_CONF should be enough)

1. (*) qtlm should use multiple processors for `qtlm evaluate`

1. (*) add hooks for saving snapshots of dependency repositories (such as LX-Suite)

1. (GN) `ReverseAlignment` is no longer needed (though it works as it is)
