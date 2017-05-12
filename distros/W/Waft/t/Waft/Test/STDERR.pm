package Waft::Test::STDERR;

use strict;
use vars qw( $VERSION );
BEGIN { eval { require warnings } ? 'warnings'->import : ( $^W = 1 ) }

use Carp;
use Symbol;

$VERSION = '1.0';

sub new {
    my ($class) = @_;

    my $duplicate = gensym;

    open $duplicate, '>&STDERR'
        or croak 'Failed to duplicate STDERR';

    open STDERR, '>t/STDERR.test'
        or croak 'Failed to open STDERR piped to file';

    bless $duplicate, $class;

    return $duplicate;
}

sub DESTROY {
    my ($duplicate) = @_;

    open STDERR, '>&=' . fileno $duplicate
        or croak 'Failed to return STDERR';

    unlink 't/STDERR.test';

    return;
}

sub get {

    my $stderr = gensym;
    open $stderr, '<t/STDERR.test'
        or croak 'Failed to open file piped from STDERR';

    return do { local $/; <$stderr> };
}

1;
