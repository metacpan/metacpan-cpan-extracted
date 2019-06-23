package Text::ANSI::Fold;
use 5.014;
use strict;
use warnings;

our $VERSION = "0.06";

use Carp;
use Text::VisualWidth::PP 'vwidth';

######################################################################
use Exporter 'import';
our @EXPORT_OK = qw(&ansi_fold);

my $myfold = __PACKAGE__->new();

sub ansi_fold {
    my($text, $width, @option) = @_;
    $myfold->fold($text, width => $width, @option);
}
######################################################################

my $alphanum_re = qr{ [_\d\p{Latin}] }x;
my $reset_re    = qr{ \e \[ [0;]* m (?: \e \[ [0;]* [mK])* }x;
my $color_re    = qr{ \e \[ [\d;]* [mK] }x;
my $control_re  = qr{ \e \] [\;\:\/0-9a-z]* \e \\ }x;

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

sub new {
    my $class = shift;
    my $obj = bless {
	text      => '',
	width     => undef,
	padding   => 0,
	boundary  => '',
	padchar   => ' ',
	ambiguous => 'narrow',
    }, $class;

    $obj->configure(@_) if @_;

    $obj;
}

sub configure {
    my $obj = ref $_[0] ? $_[0] : $myfold;
    shift;
    croak "invalid parameter" if @_ % 2;
    while (@_ >= 2) {
	my($a, $b) = splice @_, 0, 2;
	croak "$a: invalid parameter\n" if not exists $obj->{$a};
	$obj->{$a} = $b;
    }
    $obj;
}

sub fold {
    my $obj = shift;

    local $_ = shift // '';
    my %opt = @_;

    my $width     = $opt{width}     // $obj->{width};
    my $boundary  = $opt{boundary}  // $obj->{boundary};
    my $padding   = $opt{padding}   // $obj->{padding};
    my $padchar   = $opt{padchar}   // $obj->{padchar};
    my $ambiguous = $opt{ambiguous} // $obj->{ambiguous};

    if (not defined $width or $width < 1) {
	croak "invalid width";
    }

    $Text::VisualWidth::PP::EastAsian = $ambiguous eq 'wide';

    my $folded = '';
    my $eol = '';
    my $room = $width;
    my @color_stack;
    while (length) {

	if (s/\A(\r*\n)//) {
	    $eol = $1;
	    last;
	}
	if (s/\A([\f\r]+)//) {
	    last if length == 0;
	    $folded .= $1;
	    $room = $width;
	    next;
	}
	if (s/\A($control_re)//) {
	    $folded .= $1;
	    next;
	}
	if (s/\A($reset_re)//) {
	    $folded .= $1;
	    @color_stack = ();
	    next;
	}

	last if $room < 1;
	last if $room != $width and &_startWideSpacing and $room < 2;

	if (s/\A($color_re)//) {
	    $folded .= $1;
	    push @color_stack, $1;
	    next;
	}

	if (s/\A(\e*[^\e\n\f\r]+)//) {
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

    if ($boundary eq 'word'
	and my($tail) = /^(${alphanum_re}+)/o
	and $folded =~ m{
		^
		( (?: [^\e]* ${color_re} ) *+ )
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
	    $_ = substr($folded, $s, $l, '') . $_;
	    $room += $l;
	}
    }

    if (@color_stack) {
	$folded .= SGR_RESET;
	$_ = join '', @color_stack, $_ if $_ ne '';
    }

    if ($padding) {
	$folded .= $padchar x $room if $room > 0;
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
    return '' if $_ eq '';
    (my $folded, $_) = $obj->fold($_, @_);
    $folded;
}

sub chops {
    my $obj = shift;
    my %opt = @_;
    my $width = $opt{width} // $obj->{width};

    my @chops;

    if (ref $width eq 'ARRAY') {
	for my $w (@{$width}) {
	    if ((my $chop = $obj->retrieve(width => $w)) ne '') {
		push @chops, $chop;
	    } else {
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

Text::ANSI::Fold - Text folding with ANSI sequence and Asian wide characters.

=head1 SYNOPSIS

    use Text::ANSI::Fold qw(ansi_fold);
    ($folded, $remain) = ansi_fold($text, $width, [ option ]);

    use Text::ANSI::Fold;
    my $f = new Text::ANSI::Fold width => 80, boundary => 'word';
    $f->configure(ambiguous => 'wide');
    ($folded, $remain) = $f->fold($text);

    use Text::ANSI::Fold;
    while (<>) {
        print join "\n",
            Text::ANSI::Fold->new(width => 40, text => $_)->chops;
    }

=head1 DESCRIPTION

Text::ANSI::Fold provides capability to fold a text into two strings
by given width.  Text can include ANSI terminal sequences.  If the
text is divided in the middle of ANSI-effect region, reset sequence is
appended to folded text, and recover sequence is prepended to trimmed
string.

This module also support Unicode Asian full-width and non-spacing
combining characters properly.

Use exported B<ansi_fold> function to fold original text, with number
of visual columns you want to cut off the text.  Width parameter have
to be a number greater than zero.

    ($folded, $remain, $w) = ansi_fold($text, $width);

It returns a pair of strings; first one is folded text, and second is
the rest.

Additional third result is the visual width of folded text.  You may
want to know how many columns returned string takes for further
processing.

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

    my $f = new Text::ANSI::Fold
        width => 80,
        boundary => 'word';

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

    my $fold = new Text::ANSI::Fold;
    my @list = $fold->text("1223334444")->chops(width => [ 1, 2, 3 ]);
    # return ("1", "22", "333") and keep "4444"

=head1 OPTIONS

Option parameter can be specified as name-value list for B<ansi_fold>
function as well as B<new> and B<configure> method.

    ansi_fold($text, $width, boundary => 'word', ...);

    Text::ANSI::Fold->configure(boundary => 'word');

    my $f = new Text::ANSI::Fold boundary => 'word';

    $f->configure(boundary => 'word');

=over 7

=item B<width> => I<n>, I<[ n, m, ... ]>

Specify folding width.  Array reference can be specified but works
only with B<chops> method.

=item B<boundary> => "word"

B<boundary> option currently takes only "word" as a valid value.  In
this case, text is folded on word boundary.  This occurs only when
enough space will be provided to hold the word on next call with same
width.

=item B<padding> => I<bool>

If B<padding> option is given with true value, margin space is filled
up with space character.  Next code fills spaces if the given text is
shorter than 80.

    ansi_fold($text, 80, padding => 1);

=item B<padchar> => I<char>

B<padchar> option specifies character used to fill up the remainder of
given width.

    ansi_fold($text, 80, padding => 1, padchar => '_');

=item B<ambiguous> => "narrow" or "wide"

Tells how to treat Unicode East Asian ambiguous characters.  Default
is "narrow" which means single column.  Set "wide" to tell the module
to treat them as wide character.

=back

=head1 SEE ALSO

=over 7

=item L<App::ansifold>

Command line utility using L<Text::ANSI::Fold>.

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
#  LocalWords:  Utashiro
