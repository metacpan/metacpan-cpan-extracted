#pragma once
#include <panda/uri/Strict.h>

namespace panda { namespace uri {

struct URI::ftp : Strict<URI::ftp> {
    using Strict<URI::ftp>::Strict;

    static string default_scheme () { return "ftp"; }
};

struct URI::sftp : Strict<URI::sftp> {
    using Strict<URI::sftp>::Strict;

    static string default_scheme () { return "sftp"; }
};

}}
