package Text::VisualPrintf;

use v5.10;
use strict;
use warnings;

our $VERSION = "2.03";

use strict;
use warnings;
use Carp;

use Exporter 'import';
our @EXPORT_OK = qw(&vprintf &vsprintf);

sub vprintf  { &printf (@_) }
sub vsprintf { &sprintf(@_) }

sub sprintf {
    my($format, @args) = @_;

    my $uniqstr = _sub_uniqstr($format, @args)
	or return CORE::sprintf($format, @args);

    my @list;
    for (@args) {
	defined and /\P{ASCII}/ or next;
	my $replacement = $uniqstr->($_) // next;
	push @list, $replacement => $_;
	$_ = $replacement;
    }
    my $result = CORE::sprintf($format, @args);
    while (my($tmp, $orig) = splice(@list, 0, 2)) {
	$result =~ s/$tmp/$orig/;
    }
    $result;
}

sub printf {
    my $fh = ref $_[0] eq 'GLOB' ? shift : select;
    $fh->printf(&sprintf(@_));
}

use Text::VisualWidth::PP;

sub _sub_uniqstr {
    my $format = shift;
    my @seq;

  LOOP:
    for my $i (1 .. 5) {
	for my $j (1 .. 5) {
	    my $seq = pack "CC", $i, $j;
	    push(@seq, $seq) if index($format, $seq) < 0;
	    last LOOP if @seq >= @_;
	}
    }
    return undef if @seq == 0;

    my $n = 0;
    sub {
	my $len = Text::VisualWidth::PP::width(shift);
	return undef if $len < 2;
	CORE::sprintf("%s%s", $seq[$n++ % @seq], "_" x ($len - 2));
    }
}

1;

__END__

=encoding utf-8

=head1 NAME

Text::VisualPrintf - printf family functions to handle Non-ASCII characters

=head1 SYNOPSIS

    use Text::VisualPrintf;
    Text::VisualPrintf::printf(FORMAT, LIST)
    Text::VisualPrintf::sprintf(FORMAT, LIST)

    use Text::VisualPrintf qw(vprintf vsprintf);
    vprintf(FORMAT, LIST)
    vsprintf(FORMAT, LIST)


=head1 DESCRIPTION

Text::VisualPrintf is a almost-printf-compatible library with a
capability of handling multi-byte wide characters properly.

=head1 FUNCTIONS

=over 4

=item printf(FORMAT, LIST)

=item sprintf(FORMAT, LIST)

=item vprintf(FORMAT, LIST)

=item vsprintf(FORMAT, LIST)

Use just like perl's I<printf> and I<sprintf> functions
except that I<printf> does not take FILEHANDLE as a first argument.

=back

=head1 IMPLEMENTATION NOTES

Strings in the LIST which contains wide-width character are replaced
before formatting, and recovered after the process.

Unique replacement string contains a combination of control characters
(Control-A to Control-E).  If the FORMAT contains all of these two
bytes combinations, the function behaves just like a standard one.

=head1 SEE ALSO

L<Text::VisualWidth::PP>

L<https://github.com/kaz-utashiro/Text-VisualPrintf>

=head1 AUTHOR

Kaz Utashiro

=head1 LICENSE

Copyright (C) 2011-2017 Kaz Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
