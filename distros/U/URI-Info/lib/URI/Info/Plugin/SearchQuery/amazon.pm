package URI::Info::Plugin::SearchQuery::amazon;

use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-06-21'; # DATE
our $DIST = 'URI-Info'; # DIST
our $VERSION = '0.004'; # VERSION

use parent 'URI::Info::PluginBase';

sub meta {
    return {
        summary => 'Extract search query from Amazon URL',
        conf => {
        },

        host => [
            'amazon.ae',
            'amazon.ca',
            'amazon.cn',
            'amazon.co.jp',
            'amazon.com',
            'amazon.com.au',
            'amazon.com.be',
            'amazon.com.br',
            'amazon.com.mx',
            'amazon.com.tr',
            'amazon.co.uk',
            'amazon.de',
            'amazon.eg',
            'amazon.es',
            'amazon.fr',
            'amazon.in',
            'amazon.it',
            'amazon.nl',
            'amazon.sa',
            'amazon.se',
            'amazon.sg',
        ],
    };
}

sub get_info {
    my ($self, $stash) = @_;
    my $url = $stash->{url};
    my $res = $stash->{res};

    if ($url->full_path =~ m!\A/s\?!) {
        $res->{is_search} = 1;
        $res->{search_source} = 'amazon';
        $res->{search_query} =
            $url->query_param('k') //
            $url->query_param('field-keywords');
    }
    [200]; # 200=OK, 201=OK & skip the rest of the plugins, 500=error
}

1;
# ABSTRACT:

__END__

=pod

=encoding UTF-8

=head1 NAME

URI::Info::Plugin::SearchQuery::amazon

=head1 VERSION

This document describes version 0.004 of URI::Info::Plugin::SearchQuery::amazon (from Perl distribution URI-Info), released on 2023-06-21.

=for Pod::Coverage .+

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/URI-Info>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-URI-Info>.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 CONTRIBUTING


To contribute, you can send patches by email/via RT, or send pull requests on
GitHub.

Most of the time, you don't need to build the distribution yourself. You can
simply modify the code, then test via:

 % prove -l

If you want to build the distribution (e.g. to try to install it locally on your
system), you can install L<Dist::Zilla>,
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>,
L<Pod::Weaver::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla- and/or Pod::Weaver plugins. Any additional steps required beyond
that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023, 2021 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=URI-Info>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
