package XML::Stream::IO::Select::Win32;

=head1 NAME

XML::Stream::IO::Select::Win32 - Fake filehandle support for XML::Stream

=head1 SYNOPSIS

  You should have no reason to use this directly.

=cut

use strict;
use warnings;

use vars qw( $VERSION );

$VERSION = "1.24";

use base 'IO::Select';

sub can_read {
    my $vec = shift;
    my $timeout = shift;

    $vec->handles();
}

1;
