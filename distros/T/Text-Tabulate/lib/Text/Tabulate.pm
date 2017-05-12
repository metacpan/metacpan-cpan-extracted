#! /usr/bin/perl

=head1 NAME

Text::Tabulate - a pretty text data tabulator that minimises the width of tables.

=head1 SYNOPSIS

	use Text::Tabulate;

	$tab = new Text::Tabulate (<options>);

	$tab->configure(<options>);

	@out = $tab->format(@lines);

	@out = $tab->common(@lines);


	@out = tabulate ( { tab => '???', ...}, @lines);

	@out = tabulate ( $tab, $pad, $gutter, $adjust, @lines);

=head1 DESCRIPTION

This perl module takes an array of line text data, each line separated
by some string matching a given regular expression, and returns a
minimal width text table with each column aligned.

=head1 FUNCTIONS

=over 4

=cut


;#####################################################################################

package Text::Tabulate;

use 5.006_001;
use warnings;
use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);
use Carp;

require Exporter;

$VERSION = '1.1.1';
@ISA = qw(Exporter);
@EXPORT = qw( tabulate );
@EXPORT_OK = ();

sub debug {}

;# Default tabulate settings.
my %defaults = (
	tab	=> "\t",
	eol	=> '(\n)|(\r\n)|(\r)',
	pad	=> ' ',
	gutter	=> ' ',
	adjust	=> '',
	ignore	=> undef,
	cf	=> -1,
	ditto	=> '',
	left	=> '',
	right	=> '',
	bottom	=> '',
	top	=> '',
	joint	=> '',
);

=pod

=item C<new>

	my $tab = new Text::Tabulate( -tab => 'tab', ...);

Create an Text::Tabulate object.
All CONFIGURATION OPTIONS are accepted, with or without a leading -.

=cut

;# NB allow this: my $a = $b->new();

sub new
{
	# Create an object.
	my $this = shift;
	my $class = ref($this) || $this;
	my $self = { };
	bless $self, $class;

	# Initialise
	$self->initialise();

	# Load args into $self.
	unless ($self->configure(@_))
	{
		croak "$class: initialisation failed!";
		return undef;
	}

	#use Data::Dumper; warn Dumper(\$self);

	$self;
}

;# "private" function.
sub initialise
{
	my ($self) = @_;

	# Load defaults
	while ( my ($k, $v) = each %defaults)
	{
		$self->{$k} = $v;
	}

	# return object
	$self;
}


=pod

=item C<configure>

	my $tab = new Text::Tabulate();
	$tab->configure(-tab => 'tab', gutter => '|', ...);

This function chages the configuration settings of a Text::Tablulate
object.
All CONFIGURATION OPTIONS are accepted, with or without a leading -.

=cut

sub configure
{
	my $self = shift;

	unless ($#_ % 2)
	{
		croak ref($self), ": Odd number of arguments";
		return 0;
	}

	# Load args into $self.
	my %arg = @_;
	while ( my ($k, $v) = each %arg)
	{
		# Remove any leading -
		my $kk = $k; $kk =~ s/^-//;

		# Is this a real config option?
		next unless exists $defaults{$kk};

		# Set option.
		$self->{$kk} = delete $arg{$k};
	}

	# Are there extra options?
	if (%arg)
	{
		my @extras = sort keys %arg;
		my $s = ($#extras > 0) ? 's' : '';
		croak ref($self), ": Extra configuration option$s '", join("', '", @extras), "'";
		return 0;
	}

	$self;
}

=pod

=item C<format>

	my $tab = new Text::Tabulate(...);
	@out = $tab->format (@lines);

Format the table data (@lines) according to the Text::Tabulate object.

=cut

sub format
{
	my ($self, @lines) = @_;

	my $tab		= $self->{tab};
	my $eol		= $self->{eol};
	my $pad		= $self->{pad};
	my $gutter	= $self->{gutter};
	my $adjust	= $self->{adjust};
	my $ignore	= $self->{ignore};
	my $left	= $self->{left};
	my $right	= $self->{right};
	my $cf		= $self->{cf};
	my $ditto	= $self->{ditto};
	my $bottom	= $self->{bottom};
	my $top		= $self->{top};
	my $joint	= $self->{joint};

	# Repackage lines, split with eol regular expression
	# remembering the end of line string.
	my @l = ();
	my @eol = ();
	for my $line (@lines)
	{
		# Split into lines...
		while ($line =~ s/^(.*?)($eol)//s)
		{
			push @l, $1;
			push @eol, $2;

		}

		# If there is any left, just add.
		if ($line)
		{
			push @l, $line;
			push @eol, '';
		}
	}
	@lines = @l;

	# ignore blank lines at end.
	my @blanks = ();
	while (@lines && $lines[$#lines] =~ /^\s*$/)
	{
		push @blanks, pop(@lines);
	}

	# Remove common first column entries?
	@lines = $self->common(@lines) if ($cf >= 0);

	local ($_);

	# extract the maximum column widths.
	my @width;
	my $cols = 0;
	for my $line (@lines)
	{
		# ignore line like the $ignore regular expression.
		next if (defined($ignore) && ($line =~ /$ignore/));

		# Look through the fields.
		my $i = 0;
		my @cell = split(/$tab/, $line);
		$cols = $#cell if ($#cell > $cols);

		for (@cell)
		{
			my ($l) = length;

			$width[$i] = $l if (!defined($width[$i]) || $width[$i] < $l);

			++$i;
		}

		debug "checking widths: $line\n";
		debug "         widths: " , join(", ", @width) , "\n";
	}

	my @adjust = split(//, $adjust);

	# extend padding if needs be.
	$pad = ' ' if (length($pad) < 1);
	if (length($pad) == 1)
	{
		$pad .= ${pad}x(2+$cols);
	}
	my @pad = split(//, $pad);

	my @table;

	# add top.
	if ($top)
	{
		my $out = '';
		if (length($top) == 1)
		{
			$top .= ${top}x(2+$cols);
		}
		my @top = split(//, $top);

		for (my $i=0; $i<=$#width; $i++)
		{
			$out .= $gutter if ($i);
			$out .= $top[$i]x$width[$i];
		}

		push @table, $left . $out . $right;
	}

	# recontruct each line with the correct padding and spacing.
	for my $line (@lines)
	{
		# ignore line like the $ignore regular expression.
		if (defined($ignore) && ($line =~ /$ignore/))
		{
			push (@table, $line);
			next;
		}

		debug "recontructing: '$line'\n";

		my $i = 0;
		my $out = '';

		# remove any end of line characters.
		my $end = ($line =~ s/[\r\n]+$//) ? $& : '';

		# Go through the columns and pad, adjust, etc..
		my @cell = split(/$tab/, $line);
		while ($#cell < $cols)
		{
			push @cell, '';
		}

		for (@cell)
		{
			my $l = $width[$i] - length;

			# Default for justification.
			$adjust[$i] = 'l' unless (defined $adjust[$i]);

			# how to adjust in the column.
			# The default is to left adjust.
			my $f = ($adjust[$i] eq 'r') ? $l :
				( ($adjust[$i] eq 'c') ? int($l/2) : 
				0 );
			my $b	= $l - $f;

			my $fpad = $pad[$i];
			my $bpad = $pad[$i+1];

			$fpad ||= ' ';
			$bpad ||= ' ';

			# gutter and adjust.
			$out .= $gutter if ($i > 0);
			$out .= ${fpad}x$f if ($f>0);
			$out .= $_;
			$out .= ${bpad}x$b if ($b>0);

			# next column please.
			++$i;
		}

		#print "I: $line";
		#print "O: $out";

		debug "becomes      : '$out'\n";

		# reassemble
		push (@table, $left . $out . $right . $end);

		# extend eol array; use last value.
		unshift @eol, $eol[0];
	}

	# add bottom.
	if ($bottom)
	{
		my $out = '';
		if (length($bottom) == 1)
		{
			$bottom .= ${bottom}x(2+$cols);
		}
		my @bottom = split(//, $bottom);

		for (my $i=0; $i<=$#width; $i++)
		{
			$out .= $gutter if ($i);
			$out .= $bottom[$i]x$width[$i];
		}

		push @table, $left . $out . $right;

		# extend eol array; use last value.
		push @eol, $eol[$#eol];
	}

	# add the blank lines.
	push @table, @blanks;

	# strip any white space at the end of the lines.
	for (@table)	{ s/[\t ]+$//; }

	# Rejoin the eol of table line strings.
	for my $line (@table)
	{
		$line .= shift(@eol);
	}

	# return final table.
	return @table if (wantarray);

	# combine the array into a single string.
	join($joint, @table);
}

=pod

=item C<common>

	my $tab = new Text::Tabulate();
	$tab->configure(-tab => 'tab', cf => 2, ditto => '?');
	@out = $tab->common(@lines);

This function returns an array of lines identical to the input except
that any repeated common value in the first column is removed in
subsequent lines and replaced by the string $ditto. If $max is positive,
then only that number of columns are considered; otherwise all column
are considered.

The array of lines, @lines, is assumed to be an array of sigle table
rows.

=cut

;# Take an 'tab' string and a array of lines and return the array with
;# any repeated first column values obmitted.
sub common
{
	my ($self, @lines) = @_;

	my ($tab)	= $self->{tab};
	my ($max)	= $self->{cf};
	my ($ditto)	= $self->{ditto};

	local ($_);

	# look through all the lines....
	my (@last);
	for (@lines)
	{
		# ignore if there is no tab.
		next unless /$tab/;

		# Split the line into cells.
		my @this = split(/$tab/, $_);

		# look at each line.
		if (@last)
		{
			# consider this line against the last.
			my $tmp = '';
			my $i = 0;
			while (1)
			{
				last if ($max > 0 && $i >= $max);
				last unless defined($this[$i]);
				last unless defined($last[$i]);
				last unless ($this[$i] eq $last[$i]);
				
				$i++;

				# Remove field.
				s/.+?($tab)?//;

				# Remember duplicate fields.
				$tmp .= $ditto;
				$tmp .= $1;
			}

			# reassemble line.
			$_ = $tmp . $_;
		}

		# Remember the last line.
		@last = @this;
	}

	# return ammended table.
	@lines;
}

;#############################################################################

=pod

=item C<tabulate>

	@out = tabulate ( { tab => '???', ...}, @lines);
	@out = tabulate ( $tab, $pad, $gutter, $adjust, @lines);

This function returns an array of formated lines identical to the input except
that tab separated columns have been aligned with the padding chacater.

It can be involked in two ways; either with an hashed array of arguments
followed by an array of lines or by 4 parameters (tab, pad, gutter,
adjust) followed by an array of lines.


Suggested usage:

	perl -MText::Tablutate -e'tabulate {gutter=>"|",}'

=cut

sub tabulate
{
	my $obj = new Text::Tabulate();

	# array version
	if (ref $_[0] eq '')
	{
		$obj->configure(
			tab	=> shift,
			pad	=> shift,
			gutter	=> shift,
			adjust	=> shift,
		);
	}

	# hash version.
	elsif (ref $_[0] eq 'HASH')
	{
		$obj->configure( %{$_[0]});
		shift;
	}

	# Wrong arguments.
	else 
	{
		croak ref($obj), "; tabulate error!";
	}

	$obj->format(@_);
}


=pod

=item C<filter>

	Text::Tabulate::filter(@ARGV)

Act as a UNIX filter taking input from either STDIN or files specified
as function arguments, and sending the resulting formtted table to STDOUT.
Additional arguments will modify the behavour. 

	perl -MText::Tablutate -e'filter(@ARGV)' <options> [files]

This function is involked if the Text::Tabulate module is run as a perl script.

	perl Text/Tabulate.pm <options> [input-files]

The function options are

=over 4

=item -s|--stanza

Treat each paragraph as a individual table.

=item -h|--html	

Format each table as HTML.

=back

The other options correspond to the configuration options of the
module.

=over 4

=item -t|--tab <tab>		

Set the tab string.
See module configuation options.

=item -e|--eol <end-of-line-reg-ex>

Set the regular expression denoting an end of a table row.
See module configuation options.

=item -p|--pad <pad>		

Set the pad character.
See module configuation options.

=item -g|--gutter <gutter>

Set the gutter string.
See module configuation options.

=item -I|--Ignore <reg-ex>

Ignore lines that match this regular expression.
See module configuation options.

=item -a|--adjust <string>

Justify columns according to this string.
See module configuation options.

=item -T|--top <string>

Set the top border characters.
See module configuation options.

=item -B|--top <string>

Set the bottom border characters.
See module configuation options.

=item -l|--left <string>

Set the left border string.
See module configuation options.

=item -r|--right <string>

Set the right border string.
See module configuation options.

=item -c|--cf <number>

This specifies if repeated values in the first few fields should be
replaced by the empty string.
See module configuation options.

=item -d|--ditto <number>

This specified the string that replaces common values (see cf above).
See module configuation options.

=back

=cut

sub filter
{
	# Load these modules if we are running this function.
	# Exit gracefully if we can't.
	our @missing = grep( !eval "use $_; 1", qw (
		File::Basename
		Getopt::Long
	)) and die "Please install CPAN modules:\n\tcpan -i @missing\n";

	# Initialise.
	my $tab		= new Text::Tabulate();
	my $bystanza	= 0;
	my $html	= 0;
	my $program	= basename($0);

	# usage
	my $usage	= 
	"Usage:\t$program --usage
	$program <options> [<files>]
	
Options:
	-p|--pad <pad>		set the pad character
	-t|--tab <tab>		set the tab string; default is <tab>
	-e|--eol <eol>		set the eol regular expression
	-g|--gutter <gutter>	set the gutter
	-I|--Ignore <reg-ex>	ignore lines that match this reg-ex
	-a|--adjust <string>	justify columns as this string
	-c|--cf <number>	set the number of common valued cells to remove.
	-d|--ditto <string>	set the dulpicate value replacement string.
	-T|--top <string>	set the top border
	-B|--bottom <string>	set the bottom border
	-r|--right <string>	set the right border
	-l|--left <string>	set the left border

	-s|--stanza		treat each paragraph as a individual table
	-h|--html		output an HTML table
";

	################# start of command processing. #################

	# Use a local copy for this function.
	local @ARGV = @_;

	# Load all the default options as flags.
	my %opts = ();
	for my $opt (keys %defaults)
	{
		$opts{"$opt=s"} = \$tab->{$opt};
	}

	&Getopt::Long::config(qw(bundling auto_abbrev require_order));
	GetOptions(
		'usage'		=> sub { print $usage; exit; },

		# From module defaults
		%opts,

		# aliases.
		'p=s'	=> \$tab->{pad},
		't=s'	=> \$tab->{tab},
		'e=s'	=> \$tab->{eol},
		'i=s'	=> \$tab->{ignore},
		'g=s'	=> \$tab->{gutter},
		'a=s'	=> \$tab->{adjust},
		'c=i'	=> \$tab->{cf},
		'l=s'	=> \$tab->{left},
		'r=s'	=> \$tab->{right},
		'T=s'	=> \$tab->{top},
		'B=s'	=> \$tab->{bottom},

		# Extras
		's|stanza+'	=> \$bystanza,
		'h|html+'	=> \$html,
		'v|version'	=> sub { print "$VERSION\n"; exit; },

		'debug'	=> sub {
				no warnings;
				eval 'sub debug { print STDERR @_; }';
			},
	) || die $usage;


	################## rest of the script goes here. #################

	my $startTab	= '';
	my $startRow	= '';
	my $endRow	= "\n";
	my $endTab	= '';

	if ($html%2)
	{
		$startTab	= "<TABLE>\n";
		$endTab		= "</TABLE>\n";

		$tab->{left}	= "<TR><TD>" .$tab->{left};
		$tab->{right}	.= "</TD></TR>";

		$tab->{gutter}	= "</TD>" . $tab->{gutter} . "<TD>";
	}

	# slurp or stanza mode?
	$bystanza = ($bystanza%2);
	local $/ = $bystanza ? '' : undef;

	# read in the data.
	while (<>)
	{
		my @table = $tab->format($_);

		next unless (@table);

		print $startTab;
		print join('', @table);
		print $endTab;
	}
}

;# self run
filter(@ARGV) if ($0 eq __FILE__);

=pod

=head1 CONFIGURATION OPTIONS

The module configuration options are:

=over 4

=item tab

This specified a regular expression denoting the original table
separator. The default is <TAB>.

=item eol

This specified a regular expression denoting the end of table lines. 
The default is '(\n)|(\r\n)|(\r)' to match most text formats. These
end of line strings are replaced after the table is formating.

=item pad

This specified the character used to pad the fields in the final
representation of the table. The default is a space.

=item gutter

This specifies the string places between columns in the final
representation. The default is the empty string.

=item adjust

This is a string specifying the justification of each field in the final
representation. Each character of this string should be 'r', 'l' or 'c'.
The default is left justification for all fields.

=item ignore

This regular expresion specifies lines that should be ignored. The
default is not to ignore any line.

=item cf

This specifies if repeated values in the first few fields should be
replaced by the empty string. The default is not to do this.

=item ditto

This specified the string that replaces common values (see cf above).

=item top

This specified the characters to be placed at the top of the table as a
border. If it is one character, then this is used as every character on
the top border. If there are more than one character then the first is
used for the first column, the second character for the second column,
etc.. The default is empty (i.e. no top border).

=item bottom

This specified the characters to be placed at the bottom of the table as a
border. If it is one character, then this is used as every character on
the bottom border. If there are more than one character then the first is
used for the first column, the second character for the second column,
etc.. The default is empty (i.e. no bottom border).

=item left

This specifies the strings to be placed as a border on the left of the
table. The default is nothing.

=item right

This specifies the strings to be placed as a border on the right of the
table. The default is nothing.

=item joint

This specifies the string used to join the rows of the table when the
I<format> and I<tabulate> functions are called in a scalar context.
This is most useful when the table input is split on newlines and
a scaler return is required that includes newlines. Very similar to
I<left> but depends on the context.
The default is nothing.

=back

=cut

=pod

=back

=head1 EXAMPLE

	use Text::Tabulate;
	my $tab = new Text::Tabulate();
	$tab->configure(-tab => "\t", gutter => '|');

	my @lines = <>:
	@out = $tab->format (@lines);
	print @out;

=head1 VERSION

This is version 1.0 of Text::Tabulate, released 1 July 2007.

=head1 AUTHOR

	Anthony Fletcher

=head1 COPYRIGHT

Copyright (c) 1998-2007 Anthony Fletcher. All rights reserved.
This module is free software; you can redistribute them and/or modify
them under the same terms as Perl itself.

This code is supplied as-is - use at your own risk.

=cut

1;

