package Text::ANSI::Fold;

use v5.14;
use warnings;
use utf8;

our $VERSION = "2.2701";

use Data::Dumper;
{
    no warnings 'redefine';
    *Data::Dumper::qquote = sub { qq["${\(shift)}"] };
    $Data::Dumper::Useperl = 1;
    $Data::Dumper::Sortkeys = 1;
}
use Carp;
use List::Util qw(pairmap pairgrep);
use Scalar::Util qw(looks_like_number);
use Text::VisualWidth::PP 'vwidth';
sub pwidth { vwidth $_[0] =~ s/\X\cH{1,2}//gr }

######################################################################
use Exporter 'import';
our %EXPORT_TAGS = (
    constants => [ qw(
	&LINEBREAK_NONE
	&LINEBREAK_ALL
	&LINEBREAK_RUNIN
	&LINEBREAK_RUNOUT
	) ],
    regex => [ qw(
	$reset_re
	$color_re
	$erase_re
	$csi_re
	$osc_re
	) ],
    );

our @EXPORT_OK = ( qw(&ansi_fold),
		   @{$EXPORT_TAGS{constants}},
		   @{$EXPORT_TAGS{regex}},
    );

sub ansi_fold {
    my($text, $width, @option) = @_;
    __PACKAGE__->fold($text, width => $width, @option);
}
######################################################################

our $alphanum_re = qr{ [_\d\p{Latin}\p{Greek}\p{Cyrillic}\p{Hangul}] }x;
our $nonspace_re = qr{ \p{IsPrintableLatin} }x;
our $reset_re    = qr{ \e \[ [0;]* m }x;
our $color_re    = qr{ \e \[ [\d;]* m }x;
our $erase_re    = qr{ \e \[ [\d;]* K }x;
our $csi_re      = qr{
    # see ECMA-48 5.4 Control sequences
    (?: \e\[ | \x9b )	# csi
    [\x30-\x3f]*	# parameter bytes
    [\x20-\x2f]*	# intermediate bytes
    [\x40-\x7e]		# final byte
}x;
our $osc_re      = qr{
    # see ECMA-48 8.3.89 OSC - OPERATING SYSTEM COMMAND
    (?: \e\] | \x9d )		# osc
    [\x08-\x13\x20-\x7d]*+	# command
    (?: \e\\ | \x9c | \a )	# st: string terminator
}x;

use constant SGR_RESET => "\e[m";

sub IsPrintableLatin {
    return <<"END";
+utf8::ASCII
+utf8::Latin
-utf8::White_Space
END
}

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

BEGIN {
    if ($] < 5.016) {
	require charnames;
	charnames->import(':full');
    }
}

our %TABSTYLE = (
    pairmap {
	( $a =~ s/_/-/gr => ref $b ? $b : [ $b, $b ] );
    }
    symbol   => [ "\N{SYMBOL FOR HORIZONTAL TABULATION}",		    # ␉
		  "\N{SYMBOL FOR SPACE}" ],				    # ␠
    shade    => [ "\N{MEDIUM SHADE}",					    # ▒
		  "\N{LIGHT SHADE}" ],					    # ░
    block    => [ "\N{LOWER ONE QUARTER BLOCK}",			    # ▂
		  "\N{LOWER ONE EIGHTH BLOCK}" ],			    # ▁
    needle   => [ "\N{BOX DRAWINGS HEAVY RIGHT}",			    # ╺
		  "\N{BOX DRAWINGS LIGHT HORIZONTAL}" ],		    # ─
    dash     => [ "\N{BOX DRAWINGS HEAVY RIGHT}",			    # ╺
		  "\N{BOX DRAWINGS LIGHT DOUBLE DASH HORIZONTAL}" ],	    # ╌
    triangle => [ "\N{BLACK RIGHT-POINTING SMALL TRIANGLE}",		    # ▸
		  "\N{WHITE RIGHT-POINTING SMALL TRIANGLE}" ],		    # ▹

    dot          => '.',
    space        => ' ',
    emspace      => "\N{EM SPACE}",					    #  
    blank        => "\N{OPEN BOX}",					    # ␣
    middle_dot   => "\N{MIDDLE DOT}",					    # ·
    arrow        => "\N{RIGHTWARDS ARROW}",				    # →
    double_arrow => "\N{RIGHTWARDS DOUBLE ARROW}",			    # ⇒
    triple_arrow => "\N{RIGHTWARDS TRIPLE ARROW}",			    # ⇛
    white_arrow  => "\N{RIGHTWARDS WHITE ARROW}",			    # ⇨
    wave_arrow   => "\N{RIGHTWARDS WAVE ARROW}",			    # ↝
    circle_arrow => "\N{CIRCLED HEAVY WHITE RIGHTWARDS ARROW}",		    # ➲
    curved_arrow => "\N{HEAVY BLACK CURVED DOWNWARDS AND RIGHTWARDS ARROW}",# ➥
    shadow_arrow => "\N{HEAVY UPPER RIGHT-SHADOWED WHITE RIGHTWARDS ARROW}",# ➮
    squat_arrow  => "\N{SQUAT BLACK RIGHTWARDS ARROW}",			    # ➧
    squiggle     => "\N{RIGHTWARDS SQUIGGLE ARROW}",			    # ⇝
    harpoon      => "\N{RIGHTWARDS HARPOON WITH BARB UPWARDS}",		    # ⇀
    cuneiform    => "\N{CUNEIFORM SIGN TAB}",				    # 𒋰

    );

for my $alias (
    [ bar => 'needle'],
    [ pin => 'needle']
) {
    $TABSTYLE{$alias->[0]} = $TABSTYLE{$alias->[1]};
}

my @default = (
    text      => '',
    width     => undef,
    padding   => 0,
    boundary  => '',
    padchar   => ' ',
    prefix    => '',
    ambiguous => 'narrow',
    margin    => 0,
    linebreak => $DEFAULT_LINEBREAK,
    runin     => $DEFAULT_RUNIN_WIDTH,
    runout    => $DEFAULT_RUNOUT_WIDTH,
    expand    => 0,
    tabstop   => 8,
    tabhead   => ' ',
    tabspace  => ' ',
    discard   => {},
    crackwide => 0,
    lefthalf  => "\N{NO-BREAK SPACE}",
    righthalf => "\N{NO-BREAK SPACE}",
    );

sub new {
    my $class = shift;
    my $obj = bless { @default }, $class;
    $obj->configure(@_) if @_;
    $obj;
}

INTERNAL_METHODS: {
    sub spawn {
	my $obj = shift;
	my $class = ref $obj;
	my %new = ( %$obj, pairgrep { defined $b } @_ );
	bless \%new, $class;
    }
    sub do_runin  { $_[0]->{linebreak} & LINEBREAK_RUNIN  && $_[0]->{runin}  > 0 }
    sub do_runout { $_[0]->{linebreak} & LINEBREAK_RUNOUT && $_[0]->{runout} > 0 }
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
    my $obj = shift;
    if (not ref $obj) {
	$obj = state $private = __PACKAGE__->new;
    }
    croak "invalid parameter" if @_ % 2;
    while (@_ >= 2) {
	my($a, $b) = splice @_, 0, 2;

	if ($a eq 'tabstyle') {
	    $b // next;
	    my($h, $s) = $b =~ /([-\w]+)/g or croak "$b: invalid tabstyle";
	    $s ||= $h;
	    my %style = (
		h => ($TABSTYLE{$h} or croak "$h: invalid tabstyle"),
		s => ($TABSTYLE{$s} or croak "$s: invalid tabstyle"),
		);
	    unshift @_,
		tabhead  => $style{h}->[0],
		tabspace => $style{s}->[1];
	    next;
	}

	croak "$a: invalid parameter" if not exists $obj->{$a};
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

use constant MAX_INT => ~0 >> 1;

sub IsEOL {
    <<"END";
0000\t0000
000A\t000D
2028\t2029
END
}

sub fold {
    my $obj = shift;
    local $_ = shift // '';

    if (not ref $obj) {
	$obj = state $private = configure();
    }
    my $opt = $obj->spawn(splice @_);

    my $width = $opt->{width};
    looks_like_number $width and $width == int($width)
	or croak "$width: invalid width";
    $opt->{padding} = 0 if $width <= 0;
    $width = MAX_INT    if $width <  0;
    ($width -= $opt->{margin}) > 0 or croak "margin too big";

    my $word_char_re =
	    { word => $alphanum_re, space => $nonspace_re }
	    ->{$opt->{boundary} // ''};

    local $Text::VisualWidth::PP::EastAsian = $opt->{ambiguous} eq 'wide';

    my $folded = '';
    my $eol = '';
    my $room = $width;
    @bg_stack = @color_stack = @reset = ();
    my $unremarkable_re =
	$opt->{expand} ? qr/[^\p{IsEOL}\e\t]/
		       : qr/[^\p{IsEOL}\e]/;

  FOLD:
    while (length) {

	# newline, null, vt
	# U+2028: Line Separator
	# U+2029: Paragraph Separator
	if (s/\A(\r*\n|[\0\x0b\N{U+2028}\N{U+2029}])//) {
	    $eol = $1;
	    last;
	}
	# form feed
	if (m/\A(\f+)/p) {
	    last if length $folded;
	    ($folded, $_) = ($1, ${^POSTMATCH});
	    next;
	}
	# carriage return
	if (s/\A(\r+)//) {
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
	if ($room < 2 and !$opt->{crackwide}) {
	    last if $room != $width and &_startWideSpacing;
	}

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
	if ($opt->{expand} and s/\A\t//) {
	    my $space = $opt->{tabstop} - ($width - $room) % $opt->{tabstop};
	    $_ = $opt->{tabhead} . $opt->{tabspace} x ($space - 1) . $_;
	    next;
	}

	# backspace
	my $bs = 0;
	while (m/\A(?:\X\cH+)++(?<c>\X|\z)/p) {
	    my $w = vwidth($+{c});
	    last FOLD if $w > $room and $room != $width;
	    $folded .= ${^MATCH};
	    $_ = ${^POSTMATCH};
	    $room -= $w;
	    $bs++;
	    last FOLD if $room < 0;
	    last      if $room < 1;
	}
	next if $bs;

	# consume unremarkable characters
	if (s/\A(\e+|(?:${unremarkable_re}(?!\cH))+)//) {
	    my $s = $1;
	    if ((my $w = vwidth($s)) <= $room) {
		$folded .= $s;
		$room -= $w;
		next;
	    }
	    my($a, $b, $w) = simple_fold($s, $room);
	    if ($opt->{crackwide}) {
		if ($w == $room - 1 && $b =~ /\A\p{IsWideSpacing}/p) {
		    $a .= $opt->{lefthalf};
		    $b  = $opt->{righthalf} . ${^POSTMATCH};
		    $w++;
		}
		elsif ($w > $room) {
		    $a = $opt->{lefthalf};
		    $b = $opt->{righthalf} . $b;
		    $w--;
		}
	    }
	    if ($w > $room && $room != $width) {
		$_ = $s . $_;
		last;
	    }
	    ($folded, $_) = ($folded . $a, $b . $_);
	    $room -= $w;
	} else {
	    die "panic ($_)";
	}
    }

    ##
    ## --boundary=word
    ##
    if ($word_char_re
	and my($w2) = /\A( (?: ${word_char_re} \cH ? ) + )/x
	and my($lead, $w1) = $folded =~ m{
		\A ## avoid CSI final char making a word
		   ( (?: [^\e]* ${csi_re}++ ) *+ .*? )
		   ( (?: ${word_char_re} \cH ? ) + )
		\z }x
    ) {
	## Break line before word only when enough space will be
	## provided for the word in the next turn.
	my $l = pwidth($w1);
	## prefix length
	my $p = $opt->{prefix} eq '' ? 0 : vwidth($opt->{prefix});
	if ($room + $l < $width - $p and $l + pwidth($w2) <= $width - $p) {
	    $folded = $lead;
	    $_ = $w1 . pop_reset() . $_;
	    $room += $l;
	}
    }

    ##
    ## RUN-OUT
    ##
    if ($_ ne '' and $opt->do_runout) {
	if ($folded =~ m{ (?<color>  (?! ${reset_re}) ${color_re}*+ )
			  (?<runout>
			    (?: ($prohibition_re{end}) (?: \cH{1,2} \g{-1})* )+
			  ) \z
			}xp
	    and ${^PREMATCH} ne ''
	    and (my $w = pwidth $+{runout}) <= $opt->{runout}) {

	    $folded = ${^PREMATCH};
	    $_ = join '', ${^MATCH}, @reset, $_;
	    pop_reset() if $+{color};
	    $room += $w;
	}
    }

    $folded .= pop_reset() if @reset;

    $room += $opt->{margin};

    ##
    ## RUN-IN
    ##
    if ($opt->do_runin) {
	my @runin;
	my $m = $opt->{runin};
	while ($m > 0 and
	       m{\A (?<color> ${color_re}*+)
	            (?<runin> $prohibition_re{head} )
		    ( \cH{1,2} \g{runin} )* # multiple strike
	            (?<reset> (?: $erase_re* $reset_re+ $erase_re* )? )
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

    if ($opt->{padding} and $room > 0) {
	my $padding = $opt->{padchar} x $room;
	if (@bg_stack) {
	    $padding .= $opt->{padchar} x $opt->{runin} if $opt->do_runin;
	    $padding = join '', @bg_stack, $padding, SGR_RESET;
	}
	$folded .= $padding;
    }

    if (length and my $p = $opt->{prefix}) {
	my $s = ref $p eq 'CODE' ? &$p : $p;
	$_ = $s . $_;
    }

    ($folded . $eol, $_, $width - $room);
}

##
## Trim off one or more *logical* characters from the beginning of a line
##
sub simple_fold {
    my $orig = shift;
    my $width = shift;
    $width <= 0 and croak "parameter error";

    my($left, $right) = $orig =~ m/^(\X{0,$width}+)(.*)/
	or croak "$width: unexpected width";

    my $w = vwidth $left;
    while ($w > $width) {
	use integer;
	my $trim = ($w - $width + 1) / 2;
	$left =~ s/\X \K ( \X{$trim} ) \z//x or last;
	$right = $1 . $right;
	$w -= vwidth $1;
    }

    ($left, $right, $w);
}

######################################################################
# EXTERNAL METHODS

sub text :lvalue {
    my $obj = shift;
    if (@_ == 0) {
	$obj->{text};
    } else {
	croak "Invalid argument" if @_ > 1;
    	$obj->{text} = shift;
	$obj;
    }
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

Version 2.2701

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

L<Text::ANSI::Fold> provides capability to divide a text into two
parts by given width.  Text can include ANSI terminal sequences and
the width is calculated by its visible representation.  If the text is
divided in the middle of colored region, reset sequence is appended to
the former text, and color recover sequence is inserted before the
latter string.

This module also support Unicode Asian full-width and non-spacing
combining characters properly.  Japanese text formatting with
head-or-end of line prohibition character is also supported.  Set
the linebreak mode to enable it.

Since the overhead of ANSI escape sequence handling is not significant
when the data does not include them, this module can be used for
normal text processing with small penalty.

=head2 B<ansi_fold>

Use exported B<ansi_fold> function to fold original text, with number
of visual columns you want to cut off the text.

    ($folded, $remain, $w) = ansi_fold($text, $width);

It returns a pair of strings; first one is folded text, and second is
the rest.

Additional third result is visual width of the folded text.  It is not
always same as given width, and you may want to know how many columns
returned string takes for further processing.

Negative width value is taken as unlimited.  So the string is never
folded, but you can use this to expand tabs and to get visual string
width.

This function returns at least one character in any situation.  If you
provide Asian wide string and just one column as width, it trims off
the first wide character even if it does not fit to given width.

=head2 B<configure>

Default parameter can be set by B<configure> class method:

    Text::ANSI::Fold->configure(width => 80, padding => 1);

Then you don't have to pass second argument.

    ($folded, $remain) = ansi_fold($text);

Because second argument is always taken as width, use I<undef> when
using default width with additional parameter:

    ($folded, $remain) = ansi_fold($text, undef, padding => 1);

Some other easy-to-use interfaces are provided by sister module
L<Text::ANSI::Fold::Util>.

=head1 OBJECT INTERFACE

You can create an object to hold parameters, which is effective during
object life time.

=head2 B<new>

Use C<new> method to make a fold object.

    my $obj = Text::ANSI::Fold->new(
        width => 80,
        boundary => 'word',
    );

This makes an object folding on word boundaries with 80 columns width.

=head2 B<fold>

Then you can call C<fold> method without parameters because the object
keeps necessary information.

    $obj->fold($text);

=head2 B<configure>

Use B<configure> method to update parameters:

    $obj->configure(padding => 1);

Additional parameter can be specified on each call, and they precede
saved value.

    $obj->fold($text, width => 40);

=head1 STRING OBJECT INTERFACE

You can use a fold object to hold string inside, and take out folded
strings from it.  Use C<text> method to store data in the object, and
C<retrieve> or C<chops> method to take out folded string from it.

=head2 B<text>

A fold object can hold string inside by B<text> method.

    $obj->text("text");

Method B<text> has an lvalue attribute, so it can be assigned to, as
well as can be a subject of mutating operator such as C<s///>.

    $obj->text = "text";

=head2 B<retrieve>

Folded string can be taken out by C<retrieve> method.  It returns
empty string if nothing remained.

    while ((my $folded = $obj->retrieve) ne '') {
        print $folded;
        print "\n" if $folded !~ /\n\z/;
    }

=head2 B<chops>

Method C<chops> returns chopped string list.  Because the C<text>
method returns the object itself when called with a parameter, you can
use C<text> and C<chops> in series:

    print join "\n", $obj->text($string)->chops;

Actually, text can be set by c<new> or C<configure> method through
C<text> parameter.  Next program just works.

    use Text::ANSI::Fold;
    while (<>) {
        print join "\n",
            Text::ANSI::Fold->new(width => 40, text => $_)->chops;
    }

=head2 B<chops> with multiple width

When using C<chops> method, C<width> parameter can take array
reference, and chops text into given width list.

    my $fold = Text::ANSI::Fold->new;
    my @list = $fold->text("1223334444")->chops(width => [ 1, 2, 3 ]);
    # return ("1", "22", "333") and keep "4444"

If the width value is 0, it returns empty string.  Negative width
value takes all the rest of stored string.  In the following code, the
fourth width (3) is ignored because the -2 immediately preceding it
consumes all remaining strings.

    my $fold = Text::ANSI::Fold->new;
    my @list = $fold->text("1223334444")->chops(width => [ 1, 0, -2, 3 ]);
    # return ("1", "", "223334444")

The padding operation is performed only on the last non-empty element,
and no elements corresponding to subsequent items are returned.  Also,
of course, padding is not performed for negative widths.

=head1 OPTIONS

Option parameter can be specified as name-value list for B<ansi_fold>
function as well as B<new> and B<configure> method.

    ansi_fold($text, $width, boundary => 'word', ...);

    Text::ANSI::Fold->configure(boundary => 'word');

    my $obj = Text::ANSI::Fold->new(boundary => 'word');

    $obj->configure(boundary => 'word');

=over 7

=item B<width> => I<n> | I<[ n, m, ... ]>

Specify folding width by integer.  Negative value means all the rest.

Array reference can be specified but works only with B<chops> method,
and retunrs empty string for zero width.

=item B<boundary> => C<word> | C<space>

Option B<boundary> takes C<word> and C<space> as a valid value.  These
prohibit to fold a line in the middle of ASCII/Latin sequence.  Value
C<word> means a sequence of alpha-numeric characters, and C<space>
means simply non-space printables.

This operation takes place only when enough space will be provided to
hold the word on next call with same width.

If the color of text is altered within a word, that position is also
taken as an boundary.

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

=item B<prefix> => I<string> | I<coderef>

B<prefix> string is inserted before remained string if it is not
empty.  This is convenient to produce indented series of text by
B<chops> interface.

If the value is reference to subroutine, its result is used as a
prefix string.

The B<fold> function does not complain if the result of adding a
prefix string is longer than the original text.  The caller must be
very careful because of the possibility of an infinite loop.

=item B<ambiguous> => C<narrow> or C<wide>

Tells how to treat Unicode East Asian ambiguous characters.  Default
is C<narrow> which means single column.  Set C<wide> to tell the
module to treat them as wide character.

=item B<discard> => [ C<EL>, C<OSC> ]

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

Default B<linebreak> mode is C<LINEBREAK_NONE> and can be set one of
those:

    LINEBREAK_NONE
    LINEBREAK_RUNIN
    LINEBREAK_RUNOUT
    LINEBREAK_ALL

Import-tag C<:constants> can be used to access these constants.

Option B<runin> and B<runout> is used to set maximum width of moving
characters.  Default values are both 2.

=item B<crackwide> => I<bool>

=item B<lefthalf> => I<char>

=item B<righthalf> => I<char>

It is sometimes necessary to split a string at the middle of a wide
character.  In such cases, the string is usually split before that
point.  If this parameter is true, that wide character is split into
left-half and right-half character.

The parameters C<lefthalf> and C<righthalf> specify the respective
characters. Their default value is both C<NON-BREAK SPACE>.

=item B<expand> => I<bool>

=item B<tabstop> => I<n>

=item B<tabhead> => I<char>

=item B<tabspace> => I<char>

Enable tab character expansion.

Default tabstop is 8 and can be set by B<tabstop> option.

Tab character is converted to B<tabhead> and following B<tabspace>
characters.  Both are white space by default.

=item B<tabstyle> => I<style>

Set tab expansion style.  This parameter set both B<tabhead> and
B<tabspace> at once according to the given style name.  Each style has
two values for tabhead and tabspace.

If two style names are combined, like C<symbol,space>, use
C<symbols>'s tabhead and C<space>'s tabspace.

Currently these names are available.

    symbol   => [ "\N{SYMBOL FOR HORIZONTAL TABULATION}",
                  "\N{SYMBOL FOR SPACE}" ],
    shade    => [ "\N{MEDIUM SHADE}",
                  "\N{LIGHT SHADE}" ],
    block    => [ "\N{LOWER ONE QUARTER BLOCK}",
                  "\N{LOWER ONE EIGHTH BLOCK}" ],
    needle   => [ "\N{BOX DRAWINGS HEAVY RIGHT}",
                  "\N{BOX DRAWINGS LIGHT HORIZONTAL}" ],
    dash     => [ "\N{BOX DRAWINGS HEAVY RIGHT}",
                  "\N{BOX DRAWINGS LIGHT DOUBLE DASH HORIZONTAL}" ],
    triangle => [ "\N{BLACK RIGHT-POINTING SMALL TRIANGLE}",
		  "\N{WHITE RIGHT-POINTING SMALL TRIANGLE}" ],

Below are styles providing same character for both tabhead and
tabspace.

    dot          => '.',
    space        => ' ',
    emspace      => "\N{EM SPACE}",
    blank        => "\N{OPEN BOX}",
    middle-dot   => "\N{MIDDLE DOT}",
    arrow        => "\N{RIGHTWARDS ARROW}",
    double-arrow => "\N{RIGHTWARDS DOUBLE ARROW}",
    triple-arrow => "\N{RIGHTWARDS TRIPLE ARROW}",
    white-arrow  => "\N{RIGHTWARDS WHITE ARROW}",
    wave-arrow   => "\N{RIGHTWARDS WAVE ARROW}",
    circle-arrow => "\N{CIRCLED HEAVY WHITE RIGHTWARDS ARROW}",
    curved-arrow => "\N{HEAVY BLACK CURVED DOWNWARDS AND RIGHTWARDS ARROW}",
    shadow-arrow => "\N{HEAVY UPPER RIGHT-SHADOWED WHITE RIGHTWARDS ARROW}",
    squat-arrow  => "\N{SQUAT BLACK RIGHTWARDS ARROW}",
    squiggle     => "\N{RIGHTWARDS SQUIGGLE ARROW}",
    harpoon      => "\N{RIGHTWARDS HARPOON WITH BARB UPWARDS}",
    cuneiform    => "\N{CUNEIFORM SIGN TAB}",

=back

=head1 EXAMPLE

Next code implements almost fully-equipped fold command for multi byte
text with Japanese prohibited character handling.

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

=head1 CONTROL CHARACTERS

Text::ANSI::Fold handles the following line break related codes
specially:

    Newline (\n)
    Form feed (\f)
    Carriage return (\r)
    Null (\0)
    Line separator (U+2028)
    Paragraph separator (U+2029)

These characters are handled as follows:

=over 4

=item NEWLINE (C<\n>), CRNL (C<\r\n>)

=item NULL (C<\0>)

=item LINE SEPARATOR (C<U+2028>)

=item PARAGRAPH SEPARATOR (C<U+2029>)

If any of these characters are found, the folding process terminates
immediately and the portion up to that character is returned as folded
text.  These character itself is included at the end of the folded
text.

=item CARRIAGE RETURN (C<\r>)

When a carriage return is found, it is added to the folded text and
the fold width is reset.

=item FORM FEED (C<\f>)

If a form feed character is found in the middle of a string,
processing stops and the string up to the point immediately before is
returned.  If it is found at the beginning of a string, it is added to
the folded text and processing continues.

=back

=head1 SEE ALSO

=over 7

=item L<https://github.com/tecolicom/ANSI-Tools>

Collection of ANSI related tools.

=item L<Text::ANSI::Fold>

=item L<https://github.com/tecolicom/Text-ANSI-Fold>

Distribution and repository.

=item L<App::ansifold>

Command line utility using L<Text::ANSI::Fold>.

=item L<Text::ANSI::Fold::Util>

Collection of utilities using L<Text::ANSI::Fold> module.

=item L<Text::ANSI::Tabs>

L<Text::Tabs> compatible tab expand/unexpand module using
L<Text::ANSI::Fold> as a backend processor.

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

=item L<https://www.w3.org/TR/jlreq/>

Requirements for Japanese Text Layout,
W3C Working Group Note 11 August 2020

=item L<ECMA-48|https://www.ecma-international.org/wp-content/uploads/ECMA-48_5th_edition_june_1991.pdf>

ECMA-48: Control Functions for Coded Character Sets

=back

=head1 AUTHOR

Kazumasa Utashiro

=head1 LICENSE

Copyright ©︎ 2018-2024 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

#  LocalWords:  ansi Unicode undef bool diff cdif sdif SGR Kazumasa
#  LocalWords:  Utashiro linebreak LINEBREAK runin runout
