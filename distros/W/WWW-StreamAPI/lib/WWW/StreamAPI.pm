package WWW::StreamAPI;

use Carp qw( carp croak );
use Time::HiRes qw( gettimeofday );
use Digest::MD5 qw( md5_hex );
use Data::Dumper qw( Dumper );
use XML::Simple qw( XMLin );
use LWP::UserAgent;
use UNIVERSAL::require;


our $VERSION = '0.01';

use base 'Class::Accessor::Fast';

=pod

=head1 NAME

    WWW::StreamAPI - Perl interface for the HTTP StreamAPI API

=head1 SYNOPSIS

    use WWW::StreamAPI;

    my $streamapi = WWW::StreamAPI->new(
        secret_key => 'YOUR_SECRET_KEY_HERE',
        api_key => 'YOUR_API_KEY_HERE',
        debug => 1,
    );

    # Fetch a list of live sessions using the simple request method.
    my $live_session_list = $streamapi->request('/session/live/list');
    print Dumper \$live_session_list;

    # Using the live_sessions helper method.
    my @live_sessions = $streamapi->live_sessions;
    print Dumper \@live_sessions;

    # Request a list of all recordings.
    my $recordings = $streamapi->request('/video/list');
    print Dumper \$recordings;



=head1 DESCRIPTION

A minimal Perl interface to the HTTP API for StreamAPI. L<http://streamapi.com>

=head1 Methods

=cut

__PACKAGE__->mk_accessors(qw( base_url api_key secret_key user_agent timeout debug ));

sub new {
    my ($class, %args) = @_;

    my $self = {};

    bless $self, $class;

    $self->base_url($args{base_url} || 'http://api.streamapi.com/service');
    $self->api_key($args{api_key} || croak 'REQUIRED argument No api_key was NOT specified. Dying.');
    $self->secret_key($args{secret_key} || croak 'REQUIRED argument secret_key was NOT specified. Dying.');

    $self->timeout($args{timeout} || 30);
    $self->debug($args{debug} || 0);

    $self->user_agent(LWP::UserAgent->new(
        agent => __PACKAGE__  . '/' . $VERSION,
        timeout => $self->timeout,
    ));

    if ($self->debug) {
        carp 'base_url: ' . $self->base_url;
        carp 'api_key: ' . $self->api_key;
        carp 'secret_key: ' . $self->secret_key;
        carp 'debug: ' . $self->debug;
        carp 'timeout: ' . $self->timeout;
    }

    return $self;
}

=pod

=head2 C<request>

    The first parameter is the HTTP path to call, so '/video/list' becomes http://api.streamapi.com/service/video/list.

    The second parameter is a hashref of arguments to send along with the required parametes (rid, sig, api key).

    The third parameter sets the HTTP request method. The default method is GET.

    Examples:

    my $request= $streamapi->request('/video/list');

    my $request = $stickam->request('/path/to/call', { arg1 => 'val1' });

    my $request = $stickam->request('/path/to/call', { arg1 => 'val1' }, 'POST');

    The return value is always the datastructure returned by XML::Simple::XMLin.

=cut

sub request {
    my ($self, $call_uri, $args, $method) = @_;

    $method ||= 'GET';

    my $request_id = int(gettimeofday * 1000);

    $args->{rid} = $request_id;
    $args->{key} = $self->api_key;

    my $signature = '';

    foreach my $key (sort keys %{$args}) {
        next if $key eq 'rid';
        $signature .= $args->{$key};
    }

    $args->{sig} = md5_hex($signature . $self->secret_key . $request_id);

    my $response;

    my $uri = URI->new($self->base_url . $call_uri);

    if ($self->debug) {
        carp "$method: Using URL '$uri'";
    }

    if ($method eq 'GET') {
        $uri->query_form(%{$args});
        $response = $self->user_agent->get($uri->as_string);
    } elsif ($method eq 'POST') {
        $response = $self->user_agent->post($uri->as_string, $args);
    }

    if ($response->is_success) {

        my $content = $response->content;

        if ($self->debug) {
            carp "XML response: $content\n";
        }

        my $xml = eval { XMLin $content };


        if (defined $xml and $xml) {

            if ($xml->{code} == 0) {
                return $xml;
            } else {
                if ($self->debug) {
                    carp "HTTP response was successful but response code was non-zero:\n$content";
                    if ($method eq 'POST') {
                        carp "POST parameters:";
                        carp "\t$k => '$v'" while (my ($k, $v) = each %{$args});
                    }
                }
            }

        } else {

            if ($self->debug) {
                carp "No XML able to parse";
            }

        }

    } else {
        if ($self->debug) {
            carp "HTTP response unsuccessful: " . $response->status_line;
        }
    }
}

=pod

=head2 C<live_sessions>

    my @live_sesions = $streamapi->live_sessions;

=cut

sub live_sessions {
    my ($self) = @_;

    my $result = $self->request('/session/live/list');

    unless (defined $result->{live_sessions} and defined $result->{live_sessions}->{session}) {
        return;
    }

    my $session = $result->{live_sessions}->{session};

    return (ref $session eq 'HASH') ? $session : return @{$session};
}

=pod

=head2 C<create_session>

    my ($private_hostid, $public_hostid) = $streamapi->create_session;

or

    my ($private_hostid, $public_hostid) = $streamapi->create_session( username => 'Peter' );

=cut

sub create_session {
    my $self = shift;
    my %args = (@_ >= 2) ? @_ : ();

    my $result = $self->request('/session/create', \%args, 'POST');

    return ($result->{private_hostid}, $result->{public_hostid});
}

=head1 COPYRIGHT

Copyright 2008, 2009 by Stickam.com E<lt>support@stickam.comE<gt>

This program is free software; you can redistribute it and/or 
modify it under the same terms as Perl itself.

See F<http://www.perl.com/perl/misc/Artistic.html>

=head1 AUTHOR

Jake Gold <jake@stickam.com>

=head1 SEE ALSO

L<http://streamapi.com>

=cut


1;
