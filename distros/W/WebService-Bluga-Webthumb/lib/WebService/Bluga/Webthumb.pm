package WebService::Bluga::Webthumb;

use warnings;
use strict;
use Carp;
use Digest::MD5;
use LWP::UserAgent;
use URI;
use Path::Class;
use POSIX qw(strftime);

=head1 NAME

WebService::Bluga::Webthumb - fetch website thumbnails via webthumb.bluga.net

=cut

our $VERSION = '0.06';

=head1 SYNOPSIS

    use WebService::Bluga::Webthumb;
    my $wt = WebService::Bluga::Webthumb->new(
        user    => $user_id,
        api_key => $api_key,
        size    => $size,  # small, medium, medium2, large (default: medium)
        cache   => $cache_days, # optional - default 14
        
        # optional settings for local caching:
        cache_dir => '....',
        cache_url_stub => '/images/thumbs/',
    );

    # get a thumbnail URL using the default settings
    my $thumb_url = wt->thumb_url($url);

    # Get a thumbnail URL overriding some settings:
    my $thumb_url = $wt->thumb_url($url, { size => 'large' });



=head1 Class methods

=over 4

=item new

Create a new WebService::Bluga::Webthumb object.  Takes the following params:

=over 4

=item user

Your webthumb user ID, available from your L<http://webthumb.bluga.net/user>
page.

=item api_key

Your webthumb API key. also available from your user page.  (This is used to
construct the hash of the thumbnail URL, but not sent directly.)

=item size

The size of the thumbnail to generate.  Size can be:

=over 4

=item * small - 80x60

=item * medium - 160x120

=item * medium2 - 320x240

=item * large - 640x480

=back


=item cache

How many days a generated thumbnail can be cached on the webthumb servers before
a fresh one is generated.  Generating a thumbnail uses a credit whereas serving
up a cached one uses a fraction of a credit, so don't set this too low.

If not specified, defaults to 14 days.

=item cache_dir

If set, generated thumbnails will be saved into this directory, and the URL
returned will be constructed using C<cache_url_stub> (so the C<cache_url_stub>
setting should be set to the URL at which the contents of C<cache_dir> are
available) - thus we're serving cached thumbnails ourselves, which costs no
credits at all and eases the load on the bluga.net servers.

The age of the cached thumbnail will be compared against the C<cache> setting, 
and if it's too old, the cached thumbnail will be replaced with a fresh one.

If you set C<cache_dir> you B<must> also set C<cache_url_stub> to the URL
at which the contents of that directory can be served from - it's up to you
to make that happen via your preferred method.

Note that if fetching and caching the thumbnail fails, we will return the
direct URL to the webthumb API such that the client's browser gets a chance
to fetch it from there instead.  I'm not sure this is the best behaviour,
it was what happened before 0.06 without much thought put in to it.  It makes
some sense as it may lead to the client being able to fetch the thumbnail
if the problem was between our server and the webthumb service, but it may
also be an unexpected surprise - so a future release may add an option to
change this behaviour and cause a hard failure if fetching & caching the
thumbnail fails (poke me if that would be useful to you!)

=item cache_url_stub

As above, if you use C<cache_dir> to arrange for generated thumbnails to be
fetched and cached locally, you must set C<cache_url_stub> to the URL at
which the contents of that directory are served; the returned thumbnail URL
will then be the value of C<cache_url_stub> with the filename (which is the
hash of the URL and desired size) appended).

=item timeout

When fetching thumbnails from the webthumb server to cache locally, this
timeout value decides how long we wait - it defaults to 3 seconds.

=back

=cut

sub new {
    my $class = shift;
    if (@_ % 2 != 0) {
        croak "Uneven number of parameters provided";
    }

    my %params = @_;
    
    # TODO: more extensive validation
    if (!$params{user} || !$params{api_key}) {
        croak "'user' and 'api_key' params must be provided";
    }

    if (exists $params{size} 
        && !grep { $params{size} eq $_ } qw(small medium medium2 large)
    ) {
        croak "Invalid size $params{size} supplied!";
    } elsif (!exists $params{size}) {
        $params{size} = 'medium';
    }

    if (!exists $params{cache}) {
        $params{cache} = 14;
    }

    if (exists $params{cache_dir} && ! exists $params{cache_url_stub}) {
        croak "Must supply cache_url_stub if you supply cache_dir";
    }

    my $self = \%params;
    bless $self => $class;

    $self->{ua} = LWP::UserAgent->new(
        agent => __PACKAGE__ . '/' . $VERSION,
        timeout => $params{timeout} || 3,
    );
    return $self;
}

=back

=head1 Instance methods

=over 4

=item thumb_url

Given an URL, and optionally C<size> / C<cache> params to override those from
the object, returns an URL to the thumbnail, to use in an IMG tag.

=cut

sub thumb_url {
    my ($self, $url, $params) = @_;

    # Get our params, use defaults from the object
    $params ||= {};
    $params->{$_} ||= $self->{$_}
        for qw(size cache cache_dir cache_url_stub);

    # First, if we're caching locally, we need to see if we already have a
    # cached version; if so, it's easy
    if (my $url = $self->_get_cached_url($url, $params)) {
        return $url;
    }

    # Generate the appropriate URL:
    my $uri = URI->new('http://webthumb.bluga.net/easythumb.php');
    $uri->query_form(
        url   => $url,
        size  => $params->{size},
        cache => $params->{cache},
        user  => $self->{user},
        hash  => Digest::MD5::md5_hex(join '',
            strftime("%Y%m%d", gmtime(time())),
            $url,
            $self->{api_key}
        ),
    );

    # If we're caching, we want to fetch the resulting thumbnail and store it
    # locally, then return the URL to that instead
    if ($params->{cache_dir}) {
        my $req = $self->{ua}->get($uri);
        if ($req->is_success) {
            my $url = $self->_cache_image($url, $params, $req->content);
            return $url if defined $url;
        } else {
            # We couldn't cache it, just return the calculated URL; maybe
            # the user will have more luck fetching it directly as they
            # would have without caching enabled (and this is the implied
            # behaviour before 0.06 switched to using a real UA object with
            # the timeout set, and checking for success here)
            # Maybe we should have an option which allows us to throw
            # an error here so calling code can differentiate easily?
            return $uri->as_string;
        }
    }

    return $uri->as_string;
}

=item easy_thumb

An alias for C<thumb_url>.  This name was used in 0.01 to reflect the fact that
it used the L<EasyThumb API|http://webthumb.bluga.net/api-easythumb> rather than
the full API; however, I think C<thumb_url> is rather clearer as to the actual
purpose of the method, and the implementation of it is somewhat unimportant, so
consider this method somewhat deprecated (but likely to be supported
indefinitely.)

=cut

sub easy_thumb { shift->thumb_url(@_); }


sub _get_cached_url {
    my ($self, $url, $params) = @_;

    my $dir = Path::Class::dir($params->{cache_dir})
        or return;
    my $file = $dir->file(
        Digest::MD5::md5_hex($url . $params->{size})
    ) or return;
    my $stat = $file->stat or return;
    if ($stat->mtime < time - ($params->{cache} * 24 * 60 * 60)) {
        $file->remove;
        return;
    } else {
        return $params->{cache_url_stub} . $file->basename;
    }
}

sub _cache_image {
    my ($self, $url, $params, $img_content) = @_;

    my $dir = Path::Class::dir($params->{cache_dir})
        or return;
    my $file = $dir->file(
        Digest::MD5::md5_hex($url . $params->{size})
    ) or return;
    $file->spew($img_content);
    return $params->{cache_url_stub} . $file->basename;
}


=back

=head1 AUTHOR

David Precious, C<< <davidp at preshweb.co.uk> >>

=head1 ACKNOWLEDGEMENTS

James Ronan


=head1 CONTRIBUTING

This module is developed on GitHub at:

L<https://github.com/bigpresh/WebService-Bluga-Webthumb>

Bug reports / suggestions / pull requests are all very welcome.

If you find this module useful, please feel free to 
L<rate it on cpanratings|http://cpanratings.perl.org/d/WebService-Bluga-Webthumb>


=head1 BUGS

Bug reports via L<Issues on
GitHub|https://github.com/bigpresh/WebService-Bluga-Webthumb/issues> are
preferred, as the module is developed on GitHub, and issues can be correlated to
commits.  Bug reports via L<the RT
queue|http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WebService-Bluga-Webthumb>
are still valued though, if you'd prefer that way.

=head1 SEE ALSO

See the API documentation at L<http://webthumb.bluga.net/api-easythumb>

For a basic description of the service, see L<http://webthumb.bluga.net/>


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WebService::Bluga::Webthumb



=head1 LICENSE AND COPYRIGHT

Copyright 2011 David Precious.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of WebService::Bluga::Webthumb
