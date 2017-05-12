$Tk::CollapsableFrame::VERSION = '1.2';

package Tk::CollapsableFrame;

use Carp;
use Tk::widgets qw/Frame/;
use vars qw/$cf_height_bias $im_Close $im_Open/;
use strict;

use base qw/Tk::Frame/;
Construct Tk::Widget 'CollapsableFrame';

sub ClassInit {

    # Define global variables and images for the class.

    my($class, $mw) = @_;

    $cf_height_bias = 22;

    $im_Close = $mw->Bitmap(-data => <<'END');
#define close_width 16
#define close_height 16
static unsigned char close_bits[] = {
  0x00, 0x80, 0x00, 0xc0, 0x00, 0xc0, 0x00, 0xc0, 0x00, 0xc0, 0x00, 0xc0,
  0xf0, 0xc7, 0xe0, 0xc3, 0xc0, 0xc1, 0x80, 0xc0, 0x00, 0xc0, 0x00, 0xc0,
  0x00, 0xc0, 0x00, 0xc0, 0xfe, 0xff, 0xff, 0xff, };
END

    $im_Open = $mw->Bitmap(-data => << 'END');
#define open_width 16
#define open_height 16
static unsigned char open_bits[] = {
  0x00, 0x80, 0x00, 0xc0, 0x00, 0xc0, 0x00, 0xc0, 0x40, 0xc0, 0xc0, 0xc0,
  0xc0, 0xc1, 0xc0, 0xc3, 0xc0, 0xc1, 0xc0, 0xc0, 0x40, 0xc0, 0x00, 0xc0,
  0x00, 0xc0, 0x00, 0xc0, 0xfe, 0xff, 0xff, 0xff, };
END
    
    $class->SUPER::ClassInit($mw);

} # end ClassInit

sub Populate {

    # Create an instance of a CollapsableFrame.  Instance variables are:
    #
    # {frame} = the ridged frame, which contains the open/close
    #           Label image, the id Label for the collapsable Frame,
    #           and the container Frame within which the user manages
    #           collapsable widgets.  It's ALMOST possible to forgo
    #           this extra internal frame, were it not for the -pady
    #           packer attribute we use to make the widget look pretty.
    # {opcl}  = the open/close image Label.
    # {ident} = the identifying Label.
    # {colf}  = the user's container Frame, advertised as "colf".

    my($self, $args) = @_;

    my $height = $args->{-height};
    croak "Tk::CollapsableFrame: -height must be >= $cf_height_bias" unless
        $height >= $cf_height_bias;
    $self->SUPER::Populate($args);

    $self->{frame} = $self->Frame(
        qw/-borderwidth 2 -height 16 -relief ridge/,
    );
    $self->{frame}->pack(
        qw/-anchor center -expand 1 -fill x -pady 7 -side left/,
    );

    $self->{opcl} = $self->Label(
        qw/-borderwidth 0 -relief raised/, -text => $height,
    );
    $self->{opcl}->bind('<Button-1>' => [sub {$_[1]->toggle}, $self]);
    $self->{opcl}->place(
        qw/-x 5 -y -1 -width 21 -height 21 -anchor nw -bordermode ignore/,
    );

    $self->{ident} = $self->Label(qw/-anchor w -borderwidth 1/);
    $self->{ident}->place(
        qw/-x 23 -y 3  -height 12 -anchor nw -bordermode ignore/,
    );

    $self->{colf} = $self->{frame}->Frame;
    $self->{colf}->place(qw/-x 20 -y 15 -relwidth 1.0 -width -20/);
    $self->Advertise('colf' => $self->{colf});

    if (not defined $args->{-width}) {
	$args->{-width} = $self->parent->cget(-width);
    }

    $self->ConfigSpecs(
      -background  => [['SELF', 'CHILDREN'], qw/background Background/],
      -height      => [qw/METHOD height Height 47/],
      -image       => [$self->{opcl}, 'image', 'Image', $im_Open],
      -title       => '-text',
      -text        => [$self->{ident}, qw/text Text NoTitle/],
      -width       => [$self->{frame}, qw/width Width 250/],
    );
   
} # end Populate

sub bias {return $cf_height_bias}

# Public instance methods.

sub close {
    my($self) = @_;
    $self->{opcl}->configure(-image  => $im_Open);
    $self->{frame}->configure(-height => 16);
}

sub open  {
    my($self) = @_;
    $self->{opcl}->configure(-image  => $im_Close);
    $self->{frame}->configure(-height => $self->{opcl}->cget(-text));
}

sub state {
    my($self) = @_;
    my $i = $self->{opcl}->cget(-image);
    my $op = ($i == $im_Open) ? 'close' : 'open';
    return $op;
}

sub toggle {
    my($self) = @_;
    my $i = $self->{opcl}->cget(-image);
    my $op = ($i == $im_Open) ? 'open' : 'close';
    $self->$op();
}

# Private instance methods.

sub height {
    my($self, $h) = @_;
    $self->{opcl}->configure(-text => $h);
}

1;

__END__

=head1 NAME

Tk::CollapsableFrame - a Frame that opens and closes via a mouse click.

=head1 SYNOPSIS

 $cf = $parent->CollapsableFrame>(-option => value);

=head1 DESCRIPTION

This widget provides a switchable open or closed Frame
that provides for the vertical arrangement of widget
controls. This is an alternative to Notebook style
tabbed widgets.

The following option/value pairs are supported:

=over 4

=item B<-title>

Title of the CollapsableFrame widget.

=item B<-height>

The maximun open height of the CollapsableFrame.

=back

=head1 METHODS

=over 4

=item B<close>

Closes the CollapsableFrame.

=item B<open>

Opens the CollapsableFrame.

=item B<state>

Returns the open/close state of the CollapsableFrame, either
"open" or "close".

=item B<toggle>

Toggles the open/close state of the CollapsableFrame.

=back

=head1 ADVERTISED WIDGETS

Component subwidgets can be accessed via the B<Subwidget> method.
Valid subwidget names are listed below.

=over 4

=item Name:  colf, Class:  Frame

  Widget reference of the internal Frame widget within which user
  widgets are managed.

=back

=head1 EXAMPLE

 use Tk::widgets qw/CollapsableFrame Pane/;

 my $mw = MainWindow->new;

 my $pane = $mw->Scrolled(
      qw/Pane -width 250 -height 50 -scrollbars osow -sticky nw/,
 )->pack;

 my $cf = $pane->CollapsableFrame(-title => 'Frame1 ', -height => 50);
 $cf->pack(qw/-fill x -expand 1/);
 $cf->toggle;

 my $colf = $cf->Subwidget('colf');
 my $but = $colf->Button(-text => 'Close Frame 1!');
 $but->pack;
 $but->bind('<Button-1>' => [sub {$_[1]->close}, $cf]);

=head1 AUTHOR and COPYRIGHT

Stephen.O.Lidie@Lehigh.EDU, 2000/11/27.

Copyright (C) 2000 - 2003, Stephen O. Lidie.

This program is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

Based on the Tck/Tk CollapsableFrame widget by William J Giddings.

=head1 KEYWORDS

CollapsableFrame, Frame, Pane

=cut
