
package Tk::CanvasLogo;

use 5.008005;
use strict;
use warnings;

use vars qw($VERSION);
$VERSION = '0.2'; 

use Tk qw (Ev);
use AutoLoader;

use base qw(Tk::Canvas);

Construct Tk::Widget 'CanvasLogo';


sub ClassInit
{
 my ($class,$mw) = @_;
 $class->SUPER::ClassInit($mw);
 return $class;
}


sub InitObject
{
 my ($w) = @_;
 $w->SUPER::InitObject;
}

	
use Tk::CanvasLogo::Turtle;


sub NewTurtle {
	return Tk::CanvasLogo::Turtle->_newTurtle(@_);
}




1;
__END__


=head1 NAME

Tk::CanvasLogo - a Tk::Canvas widget that can support methods based on the
Logo Programming Language as well as multiple turtles.

=head1 SYNOPSIS

	use Tk;
	use CanvasLogo;

	my $top = MainWindow->new();
	my $logo = $top->CanvasLogo->pack();
	my $turtle = $logo -> NewTurtle;
	$turtle -> LOGO_FD(50); # forward 50 
	MainLoop();

=head1 DESCRIPTION

The Tk::CanvasLogo widget is a regular Canvas widget that adds
support to allow drawing on the canvas with Logo commands.
The user first creates a CanvasLogo widget. Then using that
widget, the user creates turtle objects which are attached 
to that CanvasLogo widget. Turtle objects can then execute
Logo-based methods. 

The following methods are currently supported.

$turtle->LOGO_FD(N); # move turtle forward N pixels

$turtle->LOGO_BK(N); # move turtle backward N pixels

$turtle->LOGO_RT(N); # turn turtle Right (clockwise) N degrees

$turtle->LOGO_LT(N); # turn turtle Left (counter clockwise) N degrees

$turtle->LOGO_PU; # turtle's "pen" up. moving turtle while pen up will not draw.

$turtle->LOGO_PD; # turtle's "pen" down. moving turtle while pen down will draw.

$turtle->LOGO_CS; # Clear screen. This will clear the turtle and everything it drew. It will not clear entire canvas. Use Canvas->delete('all') for that.

$turtle->LOGO_HOME; # move turtle to center of screen facing straight up.

=head2 EXPORT

None

=head1 SEE ALSO

http://en.wikipedia.org/wiki/Logo_programming_language

=head1 AUTHOR

Greg London, http://www.GregLondon.com

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by Greg London

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.5 or,
at your option, any later version of Perl 5 you may have available.

=cut
