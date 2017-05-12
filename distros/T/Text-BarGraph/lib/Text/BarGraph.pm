package Text::BarGraph;

use strict;
use warnings;

use vars qw /$AUTOLOAD $VERSION/;

use Carp;

=head1 NAME

Text::BarGraph - Text Bar graph generator

=head1 SYNOPSIS

  use Text::BarGraph;

  $graph = Text::BarGraph->new();

=head1 ABSTRACT

A module to create text bar graphs

=head1 DESCRIPTION

This module takes as input a hash, where the keys are labels for bars on
a graph and the values are the magnitudes of those bars.

=head1 EXAMPLE

  $graph = Text::BarGraph->new();

  %hash = (
    alpha => 30,
    beta  => 40,
    gamma => 25
  );

  print $g->graph(\%hash);

=head1 METHODS

=over 4

=cut

our $VERSION = 1.1;
our %fields = (
	dot		=> '#',		# character to graph with
	num		=> 1,		# display data value in ()'s
	enable_color	=> 0,		# whether or not to color the graph
	sortvalue	=> "key",	# key or data
	sorttype	=> "string",	# string or numeric, ignored if sort is 'data'
	zero		=> 0,		# value to start the graph with
	max_data	=> 0,		# where to end the graph
	autozero	=> 0,		# automatically set start value
	autosize	=> 1,		# requires Term::ReadKey
	columns		=> 80,		# columns
);

=item I<new>

  $graph = Text::BarGraph->new();

The constructor.

=cut
sub new {
	my $that = shift;
	my $class = ref($that) || $that;

	my $self = {
		_permitted => \%fields,
		%fields,
	};

	my %args = @_;

	while(my ($field, $value) = each %args) {
		if(exists($self->{'_permitted'}{$field})) {
			$self->{$field} = $value;
		} else {
			croak "Invalid field name '$field' in class $class";
		}
	}

	if(eval "require Term::ANSIColor") {
		import Term::ANSIColor;
		$self->{'colortype'} = "module";
	} else {
		$self->{'colortype'} = "raw";
	}

	bless $self, $class;
	return $self;
}

sub DESTROY { }

sub AUTOLOAD {
	my $self = shift;
	my $type = ref($self) || die "$self is not an object";
	my $name = $AUTOLOAD;
	$name =~ s/.*://; # strip fully qualified portion
	unless (exists $self->{'_permitted'}{$name} ) {
		croak "Invalid field name '$name' in class $type";
	}

	if (@_) {
		$self->{$name} = shift;
	}
	return $self->{$name};
}

=item I<graph>

  $graph_text = $graph->graph(\%data);
  
Return a graph of the data in the supplied hash. The keys in 
the hash are labels, and the values are the magnitudes.

=cut
sub graph {
	my ($self, $data) = @_;
	my $gtext = '';
	my $label_length = 5;
	my $scale = 1;
	my $sep = " ";
	my $barsize = 0;
	my $sort_sub;
 	my $min_data;
	my $max_data;

	my $columns = $self->{'columns'};

	# silently fail to autoresize if we are not talking to a tty
	# OR if the Term::ReadKey module doesn't exist
	if($self->{'autosize'} && -t STDOUT && eval "require Term::ReadKey") {
		import Term::ReadKey;
		($columns) = GetTerminalSize('STDOUT');
	}

	# find initial column width and scaling
	foreach my $key (keys %{$data}) {
		if(!defined($min_data) || $min_data > $data->{$key}) {
			$min_data = $data->{$key};
		}
		if(length($key) > $label_length) {
			$label_length = length($key);
		}
		if(!defined($max_data) || $data->{$key} > $max_data) {
			$max_data = $data->{$key};
		}
	}
	if(!defined($max_data) || $self->{'max_data'} > $max_data) {
		$max_data = $self->{'max_data'};
	}

	# determine how many columns are left for the graph after
	# the labels
	my $data_length = length($max_data);
	if($label_length > ($columns * .25)) { 
		$sep = "\n"; 
		$barsize = $columns;
	} else { 
		$sep = " "; 
		if($self->{'num'}) {
			$barsize = $columns - ($label_length + $data_length + 4);
		} else {
			$barsize = $columns - ($label_length + 1);
		}
	}

	if($self->{'autozero'}) { 
		$self->{'zero'} = int($min_data - (($max_data - $min_data) / ($barsize - 1))); 
	}
  
	# determine points to change colors
	my ($p1, $p2, $p3) = 0; 
	if($self->{'enable_color'}) {
		$p1 = int($barsize * .25);
		$p2 = $p1*2; $p3 = $p1*3;
	}

	if($max_data) { $scale = $barsize / ($max_data - $self->{'zero'}); }

	# create a sort subroutine based on sortvalue and sorttype
	if($self->{'sortvalue'} eq "key") {
		if($self->{'sorttype'} eq "string") {
			$sort_sub = sub { return $a cmp $b; }
		} else {
			$sort_sub = sub { return $a <=> $b; }
		}
	} else {
		$sort_sub = sub { return $data->{$a} <=> $data->{$b}; }
	}

	# build the graph
	foreach my $label (sort $sort_sub keys %{$data}) {
		my $bar = '';
		my $dots = int(($data->{$label} - $self->{'zero'}) * $scale);

		if($self->{'enable_color'}) {
			$bar = $self->_colordots($p1, $p2, $p3, $dots);
		} else {
			$bar = $self->{'dot'}x$dots;
		}

		if($self->{'num'}) {
			$gtext .= sprintf "%${label_length}s (%${data_length}d)${sep}%s\n", 
				$label, $data->{$label}, $bar;
		} else {
			$gtext .= sprintf "%${label_length}s${sep}%s\n", $label, $bar;
		}
	}

	# add a line giving the start point if it's not zero
	if($self->{'zero'}) {
		if($self->{'num'}) {
			$gtext .= sprintf "%${label_length}s  %${data_length}d /\n", '<zero>', $self->{'zero'};
		} else {
			$gtext .= sprintf "%${label_length}s /\n", "$self->{'zero'}";
		}
	}
	return $gtext;
}

sub _colordots {
	my ($self, $p1, $p2, $p3, $dots) = @_;

	my $bar = '';

	if($self->{'colortype'} eq "module") {
		$bar = color('blue');

		for(1..$dots) {
			if(   $_ eq $p1) { $bar .= color('green'); }
			elsif($_ eq $p2) { $bar .= color('yellow'); }
			elsif($_ eq $p3) { $bar .= color('red'); }

			$bar .= $self->{'dot'};
		}
		$bar .= color('reset');

	} elsif($self->{'colortype'} eq "raw") {
		$bar = "\e[34m"; # start blue

		for(1..$dots) {
			if(   $_ eq $p1) { $bar .= "\e[32m"; } # green
			elsif($_ eq $p2) { $bar .= "\e[33m"; } # yellow
			elsif($_ eq $p3) { $bar .= "\e[31m"; } # red
			$bar .= $self->{'dot'};
		}
		$bar .= "\e[0m"; # turn the color off
	}
	return $bar;
}

1;

__DATA__


=item I<dot>

  $graph->dot('.')

Set the character used in the graph.

Default: #

=item I<num>
  
  $graph->num(0);

Whether to display the numerical value of each bar

Default: 1

=item I<sortvalue>

  $graph->sortvalue("data");

Set what to use to sort the graph. Valid values
are "data" and "key". Key sorts by the bar's label,
data sorts by the bar's magnitude.

Default: key

=item I<sorttype>

  $graph->sorttype("string");

Whether to sort bar labels as strings or numerically.
Valid values are "string" and "numeric". This option 
is ignored when sorting by 'data'

Default: string

=item I<zero>

  $graph->zero(20);

Sets the initial value (far left) of the graph. Ignored
if autozero is set. When zero is non-zero, an extra row
will be printed to identify the minimum value.

Default: 0

=item I<autozero>

  $graph->autozero(1);

Automatically choose the initial value (far left) of
the graph. Overrides any value set with I<zero>.

Default: 0


=item I<max_data>
  
  $graph->max_data(1000);

Forces the end of the graph (right side) to be larger
than the maximum value in the graph. If the supplied
value is less than the maximum value, it will be ignored.

Default: 0

=item I<columns>

  $graph->columns(120);

Set the number of columns to use when displaying the graph.
This value is ignored if autosize is used.

Default: 80


=item I<autosize>

  $graph->autosize(0);

Automatically determine the size of the display. Only works if
Term::ReadKey is installed and a terminal is detected. Otherwise,
the value set by I<columns> is used.

Default: 1

=item I<enable_color>

  $graph->enable_color(1);

Whether to use ANSI color on the bargraph. Uses
Term::ANSIColor if it is present. 

Default: 0

=back

=head1 AUTHOR

Kirk Baucom E<lt>kbaucom@schizoid.comE<gt>

=head1 COPYRIGHT

Copyright (c) 2011 Kirk Baucom.  All rights reserved.  This package
is free software; you can redistribute it and/or modify it under the same
terms as Perl itself.

=cut

