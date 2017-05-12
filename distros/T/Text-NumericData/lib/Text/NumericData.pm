package Text::NumericData;

use Storable qw(dclone);

# TODO: optimize those regexes, compile once in constructor

# major.minor.bugfix, the latter two with 3 digits each
# It's not pretty, but I gave up on 1.2.3 style.
our $VERSION = '2.002000';
our $version = $VERSION;
$VERSION = eval $VERSION;

our $years = '2005-2016';
our $copyright = 'Copyright (c) '.$years.' Thomas Orgis, Free Software licensed under the same terms as Perl 5.10';
our $author = 'Thomas Orgis <thomas@orgis.org>';

# TODO: More smarts in separator search.
# One should find ', ' as separator in
# a / c, d /e
my $newhite = '[^\S\015\012]'; # whitespace that is no line end character
my $trenner = $newhite.'+|,'.$newhite.'*|;'.$newhite.'*';
my $ntrenner = '[^\s,;]+'; # also excludes CR LF
my $lend = '[\012\015]+';
my $nlend = '[^\012\015]';
my $quotematch = "['\"]";

my %endname =   ("\015\012"=>'DOS', "\012"=>'UNIX', "\015"=>'MAC');
my %endstring = reverse %endname;

# Fallback defaults if anything else fails.
our $default_sep = "\t";
our $default_eol = $/;
our $default_comchar = '#';
our $default_quote = 1;
our $default_quotechar = '"';

our %help =
(
	 separator=>'use this separator for input (otherwise deduce from data; TAB is another way to say "tabulator", fallback is'.$default_sep.')'
	,outsep=>'use this separator for output (leave undefined to use input separator, fallback to '.($default_sep eq "\t" ? 'TAB' : $default_sep).')'
	,lineend=>'line ending to use: ('.join(', ', sort keys %endstring).' or be explicit if you can, taken from data if undefined, finally resorting to '.(defined $endname{$default_eol} ? $endname{$default_eol} : $default_eol).')'
	,comchar=>'comment character (if not set, deduce from data or use '.$default_comchar.')'
	,numregex=>'regex for matching numbers'
	,numformat=>'printf formats to use (if there is no "%" present at all, one will be prepended)'
	,comregex=>'regex for matching comments'
	,quote=>'quote titles'
	,quotechar=>'quote character to use (derived from input or '.$default_quotechar.')'
	,strict=>'strictly split data lines at configured separator (otherwise more fuzzy logic is involved)'
	,text=>'allow text as data (not first column)'
	,fill=>'fill value for undefined data'
	,black=>'ignore whitespace at beginning and end of line (disables strict mode)'
	,empty=>'treat empty lines as empty data sets, preserving them in output'
);

# These are defaults for user settings.
our %defaults = 
(
	'separator',undef,
	'outsep', undef,
	'lineend', undef,
	'comchar', undef,
	'numregex', '[\+\-]?\d*\.?\d*[eE]?\+?\-?\d*',
	'numformat',[],
	'comregex','[#%]*'.$newhite.'*',
	'quote',undef,
	'quotechar',undef,
	'strict', 0,
	'text', 1
	,'fill',undef # a value to fill in for non-existent but still demanded data
	,'black', 0
	,'empty',0
);

sub new
{
	my $class = shift;
	my $self = {};
	bless $self, $class;
	# Only pick the parts of the config hash that are of interest here.
	my $gotconf = shift;
	$self->{gotconfig} = {};
	for my $n (keys %defaults)
	{
		if(ref $gotconf->{$n})
		{
			$self->{gotconfig}{$n} = dclone($gotconf->{$n});
		}
		else
		{
			$self->{gotconfig}{$n} = $gotconf->{$n};
		}
	}
	foreach my $n (@{$self->{gotconfig}->{numformat}})
	{
		$n = '%'.$n unless $n =~ /\%/;
	}
	# Expand named special characters for line ending.
	if(defined $gotconf->{lineend})
	{
		$self->{gotconfig}{lineend} = defined $endstring{$gotconf->{lineend}}
			? $endstring{$gotconf->{lineend}}
			: $gotconf->{lineend};
	}
	for (qw(separator outsep))
	{
		if(defined $gotconf->{$_} and $gotconf->{$_} eq 'TAB'){ $self->{gotconfig}{$_} = "\t"; }
	}

	$self->{gotconfig}{strict} = 0
		if $self->{gotconfig}{black};
	$self->init();
	return $self;
}

sub init
{
	my $self = shift;
	%{$self->{config}} = %{$self->{gotconfig}};
	$self->{comments} = []; #some comment in header
	$self->{guessquote} = undef;
	$self->{titles} = []; #column titles
	$self->{title} = undef; #file title
	foreach my $k ('numregex','numformat','comregex','fill')
	{
		$self->{config}{$k} = $defaults{$k} unless defined $self->{config}{$k};
	}
	# Strict mode needs some set separator.
	if($self->{config}{strict} and not defined $self->{config}{separator})
	{
		$self->{config}{separator} = $default_sep;
	}
}

#line_check($line, $onlycheck) 
#$onlycheck: 0/undef: do full search for file/line titles and line end, etc.
#            1: only determine if data or not 
sub line_check #return 1 and set separator and line ending if data line and 0 otherwise
{
	my $self = shift;
	# temporary hack until fully switching to value instead of ref, which is a ref anyway
	my $lr = ref $_[0] ? $_[0] : \$_[0];
	my $oc = $_[1];
	my $zahl = $self->{config}{numregex};
	my $seppl = $trenner;
	$seppl = $self->{config}{separator} if $self->{config}{strict};
	#the leading whitespace is a workaround for TISEAN
	#good or bad? It should not break any files that worked before...
	if( ${$lr} =~ /^\s*$/ and ${$lr} =~ /^($nlend*)($lend)$/o )
	{
		$self->{config}{lineend} = $2 unless defined $self->{config}{lineend};
		# An empty line counts as comment when it comes after a title.
		push(@{$self->{comments}},$1)
			if defined $self->{title};
		return 0;
	}
	if(${$lr} =~ /^\s*($zahl)(($seppl)$nlend*|)($lend)$/)
	{
		my ($num, $end, $sep) = ($1, $4, $3);
		my $piece = $1.$2;
		unless(not defined $end or defined $self->{config}{lineend})
		{
			$self->{config}{lineend} = $end;
		}
		unless($self->{config}{text})
		{
			# If text is not allowed, we strictly only want
			# numbers and separators and line end.
			# Let's get expensive: Remove everything we know. if there is something
			# left, we got text.
			my $linecopy = ${$lr};
			$linecopy =~ s/$seppl//g;
			$linecopy =~ s/($zahl|\s+|$lend)//g;
			if($linecopy ne '')
			{
				if( defined $self->{title} ){ push(@{$self->{comments}},$piece); }
				else{	$self->{title} = $piece; }
				return 0;
			}
		}
		# sanity check for loosened definition of number... at least one digit shall be there
		if($num =~ /\d/)
		{
			unless(not defined $sep or defined $self->{config}{separator})
			{
				$self->{config}{separator} = $sep;
			}
			if($#{$self->{comments}} > -1 and $#{$self->{titles}} > -1)
			{
				pop(@{$self->{comments}});
			}
			return 1; # Yeah, found a number line.
		}
	}
	elsif($oc){ return 0; }
	else
	{
		if(${$lr} =~ /^($self->{config}{comregex})($lend)$/)
		{
			$self->{config}{comchar} = $1
				unless defined $self->{config}{comchar};
			$self->{config}{lineend} = $2
				unless defined $self->{config}{lineend};
			return 0;
		}
		#first non-empty line is some kind of title or comment
		#first means: we didn't have content up to now
		if(${$lr} =~ /^($self->{config}{comregex})($nlend+)($lend)$/)
		{
			if( defined $self->{title} ){ push(@{$self->{comments}},$2); }
			else{	$self->{title} = $2; }
			$self->{config}{lineend} = $3
				unless defined $self->{config}{lineend};
			$self->{config}{comchar} = $1
				unless defined $self->{config}{comchar};
		}
		#attention: I take " or ' just as quotes, do distinction!
		my $quote = $self->{config}{quotechar};
		$quote = $quotematch
			unless defined $quote;
		if(${$lr} =~ /^($self->{config}{comregex})($quote)($nlend*\2($seppl)\2*$nlend*)\2*($lend)$/)
		{
			$self->{config}{quote} = 1
				unless defined $self->{config}{quote};
			$self->{config}{quotechar} = $2
				unless defined $self->{config}{quotechar};
			# "axis title"\t"axis title"\t"..."
			# allow flexible space in separator
			my $sep  = $4;
			my $q    = $2;
			my $rest = $3;
			$rest =~ s:$q$::;
			$sep =~ s:\s+$:\\s+:
				unless($strict);
			my @ax = split($q.$sep.$q,$rest);
			$self->{titles} = \@ax;
			$self->{config}{lineend} = $5
				unless defined $self->{config}{lineend};
			$self->{config}{comchar} = $1
				unless defined $self->{config}{comchar};
		}
		#either no quotes at all or maybe quotes but single item without separator
		elsif(${$lr} =~ /^($self->{config}{comregex})($quote?)($nlend*)($lend)$/)
		{
			if($2 ne '')
			{
				$self->{config}{quotechar} = $2
					unless defined $self->{config}{quotechar};
				$self->{config}{quote} = 1
					unless defined $self->{config}{quote};
			}
			else
			{
				$self->{guessquote} = 0
			}
			$self->{config}{lineend} = $4
				unless defined $self->{config}{lineend};
			$self->{config}{comchar} = $1
				unless defined $self->{config}{comchar};
			my $d = $3;
			$d =~ s/$quote$//;
			my @ax = ();
			if($d =~ /($seppl)/)
			{
				@ax = split($1, $d);
			}
			else{ @ax = ($d); }
			$self->{titles} = \@ax;
		}
		return 0;
	}
}

sub get_insep
{
	my $self = shift;
	return defined $self->{config}{separator}
		? $self->{config}{separator}
		: $default_sep;
}

sub get_outsep
{
	my $self = shift;
	return defined $self->{config}{outsep}
		? $self->{config}{outsep}
		: (
			defined $self->{config}{separator}
				? $self->{config}{separator}
				: $default_sep
		);
}

sub get_end
{
	my $self = shift;
	return defined $self->{config}{lineend}
		? $self->{config}{lineend}
		: $default_eol;
}

sub get_quote
{
	my $self = shift;
	my $want = defined $self->{config}{quote}
		? $self->{config}{quote}
		: ( defined $self->{guessquote}
			? $self->{guessquote}
			: $default_quote );
	return $want
		? (  defined $self->{config}{quotechar}
			? $self->{config}{quotechar}
			: $default_quotechar )
		: '';
}

sub get_comchar
{
	my $self = shift;
	return defined $self->{config}{comchar}
		? $self->{config}{comchar}
		: $default_comchar;
}

sub line_data
{
	my $self = shift;
	my $lr = ref $_[0] ? $_[0] : \$_[0];
	my @ar = ();
	my $zahl = $self->{config}{numregex};
	# empty lines
	return ($self->{config}{empty} ? [] : undef) if(${$lr} =~ /^$lend$/);
	if($self->{config}{strict})
	{
		#just split with defined or found separator
		@ar = split($self->get_insep(), ${$lr});
		#remove line end
		if($#ar > -1){ $ar[$#ar] =~ s/$lend//o; }
	}
	else
	{
		my $l = ${$lr};
		if($self->{config}{black})
		{
			$l =~ s/^\s*//;
			# s/\s*$// deletes the line end -- no problem here
			$l =~ s/\s*$//;
		}
		if($l =~ /^($zahl)(.*)$/){ push(@ar, $1); $l = $2; }else{ return undef; }
		unless($self->{config}{text})
		{
			while($l =~ /^($trenner)($zahl)(.*)$/o)
			{
				push(@ar, $2);
				$l = $3;
			}
		}
		else
		{
			while($l =~ /^($trenner)($ntrenner)(.*)$/o)
			{
				push(@ar, $2);
				$l = $3;
			}
		}
	}
	return \@ar;
}

sub data_line
{
	my $self = shift;
	my $ar = shift;

	my $wr = shift;
	my $l = '';
	my $zahl = $self->{config}{numregex};
	my $end = $self->get_end();
	my $sep = $self->get_outsep();
	my @vals;
	my @cols;
	my $i = -1;

	unless(defined $wr)
	{
		@vals = @{$ar};
		@cols = (0..$#vals);
	}
	else
	{
		for my $k (@{$wr})
		{
			push(@vals, ($k > -1 and $k < @{$ar})
				? $ar->[$k]
				: $self->{config}{fill}); 
			push(@cols, $k > -1 ? $k : 0); # ... for numerformat ... arrg
		}
	}

	if(defined $self->{config}{numformat}->[0])
	{
		foreach my $i (0..$#vals)
		{
			my $v = $vals[$i];
			my $c = $cols[$i];
			unless(defined $v){ $l .= $sep; next; }

			my $numform = $self->{config}{numformat}->[$c];
			$numform = $self->{config}{numformat}->[0] unless defined $numform;
			if($numform ne '')
			{
				$l .= ($v ne '' and $v =~ /^$zahl$/ ? sprintf($numform, $v) : $v).$sep;
			}
			else{ $l .= $v.$sep; }
		}
		$l =~ s/$sep$/$end/;
	}
	else
	{
		# do I want to care for undefs?
		# not here ... failure is not communicated from here, you shall handle bad columns externally
		$l = join($sep, @vals).$end;
	}
	return \$l;
}

sub title_line
{
	my $self = shift;
	my $ar = shift;

	my $end = $self->get_end();
	my $sep = $self->get_outsep();
	my $com = $self->get_comchar();
	my $q = $self->get_quote();
	my $l = $com.$q;
	#print STDERR "titles: @{$self->{titles}}\n";
	#print STDERR "titles for @{$ar}\n" if defined $ar;
	unless(defined $ar){ $l = $com.$q.join($q.$sep.$q, @{$self->{titles}}).$q.$end; }
	else
	{
		foreach my $k (@{$ar})
		{
			# should match for title containing $q
			my $t = $k > -1 ? $self->{titles}->[$k] : undef;
			$t = "" unless defined $t;
			$l .= $t.$q.$sep.$q;
		}
		$l =~ s/$q$//;
		$l =~ s/$sep$/$end/;
	}
	return \$l;
	
}

sub comment_line
{
	my $self = shift;
	my $line = ref $_[0] ? $_[0] : \$_[0];
	my $cline = $self->get_comchar().${$line}.$self->get_end();
	return \$cline;
}

sub chomp_line
{
	my $self = shift;
	my $string = ref $_[0] ? $_[0] : \$_[0];
	if(defined $string)
	{
		${$string} =~ s/$lend$//;
	}
}

sub make_naked
{
	my $self = shift;
	my $string = ref $_[0] ? $_[0] : \$_[0];
	if(defined $string)
	{
		${$string} =~ s/$lend$//;
		${$string} =~ s/^$self->{config}{comregex}//;
	}
}

# Not well supported, but possible: Text in between numeric data.
# To make it a bit safer, this filter will replace everything that would count as separator.
# It's only a bit safer... supsequent parsers are supposed to work in strict mode if we're in strict mode here.
sub filter_text
{
	my $self = shift;
	my $match;
	if($self->{config}{strict})
	{
		my $sep = $self->get_outsep();
		$match = qr/$sep/;
	}
	else
	{
		$match = qr/$trenner/;
	}
	for(@_){ s:$match:_:g; }
}

1;

__END__

=head1 NAME

Text::NumericData - parsing and writing of textual numeric data files

=head1 SYNOPSIS

	use Text::NumericData;
	my $c = new Text::NumericData;
	my $line = "6e-6 3.4e7 123 0\n";
	my $data = $c->line_data($line);

	$data->[3] *= $data->[0]*$data->[1];
	
	print $c->data_line($data);

=head1 TODO

Add description of fill behaviour. Change argument behaviour of line_data to accept the plain string in $_[0] (it's a reference anyway). Return value needs to stay reference for performance reasons (sadly, this indeed makes a difference). Make line_check also take straight string as argument.

=head1 DESCRIPTION

This module (class) contains the basic parsing structure for Text::NumericData. It is intended for use with numerical data sets in text files as commonly produced by data aquisition software - there often called "ASCII file". It's not about arbitary tabular data - the main intention are rows of numbers after some header that ideally contains information about what kind of data is in there. Simple text fields are supported, but beware of any separator-looking characters in there!
The provided function for checking if there is data or header relies on the first data item being a number.
Additionall, the following general header layout is assumed:

	#file title
	#comments
	#comments
	#...
	#row titles with proper separators with or without quotes

Comments are optional, only a single non-empty header line results in both file and row titles to be deduced from the very same line.

=head1 MEMBERS

Some members of the hash repesenting an Text::NumericData object:

=head2 Methods (Functions)

=over 4

=item * line_check($line[, $onlycheck]) -> 0 or 1

checks if $line appears to have some data (starts with a number followed by a separator or nothing) and scans for various stuff items as line ending, separator, file and data row titles... the scanning is disabled if $onlycheck is true; returns 1 if $line supposedly is containing data

=item * line_data($line) -> \@data

input: extract the @data of $line; the return value is undefined for empty lines

=item * data_line(\@data) -> \$line

output: have @data, produce $line

=item * comment_line($comment) -> \$line

output: have bare comment, produce full $line

=item * title_line(\@colnumbers) -> \$line

output: form a proper line with the titles matching the specified columns (starting at 0 - plain array index!) or a line for all columns if @colnumbers is unspecified 

=item * chomp_line($line)

Just what you would expect from a chomp()... making sure that really any kind of line ending (that matches the internal regex) is chopped off; modifies the input directly

=item * make_naked($line)

chomp + remove comment characters

=back

=head2 Data

=over 4

=item * title

file title

=item * comments

array ref of comment lines (w/o comment character(s) and line ending)

=item * titles

array ref of data row titles

=back

=head1 CONFIGURATION

You can provide a hash reference with configuration data to the constructor to tweak some aspects of the created object. They have (mostly) sensible defaults and/or are normally deduced from the input data (p.ex. line end, separator) if possible. 
You can always check the active configuration by looking at the $c->{config} hash reference.

The module takes deep copies of only the hash elements that correspond to internal parameters and does not modify the given hash in any way; so you can rest assured that handing in some program-specific config hash with lots of additional settings that you also want to work on does not pose a problem.

The different parameters fall roughly into two categories:

=head2 Parsing

These influence how the data is parsed. A considerable amount of work went into the regexes... to change them properly you better should know and understand the source code of this module.

=over 4

=item * numregex

the regular expression a number has to match (I really hope that the default is reasonable!)

=item * comregex

regex for beginning of comment line (additional to not starting with a number)

=item * strict [0/1]

just split at every separator occurence to get the data array (otherwise there is some more fuzzy logic with treating multiple separation characters as one separation)

=item * text [0/1]

allow text in data field in non-strict mode (no effect in strict mode)

=back

=head2 Output

=over 4

=item * separator

The separator to use for data fields/columns; when strict is set it is also used for the actual data parsing.
	
=item * lineend

line ending to use

=item * comchar

character(s) to put in front of comment lines

=item * numformat
	
listref with formats for numbers as sprintf format strings (p.ex. %02d), one list entry is for one data row

=back

=head1 SEE ALSO

For computations on multi-dimensional arrays in general, there is the mighty
Perl Data Language, L<PDL>.
For many day-to-day applications, the tools based on Text::NumericData are
quickly applied with shell one-liners. But if the time for number crunching
itself becomes important, or you need more complex operations, you can
easily create L<PDL> data structures from the parsed data arrays yourself.
Also, see L<PDL::IO::Misc> for direct handling of ASCII data with L<PDL>.

=head1 AUTHOR

Thomas Orgis <thomas@orgis.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004-2013, Thomas Orgis.

This module is free software; you
can redistribute it and/or modify it under the same terms
as Perl 5.10.0. For more details, see the full text of the
licenses in the directory LICENSES.

This program is distributed in the hope that it will be
useful, but without any warranty; without even the implied
warranty of merchantability or fitness for a particular purpose.

