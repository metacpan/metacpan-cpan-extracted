package Text::VisualPrintf;

our $VERSION = "4.03";

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
our $REORDER //= 0;

sub sprintf {
    my($format, @args) = @_;
    my $conceal = Text::Conceal->new(
	except    => $format,
	test      => $IS_TARGET,
	length    => $VISUAL_WIDTH,
	max       => int @args,
	ordered   => ! $REORDER,
	duplicate => !!$REORDER,
    ) || goto &CORE::sprintf;
    ($conceal->decode(CORE::sprintf($format,
				    $conceal->encode(@args))))[0];
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

Version 4.03

=head1 DESCRIPTION

B<Text::VisualPrintf> is a almost-printf-compatible library with a
capability of handling:

    - Multi-byte wide characters
    - Combining characters
    - Backspaces

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

=item $REORDER

The original C<printf> function has the ability to specify the
arguments to be targeted by the position specifier, but by default
this module assumes that the arguments will appear in the given order,
so you will not get the expected result. If you wish to use it, set
the package variable C<$REORDER> to 1.

By doing so, the order in which arguments appear can be changed and
the same argument can be processed even if it appears more than once.

=back

=head1 IMPLEMENTATION NOTES

Strings in the LIST which contains wide-width character are replaced
before formatting, and recovered after the process.  Replacement is
implemented in the L<Text::Conceal> module.

=head1 SEE ALSO

L<Text::VisualPrintf>, L<Text::VisualPrintf::IO>,
L<https://github.com/tecolicom/Text-VisualPrintf>

L<Text::Conceal>, L<https://github.com/tecolicom/Text-Conceal>

L<Text::ANSI::Printf>, L<https://github.com/tecolicom/Text-ANSI-Printf>

=head1 AUTHOR

Kazumasa Utashiro

=head1 LICENSE

Copyright 2011-2023 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
