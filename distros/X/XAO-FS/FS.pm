############################################################################
package XAO::FS;

use vars qw($VERSION);
$VERSION='1.16';
1;

############################################################################
__END__

=head1 NAME

XAO::FS - XAO Foundation Server

=head1 DESIGN REQUIREMENTS

The following description summarizes a set of design meetings held by
XAO Inc.

Usually from both developer and management point of view it is easier to
think of a data piece as of some kind of closed entity with some content
and probably some methods for manipulating that content. This is what is
generally referred to as an object.

More often then not such an object would include references to other
objects or will contain a list of some data objects. For example a
customer can contain all orders placed by that customer and each order
in turn can contain descriptions and prices of all the products in that
order.

It would be nice to use a relational database to store all the data
because relational databases are generally fast, reliable, available on
wide range of platforms and in all price ranges, can be accessed via
network, usually have various kinds of monitoring and visualisation
tools and so on. And probably the biggest advantage is that there is a
lot of people who has experience with some kind of relational database
-- MySQL, Oracle, Sybase or something along these lines.

The biggest limitation of relational databases though is the fact
that each table in the database is what the name suggest -- just a
2-dimensional table with rows and columns. This is not enough to
represent the data structure mentioned above naturally -- a developer
would have to create a set of tables and include reference columns
(foreign keys) into these tables to relate data rows in different tables
into some kind of global data layout.

This is natural for relational databases, in fact this is where the name
"relational" comes from. But nonetheless developers have to keep in mind
all index fields and relations between tables in order to do something
useful with the data. Changing data layout can become a nightmare too.

These and other problems lead to the following list of requirements for
the XAO Foundation Server:

=over

=item *

An object can have some named properties: text, integer or real.

=item *

We must be able to store and retrieve objects using a relational
database such as MySQL as a backend.

=item *

Retrieved object must have the same functionality (same methods) as a
stored object, including class name and inheritance.

=item *

Any object can be retrieved by URI style path to it.

=item *

An object can contain other objects -- you can retrieve another fully
functional object having only a reference to the container object.

=item *

You can search for a specific object in a container using a variety of
methods. Search should be as fast as possible, no iteration over entire
objects set should ever be involved, including searches on sub-strings
or words in a sentence.

=item *

Architecture should be scalable enough for any container object to
contain at least a couple of millions of other objects and operate and
search on them about as efficiently as direct access to the database
would do.

=item *

Under no circumstances a developer should use direct access to SQL
tables or have to know much about underlying SQL tables structure. At
the same time, tables structure should make sense even without API on
top of it.

=back

=head1 STRUCTURE

The idea is to have data in a relational database in exactly the same
way as a developer would keep it without any API. API in that case would
only provide means to look at the data as at a collection of connected
objects.

Thus we would still be able to use standard reporting and database
maintaining tools, data would still be in human readable format and
would make sense even for somebody with just an SQL command prompt.

Let's start with an example of relations between data:

 /Global
   |--Customers
   |   |--cust001
   |   |   |--first_name
   |   |   |--last_name
   |   |   |--Addresses
   |   |   |   |--addr001
   |   |   |   |   |--line1
   |   |   |   |   ...
   |   |   |   |   \--zipcode
   |   |   |   \--addr002
   |   |   |       \--...
   |   |   |--Cards
   |   |   |   |--card001
   |   |   |   \--card002
   |   |   \--Orders
   |   |       |--order001
   |   |       |--order002
   |   |       \--order003
   |   |--cust002
   |   |   \--...
   |   ...
   \--Products
       |--prod001
       |--prod002
       |--prod003
       ...

Clearly most of data relations we deal with can be separated into two
major groups -- an object with a set of various properties (like a
Customer object -- cust001, cust002 above) and an object that contains a
list of objects of the same type and nothing else (like a collection of
all Customers).

These two types of objects call for a little different APIs -- data
object API and list object API.

Here is a short example of how to create simple structure similar to the
one above from absolutely empty database:

 ##
 # Creating minimal required supporting tables
 #
 my $odb=XAO::Objects->new(objname => 'FS::Glue',
                           dsn => 'OS:MySQL_DBI:testdatabase',
                           empty_database => 'confirm');

 ##
 # Retrieving top level object which is empty at that time.
 #
 my $global=$odb->fetch('/');

 ##
 # Creating place holders on top level
 #
 $global->add_placeholder(name        => 'Customers',
                          type        => 'list',
                          class       => 'Data::Customer',
                          key         => 'customer_id');

 ##
 # Creating customer detached object.
 #
 my $customer_list=$global->get('Customers');
 my $customer=$customer_list->get_new();

 ##
 # Adding some properties to the customer
 #
 $customer->add_placeholder(name      => 'first_name',
                            type      => 'text',
                            maxlength => 50);
 $customer->add_placeholder(name      => 'Addresses',
                            type      => 'list',
                            class     => 'Data::CustomerAddress',
                            key       => 'address_id');

 ##
 # Creating detached customer address object. The same as get_new()
 # above but does not require reference to the list.
 #
 my $address=XAO::Objects->new(objname => 'Data::CustomerAddress',
                                    glue => $odb);
 $address->add_placeholder(name       => 'zipcode',
                           type       => 'text',
                           maxlength  => 10);

After execution of that script you will have structure able to
manipulate with arbitrary number of customers each of them having
arbitrary number of addresses. Here is an example of usage (providing
you have defined check_and_add_extended_zipcode() somewhere):

 my $addr=$odb->fetch('/Customers/cust002/Addresses/addr001');
 my $zipcode=$addr->get('zipcode');
 $zipcode=check_and_add_extended_zipcode($zipcode);
 $addr->put(zipcode => $zipcode);

=head1 SEE ALSO

Specifics of Hash and List API can be found in
L<XAO::DO::FS::Hash> and
L<XAO::DO::FS::List>.

For additional information please see
L<XAO::DO::FS::Glue>,
L<XAO::DO::FS::Global>,
L<XAO::DO::FS::Glue::MySQL_DBI>,
L<XAO::DO>,
L<XAO::Web>.

=head1 BUGS AND MIS-FEATURES

You have to be careful with deleting objects -- you can easily destroy
long branches of objects. The same applies to drop_placeholder() - you
can completely and irreversibly destroy entire tables. No questions
asked.

=head1 AUTHOR

Copyright (c) 2005 Andrew Maltsev
Copyright (c) 2000-2004 XAO Inc.

This document summarizes ideas from a set of design meetings held by XAO
Inc. technical team.

The document is maintained by Andrew Maltsev <am@ejelta.com>. It is
based on earlier documentation set prepared by Bil Drury <bild@xao.com>
and would not be possible at all without valuable input from Marcos
Alves, Jimmy Xiang, Jason Shupe and everyone else on our team.
