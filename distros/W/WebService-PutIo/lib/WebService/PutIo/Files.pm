package WebService::PutIo::Files;

use base 'WebService::PutIo';

my $class='files';

sub list { shift->request($class,'list',@_); }
sub create_dir { shift->request($class,'create_dir',@_); }
sub info { shift->request($class,'info',@_); }
sub rename { shift->request($class,'rename',@_); }
sub move { shift->request($class,'move',@_); }
sub delete { shift->request($class,'delete',@_); }
sub search { shift->request($class,'search',@_); }
sub dirmap { shift->request($class,'dirmap',@_); }

=head1 NAME

WebService::PutIo::Files - File Operations for put.io

=head1 SYNOPSIS

    use WebService::PutIo::Files;
	my $files=WebService::PutIo::Files->new(api_key=>'..',api_secret=>'..');
	my $res=$files->list;
	foreach my $file (@{$res->results}) {
	   print "Got ". Data::Dumper($file);
	}

=head1 DESCRIPTION

File related methods for the put.io web service

=head1 METHODS 

=head2 list

Returns the list of items in a folder.

=over 4 

=item id = STRING or INTEGER

=item parent_id = STRING or INTEGER


=item offset = INTEGER (Default:0)

=item limit = INTEGER (Default: 20)

=item type = STRING (See Item class for available types)

=item orderby = STRING (Default: createdat_desc)

=back

=head3 Orderby parameters:

=over 4 

=item id_asc

=item id_desc

=item type_asc

=item type_desc

=item name_asc

=item name_desc

=item extension_asc

=item extension_desc

=item createdat_asc

item= createdat_desc (Default)

=back

=head2 create_dir

Creates and returns a new folder.

=head3 Parameters:

=over 4

=item name

=item parent_id

=back 

=head2 info

Returns detailed information about an item.

=head3 Parameters:

=over 4

=item id

=back

=head2 rename

Renames and returns an item

=head3 Parameters:

=over 4

=item id

=item name

=back

=head2 move

Moves an item from a folder to another, and returns it.

=head3 Parameters:

=over 4

=item id

=item parent_id

=back

=head2 delete

Deletes an item

=head3 Parameters:

=over 4 

=item id

=back

=head2 search

Returns list of found items

=head3 Parameters:

=over 4

=item query

=back

=head2 dirmap

Returns a flat list of directory list. Parent_id is the id of a folder the item is in.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010, Marcus Ramberg.

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=cut

1;