package Text::VisualPrintf;

use v5.10;
use strict;
use warnings;
use Carp;

our $VERSION = "3.08";

use Exporter 'import';
our @EXPORT_OK = qw(&vprintf &vsprintf);

sub vprintf  { &printf (@_) }
sub vsprintf { &sprintf(@_) }

our $IS_TARGET = qr/[\e\P{ASCII}]/;

sub sprintf {
    my($format, @args) = @_;
    my $uniqstr = _sub_uniqstr($format, @args)
	or return CORE::sprintf $format, @args;
    my @replace;
    for my $arg (grep { defined } @args) {
	next unless ( ( ref $IS_TARGET eq 'Regexp' and $arg =~ $IS_TARGET ) or
		      ( ref $IS_TARGET eq 'CODE'   and $IS_TARGET->($arg) ) );
	my($replace, $regex, $len) = $uniqstr->($arg) or next;
	push @replace, [ $regex, $arg, $len ];
	$arg = $replace;
    }
    local $_ = CORE::sprintf $format, @args;
    while (@replace) {
	my($regex, $orig, $len) = @{shift @replace};
	# capture group is defined in $regex
	s/$regex/_replace($1, $orig, $len)/e;
    }
    $_;
}

sub printf {
    my $fh = ref($_[0]) =~ /^(?:GLOB|IO::)/ ? shift : select;
    $fh->print(&sprintf(@_));
}

sub _replace {
    my($matched, $orig, $len) = @_;
    my $width = length $matched;
    if ($width == $len) {
	$orig;
    } else {
	_trim($orig, $width);
    }
}

sub _trim {
    my($str, $width) = @_;
    use Text::ANSI::Fold;
    state $f = Text::ANSI::Fold->new(padding => 1);
    my($folded, $rest, $w) = $f->fold($str, width => $width);
    if ($w <= $width) {
	$folded;
    } elsif ($width == 1) {
	' '; # wide char not fit to single column
    } else {
	die "Panic"; # should never reach here...
    }
}

use Text::VisualWidth::PP;
our $VISUAL_WIDTH = \&Text::VisualWidth::PP::width;

sub _sub_uniqstr {
    local $_ = join '', @_;
    my @a;
    for my $i (1 .. 255) {
	my $c = pack "C", $i;
	next if $c =~ /\s/ || /\Q$c/;
	push @a, $c;
	last if @a >= @_;
    }
    return if @a < 2;
    my $lead = do { local $" = ''; qr/[^\Q@a\E]*+/ };
    my $b = pop @a;
    return sub {
	my $len = $VISUAL_WIDTH->(+shift);
	return if $len < 1;
	my $a = $a[ (state $n)++ % @a ];
	( $a . ($b x ($len - 1)), qr/\G${lead}\K(\Q${a}${b}\E*)/, $len );
    };
}

1;

__END__

=encoding utf-8

=head1 NAME

Text::VisualPrintf - printf family functions to handle Non-ASCII characters

=head1 SYNOPSIS

    use Text::VisualPrintf;
    Text::VisualPrintf::printf FORMAT, LIST
    Text::VisualPrintf::sprintf FORMAT, LIST

    use Text::VisualPrintf qw(vprintf vsprintf);
    vprintf FORMAT, LIST
    vsprintf FORMAT, LIST

=head1 VERSION

Version 3.08

=head1 DESCRIPTION

Text::VisualPrintf is a almost-printf-compatible library with a
capability of handling multi-byte wide characters properly.

When the given string is truncated by the maximum precision, space
character is padded if the wide character does not fit to the remained
space.

=head1 FUNCTIONS

=over 4

=item printf FORMAT, LIST

=item sprintf FORMAT, LIST

=item vprintf FORMAT, LIST

=item vsprintf FORMAT, LIST

Use just like perl's I<printf> and I<sprintf> functions
except that I<printf> does not take FILEHANDLE.

Take a look at an experimental C<Text::VisualPrintf::IO> if you want
to work with FILEHANDLE and printf.

=back

=head1 VARIABLES

=over 4

=item $VISUAL_WIDTH

Hold a function pointer to calculate visual width of given string.
Default function is C<Text::VisualWidth::PP::width>.

=back

=head1 IMPLEMENTATION NOTES

Strings in the LIST which contains wide-width character are replaced
before formatting, and recovered after the process.

Unique replacement string contains combinations of two ASCII
characters not found in the format string and all parameters.  If two
characters are not available, function behaves just like a standard
one.

=head1 SEE ALSO

L<Text::VisualPrintf>, L<Text::VisualPrintf::IO>

L<https://github.com/kaz-utashiro/Text-VisualPrintf>

L<Text::ANSI::Printf>

=head1 AUTHOR

Kazumasa Utashiro

=head1 LICENSE

Copyright 2011-2020 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
