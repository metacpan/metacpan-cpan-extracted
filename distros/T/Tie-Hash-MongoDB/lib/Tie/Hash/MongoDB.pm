package Tie::Hash::MongoDB;

use warnings;
use strict;

use MongoDB::Connection;
use MongoDB::OID;

=head1 NAME

Tie::Hash::MongoDB - Tie a hash to a MongoDB document

Every single action to the hash is directly processed
on the MongoDB server, remember this while using this
module!

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

    use Tie::Hash::MongoDB;

    tie %foo,'Tie::Hash::MongoDB',$id,{
		server     => 'localhost',
		database   => 'default',
		collection => 'default',
    	};

Tie a MongoDB document to a Perl hash.

tie arguments:
1. the hash to be tied
2. this modules name 
3. the document id or undef for a new document
4. connection arguments for the MongoDB interface

=head1 METHODS

=head2 TIEHASH

    tie %foo,'Tie::Hash::MongoDB',$id,{
		server     => 'localhost',
		database   => 'default',
		collection => 'default',
    	};

Tie the MongoDB document or create a new one.

=cut

sub TIEHASH {
    my $class = shift;
    my $id    = shift;
    my $args  = shift;

    # Fill in some defaults
    my $server_name     = $args->{server}     || 'localhost';
    my $port            = $args->{port}       || 27017;
    my $database_name   = $args->{database}   || 'default';
    my $collection_name = $args->{collection} || 'default';

    # Create the object
    my $self = bless {}, $class;

    # Connect to the server, select the database and get a collection handle
    my $connection = MongoDB::Connection->new(
        host => $server_name,
        port => $port
    );
    my $database = $connection->$database_name;
    $self->{collection} = $database->collection_name;

    if ( defined($id) ) {

        # Create an id object
        $self->{id} = MongoDB::OID->new( value => $id );

        # Create a new document using the given id unless it's already on the server
        $self->{id} = $self->{collection}->insert( { _id => $self->{id} } )
          unless $self->{collection}->query( { _id => $self->{id} } )->count;
    }
    else {

        # Create an empty document if no id was found
        $self->{id} = $self->{collection}->insert( {} );
    }

    return $self;
}

=head2 DELETE

    $object->DELETE($key)

Remove a key from the document.

No return value.

=cut

sub DELETE {
    my $self = shift;
    my $key  = shift;

    $self->{collection}
      ->update( { _id => $self->{id} }, { '$unset' => { $key => 1 } } );

}

=head2 EXISTS

    $object->EXISTS($key)

Returns true if the key exists or false otherwise.

=cut

sub EXISTS {
    my $self = shift;
    my $key  = shift;

    return $self->{collection}
      ->query( { _id => $self->{id}, $key => { '$exists' => 'true' } } )->count
      ? 1
      : 0;
}

=head2 FETCH

    $object->FETCH($key)

Returns the current value of a key.

Returns undef if the key doesn't exist or has an undef value.

=cut

sub FETCH {
    my $self = shift;
    my $key  = shift;

    my $doc =
      $self->{collection}->find_one( { _id => $self->{id} }, { $key => 1 } );

    return $doc->{_id}->value if $key eq '_id' and ref( $doc->{$key} );

    return $doc ? $doc->{$key} : undef;
}

=head2 FIRSTKEY

    $object->FIRSTKEY

Returns the first key of the document.

=cut

sub FIRSTKEY {
    my $self = shift;

    my $doc = $self->{collection}->find_one( { _id => $self->{id} } );

    return unless $doc;

    $self->{keylist} = [ keys(%$doc) ];

    return $self->NEXTKEY;
}

=head2 NEXTKEY

    $object->NEXTKEY

Returns the next key of the document or nothing at the end of the list.

=cut

sub NEXTKEY {
    my $self = shift;

    return if $#{$self->{keylist}} == -1;
    return shift( @{ $self->{keylist} } );
}

=head2 STORE

    $object->STORE($key,$value)

Add or update a key.

=cut

sub STORE {
    my $self  = shift;
    my $key   = shift;
    my $value = shift;

    $self->{collection}
      ->update( { _id => $self->{id} }, { '$set' => { $key => $value } } );

    return $value;
}

=head2 UNTIE

    $object->UNTIE

Unties the hash from the document.

=cut

sub UNTIE {
}

=head1 AUTHOR

Sebastian Willing, C<< <sewi at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-tie-hash-mongodb at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Tie-Hash-MongoDB>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Tie::Hash::MongoDB


You can also look for information at:

=over 4

=item * Author's blog:

L<http://www.pal-blog.de/entwicklung/perl/2011/creating-tiehashmongodb-from-scratch-using-padre.html>
L<http://www.pal-blog.de/entwicklung/perl/2011/finishing-tiehashmongodb.html>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Tie-Hash-MongoDB>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Tie-Hash-MongoDB>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Tie-Hash-MongoDB>

=item * Search CPAN

L<http://search.cpan.org/dist/Tie-Hash-MongoDB/>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

Copyright 2011 Sebastian Willing.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1;    # End of Tie::Hash::MongoDB
