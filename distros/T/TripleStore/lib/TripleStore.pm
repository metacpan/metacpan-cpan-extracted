# -------------------------------------------------------------------------------------
# TripleStore
# -------------------------------------------------------------------------------------
#
#       Author : Jean-Michel Hiver (jhiver@mkdoc.com).
#      Version : $Id: TripleStore.pm,v 1.3 2003/01/27 16:11:51 jhiver Exp $
#
#    Description:
#
#      Wrapper class around the TripleStore collection of classes.
#
# -------------------------------------------------------------------------------------
package TripleStore;
use strict;
use warnings;
use Carp;

use TripleStore::Driver;
use TripleStore::Update;
use TripleStore::ResultSet;
use TripleStore::Query;

use TripleStore::Mixin::Class;
use TripleStore::Mixin::Unimplemented;

our @ISA = qw /TripleStore::Mixin::Class/;
our $VERSION = '0.03';


##
# $class->new ($driver);
# ----------------------
# Instanciates a new TripleStore object.
##
sub new
{
    my $class = shift->class;
    return bless {
	driver   => shift() || confess "No driver object specified",
	tx_count => 0,
    };
}


##
# $self->driver();
# ----------------
# Returns the current underlying
# driver object.
##
sub driver
{
    my $self = shift;
    return $self->{driver};
}


##
# BEGIN;
# ------
# Sets aliases for the driver methods.
##
BEGIN
{
    no strict 'refs';
    for my $method (qw /tx_start tx_stop tx_abort insert delete select/) {
	*$method = sub {
	    my $self = shift;
	    return $self->driver()->$method (@_);
	};
    };
}


##
# $self->update();
# ----------------
# Alias for the driver update() method.
##
sub update
{
    my $self = shift;
    my $update = shift;
    $update = do { (ref $update eq 'HASH') ? new TripleStore::Update (%{$update}) : $update };
    return $self->driver()->update ($update, @_);
}


##
# $self->var();
# -------------
# Returns a new Variable object for use within clauses.
##
sub var
{
    my $self = shift;
    return new TripleStore::Query::Variable();
}


##
# $self->clause ($criterion1, $criterion2, $criterion3);
# ------------------------------------------------------
# Returns a new clause. Each criterion is either a variable
# object, a criterion object, a scalar, or an array reference.
##
sub clause
{
    my $self = shift;
    my $subject   = $self->_make_criterion (shift());
    my $predicate = $self->_make_criterion (shift());
    my $object    = $self->_make_criterion (shift());
    return new TripleStore::Query::Clause ($subject, $predicate, $object);
}


sub _make_criterion
{
    my $self = shift;
    my $crit = shift;
    return $self->var() unless (defined $crit);
    return new TripleStore::Query::Criterion (@{$crit}) if (ref $crit and ref $crit eq 'ARRAY');
    return new TripleStore::Query::Criterion ('eq', $crit) unless (ref $crit);
    return $crit;
}


sub sort_num_asc
{
    my $self = shift;
    return new TripleStore::Query::Sort::NumericAscending (@_);
}


sub sort_num_desc
{
    my $self = shift;
    return new TripleStore::Query::Sort::NumericDescending (@_);
}


sub sort_str_asc
{
    my $self = shift;
    return new TripleStore::Query::Sort::StringAscending (@_);
}


sub sort_srt_desc
{
    my $self = shift;
    return new TripleStore::Query::Sort::StringDescending (@_);
}


sub limit
{
    my $self = shift;
    return new TripleStore::Query::Limit (@_);
}


sub limit_page
{
    my $self = shift;
    my $page_num = shift;
    my $per_page = shift;
    
    my $offset = $per_page * ($page_num - 1);
    return $self->limit ($offset, $per_page);
}


1;


__END__


=head1 NAME

TripleStore - An SQL-Free Triple Store API with a Perl Query Language.


=head1 SYNOPSIS

  use TripleStore;
  use TripleStore::Driver::MySQL;
  
  my $::DB = new TripleStore (
      new TripleStore::Driver::MySQL (
          "DBI:mysql:database=test",
          "root",
          "someSecretPassword",
      )
  );
  
  $::DB->tx_start();
  eval { do_some_stuff() };
  $@ ? $::DB->tx_abort() ? $::DB->tx_stop();

  $::DB = undef;


=head1 SUMMARY

TripleStore is a Perl interface for a triple store. Currently a quite
naive MySQL implementation is provided. Alternative SQL implementations
can be developed by subclassing TripleStore::Driver or any of its
subclasses (such as TripleStore::Driver::SQL).

Note that TripleStore API strives to NOT be connected in any way with
SQL (especially for querying). There might be a few common points, but
as you will see TripleStore is quite neutral at that level.


=head1 BASIC OPERATIONS / HOW IT WORKS


=head2 Constructing a triple store object.

To construct a triple store object, you need to instanciate a driver
first. Currently there's only one driver available, so that's not so
hard :=)

  sub gimme_driver
  {
      new TripleStore::Driver::MySQL (
          "DBI:mysql:database=test",
          "root",
          "someSecretPassword",
      );
  }

Then you need to instanciate a TripleStore object and put it somewhere
where you can access it everywhere in your program.

  sub main
  {
      local $::DB = new TripleStore (gimme_driver());
      $::DB->tx_start(); # starts a transaction
      eval {
          # here we're gonna do
          # plenty of stuff
          # that involves the triple store.
      }
      $@ ? $::DB->tx_abort() : $::DB->tx_stop();
  }


=head2 Inserting new triples

  $::DB->insert ($subject, $predicate, $object);


=head2 Deleting existing triples

In order to delete triples you need to define some condition.
You do that using a clause object.

  # clause that matches all triples with:
  #    predicate eq 'price'
  #    object    >  100.25
  my $clause = $::DB->clause (undef, 'price', [ '>', 125.25 ]);
  $::DB->delete ($clause);

The current MySQL driver does not support complex conditions
for deletion yet (i.e. $clause1 & ( $clause2 | $clause3 )).


=head2 Updating exising triples

Same as delete, except that you define a hashref of elements
to set, i.e.

  # this is a silly update:
  # for everything that has a price greater than
  # 125.25, set the price to 90.
  my $clause = $::DB->clause (undef, 'price', [ '>', 125.25 ]);
  $::DB->update ( { object => 90 }, $clause);

You can update on 'subject', 'predicate' or 'object'.


=head1 QUERYING THE TRIPLE STORE

StoreTriple features a quite nice query interface which is
inspired from the rdfdb-style queries.

In rdbf, queries are expected to be parsed from a form such as:

  select ( ?x ?y ) from triple where (?x worksFor ?y) (?y name 'BBC')

With TripleStore, this translates as:

  my $x = $::DB->var();
  my $y = $::DB->var();
  my $rs = $::DB->select ($x, $y,
      $::DB->clause ($x, 'worksFor', $y) &
      $::DB->clause ($y, 'name', 'BBC')
  );

Except that TripleStore lets you do a bit more...


=head2 Making complex queries

  my $complex = $clause1 & ( $clause2 | $clause3 | ( $clause4 & $clause5 ) );


=head2 Sorting variables

  # same query, sorted by alphabetical order on $x
  # and then by descending numerical order on $y
  my $rs = $::DB->select ($x, $y,
      $::DB->clause ($x, 'worksFor', $y) &
      $::DB->clause ($y, 'name', 'BBC')
      $::DB->sort_str_asc ($x), $::DB->sort_num_desc ($y)
  );

The available sorting functions are:

  $::DB->sort_str_asc  ($variable);
  $::DB->sort_str_desc ($variable);
  $::DB->sort_num_asc  ($variable);
  $::DB->sort_num_desc ($variable);


=head2 Limiting

  # same query, but limited to the 10 first rows
  my $rs = $::DB->select ($x, $y,
      $::DB->clause ($x, 'worksFor', $y) &
      $::DB->clause ($y, 'name', 'BBC')
      $::DB->limit (0, 10) # offset, rows
  );

  # same as above, but with a different approach
  my $rs = $::DB->select ($x, $y,
      $::DB->clause ($x, 'worksFor', $y) &
      $::DB->clause ($y, 'name', 'BBC')
      $::DB->limit_page (1, 10) # first page, 10 rows per page
  );


=head2 Selecting on...

Strings:

  $::DB->clause ($y, 'name', 'BBC') # equality
  $::DB->clause ($y, 'name', [ 'ne', 'BBC' ]) # non equality
  $::DB->clause ($y, 'name', [ 'lt', 'BBC' ]) # lesser than
  $::DB->clause ($y, 'name', [ 'le', 'BBC' ]) # lesser or equals
  $::DB->clause ($y, 'name', [ 'gt', 'BBC' ]) # greater than
  $::DB->clause ($y, 'name', [ 'ge', 'BBC' ]) # greater or equals
  $::DB->clause ($y, 'name', [ 'like', '%BBC%' ]) # like
  $::DB->clause ($y, 'name', [ 'unlike', '%BBC%' ]) # unlike

Numeric:

  $::DB->clause ($y, 'someNumericValue', [ '==', 12 ] ) # equality
  $::DB->clause ($y, 'name', [ '!=', 12 ] ) # non equality
  $::DB->clause ($y, 'name', [ '<', 12 ] )  # lesser than
  $::DB->clause ($y, 'name', [ '<=', 12 ] ) # lesser or equals
  $::DB->clause ($y, 'name', [ '>', 12 ] )  # greater than
  $::DB->clause ($y, 'name', [ '>=', 12 ] ) # greater or equals


=head2 Looping through the results.

When you invoke the select() method, a ResultSet object is returned.
You can use that ResultSet object to loop through the results.

  my $rs = $::DB->select ($x, $y,
      $::DB->clause ($x, 'worksFor', $y) &
      $::DB->clause ($y, 'name', 'BBC')
      $::DB->limit_page (1, 10) # first page, 10 rows per page
  );

  while (my $arrayref = $rs->next())
  {
      my $x_variable = $arrayref->[0];
      my $y_variable = $arrayref->[1];
  }


=head1 KNOWN BUGS

This is an ALPHA release. There is no known bugs, which means that there's
plenty of them to find out... reports and patches appreciated!


=head1 AUTHOR

Copyright 2002 - Jean-Michel Hiver <jhiver@mkdoc.com> 

This module free software and is distributed under the
same license as Perl itself.


=head1 SEE ALSO

  # The TripleStore mailing list
  http://www.email-lists.org/mailman/listinfo/triplestore
  
  # Triple Querying with SQL
  http://www.picdiary.com/triplequerying/

=cut
