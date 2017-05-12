use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'ZeroMQ::PubSub',
    AUTHOR              => q{Mischa Spiegelmock <revmischa@cpan.org>},
    VERSION_FROM        => 'lib/ZeroMQ/PubSub.pm',
    ABSTRACT_FROM       => 'lib/ZeroMQ/PubSub.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'Moose' => 0,
        'MooseX::Callbacks' => 0,
        'ZMQ::LibZMQ2' => 0,
        'JSON' => 0,
        'Clone' => 0,
        'namespace::autoclean' => 0,
    },
    META_ADD => { resources => { repository => 'git://github.com/revmischa/zeromq-pubsub.git' } },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'ZeroMQ-PubSub-*' },
);
