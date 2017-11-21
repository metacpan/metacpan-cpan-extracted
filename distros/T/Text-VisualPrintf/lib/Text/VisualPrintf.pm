package Text::VisualPrintf;

use v5.10;
use strict;
use warnings;

our $VERSION = "2.01";

use strict;
use warnings;
use Carp;

use Exporter 'import';
our @EXPORT_OK = qw(&vprintf &vsprintf);

sub vprintf  { &printf (@_) }
sub vsprintf { &sprintf(@_) }

sub sprintf {
    my($format, @args) = @_;
    my @list;

    my $uniqstr = _sub_uniqstr();
    for my $arg (@args) {
	next if not defined $arg;
	next if $arg !~ /\P{ASCII}/;
	push @list, $arg;
	push @list, $arg = $uniqstr->($arg);
    }
    my $result = CORE::sprintf($format, @args);
    while (my($orig, $tmp) = splice(@list, 0, 2)) {
	$result =~ s/$tmp/$orig/;
    }
    $result;
}

sub printf ($$@) {
    my $fh = ref $_[0] eq 'GLOB' ? shift : select;
    $fh->printf(&sprintf(@_));
}

use Text::VisualWidth::PP;

sub _sub_uniqstr {
    my $n = 0;
    sub {
	my $len = Text::VisualWidth::PP::width(shift)
	    or croak "Unexpected input.";
	$len == 1 and return "\006";
	$n > 25 and $n = 25;
	my $s = pack("CC", $n / 5 + 1, $n % 5 + 1) . ("_" x ($len - 2));
	$n++;
	$s;
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
(Control-A to Control-E).  So, if the FORMAT contains a string in this
range, it has a chance to be a subject of replacement.

Single half-width multi-byte character is exception, and all
represented by single octal 006 (Control-F) character.  It may sounds
odd, but they are converted to proper string because the order is
preserved.  Same thing can be done for longer arguments, and when the
number or arguments exceeds 25, they are encoded by same code.

=head1 SEE ALSO

L<Text::VisualWidth::PP>

=head1 AUTHOR

Kaz Utashiro

=head1 LICENSE

Copyright (C) 2011-2017 Kaz Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
