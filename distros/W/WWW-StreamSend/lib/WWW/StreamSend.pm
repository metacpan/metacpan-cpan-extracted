package WWW::StreamSend;

use 5.010001;
use strict;
use warnings;

use AutoLoader qw(AUTOLOAD);

use LWP::UserAgent;
use XML::Simple;
use Carp ();

use WWW::StreamSend::Audience;
use WWW::StreamSend::Subscriber;

our $VERSION = '0.03';

sub new {
    my ($class, $params) = @_;

    Carp::croak("Options to WWW::StreamSend should be hash reference")
        if ref($params) ne ref {};

    my $self = {
        login_id => $params->{login_id} || $params->{login},
        key => $params->{key},
        ua  => LWP::UserAgent->new,
        xs  => XML::Simple->new,
    };

    $self->{ua}->agent("Mozilla/5.0");

    bless $self => $class;
    return $self;
}

sub get_emails {
    my ($self) = @_;
    my $res = $self->_send_request('emails');

    return $res->{content};
}

sub get_subscribers {
    my ($self, $params) = @_;
    my $audience = $params->{audience};
    my $id = $params->{subscriber_id};

    # /audiences/1/people.xml
    my $res = $self->_send_request('audiences', $audience.'/people/'.$id);
    return $res->{content};
}

sub get_subscribers_count {
    my ($self, $params) = @_;

    my $type = $params->{type} || 'active'; # possible variations: 'inactive', 'unsubscribed', 'pending'
    my $xmldata = $self->get_field({field => 'audiences', id => $params->{id}});
    my $ref = $self->{xs}->XMLin($xmldata, ForceArray=>1);

    return $ref->{audience}->[0]->{$type.'-people-count'}->[0]->{content};
}

sub get_field {
    my ($self, $params) = @_;
    my $accepted_fields = {
        emails => 'emails',
        users => 'users',
        audiences => 'audiences',
    };
    my $res = (ref $params eq ref {}) ?
        $self->_send_request($accepted_fields->{$params->{field}}, $params->{id}) :
        $self->_send_request($accepted_fields->{$params});
    return $res->{content};
}

sub get_people {
    my ($self, $params) = @_;
}

sub get_audience {
    my ($self, $params) = @_;
    my $res = (exists $params->{id}) ?
        $self->_send_request('audiences', $params->{id}) :
        $self->_send_request('audiences');

    if ($res->{code} == '200') {
        my $xml = $res->{content};
        my $data = XMLin($xml, ForceArray=>1);

        if ($data->{type} || $data->{type} eq 'array') {
            my @ret = ();
            foreach my $item (@{$data->{audience}}) {
                my $audience = WWW::StreamSend::Audience->new({xml => '', data => $item});
                push @ret, $audience;
            }
            return @ret;
        }
        else { # 1 audience
            my $audience = WWW::StreamSend::Audience->new({xml => $xml, data => $data});
            return $audience;
        }
    }
    return;
}

sub add_subscriber {
    my ($self, $params) = @_;
    my $res = $self->_send_request(
        'audiences',
        $params->{audience}.'/people',
        {
            'person' => {
                'email-address' => $params->{'email-address'},
                'first-name' => $params->{'first-name'},
                'last-name' => $params->{'last-name'},
                'deliver-welcome' => $params->{'deliver-welcome'} || 'true'
            }
        }
    );

    return $res->{code} == 200 ? 1 : 0;
}

sub _send_request {
    # http://app.streamsend.com/docs/api/index.html
    my ($self, $rest, $id, $postdata) = @_;

    my $url = 'https://app.streamsend.com/'.$rest;
    $url.='/'.$id if $id;

    my $method = $postdata ? 'POST' : 'GET';

    my $req = HTTP::Request->new($method => $url);
    $req->header(
        Accept => 'application/xml',
    );
    $req->authorization_basic ($self->{login_id}, $self->{key});

    if ($postdata) {
        $req->content_type('text/xml');
        my $xml = $self->{xs}->XMLout($postdata, NoAttr => 1, RootName => undef);
        $req->content("$xml");
    }

    my $res = $self->{ua}->request($req);

    if ($res->is_success) {
        return ({code => 200, content => $res->content});
    }
    else {
        return ({code => $res->code, content => $res->status_line});
    }
}

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__

=head1 NAME

WWW::StreamSend - StreamSend API implementation

=head1 SYNOPSIS

  use WWW::StreamSend;

  my $ss = WWW::StreamSend->new({login_id => 'login_id', key => 'key'});

  my $user_info = $ss->get_field({
    field => 'users',
    id => 1
  });

  my $audience = $ss->get_field({
    field => 'audiences',
    id => 1
  });

  my $active_users_in_audience = $ss->get_subscribers_count({
    audience => 1,
    type => 'active'
  });


=head1 DESCRIPTION

A Perl implementation of the StreamSend mailing list management API

=head1 CONSTRUCTOR METHOD

The following constructor method is available:

=over 4

=item $ss = WWW::StreamSend->new( \%options )

This method constructs a new C<StreamSend::API> object and returns it.
Key/value pair arguments must be provided to set up the initial state.
The following options are accepted:

  login_id
  key

login_id and key are mandatory

=back

=head1 REQUEST METHODS

The methods described in this section are used to dispatch requests. The following request methods are provided:

=over

=item $ss->get_emails( )

This method will dispatch a C<GET> request to fetch all saved emails for the account.
It realises the Public Instant method C<index()> of StreamSend Emails API
Returns the XML data on success

=item $ss->get_subscribers( \%options )

This method will dispatch a C<GET> request to fetch subscribers in given audience.
It realises the Public Instant methods C<index()> and C<show()> of StreamSend People API
Returns the XML data on success

The following options are accepted:

  audience - ID of audience, mandatory option
  subscriber_id - ID of current subscriber. If no subscriber_id given, method returns ALL subscribers in given audience

=item $ss->get_subscribers_count( \%options )

Returns the counter value for subscribers in given audience. Example:
  
  my $count = $ss->get_subscribers_count({audience => 1, type => 'active'});

Available values for 'type' key are: 'active', 'inactive', 'unsubscribed', 'pending'

=item $ss->get_audience( \%options )

Dispatch a C<GET> request to fetch current audience or audience list. Example:

  my $audience = $ss->get_audience({id => 1});
  my @audiences_all = $ss->get_audience;

Returns either one L<WWW::StreamSend::Audience> instance or list of them.

=item $ss->add_subscriber( \%options )

Dispatch a C<POST> request to add new subscriber to given audience.
Realises the Public Instant method C<create()> of StreamSend People API

Mandatory options:

    email-address
    first-name
    last-name

Optional:

    deliver-welcome (default value is 'true')

=back

=head1 SEE ALSO

http://app.streamsend.com/docs/api/index.html

=head1 AUTHOR

Michael Katasonov, E<lt>dionabak@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 by Michael Katasonov

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.


=cut
