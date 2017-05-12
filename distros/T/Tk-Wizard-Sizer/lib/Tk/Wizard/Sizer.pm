
# $Id: Sizer.pm,v 1.12 2008/01/27 14:25:40 Daddy Exp $

package Tk::Wizard::Sizer;

use strict;
use warnings;

our
$VERSION = do { my @r = ( q$Revision: 1.12 $ =~ /\d+/g ); sprintf "%d." . "%03d" x $#r, @r };

=head1 NAME

Tk::Wizard::Sizer - Interactively determine the best size for your Wizard

  use Tk::Wizard::Sizer;
  my $wizard = new Tk::Wizard::Sizer(
                                     # Same arguments as Tk::Wizard
                                    );
  $wizard->Show;
  MainLoop;

=cut

use Carp;
use Tk::Wizard;
use base 'Tk::Wizard';

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

Fret no more, dear programmer!
Simply replace your call to Tk::Wizard->new with
a call to Tk::Wizard::Sizer->new, and run your Wizard application.
On each page, adjust the size of the window for best aesthetics.
After you click the Next button on each page,
on STDOUT will be printed the ideal height and width arguments.
After you click the Finish button on the last page,
on STDOUT will be printed the ideal dimensions that will
contain all your pages
(i.e. the width of the widest page and the height of the tallest page).

=head1 METHODS

=head2 new

Create a new Sizer wizard.

=cut

sub new
  {
  my $class = shift;
  # This is NOT a clone mechanism:
  return if ref($class);
  # Our arguments are exactly the same as Tk::Wizard::new:
  my $oWiz = $class->SUPER::new(@_);
  # Make sure the window is resizable!
  $oWiz->{Configure}{-resizable} = 1;
  # Make sure the window does not auto-forward:
  $oWiz->{Configure}{-wait} = 0;
  # Add our size adder-upper:
  $oWiz->configure(
                   -preNextButtonAction  => sub { &_prenext($oWiz) },
                   -finishButtonAction  => sub { &_finish($oWiz) },
                  );
  $oWiz->{_max_width_} = -999;
  $oWiz->{_max_height_} = -999;
  return bless $oWiz, 'Tk::Wizard::Sizer';
  } # new

sub _prenext
  {
  my $self = shift;
  my $iW = $self->{wizardFrame}->width;
  my $iH = $self->{wizardFrame}->height;
  if ($self->{_max_width_} < $iW)
    {
    $self->{_max_width_} = $iW;
    } # if
  if ($self->{_max_height_} < $iH)
    {
    $self->{_max_height_} = $iH;
    } # if
  printf STDOUT (qq{For page #%d ("%s"), final dimensions were:\n},
                 $self->currentPage,
                 $self->{frame_titles}->[$self->currentPage-1],
                );
  print STDOUT "  -width => $iW, -height => $iH,\n";
  } # _prenext

sub _finish
  {
  my $self = shift;
  printf STDOUT qq{Dimensions of the smallest area that will contain ALL pages are:\n};
  print STDOUT "  -width => $self->{_max_width_}, -height => $self->{_max_height_},\n";
  } # _finish

1;

__END__

=head1 AUTHOR

Martin Thurn, C<mthurn@cpan.org>, L<http://tinyurl.com/nn67z>.

=cut
