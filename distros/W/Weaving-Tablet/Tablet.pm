package Weaving::Tablet;

use 5.00400;
use strict;

require Exporter;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
@ISA = qw(Exporter);

%EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

@EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

@EXPORT = qw(
	
);
$VERSION = '0.8';

# POD is after __END__


sub new
{
	my $this = shift;
	my $class = ref($this) || $this || __PACKAGE__;
	my $self = {};
	bless $self, $class;
	$self->initialize(ref($this) ? %$this : ());
	
	$self;
}

sub new_from_file
{
	my $this = shift;
	my $class = $this || __PACKAGE__;
	my $filename = shift;
	
	return undef unless defined $filename;
	return undef unless -r $filename;
	
	my $self = $class->new;
	$self->file_name($filename);
	
	return undef unless $self->load_pattern;
	
	$self;
}

sub new_from_scratch
{
	my $this = shift;
	my $class = $this || __PACKAGE__;
	my ($cards, $rows) = @_;
	
	$cards ||= 1;
	$rows ||= 1;
	
	my $self = $class->new;
	$self->initialize(number_of_cards => $cards,
		number_of_rows => $rows);

	foreach my $c (0..$cards-1)
	{
		$self->{start}[$c] = $c % $self->number_of_holes; # rotate the starting positions
		$self->{SZ}[$c] = 'S';
		$self->{threading}[$c] = [0..$self->number_of_holes-1];
		push @{$self->{turns}[$c]}, ('/') x $rows;
	}
	
	$self->{color_table} = [qw/red green blue black yellow white/];
	
	$self;
}

sub initialize
{
	my $self = shift;
	my %parms = @_;
	$self->{number_of_cards} = 0;
	$self->{number_of_rows} = 0;
	$self->{number_of_holes} = 4;
	$self->{turns} = [];
	$self->{start} = [];
	$self->{color_table} = [];
	$self->{threading} = [];
	$self->{SZ} = [];
	$self->{file_name} = undef;
	$self->{color} = [];
	$self->{twist} = [];
	$self->{dirty} = 0;
	
	foreach my $k (keys %parms)
	{
		$self->{$k} = $parms{$k};
	}
	
	$self;
}

sub load_pattern
{
	my $self = shift;
	
	return 0 unless defined $self->{file_name};
	return 0 unless -r $self->{file_name};
	open PATTERN, $self->{file_name} or return 0;
	my ($cards, $rows, $holes) = (split(/ /,<PATTERN>))[0,2,4];
	$holes ||= 4;
	$self->initialize(number_of_cards => $cards,
		number_of_holes => $holes,
		file_name => $self->{file_name},
	);
	
	my $card;
	
	while (<PATTERN>)
	{
		chomp;
		last unless /^[\\\/|]/;
		$self->insert_row(0, $_)
	}
	
	# now $_ contains the start line...
	tr /ABCDEFGH/01234567/;
	$self->start([split(//, $_)]);
	
	$_ = <PATTERN>;
	chomp;
	$self->SZ([split(//, $_)]);
	
	for ($card = 0; $card < $cards; $card++)
	{
		$_ = <PATTERN>;
		chomp;
		$self->threading($card, [split(/,/, $_)]);
	}
	
	while (<PATTERN>)
	{
		chomp;
		push @{$self->{color_table}}, $_;# use X color names here 
	}
	
	close PATTERN;
	
	$self->color_pattern;
	$self->twist_pattern;
	$self->dirty(0);
	1;
}

sub save_pattern
{
	my $self = shift;
	
	my ($row, $card);
	
	my $file = $self->{file_name};
	
	return 0 unless $file || -w $file || -w '.';
	
	$self->color_pattern;
	
	open PATTERN,">".$file or return 0;
	
	print PATTERN $self->dump_pattern;
	
	close PATTERN;
	$self->dirty(0);
	1;
}
sub dump_pattern
{
	my $self = shift;
	
	my ($row, $card);
	my $pattern;
	
	$pattern = join(" ",$self->number_of_cards, 'cards', $self->number_of_rows, 'rows', $self->number_of_holes, 'holes')."\n";
	
	for ($row = $self->{number_of_rows}-1; $row >= 0; $row--)
	{
		for ($card = 0; $card < $self->{number_of_cards}; $card++)
		{
			$pattern .=  $self->{turns}[$card][$row];
		}
		$pattern .=  "\n";
	}
	
	(my $start = join("",@{$self->{start}})) =~ tr/01234567/ABCDEFGH/;
	$pattern .= $start."\n";
	
	$pattern .= join("",@{$self->{SZ}})."\n";
	
	for ($card = 0; $card < $self->{number_of_cards}; $card++)
	{
		$pattern .=  join(",",@{$self->{threading}[$card]})."\n";
	}
	
	foreach (@{$self->{color_table}})
	{
		$pattern .=  $_."\n";
	}
	$pattern;
}

sub color_pattern
{
	my $self = shift;
	my @cardlist = @_;
	@cardlist or @cardlist = (0..$self->number_of_cards-1);
		
	foreach my $card (@cardlist)
	{
		my $startrow = 0;
		($card, $startrow) = @$card if ref($card);
		my $color = $self->{start}[$card];
		my $pos = $color;
		my $SZ = $self->SZ($card) eq 'S' ? 1 : -1;
		
		foreach my $row (0..$self->number_of_rows-1)
		{
			my $this_turn = $self->{turns}[$card][$row];
			unless ($this_turn eq '|')
			{
				$color = $this_turn eq '/' ? $pos : $pos+1;
				$color %= $self->number_of_holes;
				$pos += $this_turn eq '/' ? -1 : +1;
				$pos %= $self->number_of_holes;
			}
			$self->{color}[$card][$row] = $color;
		}
	}
}

sub twist_pattern
{
	my $self = shift;
	my @cardlist = @_;
	@cardlist or @cardlist = (0..$self->{number_of_cards}-1);
		
	foreach my $card (@cardlist)
	{
		my $startrow = 0;
		($card, $startrow) = @$card if ref($card);
		my $twist = 0;
		my $SZ = $self->SZ($card) eq 'S' ? 1 : -1;
		
		foreach my $row (0..$self->{number_of_rows}-1)
		{
			$twist++ if $self->{turns}[$card][$row] eq '/';
			$twist-- if $self->{turns}[$card][$row] eq '\\';
			
			$self->{twist}[$card][$row] = $SZ * $twist;
		}
	}
}

sub float_pattern
{
	my $self = shift;
	my @cardlist = @_;
	@cardlist or @cardlist = (0..$self->{number_of_cards}-1);
	$self->color_pattern(@cardlist);
	
	foreach my $card (@cardlist)
	{
		next unless $self->{floats}[$card];
		my $startrow = 0;
		#print @{$self->{color}[$card]}, "\n";
		($card, $startrow) = @$card if ref($card);
		my $top = $self->{color}[$card][0];
		my $f_start = 0;
		$self->{floats}->[$card] = ();
		foreach my $row (1..$self->{number_of_rows}-1)
		{
			next if $self->{color}[$card][$row] == $top;
			push @{$self->{floats}->[$card]}, [$f_start, $row-1];
			$top = $self->{color}[$card][$row];
			$f_start = $row;
		}
		push @{$self->{floats}->[$card]}, [$f_start, $self->{number_of_rows}-1];
		#print map("$_->[0]-$_->[1],", @{$self->{floats}->[$card]}), "\n";
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

sub insert_row
{
	my $self = shift;
	INSERT: while (1)
	{
		my $row = shift; $row = $self->{number_of_rows}-1 unless defined $row;
		my $turns = shift || '/' x $self->{number_of_cards};
		$turns = pack("A$self->{number_of_cards}", $turns.'/' x $self->{number_of_cards});
		
		my @turns = split(//, $turns);
		$self->{number_of_rows}++;
		
		foreach my $card (0..$self->{number_of_cards}-1)
		{
			splice @{$self->{turns}[$card]}, $row, 0, $turns[$card];
		}
		
		last INSERT unless @_;
	}
	$self->dirty(1);
}

sub insert_card
{
	my $self = shift;
	INSERT: while (1)
	{
		my $card = shift; $card = $self->{number_of_cards}-1 unless defined $card;
		my $turns = shift || '/' x $self->{number_of_rows};
		$turns = pack("A$self->{number_of_rows}", $turns.'/' x $self->{number_of_rows});
		
		my @turns = split(//, $turns);
		$self->{number_of_cards}++;
		
		splice @{$self->{turns}}, $card, 0, [@turns];
		splice @{$self->{SZ}}, $card, 0, 'S';
		splice @{$self->{start}}, $card, 0, 0;
		splice @{$self->{threading}}, $card, 0, [0..$self->number_of_holes-1];
		
		last INSERT unless @_;
	}
	$self->dirty(1);
}

sub delete_row
{
	my $self = shift;
	foreach my $row (reverse sort @_)
	{
		$self->{number_of_rows}--;
		
		foreach my $card (0..$self->{number_of_cards}-1)
		{
			splice @{$self->{turns}[$card]}, $row, 1;
		}
	}
	$self->dirty(1);
}

sub delete_card
{
	my $self = shift;
	foreach my $card (reverse sort @_)
	{
		$self->{number_of_cards}--;
		
		splice @{$self->{turns}}, $card, 1;
		splice @{$self->{SZ}}, $card, 1;
		splice @{$self->{start}}, $card, 1;
		splice @{$self->{threading}}, $card, 1;
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

sub number_of_cards
{
	shift->{number_of_cards};
}

sub number_of_rows
{
	shift->{number_of_rows};
}

sub number_of_holes
{
	shift->{number_of_holes};
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
		$self->{SZ}[$card] = $value;
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
		my @values = @$card;
		pop @values while @values > $self->number_of_cards;
		splice @{$self->{SZ}}, 0, @values, @values;
		$self->dirty(1);
		return;
	}
	elsif (defined($card) and not ref($card))
	{
		return undef if $card < 0;
		return undef if $card >= $self->number_of_cards;
		return $self->{SZ}[$card];
	}
	elsif (not defined $card)
	{
		return (@{$self->{SZ}});
	}
	else 
	{
		return undef;
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
		$self->{start}[$card] = $value;
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
		my @values = @$card;
		pop @values while @values > $self->number_of_cards;
		splice @{$self->{start}}, 0, @values, @values;
		$self->dirty(1);
		return;
	}
	elsif (defined($card) and not ref($card))
	{
		return undef if $card < 0;
		return undef if $card >= $self->number_of_cards;
		return $self->{start}[$card];
	}
	elsif (not defined $card)
	{
		return (@{$self->{start}});
	}
	else 
	{
		return undef;
	}
}

sub threading
{
	my $self = shift;
	my ($card, $hole, $value) = @_;
	
	return @{$self->{threading}} unless @_;
	
	if (@_ == 1)
	{
		return undef if $card < 0;
		return undef if $card >= $self->number_of_cards;
		return (@{$self->{threading}[$card]});
	}
	elsif (@_ == 2) # (card, hole) or (card, listref_of_color_indices)
	{
		unless (ref($hole))
		{
			return undef if $card < 0;
			return undef if $card >= $self->number_of_cards;
			return undef if $hole < 0;
			return undef if $hole >= $self->number_of_holes;
			return ($self->{threading}[$card][$hole]);
		}
		elsif (ref($hole) eq 'ARRAY')
		{
			return undef if $card < 0;
			return undef if $card >= $self->number_of_cards;
			return undef if grep /\D/, @$hole;
			my @values = @$hole;
			pop @values while @values > $self->number_of_holes;
			splice @{$self->{threading}[$card]}, 0, @values, @values;
			$self->dirty(1);
		}
		else
		{
			return undef;
		}
	}
	elsif (@_ >= 3)
	{
		return undef if $card < 0;
		return undef if $card >= $self->number_of_cards;
		return undef if $hole < 0;
		return undef if $hole >= $self->number_of_holes;
		$self->dirty(1);
		$self->{threading}[$card][$hole] = $value;
	}
}

sub turns
{
	my $self = shift;
	my ($card, $row, $turn) = @_;
	
	if (@_ >= 3)
	{
		return undef if $card < 0;
		return undef if $card >= $self->number_of_cards;
		return undef if $row < 0;
		return undef if $row >= $self->number_of_rows;
		return undef unless $turn =~ /^[\\\/|]$/;
		$self->dirty(1);
		$self->{turns}[$card][$row] = $turn;
	}
	elsif (@_ == 2)
	{
		return undef if $card < 0;
		return undef if $card >= $self->number_of_cards;
		return undef if $row < 0;
		return undef if $row >= $self->number_of_rows;
		return $self->{turns}[$card][$row];
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
		return undef if $row < 0;
		return undef if $row >= $self->number_of_rows;
		foreach my $c (0..$self->number_of_cards-1)
		{
			last if $c >= @$turns;
			$self->{turns}[$c][$row] = $$turns[$c];
		}
		$self->dirty(1);
	}
	elsif (@_ == 1)
	{
		return undef if $row < 0;
		return undef if $row >= $self->number_of_rows;
		my @row;
		foreach my $c (0..$self->number_of_cards-1)
		{
			push @row, $self->{turns}[$c][$row];
		}
		return @row;
	}
	else
	{
		return undef;
	}
}

sub card_turns
{
	my $self = shift;
	my ($card, $turns) = @_;
	
	if (@_ >= 2)
	{
		return undef if $card < 0;
		return undef if $card >= $self->number_of_cards;
		my @values = @$turns;
		pop @values while @values > $self->number_of_rows;
		$self->dirty(1);
		splice @{$self->{turns}[$card]}, 0, @values, @values;
	}
	elsif (@_ == 1)
	{
		return undef if $card < 0;
		return undef if $card >= $self->number_of_cards;
		return (@{$self->{turns}[$card]});
	}
	else
	{
		return undef;
	}
}

sub color_table
{
	my $self = shift;
	my ($index, $value) = @_;
	defined($value) and not defined($index) and $index = @{$self->{color_table}};
	
	return (@{$self->{color_table}}) unless @_;
	return undef unless defined $index;
	return undef unless ($index >= 0 and $index <= @{$self->{color_table}});
	return $self->{color_table}[$index] unless defined $value;
	$self->{color_table}[$index] = $value unless ref($value);
	$self->dirty(1);
	splice @{$self->{color_table}}, 0, @$value, @$value if ref($value) eq 'ARRAY';
}

sub twist
{
	my $self = shift;
	my ($card, $row) = shift;
	
	return @{$self->{twist}} unless @_;
	return undef unless ($card >= 0 and $card < $self->number_of_cards);
	return undef unless ($row >= 0 and $row < $self->number_of_rows);
	return $self->{twist}[$card][$row];
}

sub row_twist
{
	my $self = shift;
	my $row = shift;
	
	return undef unless defined $row;
	return undef unless ($row >= 0 and $row < $self->number_of_rows);
	my @row;
	foreach my $c (0..$self->number_of_cards-1)
	{
		push @row, $self->{twist}[$c][$row];
	}
	return @row;
}

sub card_twist
{
	my $self = shift;
	my $card = shift;
	
	return undef unless defined $card;
	return undef unless ($card >= 0 and $card < $self->number_of_cards);
	return @{$self->{twist}[$card]};
}

sub color
{
	my $self = shift;
	my ($card, $row) = @_;
	
	return @{$self->{color}} unless @_;
	return undef unless ($card >= 0 and $card < $self->number_of_cards);
	return undef unless ($row >= 0 and $row < $self->number_of_rows);
	return $self->{color}[$card][$row];
}

sub row_color
{
	my $self = shift;
	my $row = shift;
	
	return undef unless defined $row;
	return undef unless ($row >= 0 and $row < $self->number_of_rows);
	my @row;
	foreach my $c (0..$self->number_of_cards-1)
	{
		push @row, $self->{color}[$c][$row];
	}
	return @row;
}

sub card_color
{
	my $self = shift;
	my $card = shift;
	
	return undef unless defined $card;
	return undef unless ($card >= 0 and $card < $self->number_of_cards);
	return @{$self->{color}[$card]};
}

sub file_name
{
	my $self = shift;
	@_ and $self->{file_name} = shift;
	$self->{file_name};
}

sub dirty
{
	my $self = shift;
	@_ and $self->{dirty} = shift;
	$self->{dirty};
}

1;
__END__

=head1 NAME

Weaving::Tablet - Perl extension for manipulating tablet weaving patterns

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
  
  $pattern->insert_row; 
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

The Snartemo module provides data structures and routines to manipulate
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

=item insert_row(after, turns...)

Add a new row to the pattern. 

$pattern->insert_row() inserts a new row at the end, with all cards turning
forward.

$pattern->insert_row(number) inserts a new row after row (number). Specify
-1 to insert new row at beginning. All cards will be turning forward.

$pattern->insert_row(number, turns) inserts a new row with the turning 
specified. Turning is given as a string of /, \, and |. The turns is padded with
/ if too short; excess cards are ignored.

insert_row may be called with multiple sets of rows and turnings.

=item insert_card(after, turns...)

Add a new tablet to the pattern. The variations are analagous to insert_row.
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

=head1 AUTHOR

Michael Houghton copyright 1999-2002, all rights reserved.

This software may be used under the same terms as Perl itself.

=head1 SEE ALSO

=cut
