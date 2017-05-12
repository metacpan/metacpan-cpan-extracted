package Tk::ListMgr;

use Tk qw(Ev);
use Tk::Cloth;
use Carp;
use strict;
use vars qw(@ISA $VERSION);

@ISA = qw(Tk::Derived Tk::Frame);
$VERSION = "0.02";

Construct Tk::Widget 'ListMgr';

*Tk::Widget::privateData = sub  {
    my $w = shift;
    my $p = shift || caller;
    $w->{$p} ||= {};
} unless defined &Tk::Widget::privateData;

sub ClassInit {
    my($class,$mw) = @_;
    $class->SUPER::ClassInit($mw);

    $mw->bind($class,"<1>",		['BeginSelect', Ev('index',Ev('@'))]);
    $mw->bind($class,"<Shift-1>",	['BeginExtend',Ev('index',Ev('@'))]);
    $mw->bind($class,"<Configure>" ,	['LayoutRequest', 1 ]);
    $mw->bind($class,"<FocusIn>" , 	['swapHighlight' ]);
    $mw->bind($class,"<FocusOut>" ,	['swapHighlight' ]);
}

sub swapHighlight {
    my $self = shift->Subwidget('cloth');
    $self->configure(
	-highlightbackground => $self->cget('-highlightcolor'),
	-highlightcolor => $self->cget('-highlightbackground'),
    );	
}

sub Populate {
    my $lmgr = shift;

    $lmgr->configure(
	-borderwidth => 0,
	-highlightthickness => 0
    );

    my $cloth = $lmgr->Cloth()->pack(
	-fill => 'both',
	-expand => 1
    );

    $lmgr->Advertise(cloth => $cloth);

    my $cb = [ 'ForwardEvent', Ev(['parent'])];

    foreach my $tag (qw(ButtonRelease ButtonPress KeyPress KeyRelease Motion)) {
	$cloth->bind(ref($cloth), "<Any-$tag>" , $cb);
    }
    $cloth->bindtags([ ref($cloth),$cloth->toplevel, 'all']);

    $lmgr->ConfigSpecs(
	DEFAULT => [$cloth],
	-layout => [METHOD => undef, undef, 'horizontal'],
	-takefocus => ["SELF", "takeFocus", "TakeFocus", 1],
	-background => [['SELF',$cloth],qw(background Background green)],
	-borderwidth => [$cloth, 'borderwidth','Borderwidth',2],
	-relief => [$cloth, 'relief','Relief','raised'],
	-highlightthickness => [$cloth, 'highlightThickness','HighlightThickness',0],
	-selectmode => [PASSIVE => undef, undef, 'single'],
    );

    my $data = $lmgr->privateData;

    %$data = (
	items		 => [],
	columns		 => [],
	headerConfigure	 => [],
	subitemConfigure => [],
	why		 => 0,
    );

    $lmgr;
}

sub col {
    my $lmgr = shift;
    my $index = shift;
    my $data = $lmgr->privateData;
    my $cols = $data->{'columns'} ||= [];

    return $cols->[$index]
	if defined $cols->[$index];

    my $col = $lmgr->Tag;
    my $l = $col->Component(Line => 'anchor',
			  -coords => [$index*100,0,$index*100,-20]
			 );

    $l->bind('<B1-Motion>', [
	sub {
	    my($line,$col,$x) = @_;
	    $x = $line->cloth->canvasx($x);
	    my $tx = ($col->SubItem('anchor')->coords)[0];
	    $x = 0 if $x < 0;
	    $col->move($x - $tx,0);
	}, $col, Ev('x') ]
    );

    $l->bind('<Any-Enter>', [
	sub { shift->cloth->configure(-cursor => 'sb_h_double_arrow') }]
    );
    $l->bind('<Any-Leave>', [
	sub { shift->cloth->configure(-cursor => undef) }]
    );

    $cols->[$index] = $col;
}

sub BeginSelect
{
 my $w = shift;
 my $el = shift;

 if ($w->cget("-selectmode") eq "multiple")
  {
   if ($w->selectionIncludes($el))
    {
     $w->selectionClear($el)
    }
   else
    {
     $w->selectionSet($el)
    }
  }
 else
  {
   $w->selectionClear(0,"end");
   $w->selectionSet($el);
   $w->selectionAnchor($el);
#   @Selection = ();
#   $Prev = $el
  }
}

sub Motion
{
}

sub BeginExtend
{
 my $w = shift;
 my $el = shift;
 if ($w->cget("-selectmode") eq "extended" && $w->selectionIncludes("anchor"))
  {
   $w->Motion($el)
  }
}

sub Button1 {
    my $lmgr = shift;
    my $cloth = $lmgr->Subwidget('cloth');
    my $x = $cloth->canvasx(shift);
    my $y = $cloth->canvasy(shift);

    return
	if $y <= 0 || $x <= 0;

    my @i = $cloth->find('overlapping',$x,$y,$x,$y);

    my $item = undef;
    my $i;

    foreach $i (@i) {
	next if $i->tag =~ /^seln/;
	$item = $i;
	last;
    }

    if($item) {
	$item = $item->parent
	    while $item->parent != $lmgr;
    }

    $lmgr->selectSet($item)
	unless $item && $item->{'selected'};
}

sub ShiftButton1 {
    my $lmgr = shift;
    my $x = $lmgr->canvasx(shift);
    my $y = $lmgr->canvasy(shift);

    $lmgr->selectAdd($lmgr->itemAt($x,$y));
}

sub LayoutRequest {
    my $lmgr = shift;
    my $why = shift;
    my $data = $lmgr->privateData;
    my $wref = \$data->{why};

    $lmgr->DoWhenIdle( [ 'arrange', $lmgr ])
	unless $$wref;

    $$wref ||= $why;
}

sub arrange {
    my $lmgr = shift;
    my $layout = $lmgr->layout;

    my $data = $lmgr->privateData;
    my $why = delete $data->{why};

    $lmgr->update
	if($why & 1);

    my $meth = "arrange_" . $layout;
    $lmgr->$meth(0);
}

sub layout {
    my $lmgr = shift;
    my $data = $lmgr->privateData;
    my $o = $lmgr->{Configure}{'-layout'} ||= 'vertical';
    if(@_) {
	my $new = shift;
	croak "Bad value for -layout, shoutl be one of horizontal, vertical, list"
		unless $new =~ /^(horizontal|vertical|list)$/;
	$lmgr->{Configure}{'layout'} = $new;
	$data->{H} = $data->{W} = 1;
	$lmgr->LayoutRequest(2);
    }
    $o;
}

sub subitemConfigure {
    my $lmgr = shift;
    my $index = shift;

    my $data = $lmgr->privateData;
    my $fmt = $data->{'subitemConfigure'};
    my $item = $fmt->[$index] ||= {
	-type => 'Text',
	-display => 1,
	-imageon => undef,
	-imageoff => undef,
	-width => undef,
    };

    return %$item
	unless @_;

    my %args = @_;

    %$item = (%$item, %args);

}

sub headerConfigure {
    my $lmgr = shift;
    my $index = shift;

    my $data = $lmgr->privateData;
    my $hdr = $data->{'headerConfigure'};
    my $item = $hdr->[$index] ||= {
	-type => 'Text',
	-text => '',
	-image => '',
	-columnspan => 1,
	-display => 1,
	-width => undef,
    };

    return %$item
	unless @_;

    my %args = @_;

    %$item = (%$item, %args);
}

my $pad = 2;

sub arrange_list {
    my $lmgr  = shift;
    my $start = shift;
    my $data  = $lmgr->privateData;
    my $items = $data->{'items'};
    my $cols  = $data->{'columns'};

    my $H = $data->{H} ||= 0;

    my $redo = 0;
    my $where = $start;

    for( ; $start < @$items ; $start++) {
	my $item = $items->[$start];
	my @rb = $item->SubItem(0)->bbox;
	my $ry = $rb[1] + int(($rb[3] - $rb[1]) / 2);
	my $i;
	my $subitem;

	for($i = 0 ; $subitem = $item->SubItem($i) ; $i++) {
	    my $column = $cols->[$i] ||= $lmgr->Tag;
	    my @b = $subitem->bbox;
	    my $dx = $pad - int(($subitem->coords)[0]);
	    my $dy = 0;
	    my $h = $b[3] - $b[1] + $pad;

	    $redo = $data->{H} = $H = $h
	        if $h > $H;

	    my $anchor = $column->SubItem('anchor');

	    unless(defined $anchor) {
		$anchor = $column->Component(
				Line => 'anchor',
				-coords => [ $i * 100,0, $i*100,-20]
			  );
		if($i) {
		    $anchor->bind('<B1-Motion>', [
			sub {
			    my($line,$col,$x) = @_;
			    $x = $line->cloth->canvasx($x);
			    my $tx = ($col->SubItem('anchor')->coords)[0];
			    $x = 0 if $x < 0;
			    $col->move($x - $tx,0);
			}, $column, Ev('x') ]
		    );
		    $anchor->bind('<Any-Enter>', [
			sub { shift->cloth->configure(-cursor => 'sb_h_double_arrow') }]
		    );
		    $anchor->bind('<Any-Leave>', [
			sub { shift->cloth->configure(-cursor => undef) }]
		    );
		}
	    }

	    $dx += int (($anchor->coords)[0]);

	    if($i) {
		my $y = $b[1] + (($b[3] - $b[1]) / 2);
		$dy = $ry - $y;
	    }
	    $subitem->move(int $dx,int $dy);
	    $column->addtagWithtag($subitem);
	}
    }
    $start = $redo ? 0 : $where;

    for( ; $start < @$items ; $start++) {
	my $item = $items->[$start];
	my @b = $item->SubItem(0)->bbox;
	my $y = $b[1] + int(($b[3] - $b[1]) / 2) - int($H / 2);
	my $seln = $item->SubItem('seln') ||
		$item->Component(Tag => 'seln');
	my $i;
	my $subitem;

	for($i = 0 ; $subitem = $item->SubItem($i) ; $i++) {
	    my $column = $cols->[$i];
	    my $x = int(($column->SubItem('anchor')->coords)[0]);
	    my $bg = $item->selected
		? $lmgr->cget(-selectbackground)
		: $lmgr->cget(-background);
	    my $r = $seln->SubItem($i) ||
		$seln->Component(Rectangle => $i,
			-coords => [0,0,0,0],
			-fill	  => $bg,
			-outline  => $bg,
		);
	    $r->coords($x-$pad,$y,10000,$y+$H);
	    $r->raise($subitem);
	    $r->lower($subitem);
	    $column->addtagWithtag($r);
	}
	$y = ($item->SubItem('seln')->SubItem(0)->coords)[1];
	$item->move(0,$start * $H - $y);
    }
    $lmgr->configure(-scrollregion => [0,-20,300,100]);
}




sub arrange_vertical {
    my $lmgr  = shift;
    my $start = shift;

    my $data  = $lmgr->privateData;
    my $items = $data->{'items'};
    my $cols  = $data->{'columns'};
    my $cloth = $lmgr->Subwidget('cloth');

    my $H      = $data->{H} ||= 1;
    my $W      = $data->{W} ||= 1;
    my $hlbw   = $cloth->cget('-highlightthickness') +
			$cloth->cget('-borderwidth');
    my $width  = $cloth->Width - $hlbw*2 - 2;
    my $across = int($width / $W) || 1;
    my $redo   = 0;
    my $where  = $start;
    my $mW     = 1;

    my $bg = $lmgr->cget('-background');

    for( ; $start < @$items ; $start++) {
	my $item = $items->[$start];
	my @rb = $item->SubItem(0)->bbox;
	my $ry = $rb[3];
	my $rx = $rb[0] + int(($rb[2] - $rb[0]) / 2);
	my $seln = $item->SubItem('seln') ||
		$item->Component(Tag => 'seln');
	my $i;
	my $subitem;

	for($i = 0 ; $subitem = $item->SubItem($i) ; $i++) {
	    my @b = $subitem->bbox;
	    my $dx = $rx - ($b[0] + int(($b[2] - $b[0]) / 2));
	    my $dy = $i ? $ry - $b[1] : 0;
	    $ry = $b[3] + $dy;

	    $subitem->move(int $dx,int $dy);
	    my $r = $seln->SubItem($i) ||
		$seln->Component(Rectangle => $i,
			-coords => [0,0,0,0],
			-fill	  => $bg,
			-outline  => $bg,
		);
	    $r->coords($subitem->bbox);
	    $r->raise($subitem);
	    $r->lower($subitem);
	    $r->delete unless $subitem->Tk_type eq 'text';
	}
	my @b = $item->bbox;
	my $h = $b[3] - $b[1];
	my $w = $b[2] - $b[0];

	$redo = $H = $data->{H} = $h
		if $h > $H;

	$mW = $w
	    if($w > $mW);
    }

    $across = int($width / $mW) || 1;

    $mW = int($width / $across)
	if $across < @$items;

    $redo = $W = $data->{W} = $mW
	if($mW != $W);

    $start = $redo ? 0 : $where;
    my $hW = int($W/2);
    my $hH = int($H/2);

    for( ; $start < @$items ; $start++) {
	my $item = $items->[$start];
	my @b = $item->bbox;
	my $cx = $b[0] + int(($b[2] - $b[0]) / 2);
	my $cy = $b[1] + int(($b[3] - $b[1]) / 2);
	my $x = ($start % $across) * $W + $hW;
	my $y = int($start / $across) * $H + $hH;

	$item->move($x - $cx,$y - $cy);
    }

    $cloth->configure(-scrollregion => [0,0,300,100]);
}


sub arrange_horizontal {
    my $lmgr  = shift;
    my $start = shift;

    my $data  = $lmgr->privateData;
    my $items = $data->{'items'};
    my $cols  = $data->{'columns'};
    my $cloth = $lmgr->Subwidget('cloth');

    my $H      = $data->{H} ||= 1;
    my $W      = $data->{W} ||= 1;
    my $hlbw   = $cloth->cget('-highlightthickness') +
			$cloth->cget('-borderwidth');
    my $width  = $cloth->Width - $hlbw*2 - 2;
    my $across = int($width / $W) || 1;
    my $redo   = 0;
    my $where  = $start;
    my $mW     = 1;

    my $bg = $lmgr->cget('-background');

    for( ; $start < @$items ; $start++) {
	my $item = $items->[$start];
	my @rb = $item->SubItem(0)->bbox;
	my $rx = $rb[2];
	my $ry = $rb[1] + int(($rb[3] - $rb[1]) / 2);
	my $seln = $item->SubItem('seln') ||
		$item->Component(Tag => 'seln');
	my $i;
	my $subitem;

	for($i = 0 ; $subitem = $item->SubItem($i) ; $i++) {
	    my @b = $subitem->bbox;
	    my $dy = $ry - ($b[1] + int(($b[3] - $b[1]) / 2));
	    my $dx = $i ? $rx - $b[0] : 0;
	    $rx = $b[2] + $dx;

	    $subitem->move(int $dx,int $dy);
	    my $r = $seln->SubItem($i) ||
		$seln->Component(Rectangle => $i,
			-coords => [0,0,0,0],
			-fill	  => $bg,
			-outline  => $bg,
		);
	    $r->coords($subitem->bbox);
	    $r->raise($subitem);
	    $r->lower($subitem);
	    $r->delete unless $subitem->Tk_type eq 'text';
	}
	my @b = $item->bbox;
	my $h = $b[3] - $b[1];
	my $w = $b[2] - $b[0];

	$redo = $H = $data->{H} = $h
		if $h > $H;

	$mW = $w
	    if($w > $mW);
    }

    $across = int($width / $mW) || 1;

    $mW = int($width / $across)
	if $across < @$items;

    $redo = $W = $data->{W} = $mW
	if($mW != $W);

    $start = $redo ? 0 : $where;
    my $hW = int($W/2);
    my $hH = int($H/2);

    for( ; $start < @$items ; $start++) {
	my $item = $items->[$start];
	my @b = $item->bbox;
	my $cx = $b[0]; # + int(($b[2] - $b[0]) / 2);
	my $cy = $b[1] + int(($b[3] - $b[1]) / 2);
	my $x = ($start % $across) * $W; # + $hW;
	my $y = int($start / $across) * $H + $hH;

	$item->move($x - $cx,$y - $cy);
    }

    $cloth->configure(-scrollregion => [0,0,300,100]);
}

sub itemAt {
    my $lmgr = shift;
    my $cloth = $lmgr->Subwidget('cloth');
    my($x,$y) = @_;
    my $item = ($cloth->find('overlapping',$x,$y,$x,$y))[0] or
	return undef;

    $item = $item->parent
	while($item->parent != $cloth);

    $item;
}

sub selectClear {
    my $cloth = shift;
    $cloth->selectSet(undef);
}

sub selectSet {
    my $lmgr = shift;
    my $item = shift;
    my $i;

    foreach $i (@{$lmgr->privateData->{'items'}}) {
	defined $item && $i == $item
		? $i->selectSet
		: $i->selectClear;
    }
}

sub selectAdd {
    my $lmgr = shift;
    my $item = shift;

    $item->selectSet
	if $item;
}

sub activate {
}

sub bbox {
}

sub curselection {
}

sub delete {
    my($lmgr,$start,$end) = @_;
}

sub get {
}

sub index {
    my $lmgr = shift;
    my $where = shift;
    my $idx = undef;
    my $data = $lmgr->privateData;
    my $items = $data->{'items'};

    if($where =~ /^\d+$/o) {
	return $where < @$items ? $where : undef;
    }
    elsif($where =~ /^@(\d+),(\d+)/o) {
	my $item = $lmgr->itemAt($1,$2);
	my $idx = 0;
	my $i;
	foreach $i (@$items) {
	    last if $i == $item;
	    $idx++;
	}
	return $idx < @$items ? $idx : undef;
    }
    elsif($where eq 'end') {
	my $n = @{$data->{'items'}} - 1;
	return $n >= 0 ? $n : undef;
    }
    elsif($where eq 'active') {
	return undef;
    }
    elsif($where eq 'anchor') {
	my $a = $data->{selectionAnchor};
	return defined $a ? $a : undef;
    }

    return undef;
}

sub insert {
    my $lmgr = shift;
    my $where = shift;

    my $data = $lmgr->privateData;
    my $fmt = $data->{'subitemConfigure'};
    my $bg = $lmgr->cget('-background');
    my $cloth = $lmgr->Subwidget('cloth');

    my @items = ();

    foreach my $item (@_) {
	my $tag = $cloth->ListItem;
	push(@items, $tag);
	my $seln = $tag->Component(Tag => 'seln');

	for(my $idx = 0 ; $idx < @$fmt ; $idx++) {
	    my $ifmt = $fmt->[$idx];

	    if(defined $item->[$idx] && defined $fmt->[$idx]) {
		my $type = $ifmt->{-type};
		if($type eq 'Text') {
		    $tag->Component(Text => $idx,
			-coords => [-100,-100],
			-text => $item->[$idx],
			-justify => 'left',
			-anchor => 'nw'
		    );
		}
		elsif($type eq 'Image') {
		    $tag->Component(Image => $idx,
			-coords => [-100,-100],
			-image => $item->[$idx],
			-anchor => 'nw'
		    );
		}
	    }
	    else {
		$tag->Component(Rectangle => $idx,
			-coords => [0,0,0,0],
			-fill => undef, 
			-outline => undef
		);
	    }
	    $seln->Component(Rectangle => $idx,
		-coords => [0,0,0,0],
		-fill => $bg, 
		-outline => $bg
	    );
	}
    }

    if(@items) {
	my $items = $data->{'items'};

	$where = $lmgr->index($where) || 0;

	splice(@{$items},$where,0,@items);
	$lmgr->LayoutRequest(4);
    }
}

sub nearest {
}

sub scan {
    my $lmgr = shift;
    my $opt = lc shift;
    my $meth = "scan\u$opt";
    $lmgr->$meth(@_);
}

sub scanMark {
}

sub scanDragto {
}

sub see {
}

sub selection {
    my $lmgr = shift;
    my $opt = lc shift;
    my $meth = "selection\u$opt";
    $lmgr->$meth(@_);
}

sub selectionAnchor {
    my $lmgr = shift;
    my $data = $lmgr->privateData;

    $data->{selectionAnchor} = shift;
}

sub selectionClear {
    my($lmgr,$start,$end) = @_;
    my $items = $lmgr->privateData->{'items'};

    return unless defined $start;

    $start = $lmgr->index($start);
    $end = defined $end ? $lmgr->index($end) : $start;

    for( ; $start <= $end ; $start++) {
	$items->[$start]->selectClear
	    if(defined($items->[$start]));
    }    
}

sub selectionIncludes {
    my $lmgr = shift;
    my $elem = shift;
    my $items = $lmgr->privateData->{'items'};

    defined($elem) &&
	defined($items->[$elem]) &&
	$items->[$elem]->selected;
}

sub selectionSet {
    my($lmgr,$start,$end) = @_;
    my $items = $lmgr->privateData->{'items'};

    return unless defined $start;

    $start = $lmgr->index($start);
    $end = defined $end ? $lmgr->index($end) : $start;

    for( ; $start <= $end ; $start++) {
	$items->[$start]->selectSet
	    if(defined($items->[$start]));
    }    
}

sub size {
}

sub xview {
}

sub yview {
}

package Tk::ListMgr::Item;

use vars qw(@ISA);
use Tk::Cloth;
@ISA = qw(Tk::Cloth::Tag);

Construct Tk::Cloth 'ListItem';

sub selected { shift->{'selected'} }

sub selectToggle {
    my $item = shift;

    $item->{'selected'}
	? $item->selectClear
	: $item->selectSet;
}

sub selectSet {
    my $item = shift;
    my $c = $item->cloth;
    my $bg = $c->cget('-selectbackground');
    $item->{'selected'} = 1;
    $item->SubItem('seln')->configure(-fill => $bg,-outline => $bg);
}

sub selectClear {
    my $item = shift;
    my $c = $item->cloth;
    my $bg = $c->cget('-background');

    $item->{'selected'} = 0;
    $item->SubItem('seln')->configure(-fill => $bg,-outline => $bg);
}

1;
