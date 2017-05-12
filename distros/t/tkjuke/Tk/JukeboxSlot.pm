$Tk::JukeboxSlot::VERSION = '2.0';

package Tk::JukeboxSlot;

# A jukebox media slot mega-widget.

use base qw/Tk::Frame/;
use strict;

Construct Tk::Widget 'JukeboxSlot';

our $bg       = '#d9d9d9';
our $font     = '9x15';

sub Populate {

    my($self, $args) = @_;

    $self->SUPER::Populate($args);

    my $m = $self->Component('Button'      => 'button',
        -highlightthickness => 0,
        -relief => 'flat',
        -state  => 'disabled',
    );
    my $l = $self->Component('Label'       => 'label');
    my $c = $self->Component('Checkbutton' => 'check');

    my (@pl) = qw/-side top -expand 1 -fill both/;
    $m->pack(@pl);
    $l->pack(@pl);
    $c->pack(@pl);

    $self->{mail}  = $m;
    $self->{check} = 0;

    my $command = [$self => 'toggle_mail_slot'];

    $self->ConfigSpecs(
        -borderwidth => [ $self,         qw/borderwidth Borderwidth    1/ ],
        -background  => [ qw/DESCENDANTS background     Background/,  $bg ],
        -barcode     => [ qw/METHOD      barcode        Barcode/          ],
        -barcodecmd  => [ qw/CALLBACK    barcodeCmd     BarcodeCmd/,undef ],
        -command     => [ $m,            qw/command     Command/,$command ],
        -font        => [ [$m, $l],      qw/font        Font/,      $font ],
        -foreground  => [ $l,            qw/foreground  Foreground  blue/ ],
        -height      => [ $l,            qw/height      Height        15/ ],
        -mail        => [ qw/PASSIVE     mail           Mail/,      undef ],
        -onvalue     => [ $c,            qw/onValue     OnValue/,       1 ],
        -offvalue    => [ $c,            qw/offValue    OffValue/,      0 ],
        -relief      => [ $self,         qw/relief      Relief     solid/ ],
        -slotnumber  => [ {-text => $c}, qw/slotNumber  SlotNumber     0/ ],
        -variable    => [ $c,   qw/variable    Variable/, \$self->{check} ],
        -width       => [ $l,            qw/width       Width          1/ ],
    );

    $l->bind('<Double-Button-1>' =>
	     [$self => 'Callback', '-barcodecmd', $self]);

} # end Populate

sub barcode {

    my ($self, $text) = @_;

    if ($text) {
	$self->Subwidget('label')->configure(-text =>
					     join("\n", split('', $text)));
    } else {
	return join('', split(/\n/, $self->Subwidget('label')->cget(-text)));
    }

} # end barcode

# Public methods;

sub toggle_mail_slot {

    my ($self) = @_;

    my $mail = ($self->cget(-mail) eq 'shut') ? 'open' : 'shut';
    $self->configure(-mail => $mail);
    $self->Subwidget('button')->configure(-text => $mail);

} # end toggle_mail_slot

1;
