# $Id: TFrame.pm,v 2.2 2007/12/06 20:09:39 eserte Exp $

package Tk::TFrame;

use Tk;
use strict;
use vars qw($VERSION @ISA);

@ISA = qw(Tk::Derived Tk::Frame);
$VERSION = sprintf("%d.%02d", q$Revision: 2.2 $ =~ /(\d+)\.(\d+)/);

Construct Tk::Widget "TFrame";

sub ClassInit {
    my ($class,$mw) = @_;
    $mw->bind($class,'<Configure>',['layoutRequest']);
    $mw->bind($class,'<FocusIn>',  'NoOp');
    return $class;
}

sub Populate {
    my($frame,$args) = @_;

    $frame->Tk::configure(-borderwidth => 0, -highlightthickness => 0);

    my $border    = $frame->Component(Frame => "border");

    my @label = (
	-padx => 4,
	-pady => 2,
	-borderwidth => 2,
	-relief => 'flat'
    );

    if (exists $args->{'-label'}) {
       if (not ref $args->{'-label'}) {
           $args->{'-label'} = [ -text => $args->{'-label'} ];
       }
       push @label, @{$args->{'-label'}};
    }

    my $label     = $frame->Component(Label => "label",@label);

    my $container = $frame->Component(Frame => "container", -borderwidth => 0);


    $frame->DoWhenIdle(['Manage',$frame]);

    $frame->Default("container" => $container);

    $frame->ConfigSpecs(
	-label => [ 'METHOD', undef, undef, undef],
	-relief => [$border,'relief','Relief','groove'],
	-borderwidth => [$border,'borderwidth','Borderwidth',2],
	-ipadx => [PASSIVE => undef, undef, 0],
	-ipady => [PASSIVE => undef, undef, 0],
    );

    $frame;    
}

sub label {
    my $frame = shift;
    my $v = shift || [];
    my $l = $frame->Subwidget('label');

    $l->configure(@$v);
}

sub layoutRequest {
    my($f) = @_;
    $f->DoWhenIdle(['adjustLayout',$f]) unless $f->{'layout_pending'};
    $f->{'layout_pending'} = 1;
}

sub SlaveGeometryRequest {
    my ($m,$s) = @_;
    $m->DoWhenIdle(['_SlaveGeometryRequest',$m]) unless $m->{'geom_pending'};
    $m->{'geom_pending'} = 1;
}

sub Manage {
    my $f = shift;
    my $l = $f->Subwidget('label');
    my $c = $f->Subwidget('container');
    my $b = $f->Subwidget('border');

    $f->ManageGeometry($l);
    $l->MapWindow;
    $f->ManageGeometry($c);
    $c->MapWindow;
    $f->ManageGeometry($b);
    $b->MapWindow;
    SlaveGeometryRequest($f,$l);
}

sub _SlaveGeometryRequest {
    my $f = shift;
    my $l = $f->Subwidget('label');
    my $c = $f->Subwidget('container');
    my $b = $f->Subwidget('border');

    $f->{'geom_pending'} = 0;

    my $px = $f->{Configure}{'-ipadx'} || 0;
    my $py = $f->{Configure}{'-ipady'} || 0;

    my $bw = $b->cget('-borderwidth')*2;
    my $w  = $c->ReqWidth + $bw + $px*2;
    my $w2 = $l->ReqWidth + 20 + $bw;
    my $h  = $bw + $l->ReqHeight + $c->ReqHeight #+ $f->cget('-borderwidth')*2
		+ $py*2;

    $f->GeometryRequest($w > $w2 ? $w : $w2,$h);
}

sub adjustLayout {
    my $frame = shift;
    my $label = $frame->Subwidget('label');
    my $container = $frame->Subwidget('container');
    my $border = $frame->Subwidget('border');

    $frame->{'layout_pending'} = 0;
    my $rh = $label->ReqHeight;

    my $px = $frame->{Configure}{'-ipadx'} || 0;
    my $bw = $frame->{Configure}{'-borderwidth'} || 0;
    my $py = $frame->{Configure}{'-ipady'} || 0;
    my $W = $frame->Width;
    my $H = $frame->Height;

    $border->MoveResizeWindow(0,int($rh/2),$W,$H-int($rh/2));

    $container->MoveResizeWindow(
	$px+$bw,$rh + $py, $W - (($px+$bw) * 2), $H - $rh -$bw - ($px * 2));

    $label->MoveResizeWindow(10,0,$label->ReqWidth,$label->ReqHeight);
}

sub grid {
    my $w = shift;
    $w = $w->Subwidget('container')
	if (@_ && $_[0] =~ /^(?: bbox
				|columnconfigure
				|location
				|propagate
				|rowconfigure
				|size
				|slaves)$/x);
    $w->SUPER::grid(@_);
}

sub slave {
    my $w = shift;
    $w->Subwidget('container');
}

sub pack {
    my $w = shift;
    $w = $w->Subwidget('container')
	if (@_ && $_[0] =~ /^(?:propagate|slaves)$/x);
    $w->SUPER::pack(@_);
}

1;

__END__

=head1 NAME

Tk::TFrame - A Titled Frame widget

=head1 SYNOPSIS

    use Tk::TFrame;
    
    $frame1 = $parent->TFrame(
	-label => [ -text => 'Title' ],
	-borderwidth => 2,
	-relief => 'groove',
    );

    # or simply
    $frame2 = $parent->TFrame(
       -label => 'Title'
    );

    $frame1->pack;
    $frame2->pack;

=head1 DESCRIPTION

B<Tk::TFrame> provides a frame but with a title which overlaps the border
by half of it's height.

=head1 SEE ALSO

L<Tk::LabFrame|Tk::LabFrame>

=head1 AUTHOR

Graham Barr E<lt>F<gbarr@pobox.com>E<gt>

=head1 COPYRIGHT

Copyright (c) 1997-1998 Graham Barr. All rights reserved.
This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
