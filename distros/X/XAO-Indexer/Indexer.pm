# Just a holder for documentation, no real code here
###############################################################################
package XAO::Indexer;
use strict;

use vars qw($VERSION);
$VERSION='1.05';

1;
###############################################################################
__END__

=head1 NAME

XAO::Indexer -- Full text data indexing for XAO::FS

=head1 SYNOPSIS

 my $keywords=$cgi->param('keywords');
 my $cn_index=$odb->fetch('/Indexes/customer_names');
 my $sr=$cn_index->search_by_string('name',$keywords);

=head1 DESCRIPTION

XAO Indexer allows to build an optimised external index to collections
of data stored in a XAO::FS database and then perform keyword based
searches.

It is being used with great success on collection of millions of records
on some sites, probably most notably on L<http://ISBNdb.com/> where it
powers all the searches.

=head1 PROBLEM & SOLUTION

Searches are limited to just keywords, but allow to find many keywords
in a specific sequence or just many keywords that belong to a specific
collection, but could be in different properties of different objects.

To perform the same kind of search on just two properties of an object
with two possible keywords a join similar to the following is required:

 ( (property1 match keyword1) and (property1 match keyword2) ) or
 ( (property1 match keyword1) and (property2 match keyword2) ) or
 ( (property2 match keyword1) and (property2 match keyword2) ) or
 ( (property2 match keyword1) and (property1 match keyword2) )

With bigger number of keywords and properties the expression becomes too
big to be efficiently handled by SQL server and in some cases probably
to be even parsed normally by an SQL server.

In addition, such keyword searches are not optimised in SQL databases
usually and frequently involve full table scans.

XAO Indexer solves this problem by pre-building a specially formatted
index table that has results for specific keywords. As an additional
benefit it allows to get results pre-sorted using some (possibly
computed) criteria without any performance impact.

It needs to be mentioned though, that XAO Indexer is not integrated with
the collection it builds index for in any way. It has to be maintained
and updated manually and can return IDs of objects that no longer exist
in the database.

The process of re-building indexes can take significant time depending
on the content of source collection. In our tests it takes approximately
5 minutes to build an index based on 60,000 records 5..50 fields per
record spread over 3 or more related objects (products, categories and
specifications).

=head2 STRUCTURE

XAO::Indexer is a stub module that only holds common documentation that
you are reading now. Real functionality is provided by:

=over

=item XAO::DO::Data::Index

This is a XAO FS Hash object that gets stored into some container in
your database, usually /Indexes. It provides wrapper methods to all
indexing functionality, see L<XAO::DO::Data::Index> for details.

Most of the time you will interact with this object in your
code. Something like:

 my $keywords=$cgi->param('keywords');
 my $cn_index=$odb->fetch('/Indexes/customer_names');
 my $sr=$cn_index->search('name',$keywords);

=item XAO::DO::Indexer::Base

This is the core of XAO Indexer -- a base class for derived data
collection specific indexers. Usually it is enough to override just a
couple of its methods -- analyze_object(), get_collection() and
get_orderings(). See L<XAO::DO::Indexer::Base> for details.

=item xao-indexer script

Provides command-line functions to create, update and delete
indexes. Provides also a simple search functionality intended for
debugging purposes mainly.

=back

=head1 AUTHORS

Copyright (c) 2005 Andrew Maltsev

Copyright (c) 2003-2004 Andrew Maltsev, XAO Inc.

<am@ejelta.com> -- http://ejelta.com/xao/

=head1 SEE ALSO

Recommended reading:
L<XAO::DO::Data::Index>,
L<XAO::DO::Indexer::Base>,
L<XAO::FS>,
L<XAO::Web>.
