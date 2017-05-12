package Zabbix::API;

use strict;
use warnings;
use 5.010;

use Params::Validate qw/:all/;
use Carp qw/carp croak confess cluck/;
use Data::Dumper;
use Scalar::Util qw/weaken/;

use JSON;
use LWP::UserAgent;

our $VERSION = '0.009';

sub new {

    my $class = shift;
    my %args = validate(@_, { server => 1,
                              verbosity => 0,
                              env_proxy => 0,
                              lazy => 0,
                              ua => { optional => 1 } });

    my $self = \%args;

    # defaults
    $self->{verbosity} = 0 unless exists $self->{verbosity};
    $self->{env_proxy} = 0 unless exists $self->{env_proxy};
    $self->{lazy} = 0 unless exists $self->{lazy};

    $self->{ua} = LWP::UserAgent->new(agent => 'Zabbix API client (libwww-perl)',
                                      from => 'fabrice.gabolde@uperto.com',
                                      show_progress => $self->{verbosity},
                                      env_proxy => $self->{env_proxy},)
                        unless $self->{ua};

    $self->{cookie} = '';

    bless $self, $class;

    return $self;

}

sub useragent {

    return shift->{ua};

}

sub verbosity {

    ## mutator for verbosity

    my ($self, $value) = @_;

    if (defined $value) {

        $self->{verbosity} = $value;
        $self->{ua}->{show_progress} = $value;
        return $self->{verbosity};

    } else {

        return $self->{verbosity};

    }

}

sub cookie {

    my $self = shift;

    return $self->{cookie};

}

sub login {

    my $self = shift;

    my %args = validate(@_, { user => 1,
                              password => 1 });

    my $response = $self->raw_query(method => 'user.login',
                                    params => \%args);

    $self->{cookie} = '';

    my $decoded = eval { decode_json($response->decoded_content) };

    if ($@) {

        # probably could not connect at all
        croak sprintf('Could not connect: %s (%s)', $response->message, $response->code);

    }

    if ($decoded->{error}) {

        croak 'Could not log in: '.$decoded->{error}->{data};

    }

    $self->{cookie} = $decoded->{result};

    $self->{user} = $args{user};

    return $self;

}

sub logout {

    my $self = shift;

    my $decoded = decode_json($self->raw_query(method => 'user.logout')->decoded_content);

    if ($decoded->{error}) {

        croak 'Could not log out: '.$decoded->{error}->{data};

    }

    $self->{cookie} = '';

    delete $self->{user};

    return $self;

}

sub raw_query {

    my ($self, %args) = @_;

    state $global_id = int(rand(10000));

    # common parameters
    $args{'jsonrpc'} = '2.0';
    $args{'auth'} = $self->cookie || '';
    $args{'id'} = $global_id++;

    my $response = eval { $self->{ua}->post($self->{server},
                                            'Content-Type' => 'application/json-rpc',
                                            Content => encode_json(\%args)) };

    if ($@) {

        my $error = $@;

        confess $error;

    }

    given ($self->{verbosity}) {

        when (1) {

            print $response->as_string;

        }

        when (2) {

            print Dumper($response);

        }

        default {

        }

    }

    return $response;

}

sub query {

    my $self = shift;

    my %args = validate(@_, { method => { TYPE => SCALAR },
                              params => { TYPE => HASHREF,
                                          optional => 1 }});

    my $response = $self->raw_query(%args);

    if ($response->is_success) {

        my $decoded = decode_json($response->decoded_content);

        if ($decoded->{error}) {

            croak 'Zabbix server replied: '.$decoded->{error}->{data};

        }

        return $decoded->{result};

    }

    croak 'Received HTTP error: '.$response->decoded_content;

}

sub api_version {

    my $self = shift;

    my $response = $self->query(method => 'apiinfo.version');

    return $response;

}

sub fetch {

    my $self = shift;
    my $class = shift;

    my %args = validate(@_,
                        { params => { type => HASHREF,
                                      default => {} } });

    $class =~ s/^(?:Zabbix::API::)?/Zabbix::API::/;

    ## no critic (ProhibitStringyEval)
    eval "require $class";
    ## use critic

    if ($@) {

        my $error = $@;

        croak qq{Could not load class '$class': $error};

    }

    my $response = $self->query(method => $class->prefix('.get'),
                                params => {
                                    %{$args{params}},
                                    $class->extension
                                });

    my $things = [ map { $class->new(root => $self, data => $_)  } @{$response} ];

    return $things;

}

sub fetch_single {

    my ($self, @args) = @_;

    my $results = $self->fetch(@args);
    my $result_count = scalar @{$results};

    if ($result_count > 1) {

        croak qq{Too many results for 'fetch_single': expected 0 or 1, got $result_count"};

    }

    return $results->[0];

}

1;
__END__
=pod

=head1 NAME

Zabbix::API -- Access the JSON-RPC API of a Zabbix server

=head1 SYNOPSIS

  use Zabbix::API;

  my $zabbix = Zabbix::API->new(server => 'http://example.com/zabbix/api_jsonrpc.php',
                                verbosity => 0);

  eval { $zabbix->login(user => 'calvin',
                        password => 'hobbes') };

  if ($@) { die 'could not authenticate' };

  my $items = $zabbix->fetch('Item', params => { search => { ... } });

=head1 DESCRIPTION

This module manages authentication and querying to a Zabbix server via its
JSON-RPC interface.  (Zabbix v1.8+ is required for API usage; prior versions
have no JSON-RPC API at all.)

What you need to start out is probably the C<fetch> method in C<Zabbix::API>; be
sure to check out also what the various C<Zabbix::API::Foo> classes do, as this
is how you'll be manipulating the objects you have just fetched.

Finally, there are examples in the C<examples/> folder (well, at least one) and
in the unit tests.

=head1 METHODS

=over 4

=item new(server => URL, [verbosity => INT], [env_proxy => BOOL])

This is the main constructor for the Zabbix::API class.  It creates a
LWP::UserAgent instance but does B<not> open any connections yet.
C<env_proxy> is passed to the LWP::UserAgent constructor, so if it is set to a
true value then the UA should follow C<$http_proxy> and others.

C<server> is misleading, as the URL expected is actually the whole path to the
JSON-RPC page, which usually is C<http://example.com/zabbix/api_jsonrpc.php>.

Returns an instance of the C<Zabbix::API> class.

=item login(user => STR, password => STR)

Send login information to the Zabbix server and set the auth cookie if the
authentication was successful.

Due to the current state of flux of the Zabbix API, this may or may not work
depending on your version of Zabbix.  C<user.authenticate> is marked as having
been introduced in version 1.8; so is C<user.login>, which deprecates
C<authenticate>.  Our method uses C<login>.  Version 1.8.4 is confirmed as
working with C<login>.

=item logout()

Try to log out properly.  Unfortunately, the C<user.logout> method is completely
undocumented and does not appear to work at the moment (see the bug report here:
L<https://support.zabbix.com/browse/ZBX-3907>).  Users of this distribution are
advised not to log out at all.  They will B<not be able to log back in> until the
server has decided their ban period is over (around 30s).  Furthermore, another
bug in Zabbix (resolved in 1.8.5) prevents successful logins to reset the failed
logins counter, which means that after three (possibly non-consecutive) failed
logins every failed login triggers the ban period.

The test suite logs in and out once per test file.  The logout method does not
work.  There are more than three test files.  Do the math :(

=item raw_query(method => STR, [params => HASHREF])

Send a JSON-RPC query to the Zabbix server.  The C<params> hashref should
contain the method's parameters; query parameters (query ID, auth cookie,
JSON-RPC version, and HTTP request headers) are set by the method itself.

Return a C<HTTP::Response> object.

If the verbosity is set to 1, will print the C<HTTP::Response> to STDOUT.  If
set to 2, will print the Data::Dumper output of same (it also contains the
C<HTTP::Request> being replied to).

If the verbosity is strictly greater than 0, the internal LWP::UserAgent
instance will also print HTTP request progress.

=item query(method => STR, [params => HASHREF])

Wrapper around C<raw_query> that will return the decoded result data instead.

=item api_version

Query the Zabbix server for the API version number and return it.

=item fetch(CLASS, [params => HASHREF])

This method fetches objects from the server.  The PARAMS hashref should contain
API method parameters that identify the objects you're trying to fetch, for
instance:

  $zabbix->fetch('Item', params => { search => { key_ => 'system.uptime' } });

The default value of PARAMS is an empty hashref, which should mean "fetch every
object of type CLASS".

The method delegates a lot of work to the CLASS so that it can be as generic as
possible.  Any CLASS name in the C<Zabbix::API> namespace is usable as long as
it descends from C<Zabbix::API::CRUDE> (to be precise, it should implement a
number of methods, some of which C<CRUDE> implements, some of which are provided
by specialized subclasses provided in the distribution).  The string
C<Zabbix::API::> will be prepended if it is missing.

Returns an arrayref of CLASS instances.

=item fetch_single(CLASS, [params => HASHREF])

Like C<fetch>, but also checks how many objects the server sent back.
If no objects were sent, returns C<undef>.  If one object was sent,
returns that.  If more objects were sent, throws an exception.  This
helps against malformed queries; Zabbix tends to return B<all> objects
of a class when a query contains strange parameters (like "searhc" or
"fliter").

=item useragent

Accessor for the L<LWP::UserAgent> object that handles HTTP queries
and responses.  Several useful options can be set: timeout, redirects,
etc.

=item verbosity([VERBOSITY])

Mutator for the verbosity level.

Implemented verbosities so far are 0, 1 and 2, where:

=over 4

=item 0

does not emit any messages,

=item 1

prints out the C<LWP::UserAgent> progress messages and the responses sent by the
Zabbix server,

=item 2

prints out the C<LWP::UserAgent> progress messages and dumps to stdout (via
C<Data::Dumper>) the queries sent to the server and the responses received.

=back

=back

=head1 LOW-LEVEL ACCESS

Several attributes are available if you want to dig into the class' internals,
through the standard blessed-hash-as-an-instance mechanism.  Those are:

=over 4

=item server

A string containing the URL to which JSON-RPC queries should be POSTed.

=item verbosity

Verbosity level.  So far levels 0 to 2 are supported (i.e. do something
different).

=item cookie

A string containing the current session's auth cookie, or the empty string if
unauthenticated.

=item env_proxy

Direct access to the LWP::UserAgent B<initial> configuration regarding
proxies.  Setting this attribute after construction does nothing.

=back

=head1 BUGS AND MISSING FEATURES

=head2 THE GREAT RACE CONDITION

Consider the following:

  my $host = $zabbix->fetch('Host', params => ...);

  my $same_host = Zabbix::API::Host->new(root => $zabbix,
                                         params => same...);

  $same_host->push;

  is_deeply($host, $same_host); # yup
  isnt($host, $same_host); # also yup

This means you can change the attribute A in C<$host> and push it, and it will
change on the server; then you can change some other attribute B in
C<$same_host> and push it, and it will change on the server... and attribute A
will be changed back to its old value before you changed it in C<$host> since
C<$host> and C<$same_host> are different references to different objects and
don't know about each other!  Of course this is also true if someone else is
fiddling with the hosts directly on the web interface or in any other way.

To work around this, you have to C<pull()> just before you start changing
things.

=head2 MOOSE, ABSENCE OF

The distribution doesn't use Moose, because it was written with light
dependencies in mind.  This is actually a problem in that I do not have the time
to write proper accessors to cover all types of manipulations one might expect
on, for instance, a graph's items.  Hence to push (in the stack sense) a new
item into a graph's list of items, you have to use the push builtin on the
dereferenced items mutator, instead of writing something like

  $graph->items->push($foo);

which would be easy to allow with Moose traits.  Plus, I had to write
boilerplate validation code, which would have been taken care of by Moose at
least where types and type coercions are concerned.

=head2 OTHER BUGS THAT ARE NOT RELATED TO THE ABSENCE OF MOOSE

It is quite slow.  The server itself does not appear to be lightning fast; at
least a recent Zabbix (1.8.5) on a Debian squeeze VM takes a couple seconds to
reply to even trivial JSON-RPC queries.  This is compounded by the fact that
Zabbix::API is being extra paranoid about default values and name/id collisions
and fetches data maybe more often than necessary, for instance immediately
before and after a C<push()>.

Several types of objects are not implemented in this distribution; feel free to
contribute them or write your own distribution (see L<Zabbix::API::CRUDE> for
the gory API details).

The C<logout> business.

=head1 SEE ALSO

The Zabbix API documentation, at L<http://www.zabbix.com/documentation/start>

L<LWP::UserAgent>

=head1 AUTHOR

Fabrice Gabolde <fabrice.gabolde@uperto.com>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011, 2012, 2013 SFR

This library is free software; you can redistribute it and/or modify it under
the terms of the GPLv3.

=cut
