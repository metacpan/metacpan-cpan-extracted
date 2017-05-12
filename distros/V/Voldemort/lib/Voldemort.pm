package Voldemort;
use strict;

BEGIN {
    use Exporter ();
    use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
    $VERSION     = '0.11';
    @ISA         = qw(Exporter);
    @EXPORT      = qw();
    @EXPORT_OK   = qw();
    %EXPORT_TAGS = ();
}



=head1 NAME

Voldemort - A voldemort client and infrastructure

=head1 SYNOPSIS

Voldemort::Store is a basic client to get, delete and put data.  The goal is not to be a complete POE enabled, client-side load-balancing client but a simpler sync/async client that communicates with a server.  The desire is this client can be embeded in larger structures, or not.

An admin client should be coming soon. 

=head1 DESCRIPTION

This distribution includes a few classes, the primary are:

=head2 Voldemort::Store

A top level API for communicating with a Voldemort::Connection

=head2 Voldemort::Connection 

An interface for the store to communicate to a server using sync/async methods.

=head2 Voldemort::Message

An interface for message marshalling/unmarshalling messages. When a store sends a message, in asyncronous mode it will store a reference to the implemented message to unmarshall the next message.  

=head2 Voldemort::Protobuff::Connection

An implementation of Voldemort::Connection using Protocol Buffers.

=head2 Voldemort::ProtoBuff::GetMessage

=head2 Voldemort::ProtoBuff::DeleteMessage

=head2 Voldemort::ProtoBuff::PutMessage

=head2 Voldemort::ProtoBuff::Spec2

Implementations of the various marshalling/unmarshalling from Protocol Buffer byte data to real data.  Spec2 is a generated module for protocol buffers that is used by Get/Delete/PutMessage.  They are automatically created and set when Voldemort::Connection::Protobuff is instanciated, by default.

=head2 Voldemort::ProtoBuff::Resolver

=head2 Voldemort::ProtoBuff::DefaultResolver

An interface for dealing with multiple vectors (versions) in voldemort for a given key.  If vector clocks are not used, it is entirely possible to ignore this class.  The implementation, DefaultResolver is defaulted when Voldemort::ProtoBuff::GetMessage is instanciated.  If two vectors exist for a given piece of data, the resolver will carp.  If vector clocks are not used, where all node ids are defaulting to 0, the default implementation will be fine, otherwise implement your own strategy.

Implementing your own resolver entails handling an array of Voldemort::ProtoBuff::Spec2::Versioned objects.  Each element in the array represents a vector owned by an entity (or group of entites, which is a composite entity) and a value.  In the USAGE section is an example that takes multiple vectors and merges the result.

=head1 USAGE

=head2 Quick start, no vector clocks

    use strict;
    use Moose;

    use Voldemort::Store;
    use Voldemort::ProtoBuff::Connection;

    my $connection = Voldemort::ProtoBuff::Connection->new(
        'to' => 'localhost:6666'
    );

    my $store = new Voldemort::Store( connection => $connection  );
    $store->default_store('test');
    $x->put( key=>1, value=>'5' );
    print $x->get( key=>1 );

=head2 Quick start, vector clocks

     use strict;
     use warnings;
     use Voldemort::Store;
     use Voldemort::ProtoBuff::Connection;

     my $connection = Voldemort::ProtoBuff::Connection->new(
     'to' => 'localhost:6666',
     'get_handler' =>
       Voldemort::ProtoBuff::GetMessage->new(  
        'resolver' => Foo->new() )
     );

    my $store = Voldemort::Store->new( connection => $connection );

    $store->default_store('test');

    ####
    package Foo;

    use Moose;
    use Voldemort::ProtoBuff::Resolver;

    with 'Voldemort::Protobuff::Resolver';

    sub resolve
    {
        shift;
        my $versions = shift;
        my $size = (defined $versions) ? scalar @{$versions} : 0;
        if( $size == 0 )
        {
            return (undef, []);
        }
        elsif( $size == 1 )
        {
            return $$versions[0]->value, [];
        }

        # pool everyone's likes
        my %result = ();
        my %nodes  = ();
        my @nodeRecords = ();
        foreach my $record (@{$versions})
        {
            map { $result{$_} = $_ } 
                split(/,/, $record->value);
            map { $nodes{ $_->node_id } = 1 } 
                @{$record->version->entries};
            push @nodeRecords, 
                [map {$_->node_id} @{$record->version->entries}];
        }
        return (join ",", keys %result), \@nodeRecords;
    }

=head1 BUGS

Zer are no more bugs! (for the moment)

=head1 SUPPORT

exussum@gmail.com

=head1 AUTHOR

Spencer Portee
CPAN ID: EXUSSUM
exussum@gmail.com

=head1 SOURCE

http://bitbucket.org/exussum/pockito/

=head1 COPYRIGHT

This program is free software licensed under the...

    The BSD License

The full text of the license can be found in the
LICENSE file included with this module.


=head1 SEE ALSO

perl(1).

=cut

1;
