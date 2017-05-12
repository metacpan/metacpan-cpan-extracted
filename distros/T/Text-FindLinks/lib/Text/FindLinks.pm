package Text::FindLinks;

=encoding utf8

=head1 NAME

Text::FindLinks - Find and markup URLs in plain text

=cut

use warnings;
use strict;
use Exporter;
use Params::Validate qw/validate CODEREF/;

our @ISA = 'Exporter';
our @EXPORT_OK = qw/find_links markup_links/;
our $VERSION = '0.04';

=head1 SYNOPSIS

    use Text::FindLinks 'markup_links';
    my $text = "Have you seen www.foo.com yet?";
    # Have you seen <a href="http://www.foo.com">http://www.foo.com</a> yet?
    print markup_links(text => $text);

=head1 FUNCTIONS

=head2 markup_links(text => ..., [handler => sub { ... }])

Finds all URLs in the given text and replaces them using
the given handler. The handler gets passed three arguments:
the URL itself, all the text to the left from it and all the
text to the right. (The context is passed in case you would
like to keep some URLs untouched.) If no handler is given,
the default handler will be used that simply creates a link
to the URL and skips URLs already turned into links.

=cut

sub markup_links
{
    validate(@_,
    {
        text    => 1,
        handler =>
        {
            type     => CODEREF,
            optional => 1,
        },
    });

    my %args = @_;
    my $text = $args{'text'};
    my $decorator = $args{'handler'} || \&decorate_link;

    $text =~ s{(
        (
            (((https?)|(ftp))://)   # either a schema...
            | (www\.)               # or the ‘www’ token
        )
        [^\s<]+                     # anything except whitespace and ‘<’
        (?<![,.;?!])                # must not end with given characters
        )}
        {&$decorator($1, $`, $')}gex;

    return $text;
}

=head2 find_links(text => ...)

Returns an array with all the URLs found in given text.
Just a simple wrapper around C<markup_links>, see the
sources.

=cut

sub find_links
{
    validate(@_, { text => 1 });
    my %args = @_;
    my @links;
    markup_links(
        text    => $args{'text'},
        handler => sub { push @links, shift });
    return @links;
}

=head2 decorate_link($url, $left, $right)

Default URL handler that will be used if you don’t pass your
own to the C<markup_links> sub using the C<handler> attribute.
It turns an URL into a HTML link and skips URLs that are
apparently already links. Not exported.

=cut

sub decorate_link
{
    my ($url, $left, $right) = @_;

    # Skip already marked links.
    return $url if ($left =~ /href=["']$/);
    return $url if ($right =~ qr|^</a>|);

    my $label = $url;
    $url = "http://$url" if ($url =~ /^www/i);
    return qq|<a href="$url">$label</a>|;
}

=head1 BUGS

The algorithm is extremely naive, a simple regex. It is almost
certain that some URLs will not be recognized and some things
that are not URLs will (to keep the balance). I’d be glad to
hear if there is some URL that misbehaves.

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Text-FindLinks>

=head1 AUTHOR

Tomáš Znamenáček, zoul@fleuron.cz

L<http://github.com/zoul/Text-FindLinks>

=head1 COPYRIGHT & LICENSE

Copyright 2009 Tomáš Znamenáček

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.

=cut

1;
