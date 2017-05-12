package unix2dos;

use warnings;
use strict;

=head1 NAME

unix2dos -- Converts DOS files to Unix and vice-versa

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';


=head1 SYNOPSIS

  use unix2dos ;

  unix2dos filename(s) ;
  dos2unix filename(s) ;

=head1 EXPORT

  unix2dos()
  dos2unix()

=cut

require Exporter ;

our @ISA    = "Exporter" ;
our @EXPORT = ( "unix2dos" , "dos2unix" ) ;

=head1 SUBROUTINES/METHODS

=head2 unix2dos

  unix2dos filename(s)

=cut

sub unix2dos
  {

  local ( $^I , @ARGV ) = ( defined , @_ ) ;

  s/\n/\r\n/ && print while <>
  }

=head2 dos2unix

  dos2unix filename(s)

=cut

sub dos2unix
  {

  local ( $^I , @ARGV ) = ( defined , @_ ) ;

  s/\r\n/\n/ && print while <>

  }

=head1 AUTHOR

Michael Fuersich, C<< <michael.fuersich at arcor.de> >>

=head1 BUGS

Please report any bugs or feature requests to C<michael.fuersich@arcor.de>

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc unix2dos

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Michael Fuersich.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of unix2dos
