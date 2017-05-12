
# $Id: Sizer.pm,v 1.11 2008/01/22 03:56:31 Daddy Exp $

package Tk::Wizard::Installer::Win32::Sizer;

use strict;
use warnings;

our
$VERSION = do { my @r = ( q$Revision: 1.11 $ =~ /\d+/g ); sprintf "%d." . "%03d" x $#r, @r };

=head1 NAME

Tk::Wizard::Installer::Win32::Sizer - Interactively determine the best size for your Wizard::Installer::Win32

  use Tk::Wizard::Installer::Win32::Sizer;
  my $wizard = new Tk::Wizard::Installer::Win32::Sizer(
                              # Same arguments as Tk::Wizard::Installer::Win32
                             );
  $wizard->Show;
  MainLoop;

=cut

use Carp;
use Tk::Wizard::Installer::Win32;
use Tk::Wizard::Sizer;

our @ISA = qw( Tk::Wizard::Installer::Win32 Tk::Wizard::Sizer );

=head1 DESCRIPTION

A typical Wizard application utilizes a fixed-size window;
Tk::Wizard follows this philosophy by creating a window
without resize handles.
In addition, Tk::Wizard allows you to specify the size of the content area.
But there's a problem with this mechanism --
how do you know how large to make your window?
You know what you want to appear in the window,
and you know how you want it to be arranged,
but you do not know the dimensions of that combination of elements.

Fret no more, dear programmer!  Simply replace your call to
Tk::Wizard::Installer->new with a call to
Tk::Wizard::Installer::Win32::Sizer->new, and run your Wizard
application.  On each page, adjust the size of the window for best
aesthetics.  After you click the Next button on each page, on STDOUT
will be printed the ideal height and width arguments.  After you click
the Finish button on the last page, on STDOUT will be printed the
ideal dimensions that will contain all your pages (i.e. the width of
the widest page and the height of the tallest page).

=head1 METHODS

=head2 new

Create a new Sizer wizard.

=cut

sub new
  {
  my $class = shift;
  # This is NOT a clone mechanism:
  return if ref($class);
  # Our arguments are exactly the same as Tk::Wizard::Installer::Win32::new:
  my $oWiz = $class->SUPER::new(@_);
  # Make sure the window is resizable!
  $oWiz->{Configure}{-resizable} = 1;
  # Make sure the window does not auto-forward:
  $oWiz->{Configure}{-wait} = 0;
  # Add our size adder-upper:
  $oWiz->configure(
                   -preNextButtonAction  => sub { $oWiz->_prenext() },
                   -finishButtonAction  => sub { $oWiz->_finish() },
                  );
  $oWiz->{_max_width_} = -999;
  $oWiz->{_max_height_} = -999;
  return bless $oWiz, __PACKAGE__;
  } # new

1;

__END__

=head1 AUTHOR

Martin Thurn, C<mthurn@cpan.org>, L<http://tinyurl.com/nn67z>.

=cut



