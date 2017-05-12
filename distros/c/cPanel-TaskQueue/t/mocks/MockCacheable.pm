package MockCacheable;

use warnings;
use strict;

our $VERSION = '0.0.3';

sub new {
    my $class = shift;
    return bless { save_called=>0, load_called=>0 }, $class;
}

sub load_from_cache {
    my $self = shift;
    my $fh = shift;

    $self->{load_called}++;
    $self->{data} = <$fh>;
}

sub save_to_cache {
    my $self = shift;
    my $fh = shift;

    $self->{save_called}++;
    print $fh "Save string: @{[ @$self{'save_called', 'load_called'} ]}";
}

1;
__END__

=head1 NAME

MockCacheable - Mock the interface for a cacheable data object to allow testing of StateFile.

=head1 DESCRIPTION

This is a mocked, data object that provides the appropiate interface to the
StateFile object. Interface is pretty transparent for us to verify that it is
called correctly.
