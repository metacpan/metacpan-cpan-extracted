package Text::ANSI::Fold;

use v5.14;
use warnings;
use utf8;

our $VERSION = "2.06";

use Data::Dumper;
use Carp;
use Text::VisualWidth::PP 'vwidth';

######################################################################
use Exporter 'import';
our %EXPORT_TAGS = (
    constants => [ qw(
		   &LINEBREAK_NONE
		   &LINEBREAK_ALL
		   &LINEBREAK_RUNIN
		   &LINEBREAK_RUNOUT
		   ) ] );
our @EXPORT_OK = ( qw(&ansi_fold),
		   @{$EXPORT_TAGS{constants}} );

sub ansi_fold {
    my($text, $width, @option) = @_;
    __PACKAGE__->fold($text, width => $width, @option);
}
######################################################################

my $alphanum_re = qr{ [_\d\p{Latin}] }x;
my $reset_re    = qr{ \e \[ [0;]* m }x;
my $color_re    = qr{ \e \[ [\d;]* m }x;
my $erase_re    = qr{ \e \[ [\d;]* K }x;
my $csi_re      = qr{
    # see ECMA-48 5.4 Control sequences
    \e \[		# csi
    [\x30-\x3f]*	# parameter bytes
    [\x20-\x2f]*	# intermediate bytes
    [\x40-\x7e]		# final byte
}x;
my $osc_re      = qr{
    # see ECMA-48 8.3.89 OSC - OPERATING SYSTEM COMMAND
    \e \]			# osc
    [\x08-\x13\x20-\x7d]*+	# command
    (?: \e\\ | \x9c | \a )	# st: string terminator
}x;

use constant SGR_RESET => "\e[m";

sub IsWideSpacing {
    return <<"END";
+utf8::East_Asian_Width=Wide
+utf8::East_Asian_Width=FullWidth
-utf8::Nonspacing_Mark
END
}

sub IsWideAmbiguousSpacing {
    return <<"END";
+utf8::East_Asian_Width=Wide
+utf8::East_Asian_Width=FullWidth
+utf8::East_Asian_Width=Ambiguous
-utf8::Nonspacing_Mark
END
}

sub _startWideSpacing {
    # look at $_
    if ($Text::VisualWidth::PP::EastAsian) {
	/^\p{IsWideAmbiguousSpacing}/;
    } else {
	/^\p{IsWideSpacing}/;
    }
}

use constant {
    LINEBREAK_NONE   => 0,
    LINEBREAK_RUNIN  => 1,
    LINEBREAK_RUNOUT => 2,
    LINEBREAK_ALL    => 3,
};

our $DEFAULT_LINEBREAK = LINEBREAK_NONE;
our $DEFAULT_RUNIN_WIDTH  = 2;
our $DEFAULT_RUNOUT_WIDTH = 2;

sub new {
    my $class = shift;
    my $obj = bless {
	text      => '',
	width     => undef,
	padding   => 0,
	boundary  => '',
	padchar   => ' ',
	ambiguous => 'narrow',
	margin    => 0,
	linebreak => $DEFAULT_LINEBREAK,
	runin     => $DEFAULT_RUNIN_WIDTH,
	runout    => $DEFAULT_RUNOUT_WIDTH,
	expand    => 0,
	tabstop   => 8,
	discard   => {},
    }, $class;

    $obj->configure(@_) if @_;

    $obj;
}

use Text::ANSI::Fold::Japanese::W3C qw(%prohibition);

sub chars_to_regex {
    my $chars = join '', @_;
    my($c, @s);
    for ($chars =~ /\X/g) {
	if (length == 1) {
	    $c .= $_;
	} else {
	    push @s, $_;
	}
    }
    if (@s) {
	local $" = '|';
	qr/(?:[\Q$c\E]|@s)/;
    } else {
	qr/[\Q$c\E]/;
    }
}

my %prohibition_re = do {
    head => do {
	my $re = chars_to_regex @prohibition{qw(head postfix)};
	qr/(?: $re | \p{Space_Separator} )/x;
    },
    end  => chars_to_regex @prohibition{qw(end prefix)},
};

sub configure {
    my $obj = ref $_[0] ? $_[0] : do {
	state $private = __PACKAGE__->new;
    };
    shift;
    croak "invalid parameter" if @_ % 2;
    while (@_ >= 2) {
	my($a, $b) = splice @_, 0, 2;
	croak "$a: invalid parameter\n" if not exists $obj->{$a};
	$obj->{$a} = $b;
    }
    if (ref $obj->{discard} eq 'ARRAY') {
	$obj->{discard} = { map { uc $_ => 1 } @{$obj->{discard}} };
    }
    $obj;
}

my @color_stack;
my @bg_stack;
my @reset;
sub put_reset { @reset = shift };
sub pop_reset {
    @reset ? do { @color_stack = (); pop @reset } : '';
}

use List::Util qw(pairgrep);

sub fold {
    my $obj = ref $_[0] ? $_[0] : do {
	state $private = configure();
    };
    shift;

    local $_ = shift // '';
    my %opt = ( %$obj, pairgrep { defined $b } @_ );

    my $width = $opt{width} // die;
    if ($width < 0) {
	$width = ~0 >> 1; # INT_MAX
    }

    if (not defined $width or $width < 1) {
	croak "invalid width";
    }

    if ($width <= $opt{margin}) {
	croak "invalid margin";
    }
    $width -= $opt{margin};

    $Text::VisualWidth::PP::EastAsian = $opt{ambiguous} eq 'wide';

    my $folded = '';
    my $eol = '';
    my $room = $width;
    @bg_stack = @color_stack = @reset = ();
    my $yield_re = $opt{expand} ? qr/[^\e\n\f\r\t]/ : qr/[^\e\n\f\r]/;

  FOLD:
    while (length) {

	# newline
	if (s/\A(\r*\n)//) {
	    $eol = $1;
	    last;
	}
	# formfeed / carriage return
	if (s/\A([\f\r]+)//) {
	    last if length == 0;
	    $folded .= $1;
	    $room = $width;
	    next;
	}
	# ECMA-48 OPERATING SYSTEM COMMAND
	if (s/\A($osc_re)//) {
	    $folded .= $1 unless $obj->{discard}->{OSC};
	    next;
	}
	# erase line (assume 0)
	if (s/\A($erase_re)//) {
	    $folded .= $1 unless $obj->{discard}->{EL};
	    @bg_stack = @color_stack;
	    next;
	}
	# reset
	if (s/\A($reset_re+($erase_re*))//) {
	    put_reset($1);
	    @bg_stack = () if $2;
	    next;
	}

	last if $room < 1;
	last if $room != $width and &_startWideSpacing and $room < 2;

	if (@reset) {
	    $folded .= pop_reset();
	}

	# ANSI color sequence
	if (s/\A($color_re)//) {
	    $folded .= $1;
	    push @color_stack, $1;
	    next;
	}

	# tab
	if ($opt{expand} and s/\A(\t+)//) {
	    my $space =
		$opt{tabstop} * length($1) - ($width - $room) % $opt{tabstop};
	    $_ = ' ' x $space . $_;
	    next;
	}

	# backspace
	my $bs = 0;
	while (s/\A(?:\X\cH+)++(?<c>\X|\z)//p) {
	    my $w = vwidth($+{c});
	    if ($w > $room) {
		if ($folded eq '') {
		    $folded .= ${^MATCH};
		    $room -= $w;
		} else {
		    $_ = ${^MATCH} . $_;
		}
		last FOLD;
	    }
	    $folded .= ${^MATCH};
	    $room -= $w;
	    $bs++;
	    last if $room < 1;
	}
	next if $bs;

	if (s/\A(\e*(?:${yield_re}(?!\cH))+)//) {
	    my $s = $1;
	    if ((my $w = vwidth($s)) <= $room) {
		$folded .= $s;
		$room -= $w;
		next;
	    }
	    my($a, $b, $w) = simple_fold($s, $room);
	    if ($w > $room and $room < $width) {
		$_ = $s . $_;
		last;
	    }
	    ($folded, $_) = ($folded . $a, $b . $_);
	    $room -= $w;
	} else {
	    die "panic ($_)";
	}
    }

    if ($opt{boundary} eq 'word'
	and my($tail) = /^(${alphanum_re}+)/o
	and $folded =~ m{
		^
		( (?: [^\e]* ${csi_re}++ ) *+ )
		( .*? )
		( ${alphanum_re}+ )
		\z
	}xo
	) {
	## Break line before word only when enough space will be
	## provided for the word in the next turn.
	my($s, $e) = ($-[3], $+[3]);
	my $l = $e - $s;
	if ($room + $l < $width and $l + length($tail) <= $width) {
	    $_ = substr($folded, $s, $l, '') . pop_reset() . $_;
	    $room += $l;
	}
    }

    ##
    ## RUN-OUT
    ##
    if ($_ ne ''
	and $opt{linebreak} & LINEBREAK_RUNOUT and $opt{runout} > 0
	and $folded =~ m{ (?<color>  (?! ${reset_re}) ${color_re}*+ )
			  (?<runout> $prohibition_re{end}+ ) \z }xp
	and ${^PREMATCH} ne ''
	and (my $w = vwidth $+{runout}) <= $opt{runout}) {
	$folded = ${^PREMATCH};
	$_ = join '', ${^MATCH}, @reset, $_;
	pop_reset() if $+{color};
	$room += $w;
    }

    $folded .= pop_reset() if @reset;

    $room += $opt{margin};

    ##
    ## RUN-IN
    ##
    if ($opt{linebreak} & LINEBREAK_RUNIN and $opt{runin} > 0) {
	my @runin;
	my $m = $opt{runin};
	while ($m > 0 and
	       m{\A (?<color> ${color_re}*+)
	            (?<runin> $prohibition_re{head})
	            (?<reset> ${reset_re}*)
	       }xp) {
	    my $w = vwidth $+{runin};
	    last if ($m -= $w) < 0;
	    $+{color} and do { push @color_stack, $+{color} };
	    $+{reset} and do { @color_stack = () };
	    $room -= $w;
	    push @runin, ${^MATCH};
	    $_ = ${^POSTMATCH};
	}
	$folded .= join '', @runin if @runin;
    }

    if (@color_stack) {
	$folded .= SGR_RESET;
	$_ = join '', @color_stack, $_ if $_ ne '';
    }

    if ($opt{padding} and $room > 0) {
	my $padding = $opt{padchar} x $room;
	if (@bg_stack) {
	    $padding = join '', @bg_stack, $padding, SGR_RESET;
	}
	$folded .= $padding;
    }

    ($folded . $eol, $_, $width - $room);
}

##
## Trim off one or more *logical* characters from the top.
##
sub simple_fold {
    my $orig = shift;
    my $width = shift;
    $width <= 0 and croak "parameter error";

    my($left, $right) = $orig =~ m/^(\X{0,$width}+)(.*)/ or die;

    my $w = vwidth($left);
    while ($w > $width) {
	my $trim = do {
	    # use POSIX qw(ceil);
	    # ceil(($w - $width) / 2) || 1;
	    int(($w - $width) / 2 + 0.5) || 1;
	};
	$left =~ s/\X \K ( \X{$trim} ) \z//x or last;
	$right = $1 . $right;
	$w -= vwidth($1);
    }

    ($left, $right, $w);
}

######################################################################

sub text {
    my $obj = shift;
    croak "Invalid argument." unless @_;
    $obj->{text} = shift;
    $obj;
}

sub retrieve {
    my $obj = shift;
    local *_ = \$obj->{text};
    return '' if not defined $_;
    (my $folded, $_) = $obj->fold($_, @_);
    $_ = undef if length == 0;
    $folded;
}

sub chops {
    my $obj = shift;
    my %opt = @_;
    my $width = $opt{width} // $obj->{width};

    my @chops;

    if (ref $width eq 'ARRAY') {
	for my $w (@{$width}) {
	    if ($w == 0) {
		push @chops, '';
	    }
	    elsif ((my $chop = $obj->retrieve(width => $w)) ne '') {
		push @chops, $chop;
	    }
	    else {
		last;
	    }
	}
    }
    else {
	while ((my $chop = $obj->retrieve(width => $width)) ne '') {
	    push @chops, $chop;
	}
    }

    @chops;
}

1;

__END__

=encoding utf-8

=head1 NAME

Text::ANSI::Fold - Text folding library supporting ANSI terminal sequence and Asian wide characters with prohibition character handling.

=head1 VERSION

Version 2.06

=head1 SYNOPSIS

    use Text::ANSI::Fold qw(ansi_fold);
    ($folded, $remain) = ansi_fold($text, $width, [ option ]);

    use Text::ANSI::Fold;
    my $f = Text::ANSI::Fold->new(width => 80, boundary => 'word');
    $f->configure(ambiguous => 'wide');
    ($folded, $remain) = $f->fold($text);

    use Text::ANSI::Fold;
    while (<>) {
        print join "\n",
            Text::ANSI::Fold->new(width => 40, text => $_)->chops;
    }

    use Text::ANSI::Fold qw(:constants);
    my $fold = Text::ANSI::Fold->new(
        width     => 70,
        boundary  => 'word',
        linebreak => LINEBREAK_ALL,
        runin     => 4,
        runout    => 4,
        );

=head1 DESCRIPTION

Text::ANSI::Fold provides capability to fold a text into two strings
by given width.  Text can include ANSI terminal sequences.  If the
text is divided in the middle of ANSI-effect region, reset sequence is
appended to folded text, and recover sequence is prepended to trimmed
string.

This module also support Unicode Asian full-width and non-spacing
combining characters properly.  Japanese text formatting with
head-or-end of line prohibition character is also supported.  Set
the linebreak mode to enable it.

Use exported B<ansi_fold> function to fold original text, with number
of visual columns you want to cut off the text.

    ($folded, $remain, $w) = ansi_fold($text, $width);

It returns a pair of strings; first one is folded text, and second is
the rest.

Additional third result is the visual width of folded text.  You may
want to know how many columns returned string takes for further
processing.  If the width parameter is negative, it returns string
untouched and the visual width of it.

This function returns at least one character in any situation.  If you
provide Asian wide string and just one column as width, it trims off
the first wide character even if it does not fit to given width.

Default parameter can be set by B<configure> class method:

    Text::ANSI::Fold->configure(width => 80, padding => 1);

Then you don't have to pass second argument.

    ($folded, $remain) = ansi_fold($text);

Because second argument is always taken as width, use I<undef> when
using default width with additional parameter:

    ($folded, $remain) = ansi_fold($text, undef, padding => 1);

=head1 OBJECT INTERFACE

You can create an object to hold parameters, which is effective during
object life time.  For example, 

    my $f = Text::ANSI::Fold->new(
        width => 80,
        boundary => 'word',
        );

makes an object folding on word boundaries with 80 columns width.
Then you can use this without parameters.

    $f->fold($text);

Use B<configure> method to update parameters:

    $f->configure(padding => 1);

Additional parameter can be specified on each call, and they precede
saved value.

    $f->fold($text, width => 40);

=head1 STRING OBJECT INTERFACE

Fold object can hold string inside by B<text> method.

    $f->text("text");

And folded string can be taken by B<retrieve> method.  It returns
empty string if nothing remained.

    while ((my $folded = $f->retrieve) ne '') {
        print $folded;
        print "\n" if $folded !~ /\n\z/;
    }

Method B<chops> returns chopped string list.  Because B<text> method
returns the object itself, you can use B<text> and B<chops> like this:

    print join "\n", $f->text($text)->chops;

Actually, text can be set by B<new> or B<configure> method through
B<text> option.  Next program just works.

    use Text::ANSI::Fold;
    while (<>) {
        print join "\n",
            Text::ANSI::Fold->new(width => 40, text => $_)->chops;
    }

When using B<chops> method, B<width> parameter can take array
reference, and chops text into given width list.

    my $fold = Text::ANSI::Fold->new;
    my @list = $fold->text("1223334444")->chops(width => [ 1, 2, 3 ]);
    # return ("1", "22", "333") and keep "4444"

If the width value is 0, it returns empty string.

Negative width value takes all the rest of holded string in
B<retrieve> and B<chops> method.

=head1 OPTIONS

Option parameter can be specified as name-value list for B<ansi_fold>
function as well as B<new> and B<configure> method.

    ansi_fold($text, $width, boundary => 'word', ...);

    Text::ANSI::Fold->configure(boundary => 'word');

    my $f = Text::ANSI::Fold->new(boundary => 'word');

    $f->configure(boundary => 'word');

=over 7

=item B<width> => I<n>, I<[ n, m, ... ]>

Specify folding width.  Negative value means all the rest.

Array reference can be specified but works only with B<chops> method,
and retunrs empty string for zero width.

=item B<boundary> => "word"

B<boundary> option currently takes only "word" as a valid value.  In
this case, text is folded on word boundary.  This occurs only when
enough space will be provided to hold the word on next call with same
width.

=item B<padding> => I<bool>

If B<padding> option is given with true value, margin space is filled
up with space character.  Default is 0.  Next code fills spaces if the
given text is shorter than 80.

    ansi_fold($text, 80, padding => 1);

If an ANSI B<Erase Line> sequence is found in the string, color status
at the position is remembered, and padding string is produced in that
color.

=item B<padchar> => I<char>

B<padchar> option specifies character used to fill up the remainder of
given width.

    ansi_fold($text, 80, padding => 1, padchar => '_');

=item B<ambiguous> => "narrow" or "wide"

Tells how to treat Unicode East Asian ambiguous characters.  Default
is "narrow" which means single column.  Set "wide" to tell the module
to treat them as wide character.

=item B<discard> => [ "EL", "OSC" ]

Specify the list reference of control sequence name to be discarded.
B<EL> means Erase Line; B<OSC> means Operating System Command, defined
in ECMA-48.  Erase Line right after RESET sequence is always kept.

=item B<linebreak> => I<mode>

=item B<runin> => I<width>

=item B<runout> => I<width>

These options specify the behavior of line break handling for Asian
multi byte characters.  Only Japanese is supported currently.

If the cut-off text start with space or prohibited characters
(e.g. closing parenthesis), they are ran-in at the end of current line
as much as possible.

If the trimmed text end with prohibited characters (e.g. opening
parenthesis), they are ran-out to the head of next line, if it fits to
maximum width.

Default B<linebreak> mode is B<LINEBREAK_NONE> and can be set one of
those:

    LINEBREAK_NONE
    LINEBREAK_RUNIN
    LINEBREAK_RUNOUT
    LINEBREAK_ALL

Import-tag B<:constants> can be used to access these constants.

Option B<runin> and B<runout> is used to set maximum width of moving
characters.  Default values are both 2.

=item B<expand> => I<bool>

=item B<tabstop> => I<n>

Enable tab character expansion.  Default tabstop is 8 and can be set
by B<tabstop> option.

=back

=head1 EXAMPLE

Next code implements almost perfect fold command for multi byte
characters with prohibited character handling.

    #!/usr/bin/env perl
    
    use strict;
    use warnings;
    use open IO => 'utf8', ':std';
    
    use Text::ANSI::Fold qw(:constants);
    my $fold = Text::ANSI::Fold->new(
        width     => 70,
        boundary  => 'word',
        linebreak => LINEBREAK_ALL,
        runin     => 4,
        runout    => 4,
        );
    
    $, = "\n";
    while (<>) {
        print $fold->text($_)->chops;
    }

=head1 SEE ALSO

=over 7

=item L<App::ansifold>

Command line utility using L<Text::ANSI::Fold>.

=item L<Text::ANSI::Fold::Util>

Collection of utilities using L<Text::ANSI::Fold> module.

=item L<App::sdif>

L<Text::ANSI::Fold> was originally implemented in B<sdif> command for
long time, which provide side-by-side view for diff output.  It is
necessary to process output from B<cdif> command which highlight diff
output using ANSI escape sequences.

=item L<Text::ANSI::Util>, L<Text::ANSI::WideUtil>

These modules provide a rich set of functions to handle string
contains ANSI color terminal sequences.  In contrast,
L<Text::ANSI::Fold> provides simple folding mechanism with minimum
overhead.  Also B<sdif> need to process other than SGR (Select Graphic
Rendition) color sequence, and non-spacing combining characters, those
are not supported by these modules.

=item L<https://en.wikipedia.org/wiki/ANSI_escape_code>

ANSI escape code definition.

=item L<https://www.w3.org/TR/2012/NOTE-jlreq-20120403/>

Requirements for Japanese Text Layout,
W3C Working Group Note 3 April 2012

=item L<http://www.ecma-international.org/publications/files/ECMA-ST/Ecma-048.pdf>

Control Functions for Coded Character Sets

=back

=head1 LICENSE

Copyright (C) 2018- Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

=over

=item Kazumasa Utashiro

=item L<https://github.com/kaz-utashiro/Text-ANSI-Fold>

=back

=cut

#  LocalWords:  ansi Unicode undef bool diff cdif sdif SGR Kazumasa
#  LocalWords:  Utashiro linebreak LINEBREAK runin runout
