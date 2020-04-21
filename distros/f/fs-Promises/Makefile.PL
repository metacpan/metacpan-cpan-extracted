use strict;
use warnings;

use ExtUtils::MakeMaker;
use ExtUtils::CBuilder;
use Getopt::Std;
use Config;

WriteMakefile(
    ABSTRACT_FROM  => 'lib/fs/Promises.pm',
    AUTHOR         => [
        "Brian Fraser (brian.fraser at booking.com)",
    ],
    CONFIGURE_REQUIRES => {
        "File::Spec" => 0,
        "ExtUtils::MakeMaker" => 0,
    },
    DISTNAME  => "fs-Promises",
    EXE_FILES => [],
    LICENSE   => "perl",
    NAME      => "fs::Promises",
    PREREQ_PM => {
        "Carp"          => 0,
        "XSLoader"      => 0,
        "strict"        => 0,
        "warnings"      => 0,
        "Ref::Util"            => 0,
        "POSIX::AtFork"        => 0,
        "AnyEvent::XSPromises" => 0,
        "AnyEvent::AIO"        => 0,
        "Hash::Util::FieldHash"=> 0,
    },
    TEST_REQUIRES => {
        "Test::More"      => 0,
        "Test::Exception" => 0,
    },
    VERSION_FROM     => 'lib/fs/Promises.pm',
    test => {
        "TESTS" => "t/*.t"
    }
);



