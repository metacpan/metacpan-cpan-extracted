package Text::VisualPrintf;

use v5.10;
use strict;
use warnings;
use Carp;

our $VERSION = "3.01";

use Exporter 'import';
our @EXPORT_OK = qw(&vprintf &vsprintf);

sub vprintf  { &printf (@_) }
sub vsprintf { &sprintf(@_) }

sub sprintf {
    my($format, @args) = @_;
    my $uniqstr = _sub_uniqstr($format, @args)
	or return CORE::sprintf($format, @args);
    my @replace;
    for (@args) {
	defined and /\P{ASCII}/ or next;
	my($replace, $regex, $len) = @{$uniqstr->($_) // next};
	push @replace, [ $regex, $_, $len ];
	$_ = $replace;
    }
    local $_ = CORE::sprintf($format, @args);
    while (@replace) {
	my($regex, $orig, $len) = @{shift @replace};
	s/($regex)/_replace($1, $orig, $len)/e;
    }
    $_;
}

sub printf {
    my $fh = ref($_[0]) =~ /^(?:GLOB|IO::)/ ? shift : select;
    $fh->print(&sprintf(@_));
}

use Text::VisualWidth::PP;

sub _replace {
    my($matched, $orig, $len) = @_;
    if ((my $width = length $matched) == $len) {
	$orig;
    } else {
	require Text::ANSI::Fold;
	Text::ANSI::Fold
	    ->new(text => $orig, width => $width, padding => 1)
	    ->retrieve;
    }
}

sub _sub_uniqstr {
    my $format = shift;
    my @seq;

  LOOP:
    for my $i (1 .. 5) {
	for my $j (1 .. 5) {
	    next if $i == $j;
	    my($c1, $c2) = map pack("C", $_), $i, $j;
	    next if @seq and $seq[-1][1] eq $c1;
	    push @seq, [$c1, $c2] if index($format, $c1.$c2) < 0;
	    last LOOP if @seq >= @_;
	}
    }
    return undef if @seq == 0;

    my $n = 0;
    sub {
	my $len = Text::VisualWidth::PP::width +shift;
	return undef if $len-- < 2;
	my($c1, $c2) = @{$seq[$n++ % @seq]};
	my $replace = $c1 . ($c2 x $len);
	my $regex = qr/${c1}${c2}{1,$len}/;
	[ $replace, $regex, ++$len ];
    }
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

Version 3.01

=head1 DESCRIPTION

Text::VisualPrintf is a almost-printf-compatible library with a
capability of handling multi-byte wide characters properly.

When the given string is truncated by the maximum precision, space
character is padded if the wide character does not fit to the remained
space.  It fails with the target width less than two.

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

=head1 IMPLEMENTATION NOTES

Strings in the LIST which contains wide-width character are replaced
before formatting, and recovered after the process.

Unique replacement string contains combinations of control characters
(Control-A to Control-E).  If the FORMAT contains all of these two
bytes combinations, the function behaves just like a standard one.

Because this mechanism expects at least two bytes of string can be
found in the formatted text, it does not work when the string is
truncated to one.

=head1 SEE ALSO

L<Text::VisualPrintf::IO>

L<Text::VisualWidth::PP>

L<https://github.com/kaz-utashiro/Text-VisualPrintf>

=head1 AUTHOR

Kazumasa Utashiro

=head1 LICENSE

Copyright (C) 2011-2020 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
