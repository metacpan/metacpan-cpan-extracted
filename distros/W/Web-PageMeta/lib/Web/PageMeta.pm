package Web::PageMeta;

our $VERSION = '0.09';

use 5.010;
use Moose;
use MooseX::Types::URI qw(Uri);
use MooseX::StrictConstructor;
use URI;
use URI::QueryParam;
use Log::Any qw($log);
use Future;
use Future::AsyncAwait;
use Future::HTTP::AnyEvent;
use Web::Scraper::LibXML;
use Encode qw(find_mime_encoding);
use Time::HiRes qw(time);
use HTTP::Exception;
use List::Util qw(pairmap);

use namespace::autoclean;

has 'url' => (
    isa      => Uri,
    is       => 'ro',
    required => 1,
    coerce   => 1,
);

has 'timeout' => (
    isa      => 'Int',
    is       => 'rw',
    required => 1,
    default  => 5 * 60,
);

has 'max_size' => (
    isa      => 'Int',
    is       => 'rw',
    required => 1,
    default  => 100 * 1024 * 1024,
);

has 'user_agent' => (
    isa      => 'Str',
    is       => 'ro',
    required => 1,
    default =>
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/89.0.4389.90 Safari/537.36',
    lazy => 1,
);

has 'extra_headers' => (
    isa      => 'HashRef',
    is       => 'ro',
    required => 1,
    default  => sub {{}},
    lazy     => 1,
);

has 'cookie_jar' => (
    isa       => 'Object',
    is        => 'ro',
    predicate => 'has_cookie_jar',
);

has 'title' => (
    isa     => 'Str',
    is      => 'ro',
    lazy    => 1,
    default => sub {return $_[0]->page_meta->{title} // ''},
);
has 'image' => (
    isa     => 'Str',
    is      => 'ro',
    lazy    => 1,
    default => sub {return $_[0]->page_meta->{image} // ''},
);
has 'description' => (
    isa     => 'Str',
    is      => 'ro',
    lazy    => 1,
    default => sub {return $_[0]->page_meta->{description} // ''},
);

has 'canonical_url' => (
    isa     => Uri,
    is      => 'ro',
    lazy    => 1,
    default => sub {return $_[0]->page_meta->{url} // $_[0]->url},
);

has 'image_data' => (
    isa     => 'Str',
    is      => 'ro',
    lazy    => 1,
    default => sub {$_[0]->fetch_image_data_ft->get},
);

has 'page_meta' => (
    isa     => 'HashRef',
    is      => 'rw',
    lazy    => 1,
    default => sub {$_[0]->fetch_page_meta_ft->get},
);

has 'page_body_hdr' => (
    isa     => 'ArrayRef',
    is      => 'ro',
    lazy    => 1,
    default => sub {$_[0]->fetch_page_body_hdr_ft->get},
);

has 'fetch_page_body_hdr_ft' => (
    isa     => 'Future',
    is      => 'ro',
    lazy    => 1,
    builder => '_build__fetch_page_body_hdr_ft',
);

has 'fetch_page_meta_ft' => (
    isa     => 'Future',
    is      => 'ro',
    lazy    => 1,
    builder => '_build__fetch_page_meta_ft',
);

has 'fetch_image_data_ft' => (
    isa     => 'Future',
    is      => 'ro',
    lazy    => 1,
    builder => '_build__fetch_image_data_ft',
);

has '_ua' => (
    is      => 'ro',
    lazy    => 1,
    default => sub {Future::HTTP::AnyEvent->new()},
);

has '_html_meta_scraper' => (
    is      => 'ro',
    lazy    => 1,
    builder => '_build__html_meta_scraper',
);

has 'extra_scraper' => (
    is        => 'ro',
    predicate => 'has_extra_scraper',
);

sub _build__html_meta_scraper {
    state $html_meta_scraper = scraper {
        process '/html/head/meta[contains(@property, "og:")]',
            'head_meta_og[]' => {
            key => '@property',
            val => '@content',
            };
        process '/html/head/title',                     'title'       => 'TEXT';
        process '/html/head/meta[@name="description"]', 'description' => '@content';
        process '/html/head/base',                      'base_href'   => '@href';
    };
    return $html_meta_scraper;
}

sub compile_headers {
    my ($self) = @_;

    my %headers = (
        'Accept' => 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
        'User-Agent' => $self->user_agent,
    );
    if ($self->has_cookie_jar) {
        my $cookies = $self->cookie_jar->get_cookies($self->url);
        if (%$cookies) {
            $headers{'Cookie'} = join("; ", pairmap {$a . "=" . $b} %$cookies);
            $headers{'Cookie2'} = '$Version="1"';
        }
    }
    %headers = (%headers, %{$self->extra_headers});
    return \%headers;
}

async sub _build__fetch_page_body_hdr_ft {
    my ($self) = @_;

    # await url htmp http download
    my $timer      = time();
    my $timeout    = $self->timeout;
    my $timeout_at = $timer + $timeout;
    my $max_size   = $self->max_size;
    my $cur_size   = 0;
    my $body = '';
    my ( undef, $headers ) = await $self->_ua->http_get(
        $self->url,
        headers   => $self->compile_headers,
        timeout   => $timeout,
        on_header => sub {
            my ($hdrs) = @_;
            my $content_type = $hdrs->{"content-type"} || '';
            if ($content_type =~ /^text\/html\s*(?:;|$)/i) {
                return 1;
            }
            elsif ($hdrs->{Status} != 200) {
                # non-200 status handled below with exception
                return 1;
            }
            else {
                $log->warnf( 'unsupported content-type "%s", status "%d", fetching %s',
                    $content_type, $hdrs->{Status}, $self->url );
                return 0;
            }
        },
        on_body => sub {
            my ( $part_body, undef ) = @_;

            $body .= $part_body;

            if ( time() > $timeout_at ) {
                $log->warnf( 'timeout %ds fetching %s',
                    $timeout, $self->url );
                return 0;
            }

            $cur_size += length($part_body);
            if ($cur_size > $max_size) {
                $log->warnf( 'max size %d exceeded with %d fetching %s',
                    $max_size, $cur_size, $self->url );
                return 0;
            }

            return 1;
        },
    );
    my $status = _get_update_status_reason($headers);
    $log->debugf('page meta fetch %d %s finished in %.3fs', $status, $self->url, time() - $timer);
    HTTP::Exception->throw($status, status_message => $headers->{Reason})
        if ($status != 200);

    return [$body, $headers];
}

async sub _build__fetch_page_meta_ft {
    my ($self) = @_;

    my ( $body, $headers ) = @{await $self->fetch_page_body_hdr_ft};

    # turn body to utf-8
    if (my $content_type = $headers->{'content-type'}) {
        if (my ($charset) = ($content_type =~ m/\bcharset=(.+)/)) {
            if (my $decoder = find_mime_encoding($charset)) {
                $body = $decoder->decode($body);
            }
        }
    }

    # scrape default head meta
    my $scraper_data = $self->_html_meta_scraper->scrape(\$body);
    my %page_meta    = (
        title       => $scraper_data->{title} // '',
        description => $scraper_data->{description} // '',
    );
    foreach my $attr (@{$scraper_data->{head_meta_og} // []}) {
        my $key = $attr->{key};
        my $val = $attr->{val};
        next unless $key =~ m/^og:(.+)$/;
        $page_meta{$1} = $val;
    }

    # do any other extra scraping
    if ($self->has_extra_scraper) {
        my $escraper_data = $self->extra_scraper->scrape(\$body);
        foreach my $key (keys %{$escraper_data}) {
            $page_meta{$key} = $escraper_data->{$key};
        }
    }

    # make image links absolute
    if ($page_meta{image}) {
        my $base_url = (
            $scraper_data->{base_href}
            ? URI::WithBase->new($scraper_data->{base_href}, $self->url)->abs->as_string
            : $self->url
        );
        $page_meta{image} = URI::WithBase->new($page_meta{image}, $base_url)->abs->as_string;
    }

    return $self->page_meta(\%page_meta);
}

async sub _build__fetch_image_data_ft {
    my ($self) = @_;

    # await for image link
    await $self->fetch_page_meta_ft;
    my $fetch_url = $self->image;
    HTTP::Exception->throw(404, status_message => 'No image found')
        unless $fetch_url;

    # await image http download
    my $timer      = time();
    my $timeout    = $self->timeout;
    my $timeout_at = $timer + $timeout;
    my $max_size   = $self->max_size;
    my $cur_size   = 0;
    my $body       = '';
    my ( undef, $headers ) = await $self->_ua->http_get(
        $fetch_url,
        headers => $self->compile_headers,
        on_body => sub {
            my ( $part_body, undef ) = @_;

            $body .= $part_body;

            if ( time() > $timeout_at ) {
                $log->warnf( 'timeout %ds fetching %s',
                    $timeout, $self->url );
                return 0;
            }

            $cur_size += length($part_body);
            if ( $cur_size > $max_size ) {
                $log->warnf( 'max size %d exceeded with %d fetching %s',
                    $max_size, $cur_size, $self->url );
                return 0;
            }

            return 1;
        },
    );
    my $status = _get_update_status_reason($headers);
    $log->debugf('img fetch %d %s for %s finished in %.3fs',
        $status, $fetch_url, $self->url, time() - $timer);
    HTTP::Exception->throw($status, status_message => $headers->{Reason})
        if ($status != 200);

    return $self->{image_data} = $body;
}

sub _get_update_status_reason {
    my ($headers) = @_;
    my $status = $headers->{Status};
    unless (HTTP::Status::status_message($status)) {
        $headers->{Reason} = sprintf('(%d) %s', $status, $headers->{Reason});
        $status = $headers->{Status} = 503;
    }
    return $status;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

Web::PageMeta - get page open-graph / meta data

=head1 SYNOPSIS

    use Web::PageMeta;
    my $page = Web::PageMeta->new(url => "https://www.apa.at/");
    say $page->title;
    say $page->image;

async fetch previews and images:

    use Web::PageMeta;
    my @urls = qw(
        https://www.apa.at/
        http://www.diepresse.at/
        https://metacpan.org/
        https://github.com/
    );
    my @page_views = map { Web::PageMeta->new( url => $_ ) }
            @urls;
    Future->wait_all( map { $_->fetch_image_data_ft, } @page_views )->get;
    foreach my $pv (@page_views) {
        say 'title> '.$pv->title;
        say 'img_size> '.length($pv->image_data);
    }

    # alternativelly instead of Future->wait_all()
    use Future::Utils qw( fmap_void );
    fmap_void(
        sub { return $_[0]->fetch_image_data_ft },
        foreach    => [@page_views],
        concurrent => 3
    )->get;

=head1 DESCRIPTION

Get (not only) open-graph web page meta data. can be used in both normal
and async code.

For any other than 200 http status codes during data downloads,
L<HTTP::Exception> is thrown.

=head1 ACCESSORS

=head2 new

Constructor, only L</url> is required.

=head2 url

HTTP url to fetch data from.

=head2 timeout

In addition to L<AnyEvent::HTTP> timeout will also check time during download
as the data are being downloaded and dies when over the limit. Default 5
minutes.

=head2 max_size

Will die when the document or image size is greater than this limit.
Default 100MB.

=head2 user_agent

User-Agent header to use for http requests.
Default is one from Chrome 89.0.4389.90.

=head2 extra_headers

HashRef with extra http request headers.

=head2 cookie_jar

Accepts optional L<HTTP::Cookies> compatible object that must provide
C<get_cookies()> method. If set will send http cookie headers with each
request.

=head2 title

Returns title of the page.

=head2 description

Returns description of the page.

=head2 canonical_url

Returns open-graph url. If not present returns L</url>.

=head2 image

Returns image location of the page.

=head2 image_data

Returns image binary data of L</image> link.

Will throw 404 exception if there is not L</image> link.

=head2 page_meta

Returns hash ref with all open-graph data.

=head2 extra_scraper

L<Web::Scraper::LibXML> object to fetch image, title or description from different
than default location.

    use Web::Scraper::LibXML;
    use Web::PageMeta;
    my $escraper = scraper {
        process_first '.slider .camera_wrap div', 'image' => '@data-src';
    };
    my $wmeta = Web::PageMeta->new(
        url => 'https://www.meon.eu/',
        extra_scraper => $escraper,
    );

=head2 page_body_hdr

Returns array ref with page [$body,$headers]. Can be useful for
post-processing or special/additional data extractions.

Only C<text/html> content-type is accepted for fetching.

=head2 fetch_page_meta_ft

Returns future object for fetching paga meta data. See L</"ASYNC USE">.
On done L</page_meta> hash is returned.

=head2 fetch_image_data_ft

Returns future object for fetching image data. See L</"ASYNC USE">
On done L</image_data> scalar is returned.

=head2 fetch_page_body_hdr_ft

Returns future object for fetching page content and headers. See L</"ASYNC USE">
On done L</page_body_hdr> array ref is returned.

=head1 ASYNC USE

To run multiple page meta data or image http requests in parallel or
to be used in async programs L</fetch_page_meta_ft> and L<fetch_image_data_ft>
returning L<Future> object can be used. See L</SYNOPSIS> or F<t/02_async.t>
for sample use.

=head1 SEE ALSO

L<https://ogp.me/>

=head1 AUTHOR

Jozef Kutej, C<< <jkutej at cpan.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2021 jkutej@cpan.org

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut
