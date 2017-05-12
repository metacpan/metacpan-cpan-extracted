package Test::Mock::Mango;

use v5.10;
use strict;
use warnings;

our $VERSION = '0.09';

require 'Mango.pm'; # Bit useless if you don't actually have mango
use Test::Mock::Mango::FakeData;
use Test::Mock::Mango::DB;
use Test::Mock::Mango::Collection;

$Test::Mock::Mango::data  = Test::Mock::Mango::FakeData->new;
$Test::Mock::Mango::error = undef;
$Test::Mock::Mango::n     = undef;


# Stub "Mango" itself to deal with the situations where it'll get
# a duff or unset connection string (if for example the context in
# which the code will run requires a config file but the unit test
# will run where this file doesn't exist).
{
    no warnings 'redefine';
    *Mango::new = sub { bless {}, 'Mango' };
}

# If we're running with Test::Spec and in appropriate context
# then use Test::Spec::Mocks to do our monkey patching.
if (exists $INC{'Test/Spec.pm'} && Test::Spec->current_context) {
    use warnings 'redefine';
    Mango->expects('db')->returns( Test::Mock::Mango::DB->new($_[-1]) );  
}
else {
    no warnings 'redefine';
    *Mango::db = sub{Test::Mock::Mango::DB->new($_[-1])};
}



1;

=encoding utf8

=head1 NAME

Test::Mock::Mango - Simple stubbing for Mango to allow unit tests for code that uses it

=for html
<a href="https://travis-ci.org/necrophonic/test-mock-mango"><img src="https://travis-ci.org/necrophonic/test-mock-mango.png?branch=master"></a>

=head1 SYNOPSIS

  # Using Test::More
  #
  use Test::More;
  use Test::Mock::Mango; # Stubs in effect!
  # ...
  done_testing();


  # Using Test::Spec (uses Test::Spec::Mocks)
  #
  use Test::Spec;

  describe "Whilst stubbing Mango" => {
    require Test::Mock::Mango; # Stubs in effect in scope!
    # ...
  };
  runtests unless caller;


=head1 DESCRIPTION

For L<Mango> version 0.30 and higher

L<Test::Mock::Mango> provides simple stubbing of methods in the L<Mango> library
to allow easier unit testing of L<Mango> based code.

It does not attempt to 100% replicate the functionality of L<Mango>, but instead
aims to provide "just enough" where sensible for the majority of use cases.

The stubbed methods ignore actual queries being entered and
simply return a user-defined I<known data set>. To run a test you need to set
up the data you expect back first - this module doesn't test your queries, it allows
you to test around L<Mango> calls with known conditions.


=head1 STUBBED METHODS

The following methods are available on each faked part of the mango. We
describe here briefly how far each actually simulates the real method.

Each method supports blocking and non-blocking syntax if the original
method does. Non-blocking ops are not actually non blocking but simply
execute your callback straight away as there's nothing to actually go off
and do on an event loop.

All methods by default simuluate execution without errors. If you want to run a test
that needs to respond to an error state you can do so by L<setting the error flag/"Testing error states">.


=head2 Collection

L<Test::Mock::Mango::Collection>

=over 9

=item aggregate

Ignores query. Returns current collection documents to simulate an
aggregated result.

=item create

Doesn't really do anything.

=item drop

Doesn't really do anything.

=item find_one

Ignores query. Returns the first document from the current fake collection
given in L<Test::Mock::Mango::FakeData>. Returns undef if the collection
is empty.

=item find_and_modify

Ignores query. Returns the first document from the current fake collection
given in L<Test::Mock::Mango::FakeData>. Returns undef if the collection
is empty.

=item find

Ignores query. Returns a new L<Test::Mock::Mango::Cursor> instance.

=item full_name

Returns full name of the fake collection.

=item insert

Naively inserts the given doc(s) onto the end of the current fake collection.

Returns an C<oid> for each inserted document. If an C<_id> is specifiec
in the inserted doc then it is returned, otherwise a new
L<Mango::BSON::ObjectID> is returned instead.

=item update

Doesn't perform a real update. You should set the data state in
C<$Test::Mock::Mango::data> before making the call to be what
you expect after the update.

=item remove

Doesn't remove anything.

=back


=head2 Cursor

L<Test::Mock::Mango::Cursor>

=over 6

=item all

Return array ref containing all the documents in the current fake collection.

=item next

Simulates a cursor by (beginning at zero) iterating through each document
on successive calls. Won't reset itself. If you want to reset the
cursor then set C<Test::Mock::Mango->index> to zero.

=item count

Returns the number of documents in the current fake collection.

=item backlog

Arbitarily returns 'C<2>'

=item limit

Passthru

=item sort

Passthru

=back


=head1 TESTING ERROR STATES

L<Test::Mock::Mango> gives you the ability to simulate errors from your
mango calls.

Simply set the C<error> var before the call:

  $Test::Mock::Mango::error = 'oh noes!';

The next call will then run in an error state as if a real error has occurred.
The C<error> var is automatically cleared with the call so you don't need
to C<undef> it afterwards.


=head1 TESTING UPDATE/REMOVE FAILURES ETC

By default, L<Test::Mock::Mango> is optimistic and assumes that any operation
you perform has succeeded.

However, there are times when you want to do things in the event of a
failure (e.g. when you attempt to update and the doc to update doesn't exist
- this differs from L</"TESTING ERROR STATES"> in that nothing
is wrong with the call, and technically the operation has "succeeded" [mongodb
is funny like that ;) ])

Mongodb normally reports this by a magic parameter called C<n> that it passes
back in the resultant doc. This is set to the number of documents that have
been affected (e.g. if you remove two docs, it'll be set to 2, if you update
4 docs successfully it'll be set to 4).

In it's optimistic simulation, L<Test::Mock::Mango> automaticaly sets the
C<n> value in return docs to 1. If your software cares about the C<n> value
and you want it set specifically (especially if you want to simulate say a "not
updated" case) you can do this via the C<n> value of $Test::Mock::MangoL

  $Test::Mock::Mango::n = 0; # The next call will now pretend no docs were updated

In the same way as using C<$Test::Mock::Mango::error>, this value will be
automatically cleared after the next call. If you want to reset it yourself
at any point then set it to C<undef>.

B<Examples>

  my $doc = $mango->db('family')->collection('simpsons')->update(
    { name => 'Bart' },
    { name => 'Bartholomew' }
  );
  # $doc->{n} will be 1

  $Test::Mock::Mango::n = 0;
  my $doc = $mango->db('family')->collection('simpsons')->update(
    { name => 'Bart' },
    { name => 'Bartholomew' }
  );
  # $doc->{n} will be 0


=head1 AUTHOR

J Gregory <JGREGORY@CPAN.ORG>

=head1 SEE ALSO

L<Mango>

=cut
