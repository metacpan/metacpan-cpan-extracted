package WWW::Namecheap::API;

use 5.006;
use strict;
use warnings;
use Carp();
use LWP::UserAgent ();
use URI::Escape;
use XML::Simple;

# For convenience methods
use WWW::Namecheap::Domain ();
use WWW::Namecheap::DNS ();

=head1 NAME

WWW::Namecheap::API - Perl interface to the Namecheap API

=cut

our $VERSION = '0.06';
our %APIURL = (
    prod => 'https://api.namecheap.com/xml.response',
    test => 'https://api.sandbox.namecheap.com/xml.response',
);

=head1 SYNOPSIS

Perl interface to the Namecheap API.  API details at:

    https://www.namecheap.com/support/api/api.aspx

Actual API calls happen in the other modules in the distribution, which
can be accessed via convenience methods from an API object.  Brief
example:

    use WWW::Namecheap::API;

    my $api = WWW::Namecheap::API->new(
        System => 'test',
        ApiUser => 'wwwnamecheapapi',
        ApiKey => 'keyhere',
        DefaultIp => '1.2.3.4',
    );

    my $result = $api->domain->check(Domains => ['example.com']);

    if ($result->{'example.com'}) {
        $api->domain->create(
            DomainName => 'example.com',
            Years => 1,
            Registrant => {
                OrganizationName => 'Foo Bar Inc.',
                FirstName => 'Joe',
                LastName => 'Manager',
                Address1 => '123 Fake Street',
                City => 'Univille',
                StateProvince => 'SD',
                PostalCode => '12345',
                Country => 'US',
                Phone => '+1.2125551212',
                EmailAddress => 'joe@example.com',
            },
        );
    }

=head1 GLOBAL PARAMETERS

There are a few parameters that can be included in any of the individual
methods within the Namecheap API modules.  These are listed below.

=head2 ClientIp

The client IP address for which this request is effective.  If a DefaultIp
was not provided when setting up the parent API object, this parameter
is required, otherwise it is optional.

=head2 UserName

A sub-user (see L<WWW::Namecheap::User>) under which the command should
be performed.  A DefaultUser may be specified at API object creation
time; if one is not specified there, the default is to use the ApiUser
unless a UserName is provided for the specific command being issued.

=head1 SUBROUTINES/METHODS

=head2 WWW::Namecheap::API->new(%hash)

Instantiate a new API object.  Example:

    my $api = WWW::Namecheap::API->new(
        System  => 'test', # or 'prod' for production, default test
        ApiUser => 'username',
        ApiKey  => 'apikey',
        DefaultIp   => '1.2.3.4', # optional
        DefaultUser => 'otheruser', #optional, default ApiUser
        ApiUrl => 'https://foo.bar/', # overrides URL chosen by System
        Agent  => 'My API Agent/1.0', # optional, overrides default UA
    );

Only ApiUser and ApiKey are required, in which case System will default
to 'test' and Agent defaults to 'WWW::Namecheap::API/$VERSION'.  This
API object will be passed to the constructors of the other classes in
the distribution (or you can use its built-in convenience methods to
get objects of those classes directly).

=cut

sub new {
    my $class = shift;

    my $params = _argparse(@_);

    for (qw(ApiUser ApiKey)) {
        Carp::croak("${class}->new(): Mandatory parameter $_ not provided.") unless $params->{$_};
    }

    my $ua = LWP::UserAgent->new(
        agent => $params->{'Agent'} || "WWW::Namecheap::API/$VERSION",
    );

    my $apiurl;
    if ($params->{'ApiUrl'}) {
        $apiurl = $params->{'ApiUrl'}; # trust the user?!?!
    } else {
        if ($params->{'System'}) {
            $apiurl = $APIURL{$params->{'System'}};
        } else {
            $apiurl = $APIURL{'test'};
        }
    }

    my $self = {
        ApiUrl => $apiurl,
        ApiUser => $params->{'ApiUser'},
        ApiKey => $params->{'ApiKey'},
        DefaultUser => $params->{'DefaultUser'} || $params->{'ApiUser'},
        DefaultIp => $params->{'DefaultIp'},
        _ua => $ua,
    };

    return bless($self, $class);
}

=head2 $api->request(%hash)

Send a request to the Namecheap API.  Returns the XML response parsed into
Perl form by XML::Simple.  Intended for use by sub-classes, not outside
calls.  Parameters should be of the type and quantity required by the
Namecheap API for the given Command.  Example:

    my $xml = $api->request(
        Command => 'namecheap.domains.check',
        DomainList => 'example.com,example2.net',
        ClientIp => '1.2.3.4', # required if no DefaultIp in $api
    );

=cut

sub request {
    my $self = shift;
    my %reqparams = @_;

    unless ($reqparams{'Command'}) {
        Carp::carp("No command specified, bailing!");
        return;
    }

    my $clientip = delete($reqparams{'ClientIp'}) || $self->{'DefaultIp'};
    unless ($clientip) {
        Carp::carp("No Client IP or default IP specified, cannot perform request.");
        return;
    }
    my $username = delete($reqparams{'UserName'}) || $self->{'DefaultUser'};

    map { delete($reqparams{$_}) unless defined($reqparams{$_}) } keys %reqparams;

    my $ua = $self->{_ua}; # convenience
    my $url = sprintf('%s?ApiUser=%s&ApiKey=%s&UserName=%s&Command=%s&ClientIp=%s&',
        $self->{'ApiUrl'}, $self->{'ApiUser'}, $self->{'ApiKey'},
        $username, delete($reqparams{'Command'}), $clientip);
    $url .= join('&', map { join('=', map { uri_escape($_) } each %reqparams) } keys %reqparams);
    #print STDERR "Sent URL $url\n";
    my $response = $ua->get($url);

    unless ($response->is_success) {
        Carp::carp("Request failed: " . $response->message);
        return;
    }

    my $xml = XMLin($response->content);

    if ($xml->{Status} eq 'ERROR') {
        $self->{_error} = $xml;
        return;
    }
    return $xml;
}

=head2 $api->domain()

Helper method to create and return a WWW::Namecheap::Domain object utilizing
this API object.  Always returns the same object within a given session via
internal caching.

=cut

sub domain {
    my $self = shift;

    if ($self->{_domain}) {
        return $self->{_domain};
    }

    return $self->{_domain} = WWW::Namecheap::Domain->new(API => $self);
}

=head2 $api->dns()

Helper method to create and return a WWW::Namecheap::DNS object utilizing
this API object.  Always returns the same object within a given session via
internal caching.

=cut

sub dns {
    my $self = shift;

    if ($self->{_dns}) {
        return $self->{_dns};
    }

    return $self->{_dns} = WWW::Namecheap::DNS->new(API => $self);
}

=head2 $api->error()

Returns the full XML response from the API if an error occurred during
the request.  Most likely key of interest is $xml->{Errors} and below.

=cut

sub error {
    return $_[0]->{_error};
}

sub _argparse {
    my $hashref;
    if (@_ % 2 == 0) {
        $hashref = { @_ }
    } elsif (ref($_[0]) eq 'HASH') {
        $hashref = \%{$_[0]};
    }
    return $hashref;
}

=head1 AUTHOR

Tim Wilde, C<< <twilde at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-www-namecheap-api at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WWW-Namecheap-API>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.



=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WWW::Namecheap::API


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WWW-Namecheap-API>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WWW-Namecheap-API>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WWW-Namecheap-API>

=item * Search CPAN

L<http://search.cpan.org/dist/WWW-Namecheap-API/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2011 Tim Wilde.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of WWW::Namecheap::API
