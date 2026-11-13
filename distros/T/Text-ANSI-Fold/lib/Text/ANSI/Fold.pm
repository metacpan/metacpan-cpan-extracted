package Text::ANSI::Fold;

use v5.14;
use warnings;
use utf8;

our $VERSION = "2.3901";

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

# \p{Hangul} is Script_Extensions, which takes CJK punctuation as well
our $alphanum_re = qr{ [_\d\p{Latin}\p{Greek}\p{Cyrillic}\p{sc=Hangul}] }x;
our $nonspace_re = qr{ \p{IsPrintableLatin} }x;
our $reset_re    = qr{ \e \[ [0;]* m }x;
our $color_re    = qr{ \e \[ [\d:;]* m }x;
our $erase_re    = qr{ \e \[ [\d:;]* K }x;

# see ECMA-48 5.4 Control sequences
my  $csi_start       = qr{ (?: \e\[ | \x9b ) }x;
my  $csi_parameter   = qr/[\x30-\x3f]*+/;
my  $csi_itermidiate = qr/[\x20-\x2f]*+/;
my  $csi_final       = qr/[\x40-\x7e]/;
our $csi_body_re     = qr/${csi_start}${csi_parameter}${csi_itermidiate}/;
our $csi_re          = qr/${csi_start}${csi_parameter}${csi_itermidiate}${csi_final}/;
# CSI other than SGR (cursor movement and the like)
my  $csi_other_re    = qr/${csi_body_re}[\x40-\x6c\x6e-\x7e]/;

our $osc_re          = qr{
    # see ECMA-48 8.3.89 OSC - OPERATING SYSTEM COMMAND
    # Extended to accept non-ASCII (undefined but tolerated)
    (?: \e\] | \x9d )			  # osc
    [^\x00-\x07\x0e-\x1f\x7f-\x9f]*+	  # command (excludes C1 controls)
    (?: \e\\ | \x9c | \a )		  # st: string terminator
}x;

use constant SGR_RESET  => "\e[m";
use constant OSC8_RESET => "\e]8;;\e\\";

sub pwidth { vwidth $_[0] =~ s/\X\cH{1,2}//gr =~ s/${osc_re}|${csi_re}//gr }

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
-utf8::Default_Ignorable_Code_Point
END
}

sub IsWideAmbiguousSpacing {
    return <<"END";
+utf8::East_Asian_Width=Wide
+utf8::East_Asian_Width=FullWidth
+utf8::East_Asian_Width=Ambiguous
-utf8::Nonspacing_Mark
-utf8::Default_Ignorable_Code_Point
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
    trim      => 0,
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
    splitwide => 0,
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
my $osc8_link;
sub put_reset { @reset = shift };
sub pop_reset {
    @reset ? do { @color_stack = (); pop @reset } : '';
}

use constant MAX_INT => ~0 >> 1;

# grapheme cluster boundary, from perl 5.22
my $gcb = $] >= 5.022 ? '\b{gcb}' : '';

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
    my $unlimited = $width < 0;
    $width = MAX_INT if $unlimited;
    ($width -= $opt->{margin}) > 0 or croak "margin too big";

    my $word_char_re =
	    { word => $alphanum_re, space => $nonspace_re }
	    ->{$opt->{boundary} // ''};

    local $Text::VisualWidth::PP::EastAsian = $opt->{ambiguous} eq 'wide';

    # The prefix put at the head of this text by the previous call does
    # not count as progress: there must be something after it.
    my $prefix_width = $opt->{prefix} eq '' ? 0 : pwidth($opt->{prefix});
    my $head_width = (not ref $opt->{prefix} and index($_, $opt->{prefix}) == 0)
	? $prefix_width : 0;
    # the room of a line with nothing after the prefix yet
    my $head_room = $width > $head_width ? $width - $head_width : $width;

    my $folded = '';
    my $eol = '';
    my $room = $width;
    my $split = 0;
    @bg_stack = @color_stack = @reset = ();
    $osc8_link = undef;
    # a character with no special handling, and not overstruck
    my $unremarkable_re =
	$opt->{expand} ? qr/[^\p{IsEOL}\e\t](?!\cH)/
		       : qr/[^\p{IsEOL}\e](?!\cH)/;

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
	# It is at the beginning when no text is before it: sequences
	# such as colors do not count, or a form feed in a color would
	# stay in the rest forever.
	if (m/\A(\f+)/p) {
	    my($ff, $post) = ($1, ${^POSTMATCH});
	    last if $folded =~ s/(?:${csi_re}|${osc_re}|\f)//gr ne '';
	    ($folded, $_) = ($folded . $ff, $post);
	    next;
	}
	# carriage return
	if (s/\A(\r+)//) {
	    if (length == 0) {
		# this must be the part of CRNL
		$eol = $1;
		last;
	    } else {
		$folded .= $1;
		$room = $width;
		next;
	    }
	}
	# ECMA-48 OPERATING SYSTEM COMMAND
	if (s/\A($osc_re)//) {
	    my $osc = $1;
	    unless ($obj->{discard}->{OSC}) {
		$folded .= $osc;
		if ($osc =~ /^(?:\e\]|\x9d)8;[^;]*;(.*?)(?:\e\\|\x9c|\a)$/) {
		    $osc8_link = $1 ne '' ? $osc : undef;
		}
	    }
	    next;
	}
	# erase line (assume 0)
	if (s/\A($erase_re)//) {
	    $folded .= $1 unless $obj->{discard}->{EL};
	    @bg_stack = grep { !/$erase_re/ } @color_stack;
	    push @color_stack, $1;
	    next;
	}
	# reset
	if (s/\A($reset_re+($erase_re*))//) {
	    put_reset($1);
	    @bg_stack = () if $2;
	    next;
	}

	# sequences with no visible text after them stay on this line
	last if $room < 1
	    and not /\A(?:${csi_re}|${osc_re})*+(?:\z|\p{IsEOL})/;
	if ($room < 2 and !$opt->{splitwide}) {
	    last if $room != $head_room and &_startWideSpacing;
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

	# other CSI: no width, the cursor movement is not counted; at
	# the folding point it goes with the text after it, as color does
	if (s/\A($csi_other_re)//) {
	    $folded .= $1;
	    next;
	}

	# imcomplete CSI
	if (s/\A(\e+|$csi_body_re)\z//) {
	    $folded .= $1;
	    last;
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
	# no more than the room can take, so as not to scan the rest of
	# a long paragraph for every line; no limit for an unlimited
	# width, or beyond what a regex quantifier allows
	my $max = do {
	    if ($unlimited) {
		'';
	    } elsif ((my $n = $room * 2 + 8) > 32766) {
		'';
	    } else {
		$n;
	    }
	};
	if (s{\A(
		\e+					# escapes
	      |						# or
		${unremarkable_re}{1,$max}+		# up to the limit
		${unremarkable_re}*? $gcb		# and to the end of the grapheme
	    )}{}x) {
	    my $s = $1;
	    # simple_fold looks only as far as the room, while vwidth
	    # would measure the whole run, which can be the rest of a
	    # long paragraph
	    my($a, $b, $w) = simple_fold($s, $room);
	    if ($b eq '' and $w <= $room) {
		$folded .= $s;
		$room -= $w;
		next;
	    }
	    if ($opt->{splitwide}) {
		if ($w == $room - 1 && $b =~ /\A\p{IsWideSpacing}/p) {
		    $a .= $opt->{lefthalf};
		    $b  = $opt->{righthalf} . ${^POSTMATCH};
		    $w++;
		    $split = 1;
		}
		elsif ($w > $room) {
		    $a = $opt->{lefthalf};
		    $b = $opt->{righthalf} . $b;
		    $w--;
		    $split = 1;
		}
	    }
	    if ($w > $room && $room != $head_room) {
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
		\A ## avoid CSI/OSC final char making a word
		   ( (?: [^\e\x9b\x9d]* (?:${csi_re}|${osc_re})++ ) *+ .*? )
		   ( (?: ${word_char_re} \cH ? ) + )
		\z }x
    ) {
	## Break line before word only when enough space will be
	## provided for the word in the next turn.
	my $l = pwidth($w1);
	my $next = $width - $prefix_width;
	if ($room + $l < $next and $l + pwidth($w2) <= $next
	    and pwidth($lead) > $head_width) {
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
	    and ${^PREMATCH} ne '' and pwidth(${^PREMATCH}) > $head_width
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
    if ($opt->do_runin and not $split) {
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

    ##
    ## TRIM: spaces at the end of a folded line, unless they are colored
    ##
    if ($opt->{trim} and $eol eq '' and length and not /\A\p{IsEOL}/
	and not @color_stack and not defined $osc8_link
	and $folded =~ s/(\N{SPACE}+)\z//) {
	$room += vwidth(my $spaces = $1);
    }

    if (@color_stack) {
	$folded .= SGR_RESET;
	$_ = join '', @color_stack, $_ if $_ ne '';
    }
    if (defined $osc8_link) {
	$folded .= OSC8_RESET;
	$_ = $osc8_link . $_ if $_ ne '';
    }

    if ($opt->{padding} and $room > 0) {
	my $padding = $opt->{padchar} x $room;
	if (@bg_stack) {
	    $padding = join '', @bg_stack, $padding, SGR_RESET;
	}
	$folded .= $padding;
    }

    if (length and my $p = $opt->{prefix}) {
	my $s = ref $p eq 'CODE' ? &$p : $p;
	$_ = $s . $_;
    }

    ($folded . $eol, $_, $width + $opt->{margin} - $room);
}

##
## Trim off one or more *logical* characters from the beginning of a line
##
sub simple_fold {
    my $orig = shift;
    my $width = shift;
    $width <= 0 and croak "parameter error";

    # Printable ASCII is as wide as its length.  The character after
    # the width is checked too, as it may be a mark on the last one.
    if (substr($orig, 0, $width + 1) !~ /[^\x20-\x7e]/) {
	return ($orig, '', length $orig) if length $orig <= $width;
	return (substr($orig, 0, $width), substr($orig, $width), $width);
    }

    my $left = _trim($orig, $width);
    $left = $orig =~ /^(\X)/ ? $1 : '' if $left eq '';	# at least one
    ($left, substr($orig, length $left), vwidth $left);
}

##
## The longest leading part of a string within a width, in graphemes.
## This is trim of Text::VisualWidth::PP, which counts a zero-width
## character as 1.  The classes are those of Text::VisualWidth::PP, so
## that the result agrees with vwidth.
##
sub _trim {
    my($str, $limit) = @_;

    my $cnt = 0;
    my $ret = '';
    my $fullwidth = $Text::VisualWidth::PP::EastAsian
	? qr/\p{Text::VisualWidth::PP::InVWPP1Fullwidth}/
	: qr/\p{Text::VisualWidth::PP::InVWPP0Fullwidth}/;
    my $halfwidth = $Text::VisualWidth::PP::EastAsian
	? qr/\p{Text::VisualWidth::PP::InVWPP1Halfwidth}/
	: qr/\p{Text::VisualWidth::PP::InVWPP0Halfwidth}/;
    while ($str =~ /\G(\X)/g) {
	my $ch = $1;
	# a zero-width character is in neither class, and vwidth gives 0
	my $w = do {
	    if ($ch =~ /\A[\x00-\x7f]\z/) {
		1;
	    } elsif ($ch =~ /\A$fullwidth\z/) {
		2;
	    } elsif ($ch =~ /\A$halfwidth\z/) {
		1;
	    } else {
		vwidth($ch);
	    }
	};
	last if $cnt + $w > $limit;
	$ret .= $ch;
	$cnt += $w;
    }
    $ret;
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
    (shift->_retrieve(@_))[0];
}

# returns the folded string and its width
sub _retrieve {
    my $obj = shift;
    local *_ = \$obj->{text};
    return ('', 0) if not defined $_;
    my($folded, $rest, $width) = $obj->fold($_, @_);
    die "panic: retrieve: no progress in fold"
	if length $rest and $rest eq $_;
    $_ = length $rest ? $rest : undef;
    ($folded, $width);
}

sub chops {
    my $obj = shift;
    my %opt = @_;
    my $width = $opt{width} // $obj->{width};

    my(@chops, @length);

    if (ref $width eq 'ARRAY') {
	for my $w (@{$width}) {
	    if ($w == 0) {
		push @chops, '';
		push @length, 0;
	    }
	    elsif ((my($chop, $l) = $obj->_retrieve(width => $w))[0] ne '') {
		push @chops, $chop;
		push @length, $l;
	    }
	    else {
		last;
	    }
	}
    }
    else {
	while ((my($chop, $l) = $obj->_retrieve(width => $width))[0] ne '') {
	    push @chops, $chop;
	    push @length, $l;
	}
    }

    @{$opt{length}} = @length if $opt{length};
    @chops;
}

1;

__END__

=encoding utf-8

=head1 NAME

Text::ANSI::Fold - Text folding library supporting ANSI terminal sequence and Asian wide characters with prohibition character handling.

=head1 VERSION

Version 2.3901

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

OSC 8 hyperlink sequences are also handled properly.  If the text is
divided in the middle of a hyperlink, the link is closed at the end of
the former text and reopened at the beginning of the latter string.

Other control sequences (CSI), such as cursor movement, are passed
through with no width.  The movement of the cursor is not taken into
account: text written over by moving the cursor back is counted as
it is.

At the folding point, a sequence goes to the next line with the text
after it.  When no visible text follows up to the end of the line, it
stays on the line, even if the line has no room left.

This module also support Unicode Asian full-width and non-spacing
combining characters properly.  Text is divided between grapheme
clusters, so that a character with combining marks or an emoji
sequence stays in one line, as far as the grapheme rules of the perl
in use go; before perl 5.22, a grapheme in a long paragraph may
rarely be split.  Japanese text formatting with head-or-end of line
prohibition character is also supported.  Set the linebreak mode to
enable it.

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

=head1 REGULAR EXPRESSIONS

Import-tag C<:regex> gives the regular expressions C<$reset_re>,
C<$color_re>, C<$erase_re>, C<$csi_re> and C<$osc_re>, which match the
ANSI sequences this module recognizes.

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

Actually, text can be set by C<new> or C<configure> method through
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

=head2 B<chops> with length

Give an array reference by C<length> parameter, and it is set to the
visual width of each element returned (not the number of characters).
It is the width that the fold counted, so the strings need not be
measured again.  The padding is not included.

    my @list = $fold->text($text)->chops(length => \my @length);

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
very careful because of the possibility of an infinite loop, when the
prefix is as wide as the width or longer, or given by a subroutine.

A line has at least one character after the prefix, even if it does
not fit.  A wide character after the prefix may make the line one
column longer than the width.

=item B<trim> => I<bool>

If B<trim> option is given with true value, spaces at the end of a
folded line are removed, including those brought there by the run-in
operation, so that they do not make the line longer than the width.
Only ASCII spaces are removed; other spaces, such as full-width spaces
and the no-break space that B<splitwide> uses, are kept.  Default is 0.

Spaces at the end of the original line are left as they are, because
the line is not folded there.  Colored spaces are also left, because
their background color may be visible.

=item B<ambiguous> => C<narrow> or C<wide>

Tells how to treat Unicode East Asian ambiguous characters.  Default
is C<narrow> which means single column.  Set C<wide> to tell the
module to treat them as wide character.

=item B<discard> => [ C<EL>, C<OSC> ]

Specify the list reference of control sequence name to be discarded.
B<EL> means Erase Line; B<OSC> means Operating System Command, defined
in ECMA-48.  Erase Line right after RESET sequence is always kept.

When OSC is discarded, OSC 8 hyperlink state tracking is also
disabled.

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

=item B<margin> => I<width>

This option reserves a margin space within the specified width for
run-in operation.  When margin is specified, the actual folding width
becomes C<width - margin>, and the margin space is used for run-in
characters.  Any unused margin space is filled with padding characters
if padding is enabled.

If margin is 0 (default), run-in may cause the result to exceed the
specified width.  Set margin equal to or greater than runin value to
ensure the result always fits within the specified width.

=item B<splitwide> => I<bool>

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

The beginning is where no text is before it: a form feed after
nothing but ANSI sequences, as in a form feed with a color, is at the
beginning, and is kept in the place where it is.

=back

=head1 OSC 8 HYPERLINKS

This module handles OSC 8 hyperlink sequences.  The OSC (Operating
System Command) is defined in ECMA-48, and OSC 8 is an extension for
terminal hyperlinks.

The command string in OSC is defined in ECMA-48 8.3.89 to consist of
characters in the range 00/08-00/13 and 02/00-07/14.  However, this
module extends the definition to accept non-ASCII characters, since
they may appear in URLs even though the OSC 8 specification recommends
URI encoding.  The behavior for non-ASCII is undefined in the spec, but
this module tolerates it for practical compatibility.

The only exception is U+009C (STRING TERMINATOR), which is excluded
because it terminates the OSC sequence.

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

Copyright ©︎ 2018-2026 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

#  LocalWords:  ansi Unicode undef bool diff cdif sdif SGR Kazumasa
#  LocalWords:  Utashiro linebreak LINEBREAK runin runout
