package Weaving::Tablet;

use warnings;
use strict;
use Carp;
use Moose;
use Weaving::Tablet::Card;

our $VERSION = '0.009.007';

has 'pattern_length' => (isa => 'Int', is => 'ro', default => 10);
has 'number_of_holes' => (isa => 'Int', is => 'ro', default => 4, writer => '_set_number_of_holes');
has 'number_of_cards' => (isa => 'Int', is => 'rw', default => 20);
has 'cards' => (isa  => 'ArrayRef[Weaving::Tablet::Card]', is => 'ro', default => sub { [] });
has 'color_table' => (isa => 'ArrayRef[Str]', is => 'ro', default => sub { [qw/red green blue black yellow white/] });
has 'file_name' => (isa => 'Str', is => 'rw');
has 'dirty' => (isa => 'Bool', is => 'rw', default => 0);
has 'is_twill' => ( isa => 'Bool', is => 'rw', default => 0 );

sub BUILD
{
    my $self = shift;
    if (defined $self->file_name)
    {
        $self->load_pattern;
        return;
    }
	push @{$self->cards}, Weaving::Tablet::Card->new(number_of_turns => 
	$self->pattern_length) for 1..$self->number_of_cards;
}

sub load_pattern
{
	my $self = shift;
	
	return 0 unless defined $self->file_name;
	return 0 unless -r $self->file_name;
	open my $pattern, '<', $self->file_name or croak "Can't open ".$self->file_name.": $!";
	my ($cards, $rows, $holes) = (split(/ /,<$pattern>))[0,2,4];
	$holes ||= 4;
	$self->number_of_cards($cards);
	$self->_set_number_of_holes($holes);
	
	# prime cards with empty cards
	push @{$self->cards}, Weaving::Tablet::Card->new(number_of_turns => 0) for 1..$self->number_of_cards;
	
	my $card;
	while (<$pattern>)
	{
		chomp;
		last unless /^[\\\/|]/;
		$self->insert_pick([-1, $_]);
	}
	
	# now $_ contains the start line...
	tr /ABCDEFGH/01234567/;
	my @starts = split(//, $_);
	for my $card (0 .. $self->number_of_cards-1)
	{
	    $self->cards->[$card]->start($starts[$card]);
	}
	
	$_ = <$pattern>;
	chomp;
	my @SZ = split(//, $_);
	for my $card (0 .. $self->number_of_cards-1)
	{
	    $self->cards->[$card]->SZ($SZ[$card]);
	}
	
	for my $card (0 .. $self->number_of_cards-1)
	{
		$_ = <$pattern>;
		chomp;
		$self->cards->[$card]->set_threading([split(/,/, $_)]);
	}
	
	pop @{$self->color_table} while @{$self->color_table};
	while (<$pattern>)
	{
		chomp;
		push @{$self->color_table}, $_;# use X color names here 
	}
	
	close $pattern;
	
	$self->color_pattern;
	$self->twist_pattern;
	$self->dirty(0);
	1;
}

sub reload_pattern
{
    my $self = shift;
    $self->delete_card(0 .. $self->number_of_cards-1);
    $self->load_pattern;
}

sub save_pattern
{
	my $self = shift;
	
	my $file = $self->{file_name};
	
	return 0 unless $file || -w $file || -w '.';
	
	$self->color_pattern;
	
	open my $pattern, ">", $file or return 0;
	
	print $pattern $self->dump_pattern;
	
	close $pattern;
	$self->dirty(0);
	1;
}

sub dump_pattern
{
	my $self = shift;
	
	my ($row, $card);
	my $pattern;
	
	$pattern = join(" ",$self->number_of_cards, 'cards', $self->number_of_rows, 'rows', $self->number_of_holes, 'holes')."\n";
	
	for my $row (reverse 0 .. $self->number_of_rows-1)
	{
	    $pattern .= join('', $self->row_turns($row), "\n");
	}
	
	(my $start = join("",@{$self->start})) =~ tr/01234567/ABCDEFGH/;
	$pattern .= $start."\n";
	
	$pattern .= join("",@{$self->SZ})."\n";
	
	for my $card (0 .. $self->number_of_cards-1)
	{
		$pattern .=  join(",",@{$self->threading($card)})."\n";
	}
	
	foreach (@{$self->color_table})
	{
		$pattern .=  $_."\n";
	}
	$pattern;
}

sub color_pattern
{
	my $self = shift;
	my @cardlist = @_ == 0 ? (0 .. $self->number_of_cards-1) : @_;
	for my $card (@cardlist)
	{
	    $self->cards->[$card]->color_card;
	}
}

sub twist_pattern
{
	my $self = shift;
	my @cardlist = @_ == 0 ? (0 .. $self->number_of_cards-1) : @_;
	for my $card (@cardlist)
	{
	    $self->cards->[$card]->twist_card;
	}
}

sub float_pattern
{
	my $self = shift;
	my @cardlist = @_ == 0 ? (0 .. $self->number_of_cards-1) : @_;
	for my $card (@cardlist)
	{
	    $self->cards->[$card]->float_card;
	}
}

sub print_twist
{
	my ($self, @rowlist) = @_;
	
	$self->twist_pattern;
	
	@rowlist = ($self->number_of_rows-1) unless @rowlist;
	
	if (wantarray)
	{
		my @twist;
		
		foreach my $row (@rowlist)
		{
			push @twist, [$self->row_twist($row)];
		}
		return @twist;
	}
	else
	{
		my $s;
		foreach my $row (@rowlist)
		{
			my $rp = $row+1;
			$s .= "twist for row $rp: ";
			$s .= join(",", $self->row_twist($row));
			$s .= "\n";
		}
		return $s;
	}
}

sub insert_pick
{
	my $self = shift;
	push @_, [$self->number_of_rows-1, '/'x$self->number_of_cards] if @_ == 0; 
	while (@_)
	{
	    my $rowspec = shift;
	    my ($after, $turns) = @$rowspec;
	    $turns = pack('A'.$self->number_of_cards, $turns.'/' x $self->number_of_cards);
	    my @turns = split(//, $turns);
	    for my $card (0 .. $self->number_of_cards-1)
	    {
	        $self->cards->[$card]->insert_picks($after, $turns[$card]);
	    }
	}
	$self->dirty(1);
}

sub insert_card
{
	my $self = shift;
	while (@_)
	{
	    my $rowspec = shift;
	    my ($after, $turns) = @$rowspec;
		$turns = pack('A'.$self->{number_of_rows}, $turns.'/' x $self->{number_of_rows});
	    my $card = Weaving::Tablet::Card->new(turns => $turns);
	    splice @{$self->cards}, $after+1, 0, $card;
	}
	$self->dirty(1);
}

sub delete_row
{
	my $self = shift;
	my @rows = reverse sort { $a <=> $b } @_;
	foreach my $card (0..$self->{number_of_cards}-1)
	{
		$self->cards->[$card]->delete_picks(@rows);
	}
	$self->dirty(1);
}

sub delete_card
{
	my $self = shift;
	foreach my $card (reverse sort @_)
	{
		$self->{number_of_cards}--;
		
		splice @{$self->cards}, $card, 1;
	}
	$self->dirty(1);
}

sub duplicate_row
{
	my $self = shift;
	DUP: while (1)
	{
		my $from = shift; return unless defined $from;
		my $to = shift; $to = $self->{number_of_rows}-1 unless defined $to;
		
		$self->{number_of_rows}++;
		
		foreach my $card (0..$self->{number_of_cards}-1)
		{
			splice @{$self->{turns}[$card]}, $to, 0, $self->{turns}[$card][$from];
		}
		
		last DUP unless @_;
	}
	$self->dirty(1);
}

sub duplicate_card
{
	my $self = shift;
	DUP: while (1)
	{
		my $from = shift; return unless defined $from;
		my $to = shift; $to = $self->{number_of_cards}-1 unless defined $to;
		
		$self->{number_of_cards}++;
		
		splice @{$self->{turns}}, $to, 0, [@{$self->{turns}[$from]}];
		splice @{$self->{SZ}}, $to, 0, $self->{SZ}[$from];
		splice @{$self->{start}}, $to, 0, $self->{start}[$from];
		splice @{$self->{threading}}, $to, 0, [@{$self->{threading}[$from]}];
		
		last DUP unless @_;
	}
	$self->dirty(1);
}

sub number_of_rows
{
	shift->cards->[0]->{number_of_turns};
}

sub SZ
{
	my $self = shift;
	my $card = shift;
	my $value = shift;
	
	if (defined $value)
	{
		warn "attempt to use $value as SZ setting for card $card" unless $value =~ /[SZ]/;
		return unless $value =~ /[SZ]/;
		return if $card < 0;
		return if $card >= $self->number_of_cards;
		$self->cards->[$card]->SZ($value);
		$self->dirty(1);
		return;
	}
	elsif (defined($card) and ref($card) eq 'ARRAY')
	{
		if (grep !/^[SZ]$/, @$card)
		{
			warn "attempt to use invalid SZ value for card $card";
			return;
		}
		croak;
		my @values = @$card;
		pop @values while @values > $self->number_of_cards;
		splice @{$self->{SZ}}, 0, @values, @values;
		$self->dirty(1);
		return;
	}
	elsif (defined($card) and not ref($card))
	{
		return if $card < 0;
		return if $card >= $self->number_of_cards;
		return $self->cards->[$card]->SZ;
	}
	elsif (not defined $card)
	{
	    my @SZ;
	    for my $card (0 .. $self->number_of_cards-1)
	    {
	        push @SZ, $self->cards->[$card]->SZ;
	    }
		return \@SZ;
	}
	else 
	{
		return;
	}
}

sub start
{
	my $self = shift;
	my $card = shift;
	my $value = shift;
	
	if (defined $value)
	{
		warn "attempt to use $value as start setting for card $card" unless $value =~ /[01234567]/;
		return unless $value =~ /[01234567]/;
		return if $card < 0;
		return if $card >= $self->number_of_cards;
		$self->cards->[$card]->start($value);
		$self->dirty(1);
		return;
	}
	elsif (defined($card) and ref($card) eq 'ARRAY')
	{
		if (grep !/^[01234567]$/, @$card)
		{
			warn "attempt to use invalid start value for card $card";
			return;
		}
		for my $c (0 .. $self->number_of_cards-1)
		{
		    $self->start($c, $card->[$c]);
		}
		$self->dirty(1);
		return;
	}
	elsif (defined($card) and not ref($card))
	{
		return if $card < 0;
		return if $card >= $self->number_of_cards;
		return $self->cards->[$card]->start;
	}
	elsif (not defined $card)
	{
	    my @start;
	    for my $card (0 .. $self->number_of_cards-1)
	    {
	        push @start, $self->cards->[$card]->start;
	    }
		return \@start;
	}
	else 
	{
		return;
	}
}

sub threading
{
	my $self = shift;
	my ($card, $hole, $value) = @_;
	
	if (@_ == 0)
	{
	    return [map { $self->cards->[$_]->threading } (0 .. $self->number_of_cards)];
	}
	elsif (@_ == 1)
	{
		return if $card < 0;
		return if $card >= $self->number_of_cards;
		return $self->cards->[$card]->threading;
	}
	elsif (@_ == 2) # (card, hole) or (card, listref_of_color_indices)
	{
		unless (ref($hole))
		{
			return if $card < 0;
			return if $card >= $self->number_of_cards;
			return if $hole < 0;
			return if $hole >= $self->number_of_holes;
			return ($self->cards->[$card]->threading->[$hole]);
		}
		elsif (ref($hole) eq 'ARRAY')
		{
			return if $card < 0;
			return if $card >= $self->number_of_cards;
			return if grep /\D/, @$hole;
			return if @$hole != $self->number_of_holes;
			$self->card->[$card]->set_threading($hole);
			$self->dirty(1);
		}
		else
		{
			return;
		}
	}
	elsif (@_ >= 3)
	{
		return if $card < 0;
		return if $card >= $self->number_of_cards;
		return if $hole < 0;
		return if $hole >= $self->number_of_holes;
		$self->dirty(1);
		$self->cards->[$card]->threading->[$hole] = $value;
	}
}

sub turns
{
	my $self = shift;
	my ($card, $row, $turn) = @_;
	
	if (@_ >= 3)
	{
		return if $card < 0;
		return if $card >= $self->number_of_cards;
		return if $row < 0;
		return if $row >= $self->number_of_rows;
		return unless $turn =~ /^[\\\/|]$/;
		$self->dirty(1);
		$self->card_turns($card)->[$row] = $turn;
	}
	elsif (@_ == 2)
	{
		return if $card < 0;
		return if $card >= $self->number_of_cards;
		return if $row < 0;
		return if $row >= $self->number_of_rows;
		return $self->card_turns($card)->[$row];
	}
	else
	{
		return (@{$self->{turns}});
	}
}

sub row_turns
{
	my $self = shift;
	my ($row, $turns) = @_;
	
	if (@_ >= 2)
	{
		return if $row < 0;
		return if $row >= $self->number_of_rows;
		foreach my $c (0..$self->number_of_cards-1)
		{
			last if $c >= @$turns;
			$self->card_turns($c)->[$row] = $$turns[$c];
		}
		$self->dirty(1);
	}
	elsif (@_ == 1)
	{
		return if $row < 0;
		return if $row >= $self->number_of_rows;
		my @row;
		foreach my $c (0..$self->number_of_cards-1)
		{
			push @row, $self->card_turns($c)->[$row];
		}
		return @row;
	}
	else
	{
		return;
	}
}

sub card_turns
{
	my $self = shift;
	my ($card, $turns) = @_;
	
	if (@_ >= 2)
	{
		return if $card < 0;
		return if $card >= $self->number_of_cards;
		my @values = @$turns;
		pop @values while @values > $self->number_of_rows;
		$self->dirty(1);
		splice @{$self->cards->[$card]->turns}, 0, @values, @values;
	}
	elsif (@_ == 1)
	{
		return if $card < 0;
		return if $card >= $self->number_of_cards;
		return $self->cards->[$card]->turns;
	}
	else
	{
		return;
	}
}

sub twist
{
	my $self = shift;
	my ($card, $row) = shift;
	
	return @{$self->{twist}} unless @_;
	return unless ($card >= 0 and $card < $self->number_of_cards);
	return unless ($row >= 0 and $row < $self->number_of_rows);
	return $self->card_twist->[$row];
}

sub row_twist
{
	my $self = shift;
	my $row = shift;
	
	return unless defined $row;
	return unless ($row >= 0 and $row < $self->number_of_rows);
	my @row;
	foreach my $c (0 .. $self->number_of_cards-1)
	{
		push @row, $self->card_twist($c)->[$row];
	}
	return @row;
}

sub card_twist
{
	my $self = shift;
	my $card = shift;
	
	return unless defined $card;
	return unless ($card >= 0 and $card < $self->number_of_cards);
	return $self->cards->[$card]->twist;
}

sub color
{
	my $self = shift;
	my ($card, $row) = @_;
	
	return @{$self->{color}} unless @_;
	return unless ($card >= 0 and $card < $self->number_of_cards);
	return unless ($row >= 0 and $row < $self->number_of_rows);
	return $self->card_color($card)->[$row];
}

sub row_color
{
	my $self = shift;
	my $row = shift;
	
	return unless defined $row;
	return unless ($row >= 0 and $row < $self->number_of_rows);
	my @row;
	foreach my $c (0..$self->number_of_cards-1)
	{
		push @row, $self->card_color($c)->[$row];
	}
	return @row;
}

sub card_color
{
	my $self = shift;
	my $card = shift;
	
	return unless defined $card;
	return unless ($card >= 0 and $card < $self->number_of_cards);
	return $self->cards->[$card]->color;
}


1; # Magic true value required at end of module
__END__

=head1 NAME

Weaving::Tablet - Perl extension for manipulating tablet weaving patterns


=head1 VERSION

This document describes Weaving::Tablet version 0.9.6


=head1 SYNOPSIS

  use Weaving::Tablet;
  
  my $old_pattern = Weaving::Tablet::new_from_file("my_pattern");
  my $new_pattern = Weaving::Tablet::new_from_scratch(20, 40); # 20 cards, 40 rows
  
  $pattern->load_pattern; # load pattern from $pattern->{file_name}
  $pattern->save_pattern; # write pattern to $pattern->{file_name}
  $pattern->color_pattern; # compute $pattern->{color}
  $pattern->twist_pattern; # compute $pattern->{twist}
  $pattern->print_twist; # print accumulated twist for pattern
  $pattern->print_twist(10); # print accumulated twist at row 10
  $pattern->print_twist(10,20,25); # print accumulated twist at rows 10,20,25
  
  $pattern->insert_pick; 
  $pattern->insert_card; 
  $pattern->delete_row;
  $pattern->delete_card;
  $pattern->duplicate_row;
  $pattern->duplicate_card;
  
  # member functions
  
  # data retrieval
  $pattern->file_name
  $pattern->number_of_cards
  $pattern->number_of_rows
  $pattern->number_of_holes
  $pattern->SZ, $pattern->SZ(card)
  $pattern->threading, $pattern->threading(card), $pattern->threading(card,hole)
  $pattern->start, $pattern->start(card)
  $pattern->color_table, $pattern->color_table(color_index)
  $pattern->turns, $pattern->card_turns(card), $pattern->row_turns(row), 
  	$pattern->turns(card, row)
  $pattern->color, $pattern->card_color(card), $pattern->row_color(row),
  	$pattern->color(card,row) - gives color indices
  $pattern->twist, $pattern->card_twist(card), $pattern->row_twist(row), $pattern->twist(card, row)
  $pattern->dirty
  
  # data modification
  $pattern->SZ(card, value), $pattern->SZ(listref_of_SZ)
  $pattern->threading(card, hole, color_index), $pattern->threading(card, listref_of_color_indices)
  $pattern->start(card, hole), $pattern->start(listref_of_holes)
  $pattern->color_table(color_index, color_value), $pattern->color_table(listref_of_color_values),
  $pattern->color_table(undef, color_value) # add new color at end
  $pattern->turns(card, row, turn), $pattern->card_turns(card, listref_of_turns),
  $pattern->row_turns(row, listref_of_turns)
  $pattern->dirty(value)
  
=head1 DESCRIPTION

The Weaving::Tablet module provides data structures and routines to manipulate
tablet weaving patterns. It is limited to patterns using up to eight-holed 
tablets with all holes threaded and that do not involve flipping tablets, 
and use single turns only (no turning past more than one hole).

It supports an ASCII representation for persistent storage that is somewhat
human readable.

It provides routines to print information about the pattern in an ASCII
format. 

=head2 Object Attributes

Some attributes are stored while others are computed or temporary. In the 
discussion of attributes which care about the number of holes, the 
discussion assumes four-holed cards. For different numbers of holes, the
description extends naturally.

The persistent attributes:

=over 4

=item number_of_rows

The number of rows in the pattern.

=item number_of_cards

The number of cards (width) in the pattern.

=item number_of_holes

The number of holes in each card. This defaults to four and may be as
high as eight.

=item SZ

A list of (number_of_cards) elements, each of which is /[SZ]/. This 
indicates how the tablet is threaded, either S or Z.

=item threading

A list of (number_of_cards) lists of four elements, each being a "color"
taken from the color_table. 

Holes ABCD map to number 0123 for list indices. See the ASCII art below 
for how the holes are considered arranged (subject to rotation) regardless
of S vs. Z threading.

  <- fell
    _________
   /         \
   |  A   B  |
   |         |
   |  D   C  |
   \_________/

=item start

A list of (number_of_cards) elements which indicates which hole is in
the A position (as shown above) for the starting positions. The values
are 0123.

=item turns

A list of (number_of_cards) lists of (number_of_rows) elements whose
values are /, \, or |, indicating the turning direction for each tablet for
each row. / denotes a forward turn; \ denotes a backwards turn; | denotes
no turn, i.e., an idling card.

=item color_table

A list of color specifications (whose specific format is undefined here).
The threading attribute uses indices into this table as its values.

=back

The non-persistent and computed attributes:

=over 4

=item colors

A list parallel to turns whose values are the color of the thread visible
at that point. 

=item twist

A list parallel to turns whose values are the amount of twist (in quarter-turns)
accumulated in the pattern up to that point.

=item file_name

The disk file name associated with this pattern, or undef if no file has been
specified.

=back

=head2 Save file format

Saved patterns are meant to be human readable. To this end, they are 
text files.

The first line gives the number of cards, rows, and holes. The next (number_of_rows)
lines are @turns, with row 0 at the bottom of the list. The next line is
@start, where the start positions are given as ABCD.

Next are the S/Z threading of each card, using S and Z as the symbols.

Next come (number_of_rows) lines giving the threadings. Each line is a list of
four numbers which indicate the color table entry for each thread.

Next comes the color table. Each line is a list of three numbers giving the
RGB value in the range 0 to 65535. The number of lines depends on the number
of different colors being used in the total pattern.

For example:

 20 cards 20 rows 4 holes
 \///\\\/\\//\///\\\/
 /\\\///\//\\/\\\///\
 \/\\//\///\\\/\\//\/
 \\/\/\///\\\\\/\/\//
 \\\/\///\///\\\/\///
 ///\///\/\///\\\/\\\
 //\///\//\\///\\\/\\
 /\///\/\\\/\\//\\\/\
 \///\\\/\\//\///\\\/
 /\\\///\//\\/\\\///\
 \/\\//\///\\\/\\//\/
 \\/\/\///\\\\\/\/\//
 \\\/\///\///\\\/\///
 ///\///\/\///\\\/\\\
 //\///\//\\///\\\/\\
 /\///\/\\\/\\//\\\/\
 \///\\\/\\//\///\\\/
 /\\\///\//\\/\\\///\
 \/\\//\///\\\/\\//\/
 \\/\/\///\\\\\/\/\//
 ADABCDADABCDADABCDAD
 SSSSSSSSSSSSSSSSSSSS
 0,1,2,3
 0,1,2,3
 0,1,2,3
 0,1,2,3
 0,1,2,3
 0,1,2,3
 0,1,2,3
 0,1,2,3
 0,1,2,3
 0,1,2,3
 0,1,2,3
 0,1,2,3
 0,1,2,3
 0,1,2,3
 0,1,2,3
 0,1,2,3
 0,1,2,3
 0,1,2,3
 0,1,2,3
 0,1,2,3
 65535,0,0
 0,65535,0
 0,0,65535
 65535,65535,0

=head2 Routines

=over 4

=item new_from_file(file)

Load an existing pattern from the specified file. Returns undef if the
file is not specified, is not readable, or cannot be loaded.

=item new_from_scratch(cards, rows)

Create a pattern with the specified number of cards and rows (both defaulting
to 1). This assumes that the pattern uses four colors: black, red, green, blue.
It sets the cards to all turn forward, threaded S, and arranged to make 
diagonals.

=item load_pattern

Attempts to load the pattern from $self->{file_name}. If the load fails for any
reason it returns false, else true. It calls color_pattern and twist_pattern
before returning.

=item save_pattern

Attempts to write the pattern to $self->{file_name}. If the save fails for any
reason it returns false, else true. 

=item color_pattern(cardlist)

Computes $self->{color} by walking each card to see what color is on top at
each point in the pattern. If cardlist is specified, limit recoloring to 
specified cards.

=item twist_pattern(cardlist)

Computes the accumulated twist in quarter-turn units at each point in the
pattern. If cardlist is specified, limit calculation to 
specified cards.

=item print_twist(rowlist)

"Prints" the accumulated twist for the last row or each row specified in
the rowlist. 

In a scalar context, print_twist returns a string suitable
for direct printing. The string contains one line for each row specified.
Each line is a comma-separated list of values.

In a list context, print_twist returns a list of lists.
Each inner list is a list of twist values for the selected row.

For example: $pattern->print_twist(10,11) will return a list of two lists in
a list context

=item insert_pick(rowspec...)

Add picks to the pattern. Row numbers begin with 0.

$pattern->insert_pick() inserts a new row at the end, with all cards turning
forward.

$pattern->insert_pick([]number]) inserts a new row after row (number). Specify
-1 to insert new row at beginning. All cards will be turning forward.

$pattern->insert_pick([]number, turns]) inserts a new row with the turning 
specified. Turning is given as a string of /, \, and |. The turns is padded with
/ if too short; excess cards are ignored.

insert_pick may be called with multiple sets of rows and turnings.

=item insert_card(after, turns...)

Add a new tablet to the pattern. The variations are analagous to insert_pick.
The tablet is presumed to be S threaded starting with hole A.

=item delete_row(rowlist)

Delete the specified rows from the pattern. 

=item delete_card(cardlist)

Delete the specified card from the pattern.

=item duplicate_row(from, to)

Creates a new row after the specified row with the same turnings as the
source row. Omitting the 'to' argument places the new row at the end.

=item duplicate_card(card, after)

Creates a new tablet after the specified tablet with the same turnings as the
source tablet.

=back

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-weaving-tablet@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.


=head1 AUTHOR

Michael Houghton  C<< <herveus@cpan.org> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 1999-2012, Michael Houghton C<< <herveus@cpan.org> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
