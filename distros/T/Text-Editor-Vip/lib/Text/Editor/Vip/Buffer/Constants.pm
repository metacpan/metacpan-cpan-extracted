
package Text::Editor::Vip::Buffer::Constants;

use strict;
use warnings ;

BEGIN 
{
use Exporter ();

use vars qw ($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
$VERSION     = 0.01;
@ISA         = qw (Exporter);
@EXPORT      = qw (SMART_INDENTATION NO_SMART_INDENTATION);
@EXPORT_OK   = qw ();
%EXPORT_TAGS = ();
}

#-------------------------------------------------------------------------------

use constant SMART_INDENTATION    => 1 ;
use constant NO_SMART_INDENTATION => 0 ;

#-------------------------------------------------------------------------------

1 ;

=head1 NAME

Text::Editor::Vip::Buffer::Constants - Editing engine constants

=head1 SYNOPSIS

  use Text::Editor::Vip::Buffer::Constants
  
=head1 DESCRIPTION

=head1 USAGE

=head1 BUGS

=head1 AUTHOR

	Khemir Nadim ibn Hamouda
	CPAN ID: NKH
	mailto:nadim@khemir.net
	http:// no web site

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
