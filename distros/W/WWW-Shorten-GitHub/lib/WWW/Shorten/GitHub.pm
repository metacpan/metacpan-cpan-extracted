package WWW::Shorten::GitHub;

# ABSTRACT: Shorten GitHub URLs using GitHub's URL shortener - git.io

=head1 NAME

WWW::Shorten::GitHub - Shorten GitHub URLs using GitHub's URL shortener - git.io

=head1 SYNOPSIS

This module provides a perl interface to GitHub's URL shortening service, git.io.

It allows you to shorten any GitHub URL, and also retrieve the original URL from
a pre-shortened URL

=head1 USAGE

    use WWW::Shorten 'GitHub';

    my $long_url = 'https://github.com/LoonyPandora/WWW-Shorten-GitHub';

    my $short_url = makeashorterlink($long_url);

=cut


use strict;
use warnings;
use base qw(WWW::Shorten::generic Exporter);

our @EXPORT = qw(makeashorterlink makealongerlink);
our $VERSION = '0.1.7';

use Carp;
use URI;

sub makeashorterlink {
    my $url = shift or croak 'No URL passed to makeashorterlink';

    my $host = URI->new($url)->host();
    if ($host !~ m/^(gist\.)?github\.com$/) {
        croak "Git.io only shortens URLs under the github.com domain";
    }

    my $ua = __PACKAGE__->ua();
    my $response = $ua->post('https://git.io/create', [
        url    => $url,
        source => 'PerlAPI-' . (defined __PACKAGE__->VERSION ? __PACKAGE__->VERSION : 'dev'),
        format => 'simple',
    ]);

    if ($response->header('Status') eq '200 OK') {
        return 'http://git.io/' . $response->decoded_content;
    }

    return;
}


sub makealongerlink {
    my $token = shift or croak 'No URL / Git.io token passed to makealongerlink';

    my $url = URI->new($token);

    unless ($url->scheme() && $url->host() eq 'git.io') {
        $url->scheme('https');
        $url->host('git.io');
        $url->path($token);
    }

    my $ua = __PACKAGE__->ua();
    my $response = $ua->get($url->as_string);

    if ($response->is_redirect) {
        return $response->header('Location');
    }

    return;
}

1;

=head1 CAVEATS

Git.io only shortens URLs on github.com and its subdomains.

It is not a general purpose URL shortener.

=head1 SEE ALSO

L<WWW::Shorten>, L<http://git.io/help>

=head1 AUTHOR

James Aitken <jaitken@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by James Aitken.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
