package WebService::Zaqar::Middleware::Format::JSONSometimes;

# ABSTRACT: middleware for JSON format

use JSON;
use Moose;
extends 'Net::HTTP::Spore::Middleware::Format';

has _json_parser => (
    is      => 'rw',
    isa     => 'JSON',
    lazy    => 1,
    default => sub { JSON->new->utf8(1)->allow_nonref },
);

sub encode       { $_[0]->_json_parser->encode( $_[1] ); }
sub decode       { $_[0]->_json_parser->decode( $_[1] ); }
sub accept_type  { ( 'Accept' => 'application/json' ) }
sub content_type { ( 'Content-Type' => 'application/json;' ) }

sub should_serialize {
    my $self = shift;
    $self->_check_serializer( shift->env, $self->serializer_key );
}

sub should_deserialize {
    my ($self, $response) = @_;
    $self->_check_is_authenticated( $response )
        and $self->_check_serializer( $response->env, $self->deserializer_key );
}

sub _check_is_authenticated {
    my ($self, $response) = @_;
    $response->status < 400;
}

sub _check_serializer {
    my ( $self, $env, $key ) = @_;
    if ( exists $env->{$key} && $env->{$key} == 1 ) {
        return 0;
    }
    else {
        return 1;
    }
}

sub call {
    my ( $self, $req ) = @_;

    return unless $self->should_serialize( $req );

    $req->header( $self->accept_type );

    if ( $req->env->{'spore.payload'} ) {
        $req->env->{'spore.payload'} =
          $self->encode( $req->env->{'spore.payload'} );
        $req->header( $self->content_type );
    }

    $req->env->{ $self->serializer_key } = 1;

    return $self->response_cb(
        sub {
            my $res = shift;
            if ( $res->body ) {
                return if $res->code >= 500;
                return unless $self->should_deserialize( $res );
                my $content = $self->decode( $res->body );
                $res->body($content);
                $res->env->{ $self->deserializer_key } = 1;
            }
        }
    );
}

1;
