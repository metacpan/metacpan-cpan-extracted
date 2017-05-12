package URI::redis_Punix;
 
use strict;
use warnings;

our $VERSION = '0.01';
 
use base qw( URI::redis );

sub host { undef }

sub port { undef }

sub socket_path {
    my $self = shift;

    return $self->path;
}

sub database_from_path { undef }

1;

__END__

=head1 METHODS

=begin internal

Added these paragraphs just to make Pod::Coverage happy.

=head2 host

=head2 port

=head2 socket_path

=head2 database_from_path

=end internal
