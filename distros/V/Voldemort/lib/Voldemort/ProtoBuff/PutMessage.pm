package Voldemort::ProtoBuff::PutMessage;

use Moose;
use IO::Select;
use Carp;
use Scalar::Util qw(reftype);

use Voldemort::Message;
use Voldemort::ProtoBuff::Spec2;
use Voldemort::ProtoBuff::BaseMessage;

extends 'Voldemort::ProtoBuff::BaseMessage';

sub write {
    my $self       = shift;
    my $connection = shift;
    my $store      = shift;
    my $key        = shift;
    my $value      = shift;
    my $node       = shift || 0;

    my $entries = $self->_get_entries($node);

    my $data = Voldemort::ProtoBuff::Spec2::VoldemortRequest->encode(
        {
            'type'  => Voldemort::ProtoBuff::Spec2::RequestType::PUT(),
            'store' => $store,
            'put'   => Voldemort::ProtoBuff::Spec2::PutRequest->new(
                {
                    versioned => Voldemort::ProtoBuff::Spec2::Versioned->new(
                        {
                            value => $value,
                            version =>
                              Voldemort::ProtoBuff::Spec2::VectorClock->new(
                                {
                                    timestamp => time(),
                                    entries   => $entries
                                }
                              )
                        }
                    ),
                    key => $key
                }
            )
        }
    );

    $connection->send( pack( 'N', length($data) ) );
    $connection->send($data);
    return;
}

sub read {
    my $self       = shift;
    my $connection = shift;
    my $store      = shift;
    my $key        = shift;

    my $size = $connection->recv(4);
    $size = unpack( 'N', $size );
    return if !$size;

    my $data = $connection->recv($size);
    $data = Voldemort::ProtoBuff::Spec2::PutResponse->decode($data) || carp($!);
    return $data->{'error'}->{'error_code'},
      $data->{'error'}->{'error_message'};
}
1;

