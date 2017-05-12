
package Xmldoom;

# This file only exists to make CPAN happy ...

our $VERSION = '0.0.16';

1;

__END__

=pod

=head1 NAME

Xmldoom -- The XML Document Object-Oriented Model

=head1 HOME PAGE

http://gna.org/projects/xmldoom

=head1 DESCRIPTION

Xmldoom is what is commonly refered to as an I<Object Persistence Framework> or an 
I<Object-Relational Mapping> [1].  Basically, it is a framework that allows you to create 
an automatic mapping between the tables in your relational database and the code objects 
you use to manipulate it.  Any large database bound application will eventually create
a code abstraction over the database as opposed to writting SQL manually for every database
access.  Xmldoom does this automatically and makes it possible to avoid writting any SQL.

This is not a new concept, however, there are a few things that make Xmldoom unique:

=over

=item B<Programming language agnostic>

This implementation is a Perl module.  However, there
exists an actively maintained JavaScript and an inactive Python implementation.  This means
you can setup your object and database definitions once, and be able to access your database
via Xmldoom with roughly the same interface from any programming language that has an 
Xmldoom implementation.

=item B<Heavy abstraction>

While the standard in the Perl world is to be as light as possible,
Xmldoom is a heavy abstraction, and we treat that as an advantage in this context.  The objects
provided by Xmldoom have a very consistant and well thought-out interface, that attempts to
handle as many possible "object-like" interactions as possible.  The thinking is that the more
Xmldoom does for you, the less you have to do.  This is provided in an extensible
object-oriented fashion.

=item B<Adapts to your database>

Even though it is a very heavy abstraction, it doesn't hide the
database from you, or force your database to operate in some set way.  It can be made to adapt
to almost any way you have set up your database to operate, and still provide the same consistant
object interface regardless.

=item B<Object meta-data>

Aside from simply connecting your database to objects, it allows you specify domain specific
meta-data about each object and each of its properties.  This meta-data is available anywhere in code,
such that you can provide generic functions that can take any object, and perform some action on it
based on the stored meta-data, without regard to the actual type of the object.  For example, you 
can create a generic mechanism to generate reports, which can generate a report for any object, 
without needing to be special cased for each type of object you want to report on.

=item B<Flexible searches>

Xmldoom provides you with a mechanism to search for any object based on any property, whether its
a property of that object or any other, so long as it can find a keys relating the objects together.
This allows to find any information in your database, without ever having to write an SQL.

=back

=head1 DOCUMENTATION

Currently, documentation is very scarce.  However, I am working really hard right now to rectify
that.  I know that this is far too complicated a package to even begin using without good
documentation.

=over

=item L<Xmldoom::doc::GettingStarted>

A step-by-step tutorial to setting up Xmldoom.

=item L<Xmldoom::doc::UsingSQLTranslator>

How to use SQL::Translator to work with your database.xml.

=item L<Xmldoom::doc::UsingTorque>

How to use the Apache Torque generator to work with your database.xml.

=back

=head1 AUTHOR

David Snopek <dsnopek@gmail.com>

=head1 SEE ALSO

Like I mentioned above, automatic I<Object Relational Mapping> is far from a new concept and there
is absolutely no general consensus on how it should be done.  Many others exist for Perl, and they are
all drastically different from eachother.  Xmldoom is unique in the way it gets this job done, however,
it was designed this way to tackle a specific problem-set.  So, if you don't think that Xmldoom is a good
fit for your project, try out some of these other great Perl packages:

=over

=item *

L<ORM>

=item *

L<Class::DBI>

=item *

L<Rose::DB::Object>

=item *

L<OOPS>

=item *

L<DBIx::Class>

=item *

L<Alzabo>

=back

=head1 FOOTNOTES

[1] "Object-relational mapping" at the Wikipedia -- L<http://en.wikipedia.org/wiki/Object-relational_mapping>

=cut

