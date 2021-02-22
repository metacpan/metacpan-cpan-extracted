package Web::PageMeta;

our $VERSION = '0.01';

use 5.010;
use Moose;
use MooseX::Types::URI qw(Uri);
use URI;
use URI::QueryParam;
use Log::Any qw($log);
use Future 0.44;
use Future::AsyncAwait;
use Future::HTTP;
use Web::Scraper;
use Encode qw(find_mime_encoding);
use Time::HiRes qw(time);

use namespace::autoclean;

has 'url' => (
    isa      => Uri,
    is       => 'ro',
    required => 1,
    coerce   => 1,
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
    default => sub {Future::HTTP->new()},
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

async sub _build__fetch_page_meta_ft {
    my ($self) = @_;

    my $timer = time();
    my ($body, $headers) =
        await $self->_ua->http_get($self->url, headers => {'Accept' => 'text/html',},);
    my $status = $headers->{Status};
    $log->debugf('page meta fetch %d %s finished in %.3fs', $status, $self->url, time() - $timer);

    die 'failed to fetch ' . $self->url
        unless $status == 200;

    if (my $content_type = $headers->{'content-type'}) {
        if (my ($charset) = ($content_type =~ m/\bcharset=(.+)/)) {
            if (my $decoder = find_mime_encoding($charset)) {
                $body = $decoder->decode($body);
            }
        }
    }

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

    if ($self->has_extra_scraper) {
        my $escraper_data = $self->extra_scraper->scrape(\$body);
        foreach my $key (keys %{$escraper_data}) {
            $page_meta{$key} = $escraper_data->{$key};
        }
    }

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

    await $self->fetch_page_meta_ft;
    my $fetch_url = $self->image;
    return $self->{image_data} = ''
        unless $fetch_url;

    my $timer = time();
    my ($body, $headers) = await $self->_ua->http_get($fetch_url);
    my $status = $headers->{Status};
    $log->debugf('img fetch %d %s for %s finished in %.3fs',
        $status, $fetch_url, $self->url, time() - $timer);

    die 'failed to fetch ' . $fetch_url
        unless $status == 200;
    return $self->{image_data} = $body;
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

=head1 ACCESSORS

=head2 new

Constructor, only L</url> is required.

=head2 url

HTTP url to fetch data from.

=head2 title

Returns title of the page.

=head2 description

Returns description of the page.

=head2 image

Returns image location of the page.

=head2 image_data

Returns image binary data of L</image> link.

=head2 page_meta

Returns hash ref with all open-graph data.

=head2 extra_scraper

L<Web::Scrape> object to fetch image, title or description from different
than default location.

    use Web::Scrape;
    use Web::PageMeta;
    my $escraper = scraper {
        process_first '.slider .camera_wrap div', 'image' => '@data-src';
    };
    my $wmeta = Web::PageMeta->new(
        url => 'https://www.meon.eu/',
        extra_scraper => $escraper,
    );

=head2 fetch_page_meta_ft

Returns future object for fetching paga meta data. See L</"ASYNC USE">.
On done L</page_meta> hash is returned.

has fetch_image_data_ft

Returns future object for fetching image data. See L</"ASYNC USE">
On done L</image_data> scalar is returned.

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
