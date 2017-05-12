package Yars::Util;

use strict;
use warnings;
use 5.010;
use base qw( Exporter );

# ABSTRACT: Yars internally used functions.
our $VERSION = '1.27'; # VERSION

our @EXPORT_OK = qw( format_tx_error );


sub format_tx_error
{
  my($error) = @_;
  if($error->{advice})
  {
    return sprintf("[%s] %s", $error->{advice}, $error->{message});
  }
  elsif($error->{code})
  {
    return sprintf("(%s) %s", $error->{code}, $error->{message});
  }
  $error->{message};
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Yars::Util - Yars internally used functions.

=head1 VERSION

version 1.27

=head1 FUNCTIONS

=head2 format_tx_error

 say format_tx_error($tx->error);

Formats a transaction error for human readable diagnostic.

=head1 AUTHOR

Original author: Marty Brandon

Current maintainer: Graham Ollis E<lt>plicease@cpan.orgE<gt>

Contributors:

Brian Duggan

Curt Tilmes

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by NASA GSFC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
