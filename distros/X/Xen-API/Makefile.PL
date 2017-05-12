use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Xen::API',
    AUTHOR              => q{Ben Booth <benwbooth@gmail.com>},
    VERSION_FROM        => 'lib/Xen/API.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    EXE_FILES => ['scripts/xen'],
    PREREQ_PM => {
        'Test::More' => 0,
        'RPC::XML' => 0,
        'IO::Prompt' => 0,
        'Number::Format' => 0,
        'Devel::REPL' => 0,
        'Net::OpenSSH' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Xen-API-*' },
);
