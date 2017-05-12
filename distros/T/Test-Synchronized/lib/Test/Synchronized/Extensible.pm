package Test::Synchronized::Extensible;
use strict;
use warnings;
use Test::Synchronized::FileLock;

my $default_instance;

$SIG{INT} = sub {
    undef $default_instance;
};

END {
    undef $default_instance;
}

sub import {
    my ($class, %rest) = @_;

    my $lock_class = $rest{lock_class};

    $default_instance ||= $lock_class->new({ id => getppid() });
    $default_instance->lock;
}

1;
