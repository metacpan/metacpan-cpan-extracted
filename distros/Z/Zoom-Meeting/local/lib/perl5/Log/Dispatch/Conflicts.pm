package # hide from PAUSE
    Log::Dispatch::Conflicts;

use strict;
use warnings;

# this module was generated with Dist::Zilla::Plugin::Conflicts 0.19

use Dist::CheckConflicts
    -dist      => 'Log::Dispatch',
    -conflicts => {
        'Log::Dispatch::File::Stamped' => '0.17',
    },
    -also => [ qw(
        Carp
        Devel::GlobalDestruction
        Dist::CheckConflicts
        Encode
        Exporter
        Fcntl
        IO::Handle
        Module::Runtime
        Params::ValidationCompiler
        Scalar::Util
        Specio
        Specio::Declare
        Specio::Exporter
        Specio::Library::Builtins
        Specio::Library::Numeric
        Specio::Library::String
        Sys::Syslog
        Try::Tiny
        base
        namespace::autoclean
        parent
        strict
        warnings
    ) ],

;

1;

# ABSTRACT: Provide information on conflicts for Log::Dispatch
# Dist::Zilla: -PodWeaver
