package WebService::FritzBox;
# ABSTRACT: Interface to FritzBox devices
use Digest::MD5 qw/md5_hex/;
use JSON::MaybeXS;
use LWP::UserAgent;
use Log::Log4perl;
use Moose;
use MooseX::Params::Validate;
use Try::Tiny;
use YAML;
BEGIN { Log::Log4perl->easy_init() };
our $VERSION = 0.010;

with "MooseX::Log::Log4perl";

=head1 NAME

WebService::FritzBox

=head1 DESCRIPTION

Interact with FritzBox devices

=head1 ATTRIBUTES

=cut

with "MooseX::Log::Log4perl";

=over 4

=item password

Required.

=cut
has 'password' => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
    );

=item host

Optional.  Default: fritz.box

=cut
has 'host' => (
    is		=> 'ro',
    isa		=> 'Str',
    required	=> 1,
    default     => 'fritz.box',
    );

=item use_https

Optional.  Default: 0

=cut

has 'use_https' => (
    is		=> 'ro',
    isa		=> 'Bool',
    );

=item user_agent

Optional.  A new LWP::UserAgent will be created for you if you don't already have one you'd like to reuse.

=cut

has 'user_agent' => (
    is		=> 'ro',
    isa		=> 'LWP::UserAgent',
    required	=> 1,
    lazy	=> 1,
    builder	=> '_build_user_agent',

    );

=item loglevel

Optional.

=cut

has 'loglevel' => (
    is		=> 'rw',
    isa		=> 'Str',
    trigger     => \&_set_loglevel,
    );

has 'base_url' => (
    is		=> 'ro',
    isa		=> 'Str',
    required	=> 1,
    lazy	=> 1,
    builder	=> '_build_base_url',
    );

has 'sid' => (
    is		=> 'ro',
    isa		=> 'Str',
    required	=> 1,
    lazy	=> 1,
    builder	=> '_build_sid',
    );

sub _build_user_agent {
    my $self = shift;
    $self->log->debug( "Building useragent" );
    my $ua = LWP::UserAgent->new(
	keep_alive	=> 1
    );
   # $ua->default_headers( $self->default_headers );
    return $ua;
}

sub _build_base_url {
    my $self = shift;
    my $base_url = 'http' . ( $self->use_https ? 's' : '' ) . '://' . $self->host;
    $self->log->debug( "Base url: $base_url" );
    return $base_url;
}

sub _build_sid {
    my $self = shift;

    my $response = $self->user_agent->get( $self->base_url . '/login_sid.lua' );
    $self->log->trace( "Login (get challenge) http response:\n" . Dump( $response ) ) if $self->log->is_trace;
    my( $challenge_str ) = ( $response->decoded_content =~ /<Challenge>(\w+)/i );
    # generate a response to the challenge
    my $ch_pw = $challenge_str . '-' . $self->password;
    $ch_pw =~ s/(.)/$1 . chr(0)/eg;
    my $md5 = lc(md5_hex($ch_pw));
    my $challenge_response = $challenge_str . '-' . $md5;
    # Get session id
    $response = $self->user_agent->get( $self->base_url . '/login_sid.lua?user=&response=' . $challenge_response );
    $self->log->trace( "Login (challenge sent) http response :\n" . Dump( $response ) ) if $self->log->is_trace;

    # Read session id from XMl
    my( $sid ) = ( $response->content =~ /<SID>(\w+)/i );
    $self->log->debug( "SID: $sid" );
    return $sid;
}

sub _set_loglevel {
    my( $self, $new, $old ) = @_;
    $self->log->level( $new );
}


=back

=head1 METHODS

=over 4

=item init

Create the user agent log in (get a sid).

=cut

sub init {
    my $self = shift;
    my $ua = $self->user_agent;
    my $sid = $self->sid;
}

=item get

Get some path from the FritzBox.  e.g.
    
  my $response = $fb->get( path => '/internet/inetstat_monitor.lua?useajax=1&xhr=1&action=get_graphic' ); 

Returns the HTTP::Response object

=cut

sub get {
    my ( $self, %params ) = validated_hash(
        \@_,
        path        => { isa    => 'Str' },
    );

    my $response = $self->user_agent->get(
        $self->base_url .
        $params{path} .
        ( $params{path} =~ m/\?/ ? '&' : '?' ) .
        'sid=' . $self->sid );
    $self->log->trace( Dump( $response ) ) if $self->log->is_trace;
    return $response;
}

=item post

POST some path from the FritzBox.  e.g.
    
  my $response = $fb->post( path => '/system/syslog.lua?delete=1' ); 

Returns the HTTP::Response object

=cut

sub post {
    my ( $self, %params ) = validated_hash(
        \@_,
        path        => { isa    => 'Str' },
        content     => { isa    => 'Str', optional => 1 }
    );

    $params{content} .= ( $params{content} ? '&' : '' ) . 'sid=' . $self->sid;

    my $response = $self->user_agent->post(
        $self->base_url .
        $params{path},
        Content => $params{content}
        );
    $self->log->trace( Dump( $response ) ) if $self->log->is_trace;
    return $response;
}

=item bandwidth

A wrapper around the /inetstat_monitor endpoint which responds with a normalised hash.  The monitor web page
on the fritz.box refreshes every 5 seconds, and it seems there is a new value every 5 seconds... 5 seconds is
probably a reasonable lowest request interval for this method.

Example response:

    ---
    available:
      downstream: 11404000
      upstream: 2593000
    current:
      downstream:
        internet: 303752
        media: 0
        total: 303752
      upstream:
        default: 33832
        high: 22640
        low: 0
        realtime: 1600
        total: 58072
    max:
      downstream: 342241935
      upstream: 655811

The section C<current> represents the current (last 5 seconds) bandwith consumption.
The value C<current.downstream.total> is the sum of the C<media> and C<internet> fields
The value C<current.upstream.total> is the sum of the respective C<default>, C<high>, C<low> and C<realtime> fields
The section C<available> is the available bandwidth as reported by the DSL modem.
The section C<max> represents

=cut
sub bandwidth {
    my $self = shift;

    my $response = $self->get( path => '/internet/inetstat_monitor.lua?useajax=1&xhr=1&action=get_graphic' );
    $self->log->trace( Dump( $response ) ) if $self->log->is_trace();
    if( not $response->is_success ){
        $self->log->logdie( "Request failed: ($response->code): $response->decoded_content" );
    }
    my $data;
    try{
        $data = decode_json( $response->decoded_content );
        # It's just an array with one element...
        $data = $data->[0];
    }catch{
        $self->log->logdie( "Could not decode json: $_" );
    };
    
    # There is an array of values for every key, but we just want to capture the latest one
    my %latest;
    foreach( qw/prio_default_bps prio_high_bps prio_low_bps prio_realtime_bps mc_current_bps ds_current_bps/ ){
        # all the '_bps' entries are bytes per second... multiply by 8 to normalise to bits per second
        $latest{$_} = ( split( ',', $data->{$_} ) )[0] * 8;
    }
    my $document = {
        "available" => {
            "upstream"      => int( $data->{upstream} ),
            "downstream"    => int( $data->{downstream} ),
        },
        "max" => {
            "upstream"   => int( $data->{max_us} ),
            "downstream" => int( $data->{max_ds} ),
        },
        "current" => {
            "upstream" => {
                "low"       => int( $latest{prio_low_bps} ),
                "default"   => int( $latest{prio_default_bps} ),
                "high"      => int( $latest{prio_high_bps} ),
                "realtime"  => int( $latest{prio_realtime_bps} ),
                "total"     => $latest{prio_low_bps} + $latest{prio_default_bps} + $latest{prio_high_bps} + $latest{prio_realtime_bps},
            },
            "downstream" => {
                "internet"  => int( $latest{ds_current_bps} ),
                "media"     => int( $latest{mc_current_bps} ),
                "total"     => $latest{ds_current_bps} + $latest{mc_current_bps},
            },
        }
    };

    # Info if the current bandwidth is higher than what we expect to have available (this is not a problem, but
    # it is odd...)
    # Occasionally (when DSL reconnects) there can be massive spikes... maybe these should be cut out?
    if( $document->{current}{upstream}{total} > $document->{available}{upstream} ){
        $self->log->info( sprintf( "Upstream total (%u) is greater than the available bandwidth (%u)",
            $document->{current}{upstream}{total}, $document->{available}{upstream} ) );
    }
    if( $document->{current}{downstream}{total} > $document->{available}{downstream} ){
        $self->log->info( sprintf( "Downstream total (%u) is greater than the available bandwidth (%u)",
            $document->{current}{downstream}{total}, $document->{available}{downstream} ) );
    }

    return $document;
}

1;

=back

=head1 COPYRIGHT

Copyright 2015, Robin Clarke 

=head1 AUTHOR

Robin Clarke <robin@robinclarke.net>
