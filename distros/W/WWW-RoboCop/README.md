# NAME

WWW::RoboCop - Police your URLs!

# VERSION

version 0.000103

# SYNOPSIS

    use feature qw( state );

    use WWW::RoboCop ();

    my $robocop = WWW::RoboCop->new(
        is_url_allowed => sub {
            state $count = 0;
            return $count++ < 5; # just crawl 5 URLs
        },
    );

    $robocop->crawl( 'https://example.com' );

    my %history = $robocop->get_report;

    # %history = (
    #    'http://myhost.com/one' => { status => 200, ... },
    #    'http://myhost.com/two' => { status => 404, ... },
    #    ...
    # )

See `examples/crawl-host.pl`, which is included with this distribution, to get a
quick start.

# DESCRIPTION

`WWW::RoboCop` is a simple, somewhat opinionated robot.  Given a starting
page, this module will crawl only URLs which have been allowed by the
`is_url_allowed` callback.  It then creates a report of all visited pages,
keyed on URL.  You are encouraged to provide your own report creation callback
so that you can collect all of the information which you require for each URL.

# CONSTRUCTOR AND STARTUP

## new()

Creates and returns a new `WWW::RoboCop` object.

Below are the arguments which you may pass to `new` when creating an object.

### is\_url\_allowed

This argument is required.  You must provide an anonymous subroutine which will
return true or false based on some arbitrary criteria which you provide.  The
two arguments to this anonymous subroutine will be a [WWW::Mechanize::Link](https://metacpan.org/pod/WWW%3A%3AMechanize%3A%3ALink)
object as well as the referring URL, in the form of a [URI](https://metacpan.org/pod/URI) object.

Your sub might look something like this:

    use feature qw( state );

    use URI ();
    use WWW::RoboCop ();

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

### report\_for\_url

This argument is not required, but is highly recommended. The arguments to this
anonymous subroutine will be an [HTTP::Response](https://metacpan.org/pod/HTTP%3A%3AResponse) object as well as the
referring URL in the form of a [URI](https://metacpan.org/pod/URI) object.  Your sub might look something
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

The default `report_for_url` sub will already provide something like the
above, but you should only treat this as a stub method while you get up and
running.  Since it's only meant to be an example, the format of the default
report could change at some future date without notice.  You should not rely on
or expect it to remain consistent in future.  If you are going to rely on this
module, you should provide your own reporting logic.

### ua( WWW::Mechanize )

You can provide your own UserAgent object to this class.  It should be of the
[WWW::Mechanize](https://metacpan.org/pod/WWW%3A%3AMechanize) family.  If you're looking for a significant speed boost
while under development, consider providing a [WWW::Mechanize::Cached](https://metacpan.org/pod/WWW%3A%3AMechanize%3A%3ACached) object.
This can give you enough of a speedup to save you from getting distracted
and going off to read Hacker News while you wait.

    use CHI ();
    use WWW::Mechanize::Cached ();
    use WWW::RoboCop ();

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

## crawl( $url )

This method sets the `WWW::RoboCop` in motion.  The robot will only come to a
halt once has exhausted all of the allowed URLs it can find.

## get\_report

This method returns a Hash of crawling results, keyed on the URLs visited.
By default, it returns a very simple Hash, containing only the status code
of the visited URL.  You are encouraged to provide your own callback so that
you can get a detailed report returned to you.  You can do this by providing a
`report_for_url` callback when instantiating the object.

The default report looks something like this:

    # %history = (
    #    'http://myhost.com/one' => { status => 200, ... },
    #    'http://myhost.com/two' => { status => 404, ... },
    # )

See `examples/crawl-host.pl`, which is included with this distribution, to get
a dump of the default report.

# AUTHOR

Olaf Alders <olaf@wundercounter.com>

# COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by MaxMind, Inc.

This is free software, licensed under:

    The Artistic License 2.0 (GPL Compatible)
