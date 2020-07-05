# vim:ts=4:shiftwidth=4:expandtab
use 5.026;
use strict;
use warnings;

package Text::Mrkdwn::Escape;

our $VERSION = '0.01'; # VERSION

our (@ISA, @EXPORT_OK);
use parent qw/ Exporter /;
BEGIN {
    @EXPORT_OK = qw/ escape_to_mrkdwn /;
}

=head1 NAME

Text::Mrkdwn::Escape - Escape text for inclusion in mrkdwn

=head1 SYNOPSIS

    my $str = Text::Mrkdwn::Escape::escape_to_mrkdwn("*Hello*!");

=head1 DESCRIPTION

I<mrkdwn> is a variant of the Markdown text formatting system. It is used by
the Slack API. This module is for escaping text, which may contain special
characters for inclusion in mrkdwn text.

=head1 FUNCTIONS

=head2 escape

    my $escaped_string = escape_to_mrkdwn($string);

Escapes characters which may cause formatting with a backslash.

=cut

sub escape_to_mrkdwn {
    my ($str) = @_;

    $str =~ s/([\x21-\x45 \x2f \x3a-\x40 \x5b-\x60 \x7b-\x7e])/\\$1/gxx;

    return $str;
}

1;

=head1 SEE ALSO

=over

=item *

L<https://github.com/benvacha/mrkdwn>

=item *

L<https://api.slack.com/reference/surfaces/formatting#basics>

=back

=head1 AUTHOR

Dave Lambley <dlambley@cpan.org>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
