package Text::VisualPrintf;

use v5.10;
use strict;
use warnings;
use Carp;

our $VERSION = "3.02";

use Exporter 'import';
our @EXPORT_OK = qw(&vprintf &vsprintf);

sub vprintf  { &printf (@_) }
sub vsprintf { &sprintf(@_) }

sub sprintf {
    my($format, @args) = @_;
    my $uniqstr = _sub_uniqstr($format, @args)
	or return CORE::sprintf $format, @args;
    my @replace;
    for (@args) {
	defined and /\P{ASCII}/ or next;
	my($replace, $regex, $len) = @{$uniqstr->($_) // next};
	push @replace, [ $regex, $_, $len ];
	$_ = $replace;
    }
    local $_ = CORE::sprintf $format, @args;
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

use Text::VisualWidth::PP;

sub _sub_uniqstr {
    local $_ = join '', @_;
    my @pair;
    for my $i (1 .. 255) {
	my $c = pack "C", $i;
	next if $c =~ /\s/ || /\Q$c/;
	push @pair, $c;
	if (@pair >= 2) {
	    my($a, $b) = @pair;
	    return sub {
		my $len = Text::VisualWidth::PP::width +shift;
		return undef if $len-- < 2;
		[ $a . ($b x $len), qr/\Q${a}${b}\E*/, ++$len ];
	    };
	}
    }
    return undef;
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

Version 3.02

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

=head1 AUTHOR

Kazumasa Utashiro

=head1 LICENSE

Copyright (C) 2011-2020 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
