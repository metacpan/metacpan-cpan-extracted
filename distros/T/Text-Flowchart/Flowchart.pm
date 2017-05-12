package Text::Flowchart;

#Copyright (c) 1999 James A Thomason III (jim3@psynet.net). All rights reserved.
#This program is free software; you can redistribute it under the terms of the licence listed at the end
#of the module.

$VERSION = "1.00";

use Carp;


{
	my $i = 0;
	foreach ($boxes, $grid, $lines, $directed){
		$_ = $i++
	};
	
};

sub accessor {
	my $self = shift;
	my $prop = shift;
	
	$self->[$prop] = shift if @_;
	
	return $self->[$prop];
};

sub directed{ shift->accessor($directed, @_)};

sub new {

	my $class = shift;
	my %init = @_;
	my $self = [];			#why not a hash?  An array is a smidgen bit faster and no one is gonna see the underlying structure anyway
	bless $self, $class;	#Hey!  What are you doing looking in here anyway?  Use the nice OO interface I wrote you!
	
	$self->size(
		"width" => $init{"width"} ? $init{"width"} : -1, 
		"height" => $init{"height"} ? $init{"height"} : -1,
		"pad" => $init{"pad"},
		"debug" => $init{"debug"}
	);
	
	$self->directed($init{"directed"} || 0);
	
	return $self;
	
};

sub box {

	my $self = shift;
	
	my $box = Text::Flowchart::Shape::Box->new(@_, "parent" => $self);
	
	croak("Box was not created properly\n") unless $box;
	
	
	push @{$self->[$boxes]}, $box || croak("Cannot add box to flowchart stack\n");
	
	return $self->[$boxes]->[-1];
};

sub line {

	my $self = shift;
	
	my %init = @_;
	
	my $line;
	if ($init{"orientation"} eq "V"){
		$line = Text::Flowchart::Shape::Line::Vertical->new(@_, "parent" => $self);
	}
	elsif ($init{"orientation"} =~ m/^(T|B)C$/){
		$line = Text::Flowchart::Shape::Line::Corner->new(@_, "parent" => $self);
	}
	elsif ($init{"orientation"} eq "H"){
		$line = Text::Flowchart::Shape::Line::Horizontal->new(@_, "parent" => $self);
	}
	else {croak("Invalid orientation.  Must be 'H', 'V', 'TC', or 'BC'\n")};
	
	croak("Line was not created properly.\n") unless $line;
	
	
	
	push @{$self->[$lines]}, $line || croak("Cannot add line to flowchart stack\n");
	
	return $self->[$lines]->[-1];
};

sub size {
	
	my $self = shift;
	
	if (@_) {
		my $_grid = Text::Flowchart::Grid->new(@_);
		croak("Cannot create grid\n") unless $_grid;
		$self->[$grid] = $_grid;
	};
	
	return $self->[$grid];

};

sub draw {
	my $self = shift;
	
	local *OUTPUT;
	*OUTPUT = shift || *STDOUT;
	
	my $grid = $self->size();
	my ($x, $y, $x2, $y2) = (0,0,0,0);
	
	foreach $box (@{$self->[$boxes]}){
		$grid->insert($box)
	};
	
	foreach $line (@{$self->[$lines]}){
		$grid->insert($line)
	};
	
	#print OUTPUT "\n";
	
	$grid->repair();
	
	if ($grid->debug()){
		print OUTPUT " ";
		my $width = $grid->width();
		while ($width-- > 0){
			print OUTPUT ($x++ % 10 || $x2++);
		};
		print OUTPUT "\n";
	};
	foreach (0..$#{$grid->grid()}){
	print OUTPUT ($y++ % 10 || $y2++) if $grid->debug();
		if (length $grid->grid->[$_] == $grid->width()){print OUTPUT $grid->grid->[$_], "\n"}
		else {print OUTPUT $grid->pad() x $grid->width(), "\n"};
	};
};

sub relate {
	my $self = shift;

	my $from_array = shift;
	my $to_array = shift;
	
	my %init = @_;

	my ($from, $from_side, $from_offset) = @{$from_array};
	my ($to, $to_side, $to_offset)     = @{$to_array};
	if ($from->parent() ne $self){croak("Cannot relate from a box not inside this flowchart.\n")};
	if ($to->parent()   ne $self){croak("Cannot relate to a box not inside this flowchart.\n")};
	if ($from_side !~ /^(top|bottom|right|left)$/){croak("Invalid side.  Side must be 'top', 'bottom', 'left', or 'right'.\n")};
	if ($to_side   !~ /^(top|bottom|right|left)$/){croak("Invalid side.  Side must be 'top', 'bottom', 'left', or 'right'.\n")};
	if ($from_side eq $to_side){croak("Cannot relate the same sides of boxes.  Use different sides.\n")};
	if (length $init{"reason"} > 1){croak("Reasons must be a single character.\n")};
	
	return $from->relate(
		"to" 			=> $to, 
		"from_side"		=> $from_side, 
		"to_side"		=> $to_side, 
		"from_offset"	=> $from_offset,
		"to_offset"		=> $to_offset,
		"reason"		=> $init{"reason"}
	);
	
};

package Text::Flowchart::Grid;

use Carp;

@ISA = qw(Text::Flowchart);

$def_width = 72;
$def_height = 0;
$def_pad = " ";

{
	my $i = 0;
	foreach ($width, $height, $grid, $pad, $debug){
		$_ = $i++
	};
	
};

sub width 	{shift->accessor($width, @_)};
sub height 	{shift->accessor($height, @_)};
sub grid 	{shift->accessor($grid, @_)};
sub pad 	{shift->accessor($pad, @_)};
sub debug 	{shift->accessor($debug, @_)};

sub new {
	my $class = shift;
	my $self = [];
	bless $self, $class;
	my %init = @_;
	
	my $width = $init{"width"};
	my $height = $init{"height"};
	my $pad = $init{"pad"};
	my $debug = $init{"debug"};
	
	croak("Invalid dimensions.\n") unless $width =~ /^-?\d*$/ && $height =~ /^-?\d*$/;
	
	$self->width($width >  0 ? $width : $def_width);
	$self->height($height >= 0 ? $height : $def_height);
	$self->pad(length $pad == 1 ? $pad : $def_pad);
	$self->debug($debug || 0);
	$self->[$grid] = [];
	foreach (1..$self->height){
		push @{$self->[$grid]}, $pad x $self->width();
	};
	
	return $self;

};

sub insert {
	my $self = 	shift;
	my $box = shift;
	my $x = $box->x_coord();
	my $y = $box->y_coord();
	
	defined $box || croak("Nothing to insert.\n");
	if (($x < 0 || $x + length $box->render->[0] > $self->width)  && $self->width != 0)		{croak("Your object is too wide for the page.\n")};
	if (($y < 0 || $y + @{$box->render()}	 > $self->height) && $self->height != 0)		{croak("Your object is too tall for the page.\n")};
	foreach $entry (@{$box->render()}){
		my ($line, $offset) = @{$entry};
		$self->[$grid]->[$y] = $self->pad() x $self->width() unless $self->[$grid]->[$y];
		substr($self->[$grid]->[$y++], $x + $offset, length $line) = $line;
	};
	
	return 1;
};

sub repair {
	my $self = shift;


	return 1;
};



package Text::Flowchart::Shape;

use Carp;

$def_width = 15;
$def_height = 0;

$PROP_COUNT = 0;
foreach ($string, $width, $height, $x_coord, $y_coord, $parent, 
			$real_width, $real_height, $rendered){
	$_ = $PROP_COUNT++;
};


sub accessor {

	my $self = shift;
	my $prop = shift;

	$self->[$prop] = shift if @_;
	
	return $self->[$prop];
};

sub string 		{shift->accessor($string, @_)};
sub width 		{shift->accessor($width, @_)};
sub height 		{shift->accessor($height, @_)};
sub x_coord		{shift->accessor($x_coord, @_)};
sub y_coord		{shift->accessor($y_coord, @_)};
sub parent 		{shift->accessor($parent, @_)};
sub real_width 	{shift->accessor($real_width, @_)};
sub real_height {shift->accessor($real_height, @_)};
sub rendered 	{shift->accessor($rendered, @_)};

sub init {
	my $class = shift;
	my $self = [];
	bless $self, $class;

	my %init = @_;
		
	$self->string($init{"string"} || undef);
	$self->width($init{"width"} > 0 ? $init{"width"} : $def_width);
	$self->height($init{"height"} > 0 ? $init{"height"} : $def_height);
	$self->x_coord($init{"x_coord"} >= 0 ? $init{"x_coord"} : croak("X coordinate must be specified and non-negative\n"));
	$self->y_coord($init{"y_coord"} >= 0 ? $init{"y_coord"} : croak("X coordinate must be specified and non-negative\n"));
	
	return $self;

};

package  Text::Flowchart::Shape::Box;

use Carp;


@ISA = qw(Text::Flowchart::Shape);

$def_x_pad = 1;
$def_y_pad = 1;

{
	my $PROP_COUNT = $Text::Flowchart::Shape::PROP_COUNT;
	foreach ($x_pad, $y_pad, $format_char, $top_links, $bottom_links, $left_links, $right_links){
		$_ = $PROP_COUNT++;
	};
};

sub x_pad 		{shift->accessor($x_pad, @_)};
sub y_pad 		{shift->accessor($y_pad, @_)};
sub format_char	{shift->accessor($format_char, @_)};
sub top_links	{shift->accessor($top_links, @_)};
sub bottom_links{shift->accessor($bottom_links, @_)};
sub left_links	{shift->accessor($left_links, @_)};
sub right_links	{shift->accessor($right_links, @_)};

sub relate 	{
	my $from = shift;
	
	my %init = @_;
	
	my $to = $init{"to"} || croak("No shape to relate to.\n");
	my $from_side = $init{"from_side"} || croak("No shape to relate from.\n");
	my $to_side = $init{"to_side"} || croak("No side to relate to.\n");
	my $from_offset = $init{"from_offset"} || 0;
	my $to_offset = $init{"to_offset"} || 0;
	my $reason = $init{"reason"} || undef;

	if ($from->parent() ne $to->parent){croak("No shape to relate to.\n")};
	if ($from_side !~ /^(top|bottom|right|left)$/){croak("Invalid side.  Side must be 'top', 'bottom', 'left', or 'right'.\n")};
	if ($to_side   !~ /^(top|bottom|right|left)$/){croak("Invalid side.  Side must be 'top', 'bottom', 'left', or 'right'.\n")};
	if ($from_side eq $to_side){croak("Cannot relate the same sides of boxes.  Use different sides.\n")};
	if (length $reason > 1){croak("Reasons must be a single character.\n")};


	my $from_coords =  $from->get_next_coord($from_side, $from_offset);
	my $to_coords   = $to->get_next_coord($to_side, $to_offset);

	my $orientation = undef;
	
	if 	  ($from_side =~ m/^(lef|righ)t$/ 	&& $to_side =~ m/^(lef|righ)t$/){$orientation = "H"}
	elsif ($from_side =~ m/^(top|bottom)$/ 	&& $to_side =~ m/^(top|bottom)$/){$orientation = "V"}
	elsif ($from_side eq "top" 				&& $to_side =~ m/^(lef|righ)t$/){$orientation = "TC"}
	elsif ($from_side eq "bottom" 			&& $to_side =~ m/^(lef|righ)t$/){$orientation = "BC"}
	elsif ($from_side =~ m/^(lef|righ)t$/ 	&& $to_side eq "bottom"){$orientation = "BC"}
	elsif ($from_side =~ m/^(lef|righ)t$/ 	&& $to_side eq "top"){$orientation = "TC"};		
	$from->parent->line(
		"from" 			=> $from_coords,
		"to" 	 		=> $to_coords,
		"orientation" 	=> $orientation,
		"reason" 		=> $reason
	);
	
	return 1;
		 
};

sub get_next_coord {
	my $self = shift;
	$i =0;
	my $side = shift || return "SIDE";
	my $offset = shift || "0";
	my %map = ("top" => $top_links, "bottom" => $bottom_links,
			"left" => $left_links, "right" => $right_links);

	my $side_num = $map{$side};
	return "COUNT $side" if scalar $self->[$side_num] <= 0;
	
	
	if ($side eq "top"){
		return [$self->x_coord() + $self->_get_offset($self->top_links(), $offset), $self->y_coord()];
		
	}
	elsif ($side eq "bottom"){
		return [$self->x_coord() + $self->_get_offset($self->bottom_links(), $offset), $self->y_coord() + $self->real_height() - 1];
	}
	elsif ($side eq "left"){
		return [$self->x_coord(), $self->y_coord() + $self->_get_offset($self->left_links(), $offset)];
	}
	elsif ($side eq "right"){
		return [$self->x_coord() + $self->real_width() - 1, $self->y_coord() + $self->_get_offset($self->right_links(), $offset)];
	}
	else {return "ORIENT"};
	
};

sub _get_offset {
	my $self = shift;
	my $side = shift || croak("No side supplied to _get_offset.\n");
	my $offset = shift;
	my $real_offset = 0;
	
	if ($offset == 0){$real_offset = shift @{$side}; $real_offset++}
	elsif ($offset == -1){$real_offset = pop @{$side};}
	else {
		my ($i, $found) = (0,0);
		foreach $i (0.. $#{$side}){
			if ($side->[$i] == $offset){
				$found++;
				$real_offset = $side->[$i] + 1;
				splice(@{$side}, $i, 1);
				last;
			};
		};
		unless ($found){$real_offset = shift @{$side}; $real_offset++};

	};

	return $real_offset;
};

sub new {
	my $class = shift;
	my $self = $class->init(@_);

	my %init = @_;
		
	$self->x_pad(defined $init{"x_pad"} && $init{"x_pad"} >= 0 ? $init{"x_pad"} : $def_x_pad);
	$self->y_pad(defined $init{"y_pad"} && $init{"y_pad"} >= 0 ? $init{"y_pad"} : $def_y_pad);
	$self->format_char(defined $init{"format_char"} ? $init{"format_char"} : undef);
	$self->parent($init{"parent"} || undef);

	croak("Invalid width.\n") 	if $self->width()  - 2 - $self->x_pad() * 2 < 1 && $self->width()  > 0;
	croak("Invalid height.\n")	if $self->height() - 2 - $self->y_pad() * 2 < 1 && $self->height() > 0; 
	
	$self->render();
	
	my @top_links = ();
	my @bottom_links = ();
	my @left_links = ();
	my @right_links = ();
	
	foreach my $i (0..$self->real_width() - 2){push @top_links, $i};
	foreach my $i (0..$self->real_width() - 2){push @bottom_links, $i};
	foreach my $i (0..$self->real_height() - 2){push @left_links, $i};
	foreach my $i (0..$self->real_height() - 2){push @right_links, $i};

	$self->top_links(\@top_links);
	$self->bottom_links(\@bottom_links);
	$self->left_links(\@left_links);
	$self->right_links(\@right_links);

	return $self;

};

sub render {
	my $self = shift;
	
	return $self->rendered() if $self->rendered();
	
	my $string = $self->string();
	my $width = $self->width();
	my $height = $self->height();
	my $x_pad = $self->x_pad();
	my $y_pad = $self->y_pad();
	my $page_width =  $self->parent->size->[0];
	my $page_height = $self->parent->size->[1];
	
	my $box_width  = ($width  < $page_width  || $page_width == 0 ? $width  : $page_width );
	my $box_height = ($height < $page_height || $page_height == 0 ? $height : $page_height);
	
	my $wrap_width  = $box_width  - 2 - $x_pad * 2;
	my $wrap_height = $box_height - 2 - $y_pad * 2;
	
	

	$string =~ s/(.{1,$wrap_width}(?:\b|$)|\S{$wrap_width})\s*/$1\n$2/g unless $box_width == 0;
	my @string = split(/\n/, $string);
	foreach (@string){
		if (length $_ + 2 * $x_pad < $wrap_width) {
			$_ .= " " x ($wrap_width - (length $_));
		};
		s/^/"|" . " " x $x_pad/gme;
		s/$/(" " x $x_pad) . "|"/gme;
		$_ = [$_, 0];
	};
	@string = splice(@string, 0, $wrap_height) unless $box_height == 0;
		
	while ($y_pad-- > 0) {
		push 	@string, ["|" . " " x ($box_width ? $box_width - 2 : (length $string) + $x_pad * 2) . "|", 0];
		unshift @string, ["|" . " " x ($box_width ? $box_width - 2 : (length $string) + $x_pad * 2) . "|", 0];
	};
	
	my $remaining_height = $box_height - @string - 2;	#don't forget to drop 2 for the top and bottom lines!
		
	while ($remaining_height-- > 0) {
		push 	@string, ["|" . " " x ($box_width ? $box_width - 2 : (length $string) + $x_pad * 2) . "|", 0];
	};
	
	push 	@string, ["+" . "-" x ($box_width ? $box_width - 2 : (length $string) + $x_pad * 2) . "+", 0];
	unshift @string, ["+" . "-" x ($box_width ? $box_width - 2 : (length $string) + $x_pad * 2) . "+", 0];
	
	$self->real_width($box_width ? $box_width : (length $string) + $x_pad * 2 + 2);
	$self->real_height(scalar @string);
	
	return $self->rendered(\@string);
	

};



package  Text::Flowchart::Shape::Line;

use Carp;


@ISA = qw(Text::Flowchart::Shape);

{
	my $PROP_COUNT = $Text::Flowchart::Shape::PROP_COUNT;
	foreach ($from, $to, $reason, $orientation, $xfrom, $xto, $yfrom, $yto, $xdistance, $ydistance,
				$xleft, $xright, $ytop, $ybottom, $xmiddle, $ymiddle, $width, $height){
		$_ = $PROP_COUNT++;
	};
	
};

sub from 		{shift->accessor($from, @_)};
sub to 			{shift->accessor($to, @_)};
sub reason 		{shift->accessor($reason, @_)};
sub orientation {shift->accessor($orientation, @_)};
sub xfrom 		{shift->accessor($xfrom, @_)};
sub xto 		{shift->accessor($xto, @_)};
sub yfrom 		{shift->accessor($yfrom, @_)};
sub yto 		{shift->accessor($yto, @_)};
sub xdistance 	{shift->accessor($xdistance, @_)};
sub ydistance 	{shift->accessor($ydistance, @_)};
sub xleft 		{shift->accessor($xleft, @_)};
sub xright 		{shift->accessor($xright, @_)};
sub ytop 		{shift->accessor($ytop, @_)};
sub ybottom 	{shift->accessor($ybottom, @_)};
sub xmiddle 	{shift->accessor($xmiddle, @_)};
sub ymiddle 	{shift->accessor($ymiddle, @_)};
sub width 		{shift->accessor($width, @_)};
sub height 		{shift->accessor($height, @_)};

sub new {

	my $class = shift;
	my $self = $class->init(@_);

	if ($class eq "Text::Flowchart::Shape::Line"){
		if ($class eq "Text::Flowchart::Shape::Line::Horizontal"){
			return Text::Flowcahrt::Shape::Line::Horizontal->new(@_);
		}
		elsif ($class eq "Text::Flowchart::Shape::Line::Vertical"){
			return Text::Flowcahrt::Shape::Line::Vertical->new(@_);
		}
		elsif ($class eq "Text::Flowchart::Shape::Line::Corner"){
			return Text::Flowcahrt::Shape::Line::Corner->new(@_);
		};
	}
	else {

		my %init = @_;
		
		
		if (ref $init{"from"} eq "ARRAY" && @{$init{"from"}} == 2){
			$self->from($init{"from"});
		}
		else {
			croak("Invalid from coordinates, should be [x,y]");
		};
		
		if (ref $init{"to"} eq "ARRAY" && @{$init{"from"}} == 2){
			$self->to($init{"to"});
		}
		else {
			croak("Invalid to coordinates, should be [x,y]");
		};
		
		$self->reason($init{"reason"} || undef);
		$self->orientation($init{"orientation"} || croak("I require an orientation.  'HR', 'HL', 'VT', 'VB' please.\n"));
		$self->parent($init{"parent"} || undef);
		
		$self->xfrom($self->from->[0]);
		$self->yfrom($self->from->[1]);	
		
		$self->xto($self->to->[0]);
		$self->yto($self->to->[1]);
		
		$self->width(abs ($self->xfrom() - $self->xto()) + 1);
		$self->height(abs ($self->yfrom() - $self->yto()) + 1);
		
		unless ($self->width() == 1 || $self->width() > 2){croak("Invalid width.  Make your shape wider.\n")};
		
		$self->xdistance($self->width()  - 2);
		$self->ydistance($self->height() - 2);
		
		$self->xleft(int ($self->xdistance() / 2));
		$self->ytop(int ($self->ydistance() / 2));
		
		$self->xright($self->xdistance() - $self->xleft() - 1);
		$self->ybottom($self->ydistance() - $self->ytop() - 1);
		
		
		$self->xmiddle(1 + ($self->offset() ? $self->xleft() : $self->xright()));
		$self->ymiddle(1 + ($self->offset() ? $self->ytop() : $self->ybottom()));

		$self->render();
		
		return $self;
	
	};

};

sub offset {
	my $self = shift;

	return (($self->xfrom() > $self->xto()) xor ($self->yto() > $self->yfrom())) || 
			(($self->xfrom() < $self->xto()) xor ($self->yto() < $self->yfrom()));
};

sub end_char {
	my $self = shift;
	
	my $direction = shift;
	if ($direction =~ /V/){
		if ($self->reason()){
			if (($self->yfrom() < $self->yto() && $direction eq "VT") 
				|| ($self->yfrom() > $self->yto() && $direction eq "VB")){
					return $self->reason()};
		};
		
		if ($self->yfrom() < $self->yto()){return "V"}
		else {return "^"};
	}
	elsif ($direction =~ /H/){
		if ($self->reason()){
			if (($self->xfrom() < $self->xto() && $direction eq "HL") 
				|| ($self->xfrom() > $self->xto() && $direction eq "HR")){
					return $self->reason()};
		};
		
		if ($self->xfrom() < $self->xto()){return ">"}
		else {return "<"};
	}
	else {croak("Invalid direction for end_char.  Must be 'HR', 'HL', 'VT', or 'VB'.\n")};
};

sub end {
	my $self = shift;

	return "+" unless $self->parent->directed();

	my $arg = shift;
	my $direction = shift;
	
	if ($self->xdistance >= 0 && $self->ydistance >= 0){

		if 		($arg == 1)		{return $self->offset() ? "+" : $self->end_char($direction)}
		elsif   ($arg == 2) 	{return $self->offset() ? $self->end_char($direction) : "+"}
		else 					{return $self->end_char($direction)};
	}
	else {return $self->end_char($direction)};
	
};

package  Text::Flowchart::Shape::Line::Horizontal;

use Carp;


@ISA = qw(Text::Flowchart::Shape::Line);

sub render {
	my $self = shift;
	
	return $self->rendered() if $self->rendered();
	
		
	my @string = ();
	
	if ($self->xdistance() >= 0 && $self->ydistance() >= 0){
		push @string, [$self->end(2, "HL") . ("-" x $self->xleft()) . $self->end(1, "HR"), $self->offset() ? 0 : $self->xmiddle()];
		my $yd2 = $self->ydistance();
		while ($yd2-- > 0){
			push @string, ["|", $self->xmiddle()];
		};
		
		push @string, [$self->end(1, "HL") . ("-" x $self->xright()) . $self->end(2, "HR"), $self->offset()  ? $self->xmiddle() : 0];

	}
	elsif ($self->xdistance() > 0) {
		push @string, [$self->end(0, "HL") . ("-" x $self->xdistance()) . $self->end(0, "HR"), 0];
	}
	else {croak("You're trying to draw a vertical line with a horizontal object.  Use a Vertical line.\n")};

	$self->x_coord($self->xfrom() > $self->xto() ? $self->xto() : $self->xfrom());
	$self->y_coord($self->yfrom() > $self->yto() ? $self->yto() : $self->yfrom());
	return $self->rendered(\@string);
};	

package  Text::Flowchart::Shape::Line::Vertical;

use Carp;


@ISA = qw(Text::Flowchart::Shape::Line);

sub render {
	my $self = shift;
	
	return $self->rendered() if $self->rendered();
		
	my @string = ();
	
	if ($self->xdistance() >= 0 && $self->ydistance() >= 0){
		push @string, [$self->end(0, "VT"), $self->offset() ? 0 : $self->xdistance() + 1];
		my $yd2 = $self->ytop();
		while ($yd2-- > 0){
			push @string, ["|", $self->offset() ? 0 : $self->xdistance() + 1];
		};
		
		push @string, ["+" . ("-" x $self->xdistance()) . "+", 0];
		
		$yd2 = $self->ybottom();
		while ($yd2-- > 0){
			push @string, ["|", $self->offset() ? $self->xdistance() + 1: 0];
		};
		
		push @string, [$self->end(0, "VB"), $self->offset() ? $self->xdistance() + 1 : 0];

	}
	elsif ($self->ydistance() > 0 ) {
		push @string, [$self->end(0, "VT"), 0];
		my $yd2 = $self->ydistance();
		while ($yd2-- > 0){
			push @string, ["|", 0];
		};
		push @string, [$self->end(0, "VB"), 0];
	}
	else {croak("You're trying to draw a horizontal line with a hertical object.  Use a Vertical line.\n")};

	$self->x_coord($self->xfrom() > $self->xto() ? $self->xto() : $self->xfrom());
	$self->y_coord($self->yfrom() > $self->yto() ? $self->yto() : $self->yfrom());
	return $self->rendered(\@string);
};	

package  Text::Flowchart::Shape::Line::Corner;

use Carp;


@ISA = qw(Text::Flowchart::Shape::Line);

sub render {
	my $self = shift;
	
	return $self->rendered() if $self->rendered();	
	
		
	my @string = ();
	
	if ($self->orientation() eq "BC"){
			my $yd2 = $self->ydistance();
			while ($yd2-- > 0){
				push @string, ["|", $self->offset() ? 0 : $self->xdistance() + 1];
			};
		push @string, [$self->end(1, "HL") . ("-" x $self->xdistance()) . $self->end(2, "HR"), 0];
		unshift @string, [$self->end(0, "VT"), $self->offset() ? 0 : $self->xdistance() + 1];

	}
	elsif ($self->orientation() eq "TC") {
		my $yd2 = $self->ydistance();
		while ($yd2-- > 0){
			push @string, ["|", $self->offset() ? $self->xdistance() + 1: 0];
		};
		unshift @string, [$self->end(2, "HL") . ("-" x $self->xdistance()) . $self->end(1, "HR"), 0];
		push @string, [$self->end(0, "VB"), $self->offset() ? $self->xdistance() + 1: 0];
	}
	else {croak("Invalid orientation for Line::Corner::render.  Must be 'TC' or 'BC'.\n")}


	$self->x_coord($self->xfrom() > $self->xto() ? $self->xto() : $self->xfrom());
	$self->y_coord($self->yfrom() > $self->yto() ? $self->yto() : $self->yfrom());
	return $self->rendered(\@string);
};	

1;

__END__

=pod

=head1 NAME

Text::Flowchart - ASCII Flowchart maker

=head1 AUTHOR

Jim Thomason, jim3@psynet.net

=head1 SYNOPSIS

 +-------+      +-------------+
 | BEGIN >---+  |             |                    
 +-------+   +--> Do you need |                    
                | to make a   N------+             
       +--------Y flowchart?  |      |             
       |        |             |      |             
       |        +-------------+      |             
       |                             |             
       |         +------------+      |             
       |         |            |      |             
 +-----V-------+ | So use it. |      |             
 |             | |            |      |             
 | Then my     | +--^---V-----+      |             
 | module may  |    |   |            |             
 | help.       |    |   |            |             
 |             >----+   |            |             
 +-------------+        |            |              
                        |      +-----V-------+     
                        |      |             |     
                        |      | Then go do  |     
                        +------> something   |     
                               | else.       |     
                               |             |     
                               +-------------+     


=head1 DESCRIPTION

Text::Flowchart does what the synopsis implies, it makes ASCII flowcharts.
It also (hopefully) makes it easy to make ASCII flowcharts.

=head1 REQUIRES

Carp

=head1 OBJECT METHODS

=head2 CREATION

New flowcharts are created with the new constructor.

$object = Text::Flowchart->new();

You can also initialize values at creation time, such as:

 $object = Text::Flowchart->new(
			"width"	=>	120,
			"debug"	=>	1
		);

=head2 ACCESSORS

There aren't any.  Well, there aren't any that you really should use.

Why's that, you ask?  Because that's how the module is written.  Once an object is added into a flowchart, its appearance
becomes set in stone.  And I mean totally set in stone, you cannot remove a box from a flowchart, it sticks around until the 
flowchart is destroyed.  Even if you poked around in the internals of the module and discovered that ->string is an accessor
in the box class, for instance, it wouldn't do you any good since objects are immediately rendered upon their creation.  Even if
you re-render the object after fiddling with it, it's not going to work since the objects are inserted into the flowchart's internal
grid once they're rendered.

So basically, declare everything you need to declare about an object when you create it, and make sure that that's the information
you're going to use when you print it out.  It's not I<that> hard.  :)

=head2 Methods

There are several methods you are allowed to invoke upon your flowchart object.

=over 10

=item B<new> (?width? ?height? ?pad? ?debug?)

This is the object constructor that actually creates your flowchart object.  All parameters are optional and are passed in a hash.

=over 1

=item width

I<Optional>. Specifies the width of your flowchart object, or uses the module default (72).

The width of a flowchart must be specified, it cannot grow to accomodate objects placed within it.  If you try to place an object beyond the edge
of the flowchart, you'll die with an error. 

=back

=over 1

=item height

I<Optional>. Specifies the height of your flowchart object, or uses the module default (0).

The default height of 0 means that your flowchart will grow in height as much as necessary to accomodate the height of whatever you insert into your
flowchart.  You can also specify a specific height so that your flowchart will be no taller than 17 rows, for example.  If you try to place an object
beyond the bottom of the flowchart, you'll die with an error.

=back

=over 1

=item pad

I<Optional>. pad allows you to specify a padding character.  The padding character is what is used to fill in the space between boxes and lines.  The default padding
character is a space (\040), but you can set it to anything else you'd like.  This is most useful when debugging, IMHO.  Very useful in combination with
debug (see below).  Set to " " by default.

=back

=over 1

=item debug

I<Optional>. debug will print out the x & y coordinates of the flowchart.  This should greatly help you place your boxes where you want them to be.  Off by default,
set to 1 to enable.

=back

=over 1

=item directed

I<Optional>. directed specifies that your flowchart is direction dependent.  This will add on arrows to all of your lines.  Flowcharts are non-directed by default.
Set this to 1 to use a directed flowchart.

=back

For example:

 $flowchart = Text::Flowchart::new->();	#boring flowchart, no options
 
 $flowchart = Text::Flowchart::new->(	#flowchart specifying new width, a % as the padding character, and using the debugging option
	"width" => 100,	
	"pad" 	=> "%",
	"debug"	=> 1
 );
 
 $flowchart = Text::Flowchart::new(		#using periods as the padding character
 	"pad"	=> "."
 );

=item B<box> (string x_coord y_coord ?x_pad? ?y_pad? ?width? ?height?)

You use the box method to add a new box into your flowchart object.  All parameters are passed in a hash.

The text within a box is wrapped at word boundaries if possible, or at the appropriate width if not possible so that all of your text fits inside your
box.

=over 1

=item string

B<Required>. string is the message that you'll see within the box.  Want your box to say "Hi there!"?  "string" => "Hi there!";  Easy as pie.

=back

=over 1

=item x_coord

B<Required>. The x coordinate of the upper left corner of the box.  Use the debug option to help you find your coordinates.

=back

=over 1

=item y_coord

B<Required>. The y coordinate of the upper left corner of the box.  Use the debug option to help you find your coordinates.

=back

=over 1

=item x_pad

I<Optional>. x_pad allows you to specify the amount of horizontal white space between the edges of the box and the text within.  If this option is not specified,
it'll use the default of a single space.

=back

=over 1

=item y_pad

I<Optional>. y_pad allows you to specify the amount of vertical white space between the edges of the box and the text within.  If this option is not specified,
it'll use the default of a single line of white space.

=back

=over 1

=item width

I<Optional>. width allows you to specify the width of the box.  The narrowest possible box has a width of 3.  You must take into account your x_pad value,
as well as the edges of the box when you specify a width.  If no width is specified, it will use the default of 15.

If you specify a width of 0 (zero), then your box will grow horizontally to accomodate all of your text, or until it reaches the width of the flowchart, whichever is
lesser.  Be careful!  This will put all of your box message onto the same line.  You almost never want your width to be 0.

=back

=over 1

=item height

I<Optional>. height allows you to specify the height of the box.  The shortest possible box has a height of 3.  You must take into account your y_pad value,
as well as the edges of the box when you specify a height.  If no height is specified, it will use the default of 0 (zero).

If you specify a height of 0 (zero), then your box will grow vertically to accomodate all of your text, or until it reaches the height of the flowchart, whichever is
lesser.  You most likely want a box width of some fixed value, and a box height of zero so it will grow to accomodate your message.

If you specify a non-zero box height, then your string will be truncated once the box reaches the height that you specified.  It will still be created, you just
won't have all of your text in it.

For example:

 $example_box = $flowchart->box(								#creates a box at (15,0)
	"string" => "Do you need to make a flowchart?",
	"x_coord" => 15,
	"y_coord" => 0
 );

 Output:
 
               +-------------+
               |             |
               | Do you need |
               | to make a   |
               | flowchart?  |
               |             |
               +-------------+

 $example_box2 = $flowchart->box(								#creates a box at (0,0), with new x_pad and y_pad values
	"string"  => "Do you need to make a flowchart?",
	"x_coord" => 0,
	"y_coord" => 0,
	"x_pad"	  => 0,
	"y_pad"	  => 3
 );

 Output:
 
 +-------------+                  
 |             |                                   
 |             |                                   
 |             |                                   
 |Do you need  |                                   
 |to make a    |                                   
 |flowchart?   |                                   
 |             |                                   
 |             |                                   
 |             |                                   
 +-------------+ 

 $example_box3 = $flowchart->box(								#creates a box at (0,0), with new x_pad and y_pad values
	"string"  => "Do you need to make a flowchart?",
	"x_coord" => 0,
	"y_coord" => 0,
	"x_pad"	  => 2,
	"y_pad"	  => 0
 );
 
 Output:
 
 +-------------+                
 |  Do you     |                                   
 |  need to    |                                   
 |  make a     |                                   
 |  flowchart  |                                   
 |  ?          |                                   
 +-------------+

=back

=item B<relate> ([from, from side, ?on side?], [to, to side, ?on side?], ?reason?)

the relate method connects boxes to each other.  Once two boxes are related, a line is automatically drawn between then, listing a reason if given, and arrows
if it's a directed flowchart.  The relate method spares you the trouble of having to re-position your lines if you move your boxes around.  You may still have
to do some fiddling (such as changing the sides that are connected), but it's much less trouble than re-arranging the boxes I<and> the lines.

=over 1

=item (from or to)

B<Required>. This is the box that you're relating from or to, it's the first item in an anonymous array.

=back

=over 1

=item (from or to) side

B<Required>. This is the side of the box that you're relating from or to.  This B<must> be either "top", "bottom", "right", or "left".  It's the second item in
an anonymous array.

=back

=over 1

=item ?on side?

I<Optional>. This optional item specifies where on the box side you'd like to draw the line from.  If zero, it will take the first available slot starting
from the left (if drawing from the top or bottom) or from the top (it drawing from the right or left).  If -1, it will take the first available slot
starting from the other side (right for top and bottom or bottom for right or left).  If any other number, it will draw the line at that position, along the side,
again counting from the left or the top.

=back

=over 1

=item reason

I<Optional>. reason is a name and value pair that specifies why you would take that route.  The value must be one character long, you'll die with an error if it
isn't.  reasons only make sense in a directed flowchart, they don't appear in non-directed ones.  Typical values are "Y" for yes and "N" for no.  If no reason
is specified, the default direction character will be used.


For example:
 
$flowchart = Text::Flowchart->new(
	"width" => 50,
	"directed" => 1);

 $example_box = $flowchart->box(								#creates a box at (0,0)
	"string" => "Do you need to make a flowchart?",
	"x_coord" => 0,
	"y_coord" => 2,
 );
 
  $example_box2 = $flowchart->box(								#creates a box at (15,0)
	"string" => "Yes I do.",
	"x_coord" => 19,
	"y_coord" => 0,
	"width"	  => 13
 ); 
 
  $example_box3 = $flowchart->box(								#creates a box at (15,0)
	"string" => "No I don't.",
	"x_coord" => 19,
	"y_coord" => 7
 );
 
 $flowchart->relate(
 	[$example_box, "right"] => [$example_box2, "left"]
 );
 
  $flowchart->relate(
 	[$example_box, "right", -1] => [$example_box3, "left"]
 );
 
 $flowchart->draw();
 
 Output:

                    +-----------+
                 +-->           |                  
 +-------------+ |  | Yes I do. |                  
 |             >-+  |           |                  
 | Do you need |    +-----------+                  
 | to make a   |                                   
 | flowchart?  |                                   
 |             >--+ +-------------+                
 +-------------+  +->             |                
                    | No I don't. |                
                    |             |                
                    +-------------+                

$flowchart = Text::Flowchart->new(
	"width" => 50);	#A non-directed chart

 $example_box = $flowchart->box(	#creates a box at (0,0)
	"string" => "Do you need to make a flowchart?",
	"x_coord" => 0,
	"y_coord" => 2,
 );
 
  $example_box2 = $flowchart->box(	#creates a box at (15,0)
	"string" => "Yes I do.",
	"x_coord" => 19,
	"y_coord" => 0,
	"width"	  => 13
 ); 
 
  $example_box3 = $flowchart->box(	#creates a box at (15,0)
	"string" => "No I don't.",
	"x_coord" => 19,
	"y_coord" => 7
 );
 
 $flowchart->relate(
 	[$example_box, "right"] => [$example_box2, "left"]
 );
 
  $flowchart->relate(
 	[$example_box, "right", -1] => [$example_box3, "left"]
 );
 
 $flowchart->draw();
 
 Output:

                    +-----------+
                 +--+           |                  
 +-------------+ |  | Yes I do. |                  
 |             +-+  |           |                  
 | Do you need |    +-----------+                  
 | to make a   |                                   
 | flowchart?  |                                   
 |             +--+ +-------------+                
 +-------------+  +-+             |                
                    | No I don't. |                
                    |             |                
                    +-------------+  

$flowchart = Text::Flowchart->new(
	"width" => 50,
	"directed" => 1
);

 $example_box = $flowchart->box(	#creates a box at (0,0)
	"string" => "Do you need to make a flowchart?",
	"x_coord" => 0,
	"y_coord" => 2,
 );
 
  $example_box2 = $flowchart->box(	#creates a box at (15,0)
	"string" => "Yes I do.",
	"x_coord" => 19,
	"y_coord" => 0,
	"width"	  => 13
 ); 
 
  $example_box3 = $flowchart->box(	#creates a box at (15,0)
	"string" => "No I don't.",
	"x_coord" => 19,
	"y_coord" => 7
 );
 
 $flowchart->relate(
 	[$example_box, "right"] => [$example_box2, "left"],
 	"reason" => "Y"
 );
 
  $flowchart->relate(
 	[$example_box, "right", -1] => [$example_box3, "left"],
 	"reason" => "N"
 );
 
 $flowchart->draw();
 
 Output:

                    +-----------+
                 +-->           |                  
 +-------------+ |  | Yes I do. |                  
 |             Y-+  |           |                  
 | Do you need |    +-----------+                  
 | to make a   |                                   
 | flowchart?  |                                   
 |             N--+ +-------------+                
 +-------------+  +->             |                
                    | No I don't. |                
                    |             |                
                    +-------------+  


=back

=over 1

=item B<draw> (?FILEHANDLE?)

 the draw method actuall outputs your flowchart.  You can optionally give it a glob to a filehandle to re-direct the output to that filehandle.

 For example:
 
 $flowchart->draw();	#draw your flowchart on STDOUT;
 
 $flowchart->draw(*FILE);	#send it to the FILE filehandle.

B<Required>. This is the box that you're relating from or to, it's the first item in an anonymous array.

=back

=head1 HISTORY

=over 14

=item - 1.00 12/21/99

First public release onto CPAN.

=back

=head1 EXAMPLE

This code will print out the flowchart shown up in the SYNOPSIS.

use Text::Flowchart;
 
 $flowchart = Text::Flowchart->new(
 	"width" => 50,
 	"directed" => 0);
 
 $begin = $flowchart->box(
 	"string" => "BEGIN",
 	"x_coord" => 0,
 	"y_coord" => 0,
 	"width"   => 9,
 	"y_pad"   => 0
 );
 
 $start = $flowchart->box(
 	"string" => "Do you need to make a flowchart?",
 	"x_coord" => 15,
 	"y_coord" => 0
 );
 
 $yes = $flowchart->box(
 	"string" => "Then my module may help.",
 	"x_coord" => 0,
 	"y_coord" => 10
 );
 
 $use = $flowchart->box(
 	"string" => "So use it.",
 	"x_coord" => 16,
 	"y_coord" => 8,
 	"width"	  => 14
 );
 
 $no = $flowchart->box(
 	"string" => "Then go do something else.",
 	"x_coord" => 30,
 	"y_coord" => 17
 );
 
 $flowchart->relate(
 	[$begin, "right"] => [$start, "left", 1]
 );
 
 $flowchart->relate(
 	[$start, "left", 3] => [$yes, "top", 5],
 	"reason" => "Y"
 );
 
 $flowchart->relate(
 	[$start, "right", 2] => [$no, "top", 5],
 	"reason" => "N"
 );
 
 $flowchart->relate(
 	[$yes, "right", 4] => [$use, "bottom", 2]
 );
 
 $flowchart->relate(
 	[$use, "bottom", 6] => [$no, "left", 2]
 );
 
 $flowchart->draw();


=head1 FAQ

B<Why in the world did you write this thing?>

There's a flowcharting-type program that a couple of people use at work.  It is only available on PCs.  I got cranky about not being able to 
use it, so I wrote my own.  Admittedly, mine isn't as powerful or as easy to use as theirs is, but I'm quite pleased with it nonetheless.
Real programmers don't use software tools.  Real programmers write software tools.

B<Hey!  I created a box, and then I tried to change its string and it didn't work!  What gives?>

Boxes are rendered upon their creation.  You cannot change their strings once their are created.  I may change this in a future release, but for
now just wait until you're U<sure> you know what you want in a box before you create it, okay?  That way you won't have to change it later.

B<Hey!  I'm running a memory tracer, and even though I deleted a box, the memory wasn't freed up.  Do you have a memory leak or what?>

Nope.  Boxes are stored internally inside the flowchart object.  The box variable that you get back from ->box is just a reference to the box
that lives inside the flowchart.  Since the flowchart still knows the box exists (even if you don't), the memory is not freed up.  Naturally, it
will be freed once perl exits.  I may add in the ability to remove boxes to a future release.

B<I want to draw lines from the left side of a box to the left side of another box, but I get an error. Why?>

Because you can't draw lines like that.  :)

Basically, there are 10 types of lines that can be drawn (all of which are done by the relate method, naturally). They look like:

 +---+  +--+        +--+  +  +        +  +-+  +-+  +        +
           |        |     |  |        |    |  |    |        |
           +--+  +--+     +  +--+  +--+    +  +    +--+  +--+
                                |  |
                                +  +
                                
Or horizontal, zig-zagging horizontal, vertical, zig-zagging vertical, and corners.  Connecting the same sides of boxes would require another type of line,
(the "handle", FWIW), and Text::Flowchart can't draw those.  If I can think of a good way to implement them I will.  Incidentally, you can draw your own lines
if you need to, using the ->line method.

 $flowchart->line(
 	"from"	=> [xfrom, yfrom],
 	"to"	=> [yfrom, yto],
 	"reason"=> "Y"
 );

But you really should use relate and not connect the same sides of boxes, it will make your life much simpler.

B<I made a flowchart, but all of the lines cross over each other and make a mess.  Why?>

Text::Flowchart has no collision detection.  If you try to place a box where another box already was, it'll gladly be drawn over.  Whichever boxes or lines
are drawn last will take priority.  If things are being over-written, then you need to change the coordinates of your boxes so they stop over-writing each other,
or change the box sides that are related so they don't draw over boxes.

B<Squares and rectangles are boring.  Can I draw other shapes?>

Not yet.  The module is actually numerous packages, heavily subclassing each other.  Adding in additional shapes is quite easy, actually.  You'd just need
to define a subclass of the Text::Flowchart::Shape class and define the necessary functions.  You'd have to declare a render method to actually create the ASCII
object, a relate method that knows how to draw the lines between objects, a get_next_coord method to get the next available coordinate on a given side, and make
the necessary modifications to your new constructor (calling ::Shape's init(), of course), and you're done!

It's actually much easier than it sounds, from a programming standpoint.  Figuring out how to properly render and relate object, that's tricky.  I will be adding
more shapes into a future release.  If anyone wants to add their own shapes, e-mail 'em to me and I may add them in in the future.

B<So what is it with these version numbers anyway?>

I'm going to I<try> to be consistent in how I number the releases.

The B<hundredths> digit will indicate bug fixes, etc.

The B<tenths> digit will indicate new and/or better functionality, as well as some minor new features.

The B<ones> digit will indicate a major new feature or re-write.

Basically, if you have x.ab and x.ac comes out, you want to get it guaranteed.  Same for x.ad, x.ae, etc.

If you have x.ac and x.ba comes out, you'll probably want to get it.  Invariably there will be bug fixes from the last "hundredths"
release, but it'll also have additional features.  These will be the releases to be sure to read up on to make sure that nothing
drastic has changes.

If you have x.ac and y.ac comes out, it will be the same as x.ac->x.ba but on a much larger scale.

B<Anything else you want to tell me?>

Sure, anything you need to know.  Just drop me a message.

=head1 MISCELLANEA

If there's something that you feel would be worthwhile to include, please let me know and I'll consider adding it.

How do you know what's a worthwhile addition?  Basically, if it would make your life easier.  Am I definitely going to include it?
Nope.  No way.  But I'll certainly consider it, all suggestions are appreciated.  I may even be nice and fill you in on some of the
ideas I have for a future release, if you ask nicely.  :) 

=head1 COPYRIGHT (again) and LICENSE

Copyright (c) 1999 James A Thomason III (jim3@psynet.net). All rights reserved.
This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.
I<Except if you profit from its distribution.  If this module or works based upon this module are distributed in a way that makes you money, you must
first contact me to work out a licensing arrangement.  I'm just giving the thing away, but I'm not going to allow people to make money off of it unless
I get a cut.  :)  Amounts will be hammered out on an individual basis.  CPAN mirrors are exempt from this stipulation.  If you're not sure if you're distributing
it in a way that makes you money, contact me with details and we'll make a decision.>

=head1 CONTACT INFO

So you don't have to scroll all the way back to the top, I'm Jim Thomason (jim3@psynet.net) and feedback is appreciated.
Bug reports/suggestions/questions/etc.  Hell, drop me a line to let me know that you're using the module and that it's
made your life easier.  :-)

=cut
