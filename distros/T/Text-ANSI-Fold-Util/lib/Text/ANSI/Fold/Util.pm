package Text::ANSI::Fold::Util;
our $VERSION = "0.01";

use v5.14;
use utf8;
use warnings;
use Data::Dumper;

use Exporter qw(import);
our @EXPORT_OK = qw(&ansi_width &ansi_substr);
our %EXPORT_TAGS = ( all => [ @EXPORT_OK ] );

use List::Util qw(max);
use Text::ANSI::Fold qw(ansi_fold);

=encoding utf-8

=head1 NAME

Text::ANSI::Fold::Util - Text::ANSI::Fold utilities

=head1 SYNOPSIS

    use Text::ANSI::Fold::Util qw(:all);
    use Text::ANSI::Fold::Util qw(ansi_width ansi_substr);
    ansi_width($text);
    ansi_substr($text, $offset, $width [, $replacement]);

    use Text::ANSI::Fold::Util;
    Text::ANSI::Fold::Util::width($text);
    Text::ANSI::Fold::Util::substr($text, ...);

=head1 DESCRIPTION

This is a collection of utilities using Text::ANSI::Fold module.

=head1 FUNCTION

There are exportable functions start with B<ansi_> prefix, and
unexportable functions without them.

=over 7

=cut


=item B<width>(I<text>)

=item B<ansi_width>(I<text>)

Returns visual width of given text.

=cut

sub ansi_width {
    goto &width;
}

sub width {
    (ansi_fold($_[0], -1))[2];
}


=item B<substr>(I<text>, I<offset>, I<width> [, I<replacement>])

=item B<ansi_substr>(I<text>, I<offset>, I<width> [, I<replacement>])

Returns substring just like Perl's B<substr> function, but string
position is calculated by the visible width on the screen instead of
number of characters.

If an optional I<replacemnt> parameter is given, replace the substring
by the replacement and return the entire string.

It does not cut the text in the middle of multi-byte character, of
course.  Its behavior depends on the implementation of lower module.

=cut

sub ansi_substr {
    goto &substr;
}

sub substr {
    my($text, $offset, $length, $replacement) = @_;
    if ($offset < 0) {
	$offset = max(0, $offset + ansi_width($text));
    }
    my @s = Text::ANSI::Fold
	->new(text => $text, width => [ $offset, $length // -1, -1 ])
	->chops;
    if (defined $replacement) {
	$s[0] . $replacement . ($s[2] // '');
    } else {
	$s[1];
    }
}

=back

=cut

1;

__END__

=head1 SEE ALSO

L<Text::ANSI::Fold>

=head1 LICENSE

Copyright (C) 2020 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Kazumasa Utashiro E<lt>kaz@utashiro.comE<gt>

=cut
