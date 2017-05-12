package Voldemort::ProtoBuff::GetMessage;

use Moose;
use Voldemort::Message;
use Voldemort::ProtoBuff::DefaultResolver;
use Voldemort::ProtoBuff::Spec2;
use IO::Select;
use Carp;

with 'Voldemort::Message';

has 'resolver' => (
    'is'      => 'rw',
    'default' => sub { Voldemort::Protobuff::DefaultResolver->new() },
    'lazy'    => 1
);

sub write {
    my $self       = shift;
    my $connection = shift;
    my $store      = shift;
    my $key        = shift;

    my $data = Voldemort::ProtoBuff::Spec2::VoldemortRequest->encode(
        {
            'type'  => Voldemort::ProtoBuff::Spec2::RequestType::GET(),
            'store' => $store,
            'get' =>
              Voldemort::ProtoBuff::Spec2::GetRequest->new( { key => $key } )
        }
    );

    $connection->send( pack( 'N', length($data) ) );
    $connection->send($data);
    return;
}

sub read {
    my $self       = shift;
    my $connection = shift;

    my $size = $connection->recv(4);
    $size = unpack( 'N', $size );
    my $data;
    if ($size) {
        $data = $connection->recv($size);
        $data = Voldemort::ProtoBuff::Spec2::GetResponse->decode($data)
          || carp($!);
        $data = $data->versioned();
        return $self->resolver()->resolve($data);
    }
    return;
}
1;
