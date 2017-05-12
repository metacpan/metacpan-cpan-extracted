# $Id: Zinc.pm,v 1.30 2005/05/16 12:27:51 lecoanet Exp $
# $Name: cpan_3_0_3 $

package Tk::Zinc;

use Tk;
use Tk::Photo;
use Carp;

use base qw(Tk::Widget); 
Construct Tk::Widget 'Zinc';


use vars qw($VERSION $REVISION);

$REVISION = q$Revision: 1.30 $ ;  # this line is automagically modified by CVS
$VERSION = 3.303;


bootstrap Tk::Zinc $Tk::VERSION;

sub Tk_cmd { \&Tk::zinc }

sub CreateOptions
{
 return (shift->SUPER::CreateOptions,'-render')
}

Tk::Methods("add", "addtag", "anchorxy", "bbox", "becomes", "bind", "cget",
	    "chggroup", "clone", "configure", "contour", "coords", "currentpart",
	    "cursor", "dchars", "dtag", "find", "fit", "focus", "gdelete", "gettags",
	    "gname", "group", "hasanchors", "hasfields", "hastag", "index",
	    "insert", "itemcget", "itemconfigure", "lower", "monitor",
	    "numparts", "postscript", "raise", "remove", "rotate", "scale",
	    "select", "skew", "smooth", "tapply", "tcompose", "tdelete", "tget",
	    "transform", "translate", "treset", "trestore", "tsave", "tset",
	    "type", "vertexat", "xview", "yview");

## coord0 is a compatibility function usefull for porting old application
## previously running with Tk::Zinc V <= 3.2.6a
## The Zinc methode coords0 can/should replace coords as long as no control points are
## used in curve or rectangle or an arc...
## This can dramaticaly simplify the port of an old application from Zinc V<3.2.6a to
## a newer version of Zinc. HOWEVER YOU STILL MUST CHANGE THE CODE OF THIS OLD APPICATION
##
## Remember: the incompatible change in Zinc is due to the introduction of
## control points in curves (and a future release, in arc or rectangle items...)
sub coords0 {
    if (wantarray) {
	## we are in list context, so we should convert the returned value
	## to match the specification of Zinc Version <= 3.2.6a
	my @res = &Tk::Zinc::coords(@_);
	if ( !ref $res[0] ) {
	    ## The first item of the list is not a reference, so the
	    ## list is guarranted to be a flat list (x, y, x, y, ... x, y)
	    return @res;
	}
	else {
	    ## The list is a list of references like : [x y] or [x y symbol] 
	    ## In the latter case, coord0 should warn that there is a control point!
	    ## coord0 will return a flatten list of (x, y, ... x , y)
	    my @res0;
	    foreach my $ref (@res) {
		my @array = @{$ref};
	        if ($#array > 1) {
		   my $item = $_[1];
		   my $zinc = $_[0];
		   my $type = $zinc->type($item);
		   carp "Using Zinc coord0 compatibility method with item $item (type=$type) which contains a control point: @array";
	        }
		push @res0, $array[0];
		push @res0, $array[1];
	    }
	    return @res0;
        }
    }
    else {
	## contexte scalaire
	## le résultat n'était pas utilisé jusqu'à présent, vu le bug...
	## donc inutile de le convertir!
	return &Tk::Zinc::coords(@_);
    }
}

1;

__END__

=head1 NAME

Tk::Zinc - TkZinc is another Canvas which proposes many new functions, some based on openGL

=for category Tk Widget Classes

=head1 SYNOPSIS

I<$zinc> = I<$parent>-E<gt>B<Zinc>(?I<options>?);

=head1 DESCRIPTION

I<Zinc> widget is very similar to Tk Canvase in that it supports
structured graphics. Like the Canvas, TkZinc implements items used to
display graphical entities. Those items can be manipulated and bindings can be
associated with them to implement interaction behaviors. But unlike the
Canvas, TkZinc can structure the items in a hierarchy (with the use of
group items), has support for affine 2D transforms (i.e. translation, scaling, and
rotation), clipping can be set for sub-trees of the item hierarchy, the item set
is quite more powerful including field specific items for Air Traffic systems and
new rendering techniques such as transparency and gradients.

Since the 3.2.2 version, TkZinc also offers as a runtime option, the support
for openGL rendering, giving access to features such as antialiasing, transparency,
color gradients and even a new, openGL oriented, item type triangles.

TkZinc full documentation is available as part of the Zinc software as a
pdf file, B<refman.pdf> and html pages B<refman/index.html>.

As a complement to the reference manual, small Perl/Tk demos of TkZinc are
also available through a small application named zinc-demos, highly inspired
from the widget application included in Tk. The aim of these demos are both
to demonstrates the power of TkZinc and to help newcomers start using
TkZinc with small examples.

=head1 WHERE CAN I FIND TkZinc?

TkZinc is available as source in tar.gz format or as Debian or RedHat/Mandrake
packages at http://www.tkzinc.org/ or http://freshmeat.net/projects/zincisnotcanvas/

TkZinc is also available on CPAN since v3.294 (a kind of 3.2.94)

=head1 AUTHOR

Patrick Lecoanet <lecoanet@cena.fr>

=head1 COPYRIGHT

Zinc has been developed by the CENA (Centres d'Etudes de la Navigation
Aérienne) for its own needs in advanced HMI (Human Machine Interfaces or Interactions).
Because we are confident in the benefit of free software, the CENA delivered this
toolkit under the GNU Library General Public License.

This code is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
Library General Public License for more details.

Parts of this software are derived from the Tk toolkit which is copyrighted
under another open source license by The Regents of the University of California
and Sun Microsystems, Inc. The GL
font rendering is derived from Mark Kilgard code described in `A Simple OpenGL-based
API for Texture Mapped Text' and is copyrighted by Mark Kilgard under an open source license.

=head1 SEE ALSO

L<Tk(1)>, L<zinc-demos(1)>.

=cut

