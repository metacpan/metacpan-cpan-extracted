package WWW::Google::Contacts::Server;
{
    $WWW::Google::Contacts::Server::VERSION = '0.39';
}

use Moose;
use LWP::UserAgent;
use Net::Google::AuthSub;
use Carp qw( croak );

has ua => (
    is      => 'ro',
    default => sub { LWP::UserAgent->new },
);

has authsub => (
    is         => 'ro',
    lazy_build => 1,
);

has username => (
    isa      => 'Str',
    is       => 'ro',
    required => 1,
);

has password => (
    isa      => 'Str',
    is       => 'ro',
    required => 1,
);

has protocol => (
    isa     => 'Str',
    is      => 'ro',
    default => 'http',
);

has gdata_version => (
    isa     => 'Str',
    is      => 'ro',
    default => '3.0',
);

sub _build_authsub {
    my $self = shift;

    my $auth = Net::Google::AuthSub->new( service => 'cp' );
    my $res = $auth->login( $self->username, $self->password );
    unless ( $res and $res->is_success ) {
        if ($res) {
            warn $res->{_response}->content;
        }
        croak "Authentication failed";
    }
    return $auth;
}

sub authenticate {
    my $self = shift;
    return 1 if ( $self->authsub );
}

foreach my $method (qw(get post put delete)) {
    around $method => sub {
        my $orig = shift;
        my $self = shift;
        my $id   = shift;

        # ENSURE we use right protocol.. Even though we've specified https,
        # references in the data from google points to http://
        my $proto = $self->protocol;
        $id =~ s{^\w+://}{$proto://};
        return $self->$orig( $id, @_ );
    };
}

sub get {
    my ( $self, $id ) = @_;

    my %headers = $self->authsub->auth_params;
    $headers{'GData-Version'} = $self->gdata_version;
    my $res = $self->ua->get( $id, %headers );
    unless ( $res->is_success ) {
        croak "GET failed: " . $res->status_line;
    }
    return $res;
}

sub post {
    my ( $self, $id, $etag, $content_type, $content ) = @_;

    my %headers = $self->authsub->auth_params;
    $headers{'Content-Type'}  = $content_type;
    $headers{'GData-Version'} = $self->gdata_version;
    my $res = $self->ua->post( $id, %headers, Content => $content );
    unless ( $res->is_success ) {
        use Data::Dumper;
        print Dumper $res;
        croak "POST failed: " . $res->status_line;
    }
    return $res;
}

sub put {
    my ( $self, $id, $etag, $content_type, $content ) = @_;

    my %headers = $self->authsub->auth_params;
    $headers{'Content-Type'}           = $content_type;
    $headers{'GData-Version'}          = $self->gdata_version;
    $headers{'If-Match'}               = $etag;
    $headers{'X-HTTP-Method-Override'} = 'PUT';
    my $res = $self->ua->post( $id, %headers, Content => $content );
    unless ( $res->is_success ) {
        use Data::Dumper;
        print Dumper $res;
        croak "PUT failed: " . $res->status_line;
    }
    return $res;
}

sub delete {
    my ( $self, $id, $etag ) = @_;

    my %headers = $self->authsub->auth_params;
    $headers{'If-Match'}               = $etag;
    $headers{'X-HTTP-Method-Override'} = 'DELETE';
    $headers{'GData-Version'}          = $self->gdata_version;
    my $res = $self->ua->post( $id, %headers );
    unless ( $res->is_success ) {
        croak "DELETE failed: " . $res->status_line;
    }
    return $res;
}

no Moose;
__PACKAGE__->meta->make_immutable;
1;
__END__
