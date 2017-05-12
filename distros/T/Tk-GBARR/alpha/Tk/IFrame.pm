package Tk::IFrame;

use Tk;
use strict;
use vars qw(@ISA $VERSION);

@ISA = qw(Tk::Derived Tk::Frame);
$VERSION = "0.03";

Construct Tk::Widget "IFrame";

sub Populate {
    my($frame,$args) = @_;

    $frame->Tk::configure(-borderwidth => 0, -highlightthickness => 0);

    my $c = $frame->Component(Frame => 'container',
	-borderwidth => 2,
	-relief => 'raised'
    );

    $c->place(
	'-x' => 0,
	'-y' => 0,
	-relwidth => 1.0,
	-relheight => 1.0
    );

    $frame->ConfigSpecs(
	-borderwidth	  => [PASSIVE => undef, undef, 2],
	-relief		  => [PASSIVE => undef, undef, 'raised'],
	-selectbackground =>
		[PASSIVE => 'selectBackground', 'SelectBackground', 'red'],
	-background 	  => ['SELF'],

	# XXX these are ignored --- YET
	-ipadx => ['PASSIVE', 'ipadX', 'Pad', 0],
	-ipady => ['PASSIVE', 'ipadY', 'Pad', 0],
        -takefocus => ['SELF', 'takeFocus', 'TakeFocus', 0],
        -dynamicgeometry => ['PASSIVE', 'dynamicGeometry', 'DynamicGeometry', 0]
    );

    $frame->bind('<Configure>', [\&layoutRequest, 1]);

    $frame->bind('<Map>', [
	sub {
	    my $f = shift;
	    my $info = $f->privateData;
	    my $tags;

	    return
		unless defined($tags = $info->{'tags'}) && @$tags;
	    $f->update;
	    $f->selectCard($tags->[0]);
	},
    ]);

    $frame->privateData->{'tags'} = [];

    $frame;
}

sub layoutRequest {
    my($f,$why) = @_;
    $f->DoWhenIdle(['adjustLayout',$f]) unless $f->{'layout_pending'};
    $f->{'layout_pending'} |= $why;
}

sub adjustLayout {
    my $f = shift;
    $f->{'layout_pending'} = 0;

    my $info = $f->privateData;
    my $tags = $info->{'tags'};

    return unless $tags;

    my $bw = $f->{Configure}{'-borderwidth'};

    my($w,$h) = (0,0,0,0);
    my $t;
    my @rowHeight;
    my @rowWidth;

    foreach $t (@$tags) {
	$t->update;

	my $cardinfo = $t->privateData;
	my($lbl,$row) =($cardinfo->{label},$cardinfo->{row});
	my ($rw,$rh) = ($t->ReqWidth, $t->ReqHeight);

	$w = $rw
	    if $rw > $w;

	$h = $rh
	    if $rh > $h;

	$rowWidth[$row] = 0
	    unless defined($rowWidth[$row]);
	$rowWidth[$row] += $lbl->ReqWidth;

	$rh = $lbl->ReqHeight + $bw;
	$rowHeight[$row] = $rh
	    if !defined($rowHeight[$row]) || $rh > $rowHeight[$row];
    }

    my $nrows = @rowHeight;

    return unless $nrows > 0;

    my $tagHeight = 0;
    my @rowOrder = ();
    my $i;
    for($i = 0 ; $i < @rowHeight ; $i++) {
	next
	    unless defined($rowHeight[$i]);
	
	$tagHeight += $rowHeight[$i];
	unshift(@rowOrder, $i);
    }


    my $tw = $bw * 2 * @$tags;
    $w = $tw if $tw > $w;

    my $x = $bw;

    foreach $t (@$tags) {
	my $inf = $t->privateData;
	$inf->{tag}->place(
		'-x' => $x,
		'-y' => $bw,
		-width => $inf->{label}->ReqWidth + $bw*2,
		-height => $tagHeight + $bw
	);
	$inf->{label}->place(
		-in => $inf->{tag},
		'-x' => 0,
		'-y' => 0,
		-relwidth => 1.0,
		-height => $tagHeight
	);

	$f->Subwidget('container')->place(
		'-x' => 0,
		'-y' => $tagHeight,
		-height => -$tagHeight - $bw,
		-relwidth => 1.0,
		-relheight => 1.0
	);
	$x += $inf->{label}->ReqWidth + $bw*2;
    }
  
    $f->GeometryRequest($w,$h + $tagHeight + $bw + $bw);

    $f->{'layout_pending'} = 0;
}

sub selectCard {
    my $f = shift;
    my $page = shift;

    my $cntr = $f->Subwidget('container');

    $page = $cntr->Subwidget(lc $page)
	unless ref($page);

    my $info = $f->privateData;
    my $cur = $info->{'current'};

    return
	if defined($cur) && $cur == $page;

    my $con;

    my $bw = $f->{Configure}{'-borderwidth'};

    foreach $con ($cntr->Subwidget) {
	my $cardinfo = $con->privateData;
	if($con == $page) {
	    my %info = $cardinfo->{'tag'}->placeInfo;
	    $info{'-x'} -= $bw;
	    $info{'-y'} -= $bw;
	    $info{'-width'} += $bw*2;
	    $cardinfo->{'tag'}->place(%info);
	    $cardinfo->{'tag'}->raise;
	    $cardinfo->{'tag'}->lower($cntr) if $info{'-x'} == 0;
	    $cardinfo->{'label'}->raise;
	    $con->raise;
	    $info->{'current'} = $page;
	}
	elsif(defined($cur) && $con == $cur) {
	    my %info = $cardinfo->{'tag'}->placeInfo;
	    $info{'-x'} += $bw;
	    $info{'-y'} += $bw;
	    $info{'-width'} -= $bw*2;
	    $cardinfo->{'tag'}->place(%info);
	    $cardinfo->{'label'}->lower($cntr);
	    $cardinfo->{'tag'}->lower;
	}
    }

}

*add = \&addCard; # alias for addCard

sub addCard {
    my $f = shift;
    my $name = shift;

    my %arg = @_;

    my $row = delete $arg{-row} || 0;

    my $tf = $f->Frame(
	-borderwidth => 2,
	-relief => 'raised'
    );

    my $l = $f->Label(
	-text => $arg{'-label'},
	-borderwidth => 0,
	-padx => 4, -pady => 4,
	-anchor => $arg{'-anchor'} || 'w'
    );

    my $cf = $f->Subwidget('container')->Component( Frame => lc $name,
	-borderwidth => 0
    );


    $l->bind('<1>', [
	sub {
	    my($lbl,$f,$cf) = @_;
	    $f->selectCard($cf)
	},
	$f, $cf
    ]);

    $l->bind('<Any-Enter>', [ 
	sub {
	    my $l = shift;
	    my $s = $l->parent->cget('-selectbackground');
	    $l->configure(-background => $s);
	}
    ]);

    $l->bind('<Any-Leave>', [ 
	sub {
	    my $l = shift;
	    my $s = $l->parent->cget('-background');
	    $l->configure(-background => $s);
	}
    ]);

    my $info = $cf->privateData;

    $info->{label} = $l;
    $info->{tag} = $tf;
    $info->{row} = $row;

    push(@{$f->privateData->{'tags'}}, $cf);

    $cf->place(
	-relwidth  => 1.0,
	-relheight => 1.0,
    );

    $tf->raise;
    $tf->lower($f->Subwidget('container'));
    $l->lower;
    $l->raise($tf);
    $cf->lower;

    $f->layoutRequest(2);

    $cf;    
}

__END__

=head1 NAME

Tk::IFrame - An Indexed Frame

=head1 SYNOPSIS

    use Tk::IFrame;

=head1 DESCRIPTION

C<Tk::IFrame> defines a widget which enables multiple frames (cards) to be
defined, and then stacked on top of each other. Each card has an associated
tag, selecting this tag will cause the associated card to be brought to
the top of the stack.

=head1 STANDARD OPTIONS

I<-borderwidth -relief -selectbackground -background>

=head1 WIDGET-SPECIFIC OPTIONS

=over 4

=item none

=back

=head1 AUTHOR

Graham Barr E<lt>F<gbarr@ti.com>E<gt>

=head1 ACKNOWLEDGEMENTS

None - (yet :-)

=head1 COPYRIGHT

Copyright (c) 1997 Graham Barr. All rights reserved.
This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
