package Text::VisualPrintf;

our $VERSION = "4.01";

use v5.14;
use warnings;
use Carp;

use Exporter 'import';
our @EXPORT_OK = qw(&vprintf &vsprintf);

use Data::Dumper;
use Text::Conceal;

sub vprintf  { &printf (@_) }
sub vsprintf { &sprintf(@_) }

use Text::VisualWidth::PP;
our $IS_TARGET = qr/[\e\b\P{ASCII}]/;
our $VISUAL_WIDTH = \&Text::VisualWidth::PP::width;

sub sprintf {
    my($format, @args) = @_;
    my $conceal = Text::Conceal->new(
	except => $format,
	test   => $IS_TARGET,
	length => $VISUAL_WIDTH,
	max    => int @args,
	);
    $conceal->encode(@args) if $conceal;
    my $s = CORE::sprintf $format, @args;
    $conceal->decode($s)    if $conceal;
    $s;
}

sub printf {
    my $fh = ref($_[0]) =~ /^(?:GLOB|IO::)/ ? shift : select;
    $fh->print(&sprintf(@_));
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

Version 4.01

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

Hold a function reference to calculate visual width of given string.
Default function is C<Text::VisualWidth::PP::width>.

=item $IS_TARGET

Hold a regexp object of funciton reference to test if the given string
is subject of replacement.  Default is C<qr/[\e\b\P{ASCII}]/>, and
test if the string include C<ESCAPE> or C<BACKSPACE> or non-ASCII
characters.

=back

=head1 IMPLEMENTATION NOTES

Strings in the LIST which contains wide-width character are replaced
before formatting, and recovered after the process.

Unique replacement string contains combinations of two ASCII
characters not found in the format string and all parameters.  If two
characters are not available, function behaves just like a standard
one.

=head1 SEE ALSO

L<Text::VisualPrintf>, L<Text::VisualPrintf::IO>,
L<https://github.com/kaz-utashiro/Text-VisualPrintf>

L<Text::Conceal>, L<https://github.com/kaz-utashiro/Text-Conceal>

L<Text::ANSI::Printf>, L<https://github.com/kaz-utashiro/Text-ANSI-Printf>

=head1 AUTHOR

Kazumasa Utashiro

=head1 LICENSE

Copyright 2011-2020 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
