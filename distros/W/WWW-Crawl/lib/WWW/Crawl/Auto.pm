package WWW::Crawl::Auto;

use strict;
use warnings;

use parent 'WWW::Crawl';

use URI;
use WWW::Crawl::Chromium;

our $VERSION = '0.5';
# $VERSION = eval $VERSION;

sub new {
    my $class = shift;
    my %attrs = @_;

    $attrs{'auto_min_bytes'} //= 512;
    $attrs{'retry_count'} //= 0;

    my $self = $class->SUPER::new(%attrs);

    $self->{'_chromium'} = WWW::Crawl::Chromium->new(%attrs);
    $self->{'_mode_by_authority'} = {};
    $self->{'_force_chromium'} = _normalize_host_list($attrs{'force_chromium'});
    $self->{'_force_http'} = _normalize_host_list($attrs{'force_http'});

    return $self;
}

sub _fetch_page {
    my ($self, $url) = @_;
    print STDERR "DEBUG: _fetch_page called for $url. Debug flag: " . ($self->{'debug'} // 'undef') . "\n" if $self->{'debug'};

    my $authority = _authority_for($url);

    if ($self->{'_force_chromium'}{$authority}) {
        $self->{'_mode_by_authority'}{$authority} = 'chromium';
        return $self->{'_chromium'}->_fetch_page($url);
    }
    if ($self->{'_force_http'}{$authority}) {
        $self->{'_mode_by_authority'}{$authority} = 'http';
        return $self->SUPER::_fetch_page($url);
    }

    my $mode = $self->{'_mode_by_authority'}{$authority};
    if ($mode && $mode eq 'chromium') {
        print STDERR "Use Chromium (forced): $url\n" if $self->{'debug'};
        return $self->{'_chromium'}->_fetch_page($url);
    }
    if ($mode && $mode eq 'http') {
        print STDERR "Use HTTP (forced): $url\n" if $self->{'debug'};
        return $self->SUPER::_fetch_page($url);
    }

    my $resp = $self->SUPER::_fetch_page($url);
    if ($resp->{'success'}) {
        if ($self->_should_use_chromium($url, $resp)) {
            my $chromium_resp = $self->{'_chromium'}->_fetch_page($url);
            if ($chromium_resp->{'success'}) {
                $self->{'_mode_by_authority'}{$authority} = 'chromium';
                print STDERR "Switched to Chromium: $url\n" if $self->{'debug'};
                return $chromium_resp;
            }
            # If Chromium failed but we decided we SHOULD use it, we shouldn't fallback to HTTP
            # because that returns raw dynamic logic which is useless.
            # However, if we return failure here, the crawl stops for this page.
            # But at least we don't poison the cache with 'http' mode.
            return $chromium_resp;
        }
        $self->{'_mode_by_authority'}{$authority} = 'http';
        return $resp;
    }

    if ($resp->{'status'} && $resp->{'status'} == 404) {
        $self->{'_mode_by_authority'}{$authority} = 'http';
        return $resp;
    }

    my $chromium_resp = $self->{'_chromium'}->_fetch_page($url);
    if ($chromium_resp->{'success'}) {
        $self->{'_mode_by_authority'}{$authority} = 'chromium';
        print STDERR "Use Chromium (fallback): $url\n" if $self->{'debug'};
        return $chromium_resp;
    }

    return $resp;
}

sub _should_use_chromium {
    my ($self, $url, $resp) = @_;
    print STDERR "DEBUG: _should_use_chromium checking $url\n" if $self->{'debug'};

    if ($self->{'auto_decider'} && ref $self->{'auto_decider'} eq 'CODE') {
        return $self->{'auto_decider'}->($url, $resp, $self) ? 1 : 0;
    }

    my $content = $resp->{'content'} // '';
    return 0 if $content eq '';

    my $headers = $resp->{'headers'} || {};
    my $ctype = $headers->{'content-type'} || $headers->{'Content-Type'} || '';
    if ($ctype ne '' && $ctype !~ m{\btext/html\b}i) {
        print STDERR "DEBUG: Not text/html ($ctype)\n" if $self->{'debug'};
        return 0;
    }

    if ($content =~ /data-capo/i) {
        print STDERR "DEBUG: Found data-capo\n" if $self->{'debug'};
        return 1;
    }

    if ($content =~ /<noscript[^>]*>.*?(enable javascript|requires javascript|turn on javascript|javascript required)/is) {
        print STDERR "DEBUG: Found noscript requirement\n" if $self->{'debug'};
        return 1;
    }
    if ($content =~ /id\s*=\s*["'](?:app|root|__next|__nuxt|svelte|react-root)["']/i) {
        print STDERR "DEBUG: Found SPA ID\n" if $self->{'debug'};
        return 1;
    }
    if ($content =~ /window\.(?:__NUXT__|__NEXT_DATA__)/i) {
        print STDERR "DEBUG: Found window.__NUXT__ or similar\n" if $self->{'debug'};
        return 1;
    }
    if (length($content) < $self->{'auto_min_bytes'} && $content =~ /<script\b/i) {
        print STDERR "DEBUG: Small content with script\n" if $self->{'debug'};
        return 1;
    }

    print STDERR "DEBUG: No indicators found. Content length: " . length($content) . "\n" if $self->{'debug'};
    return 0;
}

sub _authority_for {
    my ($url) = @_;
    my $uri = URI->new($url);
    return $uri ? ($uri->authority || $url) : $url;
}

sub _normalize_host_list {
    my ($list) = @_;
    return {} unless $list;
    my @hosts = ref $list eq 'ARRAY' ? @$list : ($list);
    my %map = map { $_ => 1 } @hosts;
    return \%map;
}

1;

__END__

=head1 NAME

WWW::Crawl::Auto - Crawl pages and automatically switch between HTTP and Chromium

=head1 VERSION

This documentation refers to WWW::Crawl::Auto version 0.5.

=head1 SYNOPSIS

    use WWW::Crawl::Auto;

    my $crawler = WWW::Crawl::Auto->new(
        chromium_path  => '/usr/bin/chromium',
        auto_min_bytes => 512,
    );

    my @visited = $crawler->crawl('https://example.com', \&process_page);

    sub process_page {
        my $url = shift;
        print "Visited: $url\n";
    }

=head1 DESCRIPTION

C<WWW::Crawl::Auto> uses the C<WWW::Crawl> crawling logic but decides, per
site, whether to fetch pages with C<HTTP::Tiny> or with a headless Chromium.
When a site is detected as dynamic, the crawler switches to Chromium for that
authority for the rest of the crawl.

=head1 OPTIONS

=over 4

=item *

C<force_chromium>: A hostname (or arrayref of hostnames) to always fetch with
Chromium.

=item *

C<force_http>: A hostname (or arrayref of hostnames) to always fetch with
HTTP::Tiny.

=item *

C<auto_min_bytes>: Minimum response size to consider a static page. Defaults
to 512.

=item *

C<auto_decider>: Coderef invoked as C<auto_decider-E<gt>($url, $resp, $self)>
to decide whether Chromium should be used. Return true to use Chromium.

=item *

C<retry_count>: Number of times to retry Chromium fetches before giving up.
Defaults to 0.

=item *

C<debug>: Enable debug logging to STDERR when set to a true value.

=back

=head1 CONSTRUCTOR

=head2 new(%options)

Creates a new C<WWW::Crawl::Auto> object. Options are the same as
C<WWW::Crawl>, plus the options listed above.

=head1 METHODS

All public methods are inherited from C<WWW::Crawl>.

=head1 AUTHOR

Ian Boddison, C<< <bod at cpan.org> >>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2023-2026 by Ian Boddison.

This program is released under the following license:

  Perl

=cut
