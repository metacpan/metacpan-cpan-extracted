package Voldemort::ProtoBuff::DeleteMessage;

use Moose;
use Voldemort::ProtoBuff::BaseMessage;
use Carp;

extends 'Voldemort::ProtoBuff::BaseMessage';

sub write {
    my $self       = shift;
    my $connection = shift;
    my $store      = shift;
    my $key        = shift;
    my $node       = shift || 0;

    my $entries = $self->_get_entries($node);

    my $data = Voldemort::ProtoBuff::Spec2::VoldemortRequest->encode(
        {
            'type'   => Voldemort::ProtoBuff::Spec2::RequestType::DELETE(),
            'store'  => $store,
            'delete' => Voldemort::ProtoBuff::Spec2::DeleteRequest->new(
                {
                    key       => $key,
                    'version' => Voldemort::ProtoBuff::Spec2::VectorClock->new(
                        {
                            timestamp => time(),
                            entries   => $entries
                        }
                    )
                }
            )
        }
    );

    $connection->send( pack( 'N', length($data) ) );
    $connection->send($data);
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
    $data = Voldemort::ProtoBuff::Spec2::DeleteResponse->decode($data)
      || carp($!);

    my $message =
      defined $data->error() ? $data->error()->error_message() : undef;
    return $data->success(), $message;
}

1;
