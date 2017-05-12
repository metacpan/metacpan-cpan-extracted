package WWW::Spinn3r;
use base Class::Accessor;
use base WWW::Spinn3r::Common;
use LWP::UserAgent; 
use Data::Dumper;
use Carp;
use WWW::Spinn3r::next_request_url;
use WWW::Spinn3r::item;
use WWW::Spinn3r::link;
use File::Spec;

__PACKAGE__->mk_accessors(qw( api api_url from_file future_sleep next_url retries retry_sleep last_url path this_cursor this_feed version want));

$WWW::Spinn3r::VERSION = '3.00700001';

our $DEFAULTS = { 
    api_url     => 'http://api.spinn3r.com/rss',
    debug       => 0,
    retries     => 60 * 60 * 24 * 10,
    retry_sleep => 3,
    future_sleep => 5,
    version     => '3.0.7',
    want        => 'item',
};


sub new { 

    my ($class, %args) = @_;

    my $self = bless { %$DEFAULTS, %args }, $class;

    if ($args{from_file}) { 
        # check for file's existance
        return $self;
    }

    croak "Need vendor key" unless $args{params}->{vendor};
    croak "Need api name" unless $args{api};
    $self->{ua} = new LWP::UserAgent (timeout => 30);
    unless ($args{mirror}) { 
        $self->{ua}->default_header('Accept-Encoding' => 'gzip');
    }

    return $self;

}


sub mirror { 

    my ($class, %args) = @_;
    croak "no mirror path provided" unless $args{path};
    return $class->new(%args, mirror => 1);

}


sub first_url { 

    my ($self) = @_;

    # use default version if one is not provided. 
    if (defined $self->{params}->{version}) { 
        $self->version($self->{params}->{version});
        delete $self->{params}->{version}; 
    }

    my $url = $self->api_url . '/' . $self->api . '?version=' . $self->version;
    for my $param (keys %{ $self->{params} }) {
        $url .= '&' . $param . '=' . $self->{params}->{$param};
    }

    return $url;

}


sub _next_feed_from_http { 

    my ($self, $url, %args) = @_;

    my $tries = 0;
    my $content = '';
    
    while ($tries < $self->retries and not $content) { 
    
        $tries++;

        my ($response, $content_file, $length);

        my $start = $self->start_timer();
        if ($$self{mirror}) { 
            $content_file = $self->local_file($$self{path}, $url); 
            $self->debug("fetching (to file $content_file) $url");
            $response = $self->{ua}->get($url, ':content_file' => $content_file);
        } else { 
            $self->debug("fetching (to memory) $url");
            $response = $self->{ua}->get($url);
        }
        
        my $howlong = $self->howlong($start);

        unless ($response->is_success) { 
            $self->debug($response->status_line);
            if ($response->status_line =~ /^4\d\d/) { 
                last;
            } 
            $self->debug("sleeping for " . $self->retry_sleep . " seconds...");
            sleep($self->retry_sleep);
        } else { 
            $length = $$self{mirror} ? -s $content_file : length($response->content);
            $self->debug("success! $length bytes, in $howlong seconds");
            if ($$self{mirror}) { 
                $content = $content_file;
            } else { 
                $content = $response->decoded_content;
            }
        }
        
    }

    unless ($content) { 
        croak "Unable to fetch from spinn3r: $url";
    }

    if ($$self{mirror}) { 
        return $content;
    } else { 
        return \$content;
    }

}


sub local_file { 

    my ($self, $path, $url) = @_;
    
    my $urlpath = URI->new($url)->path;
    $urlpath =~ s|^/rss/||;

    my $filename .= ' ' . URI->new($url)->query;
    $filename =~ s"\W"-"sg;
    $filename = $urlpath . '-' . $filename . '.xml';

    my $fullpath = File::Spec->catfile($path, $filename);
    $self->debug("mirror filename: $fullpath");
    return $fullpath;

}


sub next_feed {

    my ($self) = @_;

    if ($self->{ua}) { 

        my $url = $self->next_url || $self->first_url;

        if ($url =~ /before=$/) { # work around bug in permalink.history
            return;
        }

        if ($url eq $self->last_url or $url =~ /after=$/) { 
            $self->debug("it's the future! will wait for present to catch up. sleeping " . $self->future_sleep . " seconds");
            sleep($self->future_sleep);
            $self->last_url(undef);
            return $self->next_feed();
        }

        my $xml = $self->_next_feed_from_http($url, %args);

        $self->last_url($url);
        if ($self->want eq 'item') { 
            my $items = WWW::Spinn3r::item->new(stringref => $xml, debug => $self->{debug});
            return unless $items;
            $self->this_feed($items);
        } elsif ($self->want eq 'link') { 
            $self->this_feed(WWW::Spinn3r::link->new(stringref => $xml, debug => $self->{debug}));
        }

    } elsif ($self->{from_file}) { 
        my $content_file = File::Spec->catfile($self->from_file);
        if ($self->want eq 'item') { 
            $self->this_feed(WWW::Spinn3r::item->new(path => $content_file, debug => $self->{debug}));
        } elsif ($self->want eq 'link') { 
            $self->this_feed(WWW::Spinn3r::link->new(path => $content_file, debug => $self->{debug}));
        }
    }

}


sub next { 

    my ($self) = @_;

    unless ($self->this_feed) { 

        $self->next_feed();
        return undef unless $self->this_feed;  # fetch failed
        $self->this_cursor(0);
        return unless $self->this_feed;
        return unless $self->this_feed->{'api:next_request_url'};
        $self->next_url($self->this_feed->{'api:next_request_url'});
        return $self->next();

    }

    my $item = $self->this_feed->{$self->want}->[$self->this_cursor];

    unless ($item) { 
        $self->this_feed(undef);
        return undef if $self->from_file;
        return $self->next();
    }

    $self->this_cursor($self->this_cursor+1);
    return $item;

}


sub next_mirror { 

    my ($self, %args) = @_;

    unless ($self->{mirror}) {
        warn ("next_mirror called in non-mirror mode");
        return;
    }
    my $url = $self->next_url || $self->first_url;

    if ($url eq $self->last_url or $url =~ /after=$/) { 
        $self->debug("it's the future! will wait for present to catch up. sleeping " . $self->future_sleep . " seconds");
        sleep($self->future_sleep);
        $self->last_url(undef);
        return $self->next_mirror();
    }

    my $filename = $self->_next_feed_from_http($url);
    $self->last_url($url);
    my $next_url = new WWW::Spinn3r::next_request_url(path => $filename, debug => $self->{debug});
    $self->next_url($next_url->{'api:next_request_url'});

}

 
1;


=head1 NAME
    
WWW::Spinn3r - An interface to the Spinn3r API (http://www.spinn3r.com)

=head1 SYNOPSIS

 use WWW::Spinn3r;
 use DateTime;

 my $API = { 
    vendor          => 'acme',   # required
    limit           => 5, 
    lang            => 'en',
    tier            => '0:5', 
    after           => DateTime->now()->subtract(hours => 48),
 };

 my $spnr = new WWW::Spinn3r ( 
    api => 'permalink3.getDelta', params => $API, debug => 1);
 );

 while(1) { 
     my $item = $spnr->next;
     print $item->{title};
     print $item->{link};
     print $item->{dc}->{source};
     print $item->{description};
 }

=head1 DESCRIPTION 

WWW::Spinn3r is an iterative interface to the Spinn3r API. The Spinn3r API 
is implemented over REST and XML and documented at 
C<http://spinn3r.com/documentation>.

=head1 OBTAINING A VENDOR KEY 

Spinn3r service is available through a B<vendor> key, which you can 
get from the good folks at Tailrank, C<http://spinn3r.com/contact>.

=head1 HOW TO USE

Most commonly, you'll need just two functions from this module: C<new()>
and C<next()>. C<new()> creates a new instance of the API and C<next()>
returns the next item from the Spinn3r feed, as hashref. Details
are below.

=head1 B<new()>

The contructor. This function takes a hash with the following keys:

=over 4

=item B<api>

C<permalink3.getDelta> or C<feed3.getDelta>, one of the two APIs
provided by Spinn3r.

=item B<params>

These are parameters that are passed to the API call. See
C<http://spinn3r.com/documentation> for a list of available parameters
and their values.

The B<version> parameter to the API is a function of version of this
module. and the B<version()> accessor method returns the version
of the API. By default, the version will be set to the version 
that corresponds to this module.

If the version of the spinn3r API has changed, you can specify it 
as a parameter. While the module is not guranteed to work with higher
versions of the Spinn3r API than it is designed for, it might if the
underlying formats and encodings have not changed.

=item B<want>

This parameter defines the type of item returned by the next() call.
WWW::Spinn3r uses XML::Twig to parse the XML returned by Spinn3r and
comes with three Twig parsers, C<WWW::Spinn3r::item>,
C<WWW::Spinn3r::link> and C<WWW::Spinn3r::next_request_url>. The default
value for C<want> is C<item>, which corresponds to the
C<WWW::Spinn3r::item> module and returns all fields for an item included
in the Spinn3r feed.

The motivation for having multiple parsers is speed. If you only want
certain fields from the feed, for example the link and title, it is
significantly faster to write a parser that just extracts those two
fields from the feed with XML::Twig.

=item B<debug>

Emits debug noise on STDOUT if set to 1. 

=item B<retries>

The number of HTTP retries in case of a 5xx failure from the API. 
The default is 5.

=back

=head1 B<next()>

This method returns the next item from the Spinn3r feed. The item is a
reference to a hash, which contains the various fields of an item
as parsed by the parser specified in the C<want> field of the
consutructor (C<item> by default).

The module transparently fetches a new set of results from Spinn3r,
using the C<api:next_request_url> returned by Spinn3r with every
request, and caches the result to implement C<next()>.

You can control the number of results that are fetched with every call
by changing the C<limit> parameter at C<new()>.

=head1 B<last_url()>

The last API URL that was fetched.

=head1 B<mirror()>

WWW::Spinn3r supports mirroring of the Spinn3r feed to local files
and then recreating WWW:Spinn3r objects from these files. This
is useful if you want to distribute processing of the feeds 
over multiple processes or computers.

To mirror feeds to disk, use the alternative constructor B<mirror>,
which takes all the same arguments as B<new> plus the 
C<path> argument, which specifies where the files should saved.

    my $m = mirror WWW::Spinn3r ( path => $mirror_dir, ... )
    $m->next_mirror();

The iteration is done with B<next_mirror()> method, which stores the
next feed to a new file, whose filename is derived from the API url.

WWW::Spinn3r objects can be created from these disk files when 
new() is called with the C<from_file> key: 

    my $m = new WWW::Spinn3r ( from_file => ... );

=head1 DATE STRING FORMAT

Spinn3r supports ISO 8601 timestamps in the C<after> parameter. To
create ISO 8601 timestamps, use the DateTime module that returns ISO
8601 date strings by default. eg:

 after => DateTime->now()->subtract(hours => 48),
 after => DateTime->now()->subtract(days => 31),

=head1 REPORTING BUGS

Bugs should be reported at C<http://rt.cpan.org>

=head1 SEE ALSO

WWW::Spinn3r::Synced

=head1 AUTHOR

Vipul Ved Prakash <vipul@slaant.com>

=head1 LICENSE 

This software is distributed under the same terms as perl itself.

=cut
