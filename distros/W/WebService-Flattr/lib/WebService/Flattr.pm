package WebService::Flattr;
{
  $WebService::Flattr::VERSION = '0.55';
}

use strict;
use warnings;

use JSON 'decode_json';
use LWP::UserAgent ();
use URI ();
use URI::QueryParam ();
use URI::Template ();
use WebService::Flattr::Response ();

=head1 NAME

WebService::Flattr - An interface to Flattr's social micro-payment API

=head1 VERSION

version 0.55

=head1 SYNOPSIS

    use WebService::Flattr();

    my $flattr = WebService::Flattr->new;
    my $thing = $flattr->thing_exists("http://www.example.com/")->data;


=head1 DESCRIPTION

This module provides an interface to the L<< http://flattr.com/ >>
social micropayment system.

Flattr have documented their interface at L<<
http://developers.flattr.net/api/ >>.

Currently, this module only implements part of Flattr's interface.
Future versions will implement more features.

=head1 METHODS

=head2 Constructor

=head3 new

  my $flattr = WebService::Flattr->new();

This returns a C<< WebService::Flattr >> object to call L</Request Methods> on.

=cut

sub new {
    my $class = shift;

    my $name = 'WebService::Flattr';
    if ($WebService::Flattr::VERSION) {
        $name .= '/'.  $WebService::Flattr::VERSION;
    }
    my $ua = LWP::UserAgent->new(
        # the space at the end below makes LWP prepend its name and
        # version number
        agent => "${name} ",
        keep_alive => 4,
        max_redirect => 0, # Avoid auto-redirect on thing_exists() success
        protocols_allowed => ['https'],
    );

    return bless {
        ua => $ua,
    }, $class;
}

sub _req {
    my $self = shift;
    my $uri = shift;

    my $resp = $self->{ua}->get($uri, Accept => 'application/json');

    if ($resp->is_error) {
        die $resp->status_line;
    }

    return WebService::Flattr::Response->_new({
        data => decode_json $resp->content,
        response => $resp,
    });
}

=head2 Request Methods

The following request methods perform actions against Flattr's API.
Each method returns a L<< WebService::Flattr::Response >> object on
success and dies on failure.

=head3 user_flattrs

Takes a list or hash reference containing the mandatory I<< username >>
argument and zero or more optional arguments.

L<<
http://developers.flattr.net/api/resources/flattrs/#list-a-users-flattrs
>>

=cut

sub user_flattrs {
    my $self = shift;
    my $arg = @_ == 1 ? shift : { @_ };

    my $tmpl = "https://api.flattr.com/rest/v2/users/{username}/flattrs";
    my $uri = URI::Template->new($tmpl)->process(username => $arg->{username});
    foreach (keys %$arg) {
        $uri->query_param($_, $arg->{$_});
    }

    return $self->_req($uri);
}

=head3 thing_flattrs

Takes a list or hash reference containing the mandatory I<< id >>
argument and zero or more optional arguments.

L<<
http://developers.flattr.net/api/resources/flattrs/#list-a-things-flattrs
>>

=cut

sub thing_flattrs {
    my $self = shift;
    my $arg = @_ == 1 ? shift : { @_ };

    my $tmpl = "https://api.flattr.com/rest/v2/things/{id}/flattrs";
    my $uri = URI::Template->new($tmpl)->process(id => $arg->{id});
    foreach (keys %$arg) {
        $uri->query_param($_, $arg->{$_});
    }

    return $self->_req($uri);
}

=head3 things_owned_by

Takes a list or hash reference containing the mandatory I<< username >>
argument and zero or more optional arguments.

L<<
http://developers.flattr.net/api/resources/things/#list-a-users-things
>>

=cut

sub things_owned_by {
    my $self = shift;
    my $arg = @_ == 1 ? shift : { @_ };

    my $tmpl = "https://api.flattr.com/rest/v2/users/{username}/things";
    my $uri = URI::Template->new($tmpl)->process(username => $arg->{username});
    foreach (keys %$arg) {
        $uri->query_param($_, $arg->{$_});
    }

    return $self->_req($uri);
}

=head3 get_thing

Takes one argument, the ID of a thing.

L<< http://developers.flattr.net/api/resources/things/#get-a-thing >>

=cut

sub get_thing {
    my $self = shift;
    my $id = shift;

    my $tmpl = "https://api.flattr.com/rest/v2/things/{id}";
    my $uri = URI::Template->new($tmpl)->process(id => $id);

    return $self->_req($uri);
}

=head3 get_things

Takes a list of IDs of things to retrieve.

L<<
http://developers.flattr.net/api/resources/things/#get-multiple-things
>>

=cut

sub get_things {
    my $self = shift;
    my $ids = join ",", @_;

    my $uri = URI->new("https://api.flattr.com/rest/v2/things/${ids}");

    return $self->_req($uri);
}

=head3 thing_exists

Takes one argument, the URL of a thing.

L<<
http://developers.flattr.net/api/resources/things/#check-if-a-thing-exists
>>.

=cut

sub thing_exists {
    my $self = shift;
    my $url = shift;

    my $tmpl = "https://api.flattr.com/rest/v2/things/lookup/?url={url}";
    my $uri = URI::Template->new($tmpl)->process(url => $url);

    return $self->_req($uri);
}

=head3 search_things

Takes optional arguments either as a list or a hash reference.

L<< http://developers.flattr.net/api/resources/things/#search-things >>

=cut

sub search_things {
    my $self = shift;
    my $arg = @_ == 1 ? shift : { @_ };

    my $tmpl = "https://api.flattr.com/rest/v2/things/search";
    my $uri = URI::Template->new($tmpl)->process;
    foreach (keys %$arg) {
        $uri->query_param($_, $arg->{$_});
    }

    return $self->_req($uri);
}

=head3 user

Takes one argument, a string containing a username.

L<< http://developers.flattr.net/api/resources/users/#get-a-user >>

=cut

sub user {
    my $self = shift;
    my $username = shift;

    my $tmpl = "https://api.flattr.com/rest/v2/users/{username}";
    my $uri = URI::Template->new($tmpl)->process(username => $username);

    return $self->_req($uri);
}

=head3 user_activities

Takes one argument, a string containing a username.

L<<
http://developers.flattr.net/api/resources/activities/#list-an-users-activities
>>

=cut

sub user_activities {
    my $self = shift;
    my $username = shift;

    my $tmpl = "https://api.flattr.com/rest/v2/users/{username}/activities";
    my $uri = URI::Template->new($tmpl)->process(username => $username);

    return $self->_req($uri);
}

=head3 categories

Takes no arguments.

L<<
http://developers.flattr.net/api/resources/categories/#list-categories
>>

=cut

sub categories {
    my $self = shift;

    return $self->_req("https://api.flattr.com/rest/v2/categories");
}

=head3 languages

Takes no arguments.

L<<
http://developers.flattr.net/api/resources/languages/#list-all-available-languages
>>

=cut

sub languages {
    my $self = shift;

    return $self->_req("https://api.flattr.com/rest/v2/languages");
}

=head3 rate_limit

Takes no arguments.

L<< http://developers.flattr.net/api/#rate-limiting >>

=cut

sub rate_limit {
    my $self = shift;

    return $self->_req("https://api.flattr.com/rest/v2/rate_limit");
}

1;
__END__
=head1 SUPPORT

Flattr request that you post questions about their API to StackOverflow.
See L<< http://developers.flattr.net/api/questions/ >> for details.

If you would like help using WebService::Flattr, please post there using
the I<< flattr >> tag as they request and the I<< perl >> tag also.

=head1 BUG REPORTS

Please submit bug reports to L<<
https://rt.cpan.org/Public/Dist/Display.html?Name=WebService-Flattr >>.

If you would like to send patches, please send a git pull request to L<<
mailto:bug-WebService-Flattr@rt.cpan.org >>.  Thank you in advance for
your help.

=head1 SEE ALSO

L<< http://developers.flattr.net/api/ >>

L<< WebService::Flattr::Response >>

=head1 AUTHOR

Tom Hukins

=cut
