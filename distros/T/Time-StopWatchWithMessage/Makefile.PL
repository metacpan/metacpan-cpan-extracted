use 5.008000;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'Time::StopWatchWithMessage',
    VERSION_FROM      => 'lib/Time/StopWatchWithMessage.pm',
    PREREQ_PM         => {
        "List::MoreUtils" => 0,
    },
    ABSTRACT_FROM     => 'lib/Time/StopWatchWithMessage.pm',
    AUTHOR            => 'kuniyoshi.kouji <kuniyoshi@cpan.org>',
);

