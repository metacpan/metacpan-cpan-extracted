use strict;
use warnings;
use feature qw( state );

package WWW::RoboCop;
our $VERSION = '0.000100';
use Carp qw( croak );
use Moo;
use MooX::HandlesVia;
use MooX::StrictConstructor;
use Mozilla::CA;
use Type::Params qw( compile );
use Types::Standard qw( CodeRef HashRef InstanceOf );
use Types::URI -all;
use URI;
use WWW::Mechanize;

has is_url_allowed => (
    is          => 'ro',
    isa         => CodeRef,
    handles_via => 'Code',
    handles     => { _should_follow_link => 'execute' },
    required    => 1,
);

has report_for_url => (
    is          => 'ro',
    isa         => CodeRef,
    handles_via => 'Code',
    handles     => { _log_response => 'execute' },
    default     => sub {
        sub {
            my $response      = shift;    # HTTP::Response object
            my $referring_url = shift;    # URI object
            return {
                $response->redirects
                ? (
                    redirects => [
                        map {
                            {
                                status => $_->code,
                                uri    => $_->request->uri,
                            }
                        } $response->redirects
                    ],
                    target_url => $response->request->uri,
                    )
                : (),
                referrer => $referring_url,
                status   => $response->code,
            };
        };
    },
);

has ua => (
    is      => 'ro',
    isa     => InstanceOf ['WWW::Mechanize'],
    default => sub {
        WWW::Mechanize->new( autocheck => 0 );
    },
);

has _history => (
    is          => 'ro',
    isa         => HashRef,
    handles_via => 'Hash',
    handles     => {
        _add_url_to_history => 'set',
        _has_processed_url  => 'exists',
    },
    init_arg => undef,
    default  => sub { +{} },
);

sub _get {
    my $self          = shift;
    my $url           = shift;
    my $referring_url = shift;

    my $response = $self->ua->get($url);
    my $report   = $self->_log_response( $response, $referring_url );
    $self->_add_url_to_history( $url, $report );

    my @links = $self->ua->find_all_links;

    foreach my $link (@links) {

        # this just points back at the same url
        next if substr( $link->url, 0, 1 ) eq '#';

        my $uri = URI->new( $link->url_abs );
        $uri->fragment(undef);    # fragments result in duplicate urls

        next if $self->_has_processed_url($uri);
        next unless $uri->can('host');    # no mailto: links
        next unless $self->_should_follow_link( $link, $url );

        $self->_get( $uri, $url );
    }
}

sub crawl {
    my $self = shift;

    state $check = compile(Uri);
    my ($url) = $check->(@_);

    $self->_get($url);
}

sub get_report {
    my $self = shift;
    return %{ $self->_history };
}

1;

=pod

=encoding UTF-8

=head1 NAME

WWW::RoboCop - Police your URLs!

=head1 VERSION

version 0.000100

=head1 SYNOPSIS

    use feature qw( state );

    use WWW::RoboCop;

    my $robocop = WWW::RoboCop->new(
        is_url_allowed => sub {
            state $count = 0;
            return $count++ < 5; # just crawl 5 URLs
        },
    );

    $robocop->crawl( 'http://host.myhost.com/start' );

    my %history = $robocop->get_report;

    # %history = (
    #    'http://myhost.com/one' => { status => 200, ... },
    #    'http://myhost.com/two' => { status => 404, ... },
    #    ...
    # )

=head1 DESCRIPTION

BETA BETA BETA!

C<WWW::RoboCop> is a dead simple, somewhat opinionated robot.  Given a starting
page, this module will crawl only URLs which have been allowed by the
C<is_url_allowed> callback.  It then creates a report of all visited pages,
keyed on URL.  You are encouraged to provide your own report creation callback
so that you can collect all of the information which you require for each URL.

=head1 CONSTRUCTOR AND STARTUP

=head2 new()

Creates and returns a new C<WWW::RoboCop> object.

Below are the arguments which you may pass to C<new> when creating an object.

=head3 is_url_allowed

This argument is required.  You must provide an anonymous subroutine which will
return true or false based on some arbitrary criteria which you provide.  The
two arguments to this anonymous subroutine will be a L<WWW::Mechanize::Link>
object as well as the referring URL, in the form of a L<URI> object.

Your sub might look something like this:

    use feature qw( state );

    use URI;
    use WWW::RoboCop;

    my $robocop = WWW::RoboCop->new(
        is_url_allowed => sub {
            my $link          = shift;
            my $referring_url = shift;

            my $upper_limit = 100;
            my $host = 'some.host.com';

            state $limit = 0;

            return 0 if $limit > $upper_limit;
            my $uri = URI->new( $link->url_abs );

            # if the referring_url matches the host then this is a 1st degree
            # outbound web link

            if ( $uri->host eq $host || $referring_url->host eq $host ) {
                ++$limit;
                return 1;
            }
            return 0;
        }
    );

=head3 report_for_url

This argument is not required, but is highly recommended. The arguments to this
anonymous subroutine will be an L<HTTP::Response> object as well as the
referring URL in the form of a L<URI> object.  Your sub might look something
like this:

    my $reporter = sub {
        my $response      = shift;    # HTTP::Response object
        my $referring_url = shift;    # URI object
        return {
            redirects => [
                map { +{ status => $_->code, uri => $_->base->as_string } }
                    $res->redirects
            ],
            referrer => $referring_url,
            status   => $res->code,
        };
    };

    my $robocop = WWW::RoboCop->new(
        is_url_allowed => sub { ... },
        report_for_url     => $reporter,
    );

That would give you a HashRef with the status code for each link visited (200,
404, 500, etc) as well as the referring URL (the page on which the link was
found) and a list of any redirects which were followed in order to get to this
URL.

The default C<report_for_url> sub will already provide something like the
above, but you should only treat this as a stub method while you get up and
running.  Since it's only meant to be an example, the format of the default
report could change at some future date without notice.  You should not rely on
or expect it to remain consistent in future.  If you are going to rely on this
module, you should provide your own reporting logic.

=head3 ua( WWW::Mechanize )

You can provide your own UserAgent object to this class.  It should be of the
L<WWW::Mechanize> family.  If you're looking for a significant speed boost
while under development, consider providing a L<WWW::Mechanize::Cached> object.
This can give you enough of a speedup to save you from getting distracted
and going off to read Hacker News while you wait.

    use CHI;
    use WWW::Mechanize::Cached;
    use WWW::RoboCop;

    my $cache = CHI->new(
        driver => 'File',
        root_dir => /tmp/cache-example',
    );

    my $robocop = WWW::RoboCop->new(
        is_url_allowed => sub { ... },
        ua => WWW::Mechanize::Cached->new( cache => $cache ),
    );

If you're not using a Cached agent, be sure to disable autocheck.

    my $robocop = WWW::RoboCop->new(
        is_url_allowed => sub { ... },
        ua => WWW::Mechanize->new( autocheck => 0 ),
    );

=head2 crawl( $url )

This method sets the C<WWW::RoboCop> in motion.  The robot will only come to a
halt once has exhausted all of the allowed URLs it can find.

=head2 get_report

This method returns a Hash of crawling results, keyed on the URLs visited.
By default, it returns a very simple Hash, containing only the status code
of the visited URL.  You are encouraged to provide your own callback so that
you can get a detailed report returned to you.  You can do this by providing a
C<report_for_url> callback when instantiating the object.

The default report looks something like this:

    # %history = (
    #    'http://myhost.com/one' => { status => 200, ... },
    #    'http://myhost.com/two' => { status => 404, ... },
    # )

See examples/crawl-host.pl, which is included with this distribution, to get a
dump of the default report.

=head1 AUTHOR

Olaf Alders <olaf@wundercounter.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by MaxMind, Inc.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

__END__

# ABSTRACT: Police your URLs!

