
package Text::Editor::Vip::View;
use strict;
use warnings ;

BEGIN 
{
use Exporter ();
use vars qw ($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
$VERSION     = 0.01_1;
@ISA         = qw (Exporter);
@EXPORT      = qw ();
@EXPORT_OK   = qw ();
%EXPORT_TAGS = ();
}

=head1 NAME

Text::Editor::Vip::View - Buffer visualisation

=head1 SYNOPSIS

  use Text::Editor::Vip::View

=head1 DESCRIPTION

base class to define views for Text::Editor::Vip::Buffer.

=head1 MEMBER FUNCTIONS

=cut

#-----------------------------------------------------------------

sub new
{

=head2 new

creates a new View object.

=cut

my ($class, %parameters) = @_;

my $self = bless ({}, ref ($class) || $class);

return ($self);
}

#------------------------------------------------------------------------------------------------------

sub CenterCurrentLineInDisplay
{
}

#------------------------------------------------------------------------------------------------------

sub FlipDisplaySize
{
}

#------------------------------------------------------------------------------------------------------

sub FlipLineNumberDisplay
{
}

#------------------------------------------------------------------------------------------------------

sub DisplayTabStops
{
}

#------------------------------------------------------------------------------------------------------

sub ReduceTabSize
{
}

#------------------------------------------------------------------------------------------------------

sub ExpandTabSize
{
}

#------------------------------------------------------------------------------------------------------

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

#-----------------------------------------------------------------

1;

__END__

