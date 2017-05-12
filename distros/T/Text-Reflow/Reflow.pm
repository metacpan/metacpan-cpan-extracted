package Text::Reflow;

require 5.005_62;
use strict;
use warnings;
use integer;
use Carp;

require Exporter;
require DynaLoader;

our @ISA = qw(Exporter DynaLoader);

# Original script written by Michael Larsen, larsen@edu.upenn.math
# Modified by Martin Ward, martin@gkc.org.uk
# Copyright 1994 Michael Larsen and Martin Ward
# Email: martin@gkc.org.uk
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of either the Artistic License or
# the GNU General Public License as published by
# the Free Software Foundation; either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Text::Reflow ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.

our %EXPORT_TAGS = ( 'all' => [ qw(
	reflow_file
	reflow_string
	reflow_array
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

$Text::Reflow::VERSION = "1.17";

bootstrap Text::Reflow $Text::Reflow::VERSION;

# Preloaded methods go here.

# This is the perl version of the C function reflow_trial
# If the C XSUB doesn't work, comment out the line
# bootstrap Text::Reflow $VERSION;
# above, and take the _ from the front of this perl version:

sub _reflow_trial($$$$$$$$$$) {
  my ($optimum, $maximum, $wordcount,
      $penaltylimit, $semantic, $shortlast,
      $word_len, $space_len, $extra, $result) = @_;
  my ($lastbreak, @linkbreak);
  my ($j, $k, $interval, $penalty, @totalpenalty, $bestsofar);
  my (@best_linkbreak, $best_lastbreak, $opt);
  my @optimum	= unpack("N*", pack("H*", $optimum));
  my @word_len	= unpack("N*", pack("H*", $word_len));
  my @space_len	= unpack("N*", pack("H*", $space_len));
  my @extra	= unpack("N*", pack("H*", $extra));
  my $best = $penaltylimit * 21;
  foreach $opt (@optimum) {
    @linkbreak = ();
    for ($j = 0; $j < $wordcount; $j++) {  # Optimize preceding break
      $interval = 0;
      $totalpenalty[$j] = $penaltylimit * 2;
      for ($k = $j; $k >= 0; $k--) {
	$interval += $word_len[$k];
	last if (($k < $j) && (($interval > $opt + 10)
				|| ($interval >= $maximum)));
	$penalty = ($interval - $opt) * ($interval - $opt);
	$interval += $space_len[$k];
	$penalty += $totalpenalty[$k-1] if ($k > 0);
	$penalty -= ($extra[$j] * $semantic)/2;
	if ($penalty < $totalpenalty[$j]) {
	  $totalpenalty[$j] = $penalty;
	  $linkbreak[$j] = $k-1;
	}
      }
    }
    $interval = 0;
    $bestsofar = $penaltylimit * 20;
    $lastbreak = $wordcount-2;
    # Pick a break for the last line which gives
    # the least penalties for previous lines:
    for ($k = $wordcount-2; $k >= -1; $k--) {      # Break after k?
      $interval += $word_len[$k+1];
      last if (($interval > $opt + 10) || ($interval > $maximum));
      if ($interval > $opt) {  # Don't make last line too long
	$penalty = ($interval - $opt) * ($interval - $opt);
      } else {
	$penalty = 0;
      }
      $interval += $space_len[$k+1];
      $penalty += $totalpenalty[$k] if ($k >= 0);
      $penalty += $shortlast * $semantic if ($wordcount - $k - 1 <= 2);
      if ($penalty <= $bestsofar) {
	$bestsofar = $penalty;
	$lastbreak = $k;
      }
    }
    # Save these breaks if they are an improvement:
    if ($bestsofar < $best) {
      $best_lastbreak = $lastbreak;
      @best_linkbreak = @linkbreak;
      $best = $bestsofar;
    }
  } # Next $opt
  # Return the best breaks:
  $result = unpack("H*", pack("N*", ($best_lastbreak, @best_linkbreak)));
  return($result);
}


use vars qw(
$IO_Files      $lastbreak     $poetryindent  %abbrev	    @output
$connpenalty   $maximum	      $quote	     %connectives   @save_opts
$dependent     $namebreak     $semantic	     %keys	    @space_len
$frenchspacing $noreflow      $sentence	     @extra	    @tmp
$indent	       $oneparagraph  $shortlast     @from	    @to
$indent1       $optimum	      $skipindented  @linewords	    @word_len
$indent2       $penaltylimit  $skipto	     @linkbreak	    @words
$independent   $pin	      $wordcount     @optimum
);

# The following parameters can be twiddled to taste:

%keys = (optimum => '.*', maximum => '\d+',
	 indent => '.*', indent1 => '.*', indent2 => '.*',
	 quote => '.*',
	 skipto => '.*',  skipindented => '[012]', oneparagraph => '[yYnN]',
	 frenchspacing => '[yYnN]',
	 noreflow => '.*',
	 semantic => '\d+', namebreak => '\d+',
	 sentence => '\d+', independent => '\d+', dependent => '\d+',
	 shortlast => '\d+', connpenalty => '\d+',
	 poetryindent => '\d+');
	 

$optimum = [65];      # Best line length 65.  Also try [60..70]
$maximum = 75;	      # Maximum possible line length 80
$indent1 = "";	      # Indentation for first line
$indent2 = "";	      # Indentation for each line after the first
$quote = "";	      # Quote characters to remove from the front of each line
$skipto = "";	      # Pattern to skip to before starting to reflow
$skipindented = 2;    # Number of sequential indented lines required
		      # before the group of lines will be skipped
$noreflow = "";	      # A regexp to indicate lines which should not be reflowed
		      # eg table of contents: '\.\s*\.\s*\.\s*\.\s*\.'
$frenchspacing = "n"; # If "y" then don't put two spaces at end of sentence/clause
$oneparagraph = "n";  # If "Y" then put all the input into a single paragraph

$semantic = 30;	      # Extent to which semantic factors matter 20
$namebreak = 20;      # Penalty for splitting up name 10
$sentence = 20;       # Penalty for sentence widows and orphans 6
$independent = 10;    # Penalty for independent clause w's & o's
$dependent = 6;	      # Penalty for dependent clause w's & o's
$shortlast = 5;       # Penalty for a short last line (1 or 2 words) in a paragraph
$connpenalty = 1;     # Multiplier to avoid penalties at end of line
$poetryindent = 1;    # Treat $skipindented consecutive lines indented by
		      # at least this much

$penaltylimit = 0x2000000;
@save_opts = ();     # Saved original values of options

$pin = " " x $poetryindent;

# NB By default there must be two consecutive indented lines for it to count
# as poetry, so the program will not mistake a paragraph indentation
# for a line of poetry.


# Abbreviations from a half dozen novels,
# Titles and other abbreviations which should discourage
# a break have the value 1:

%abbrev = (
Jan => 1, Feb => 1, Mar => 1, Apr => 1, Jun => 1, Jul => 1,
Aug => 1, Sep => 1, Sept => 1, Oct => 1, Nov => 1, Dec => 1,
Pvt => 1, Cpl => 1, Sgt => 1, Ens => 1, Lieut => 1, Capt => 1, Cmdr => 1,
Maj => 1, Col => 1, Gen => 1, Adm => 1,
Dr => 1, Hon => 1, Mlle => 1, Mme => 1, Mr => 1, Mrs => 1, Miss => 1,
Prof => 1, Rev => 1,
Bart => 2, Esq => 2, etc => 2,
No => 1, St => 1,
Ave => 2, Rd => 2, Blvd => 2, Ct => 2, Cir => 2,
A => 1, B => 1, C => 1, D => 1, E => 1, F => 1, G => 1, H => 1,
I => 1, J => 1, K => 1, L => 1, M => 1, N => 1, O => 1, P => 1, Q => 1,
R => 1, S => 1, T => 1, U => 1, V => 1, W => 1, X => 1, Y => 1, Z => 1);

# The value is the rlative effort to avoid breaking
# a line after this connective

%connectives = (	# Extracted from /usr/dict/connectives
the => 4, he => 4,
of => 2, and => 2, to => 2, a => 2,
in => 2, that => 2, is => 1, was => 1,
for => 2, with => 2, as => 2, his => 1,
on => 1, be => 1, at => 1, by => 2,
had => 1, not => 1, are => 1, but => 2, from => 1,
or => 2, have => 1, an => 2, which => 2,
one => 1, were => 1, her => 1, all => 1, their => 1,
when => 2, who => 2, will => 1, more => 1, no => 1,
if => 2, out => 1, so => 2, what => 2, its => 1,
about => 1, into => 1, than => 1,
only => 1, other => 1, new => 1, some => 1,
these => 2, two => 1, may => 1,
do => 1, first => 1, any => 1, my => 1, now => 1,
such => 1, like => 2, our => 1, over => 1,
even => 1, most => 1, after => 1, also => 2,
many => 1, before => 1, through => 1, where => 2, your => 1,
well => 1, down => 1, should => 1, because => 2,
each => 1, just => 1, those => 2, how => 2, too => 1,
good => 1, very => 2, here => 1, between => 1, both => 1,
under => 1, never => 1, same => 1, another => 1,
while => 2, last => 1, might => 1, great => 1,
since => 2, against => 1, right => 1, three => 2, next => 2);


sub reflow_file($$@) {
  my ($from, $to, @opts) = @_;
  local $IO_Files = 1;		# We are reading/writing files
  $from = \*STDIN if ($from eq "");
  $to = \*STDOUT if ($to eq "");
  my $from_a_handle = (ref($from)
		       ? (ref($from) eq 'GLOB'
			 || UNIVERSAL::isa($from, 'GLOB')
			 || UNIVERSAL::isa($from, 'IO::Handle'))
		       : (ref(\$from) eq 'GLOB'));
  my $to_a_handle =   (ref($to)
		       ? (ref($to) eq 'GLOB'
			  || UNIVERSAL::isa($to, 'GLOB')
			  || UNIVERSAL::isa($to, 'IO::Handle'))
		       : (ref(\$to) eq 'GLOB'));
  my $closefrom = 0;
  my $closeto = 0;
  local(*FROM, *TO);

  if ($from_a_handle) {
    {
      no warnings;
      *FROM = *$from{FILEHANDLE};
    }
  } else {
    $from = "./$from" if $from =~ /^\s/s;
    open(FROM, "< $from\0") or croak "Cannot read `$from': $!";
    binmode FROM or die "($!,$^E)";
    $closefrom = 1;
  }

  if ($to_a_handle) {
    {
      no warnings;
      *TO = *$to{FILEHANDLE};
    }
  } else {
    $to = "./$to" if $to =~ /^\s/s;
    open(TO,"> $to\0") or croak "Cannot write to `$to': $!";
    binmode TO or die "($!,$^E)";
    $closeto = 1;
  }

  process_opts(@opts);
  reflow();
  restore_opts();

  close(TO) || croak("Cannot close `$to': $!") if ($closeto);
  close(FROM) || croak("Cannot close `$from': $!") if ($closefrom);
}


sub reflow_string($@) {
  my ($input, @opts) = @_;
  local $IO_Files = 0;		# We are reading/writing arrays
  # Create the array from the string, keep trailing empty lines.
  # We split on newlines and then restore them, being careful
  # not to add an extra newline at the end:
  local @from = split(/\n/, $input, -1);
  pop(@from) if @from && ($from[$#from] eq "");
  @from = map { "$_\n" } @from;
  local @to = ();
  process_opts(@opts);
  reflow();
  restore_opts();
  return(join("", @to));
}


sub reflow_array($@) {
  my ($input, @opts) = @_;
  local $IO_Files = 0;		# We are reading/writing arrays
  local @from = @$input;
  local @to = ();
  process_opts(@opts);
  reflow();
  restore_opts();
  return(\@to);
}



# Process the keyword options, set module global variables as required,
# save the old values on the @save_opts stack:

sub process_opts(@) {
  my @opts = @_;
  my ($key, $value);
  no strict 'refs';
  # Fix an externally-set $optimum value:
  $optimum = [$optimum] if ($optimum =~ /^\d+$/);
  while (@opts) {
    $key = shift(@opts);
    croak "No value for option key `$key'" unless (@opts);
    $value = shift(@opts);
    croak "`$key' is not a valid option" unless ($keys{$key});
    croak "`$value' is not a suitable value for `$key'"
      unless ($value =~ /^$keys{$key}$/);
    # keyword "indent" is short for setting both indent1 and indent2:
    if ($key eq "indent") {
      $key = "indent1";
      unshift(@opts, "indent2", $value);
    } elsif ($key eq "optimum") {
      if ($value =~ /^\d+$/) {
	$value = [$value];
      } elsif (ref($value) ne 'ARRAY') {
	croak "`$value' is not a suitable value for `$key'";
      }
    }
    # Save old value. Save a copy of the array if the value is a reference:
    if (ref(${$key}) eq "ARRAY") {
      push(@save_opts, $key, [@${$key}]);
    } else {
      push(@save_opts, $key, ${$key});
    }
    ${$key} = $value;
  }
  # Adjust $optimum and $maximum by $indent2 length:
  if ($indent2 ne "") {
    push(@save_opts, "optimum", $optimum, "maximum", $maximum);
    $maximum -= length($indent2);
    $optimum = [map { $_ - length($indent2) } @$optimum];
  }
}


sub restore_opts() {
  my ($key, $value);
  no strict 'refs';
  while (@save_opts) {
    $value = pop(@save_opts);
    $key = pop(@save_opts);
    ${$key} = $value;
  }
}


sub get_line() {
  my $line;
  if ($IO_Files) {
    $line = <FROM>;
  } else {
    $line = shift(@from);
  }
  return($line) unless defined($line);
  $line =~ tr/\015\032//d;
  $line =~ s/^$quote//;
  # Check for eg $quote = "> " and $line = ">":
  my $quote_ns = $quote;
  if ($quote_ns =~ s/\s+$//) {
    $line = "" if ($line =~ /^$quote_ns$/);
  }
  return($line);
}


# Trim EOL spaces and print the lines:
sub print_lines(@) {
  my @lines = @_;
  map { s/[ \t]+\n/\n/gs } @lines;
  if ($IO_Files) {
    print TO @lines;
  } else {
    push(@to, @lines)
  }
}


sub reflow() {
  my ($line, $last);
  if ($skipto ne "") {
    while (defined($line = get_line())) {
      print_lines($line);
      last if ($line =~ /^$skipto/);
    }
    croak "Skipto pattern `$skipto' not found!" unless (defined($line));
  }

  if ($oneparagraph =~ /[Yy]/) {
    # put all the lines into one paragraph
    while (defined($line = get_line())) {
      process($line);
    }

  } elsif ($skipindented < 2) {
    while (defined($line = get_line())) {
      if (($skipindented && ($line =~ /^($pin|\t).*\S/))
	   || (($noreflow ne "") && ($line =~ /$noreflow/))) {
	# current line is indented, or a paragraph break:
	reflow_para();
	print_lines($indent1 . $line);
      } else {
	# Add line to current paragraph in @words:
	process($line);
      }
    }

  } else {

    while (defined($line = get_line())) {
      if (($noreflow ne "") && ($line =~ /$noreflow/)) {
	# current line is a paragraph break:
	reflow_para();
	print_lines($indent1 . $line);
        next;
      } elsif ($line =~ /^($pin|\t).*\S/) {
	# current line may be poetry, check next line:
	$last = $line;
	$line = get_line();
	if (!defined($line)) {
	  process($last);
	  last;
	}
	if ($line =~ /^($pin|\t).*\S/) {
	  # found some poetry, skip indented lines until end of input
	  # or a non-indented line found:
	  reflow_para();
	  print_lines($indent1 . $last);
	  print_lines($indent1 . $line);
	  while (defined($line = get_line())) {
	    last unless (($line =~ /^($pin|\t).*\S/)
			  || ($noreflow ne "" && $line =~ /$noreflow/));
	    print_lines($indent1 . $line);
	  }
	  last unless (defined($line)); # poetry at end of document
	  # $line is a non-poetic line
	} else {
	  # $last had a poetry indent, but current line doesn't.
	  # Process last line:
	  process($last);
	}
      } # end of first poetry test
      # current line is non-poetic, so process it:
      process($line);
    }
  }
  # reflow any remaining @words:
  reflow_para();
}


# Process a non-poetry line by pushing the words onto @words
# If the line is blank, then reflow the paragraph of @words:

sub process($) {
  my ($line) = @_;
  # current line is non-poetry
  # remove spaces around dashes:
  $line =~ s/([^-])[ \t]*--[ \t]*([^-])/$1--$2/g;
  # protect ". . ." ellipses:
  $line =~ s/ \. \. \./\x9F\.\x9F\.\x9F\./g;
  $line =~ s/\. \. \./\.\x9F\.\x9F\./g;
  @linewords = split(/\s+/, $line);
  shift(@linewords) if (@linewords && ($linewords[0] eq ""));
  # If last word of previous line ends in a single hyphen,
  # then append first word of this line:
  if (@linewords && @words && ($words[$#words] =~ /[a-zA-Z0-9]-$/)) {
    $words[$#words] .= shift(@linewords);
  }
  if ($#linewords == -1) {
    # No words on this line
    if ($oneparagraph !~ /[Yy]/) {
      # end of paragraph
      reflow_para();
      print_lines("$indent1\n");
    }
  } else {
    # add @linewords to @words,
    # split on em dashes, ie word--word
    # Move "--" from beginning of current word to end of last word:
    if (($#words >= 0) && ($linewords[0] =~ s/^--[^a-zA-Z0-9]*//)) {
      $words[$#words] .= $&;
      shift(@linewords) if ($linewords[0] eq "");
    }
    my $word;
    foreach $word (@linewords) {
      if ($word =~ /[^-]--[a-zA-Z0-9]/) {
	@tmp = split(/--/, $word);
	# restore the hyphens:
	grep(s/$/--/, @tmp);
	# remove an extra one at the end:
	$tmp[$#tmp] =~ s/--$//;
	# append @tmp to @words:
	push (@words, @tmp);
      } else {
	# append $word to @words:
	push (@words, $word);
      }
    }
  }
}


sub reflow_para {
  return() unless (@words);
  reflow_penalties();
  $lastbreak = 0;
  $linkbreak[$wordcount] = 0;
  # Create space for the result:
  my $result = " " x (($wordcount + 2) * 8);
  $result = reflow_trial(unpack("H*", pack("N*", @$optimum)),
			 $maximum, $wordcount,
			 $penaltylimit, $semantic, $shortlast,
			 unpack("H*", pack("N*", @word_len)),
			 unpack("H*", pack("N*", @space_len)),
			 unpack("H*", pack("N*", @extra)),
			 $result);
  @linkbreak = unpack("N*", pack("H*", $result));
  # Convert @linkbreak from unsigned to signed:
  @linkbreak = map { $_ > 0xF0000000 ? -((0xFFFFFFFF - $_) + 1) : $_ + 0 } @linkbreak;
  $lastbreak = shift(@linkbreak);
  compute_output();
  grep (s/\x9F/ /g, @output);
  print_lines(@output);
  @words = ();
}


# Add spaces to ends of sentences and calculate @extra array of penalties
sub reflow_penalties {
  my $j;
  $wordcount = $#words + 1;
  # Add paragraph indentation to first word:
  $words[0] = $indent1 . $words[0] if ($wordcount);
  for ($j = 0; $j < $wordcount+1; $j++) {
    $extra[$j] = 0;
  }
  for ($j = 0; $j < $wordcount; $j++) {
    if ($words[$j] =~ /^([A-Za-z0-9-]+)["')]*([\.\:])["')]*$/) {	# Period or colon
      if (!defined($abbrev{$1}) || ($2 eq ":")) {	# End of sentence
	$extra[$j] += $sentence / 2;
	$extra[$j-1] -= $sentence if ($j > 0);
	$extra[$j+1] -= $sentence;
	$words[$j] = $words[$j] . " " unless ($frenchspacing =~ /[Yy]/);
      } else{
	# Don't break "Mr. X"
	$extra[$j] -= $namebreak if ($abbrev{$1} == 1);
      }
    }
    if (($words[$j] =~ /[\?\!]["')]*$/) # !? after word
	  && (($j >= $#words) || ($words[$j+1] =~ /^[^a-zA-Z]*[A-Z]/))) {
      $extra[$j] += $sentence / 2;
      $extra[$j-1] -= $sentence if ($j > 0);
      $extra[$j+1] -= $sentence;
      $words[$j] = $words[$j] . " " unless ($frenchspacing =~ /[Yy]/);
    }
    if ($words[$j] =~ /\,$/) {	# Comma after word
      $extra[$j] += $dependent / 2;
      $extra[$j-1] -= $dependent if ($j > 0);
      $extra[$j+1] -= $dependent;
    }
    if ($words[$j] =~ /[\;\"\'\)]$|--$/) { # Punctuation after word
      $extra[$j] += $independent / 2;
      $extra[$j-1] -= $independent if ($j > 0);
      $extra[$j+1] -= $independent;
    }
    if (($j < $#words) 
	 && ($words[$j+1] =~ /^\(/)) { 	# Next word has opening parenthesis
      $extra[$j] += $independent / 2;
      $extra[$j-1] -= $independent if ($j > 0);
      $extra[$j+1] -= $independent;
    }
    if (($j < $#words)
	 && ($words[$j] =~ /[A-Z]/ && $words[$j] !~ /\./
	      && $words[$j+1] =~ /[A-Z]/)) {
      $extra[$j] -= $namebreak;		# Don't break "United States"
    }
    $extra[$j] -= $connectives{$words[$j]} * $connpenalty
      if (defined($connectives{$words[$j]}));
  }

  @word_len = ();  # Length of each word (excluding spaces)
  @space_len = (); # Length the space after this word
  for ($j = 0; $j < $wordcount; $j++) {
    if ($words[$j] =~ /--$/) {
      $word_len[$j] = length($words[$j]);
      $space_len[$j] = 0;
    } elsif ($words[$j] =~ / $/) {
      $word_len[$j] = length($words[$j]) - 1;
      $space_len[$j] = 2;
    } else {
      $word_len[$j] = length($words[$j]);
      $space_len[$j] = 1;
    }
  }
  # First word already has $indent1 added and will not be indented further:
  $word_len[0] -= length($indent2) if ($wordcount);
}


# compute @output from $wordcount, @words, $lastbreak and @linkbreak

sub compute_output {
  my ($j, $terminus);
  @output = ();
  $terminus = $wordcount-1;
  for ($j = 0; $terminus >= 0; $j++) {
    $output[$j] = join(' ', @words[$lastbreak+1..$terminus])."\n";
    #print "j = $j, lastbreak = $lastbreak:\noutput = $output[$j]\n";
    $terminus = $lastbreak;
    $lastbreak = $linkbreak[$lastbreak];
  }
  @output = reverse(@output);
  # trim spaces after hyphens:
  map { s/([^-])[ \t]*--[ \t*]([^-])/$1--$2/g } @output;
  # Add the indent to all but the first line:
  map { $_ = $indent2 . $_ } @output[1..$#output];
}





1;
__END__

=head1 NAME

Text::Reflow - Perl module for reflowing text files using Knuth's paragraphing algorithm.

=head1 SYNOPSIS

	use Text::Reflow qw(reflow_file reflow_string reflow_array);

	reflow_file($infile, $outfile, key => value, ...);

	$output = reflow_string($input, key => value, ...);

	$output = reflow_array(\@input, key => value, ...);

=head1 DESCRIPTION

These routines will reflow the paragraphs in the given file,
filehandle, string or array using Knuth's paragraphing algorithm
(as used in TeX) to pick "good" places to break the lines.

Each routine takes ascii text data with paragraphs separated
by blank lines and reflows the paragraphs.  If two or more lines
in a row are "indented" then they are assumed to be a quoted poem
and are passed through unchanged (but see below)

The reflow algorithm tries to keep the lines the same length
but also tries to break at punctuation, and avoid breaking within
a proper name or after certain I<connectives> ("a", "the", etc.). The
result is a file with a more "ragged" right margin than is produced
by C<fmt> or C<Text::Wrap> but it is easier to read since fewer
phrases are broken across line breaks.

For C<reflow_file>, if $infile is the empty string, then the input
is taken from STDIN and if $outfile is the empty string, the output
is written to STDOUT.  Otherwise, $infile and $outfile may be a string,
a FileHandle reference or a FileHandle glob.

A typical invocation is:

	reflow_file("myfile", "");

which reflows the whole of F<myfile> and prints the result to STDOUT.


=head2 KEYWORD OPTIONS

The behaviour of Reflow can be adjusted by setting various keyword options.
These can be set globally by referencing the appropriate
variable in the Text::Reflow package, for example:

	$Text::Reflow::maximum = 80;
	$Text::Reflow::optimum = 75;

will set the maximum line length to 80 characters and the optimum
line length to 75 characters for all subsequent reflow operations.
Or they can be passed to a reflow_ function as a keyword parameter,
for example:

	$out = reflow_string($in, maximum => 80, optimum => 75);

in which case the new options only apply to this call.

The following options are currently implemented, with their default values:

=over 4

=item optimum => [65]

The optimum line length in characters.  This can be either a number
or a reference to an array of numbers:  in the latter case,
each optimal line length is tried in turn for each paragraph,
and the one which leads to the best overall paragraph is chosen.
This results in less ragged paragraphs, but some paragraphs will
be wider or narrower overall than others.

=item maximum => 75

The maximum allowed line length.

=item indent => ""

Each line of output has this string prepended. C<indent =E<gt> string>
is equivalent to C<indent1 =E<gt> string, indent2 =E<gt> string>.

=item indent1 => ""

A string which is used to indent the first line in any paragraph.

=item indent2 => ""

A string which is used to indent the second and subsequent line in any paragraph.

=item quote => ""

Characters to strip from the beginning of a line before processing.
To reflow a quoted email message and then restore the quotes you
might want to use

	quote => "> ", indent => "> "

=item skipto => ""

Skip to the first line starting with the given pattern before starting
to reflow. This is useful for skipping Project Gutenberg headers
or contents tables.

=item skipindented => 2

If C<skipindented> = 0 then all indented lines are flowed
in with the surrounding paragraph.  If C<skipindented> = 1 then
any indented line will not be reflowed.  If C<skipindented> = 2
then any two or more adjacent indented lines will not be reflowed.
The purpose of the default value is to allow poetry to pass
through unchanged, but not to allow a paragraph indentation
from preventing the first line of the paragraph from being reflowed.

=item noreflow => ""

A pattern to indicate that certain lines should not be reflowed.
For example, a table of contents might have a line of dots.
The option:

	noreflow => '(\.\s*){4}\.'

will not reflow any lines containing five or more consecutive dots.

=item frenchspacing => 'n'

Normally two spaces are put at the end of a sentence or a clause.
The C<frenchspacing> option (taken from the TeX macro of the same name)
disables this feature.

=item oneparagraph => 'n'

Set this to 'y' if you want the whole input to be flowed into a single
paragraph, ignoring blank lines in the input.

=item semantic => 30

This parameter indicates the extent to which semantic factors matter
(breaking on punctuation, avoiding a break within a clause etc.).
Set this to zero to minimise the raggedness of the right margin,
at the expense of readability.

=item namebreak => 10

Penalty for splitting up a name

=item sentence => 20

Penalty for sentence widows and orphans (ie splitting a line
immediately after the first word in a sentence, or before
the last word in a sentence)

=item independent => 10

Penalty for independent clause widows and orphans.

=item dependent => 6

Penalty for dependent clause widows and orphans.

=item shortlast => 5

Penalty for a short last line in a paragraph (one or two words).

=item connpenalty => 1

Multiplier for the "negative penalty" for breaking at a connective.
In other words, increasing this value makes connectives an even
more attractive place to break a line.

=back


=head2 EXPORT

None by default.


=head1 AUTHOR

Original C<reflow> perl script written by Michael Larsen, larsen@edu.upenn.math.

Modified, enhanced and converted to a perl module with XSUB
by Martin Ward, martin@gkc.org.uk

=head1 SEE ALSO

perl(1).

See "TeX the Program" by Donald Knuth for a description of the algorithm used.

=cut
