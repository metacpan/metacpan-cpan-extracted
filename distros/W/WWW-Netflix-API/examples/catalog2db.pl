#!/usr/bin/perl

####################################
# This script populates a catalog.db SQLite database with the contents of
# the Netflix catalog from catalog.xml and performs any necessary updates
# as based upon the 'updated' timestamp field.
#
# The classes used here can (should) be broken out (and renamed) to
# modules for general access to this database.  For example, here's
# a snippet that searches the database for a specific director:
#    my $d = My::Persons->retrieve(87835); # Steven Spielberg
#    my @movies = sort { $a->release_year <=> $b->release_year } map { $_->title_id } My::TitlePersons->search(person_id => $d->id);
#    printf "%s\n", $d->title;
#    printf "\t%s %s\n", $_->release_year, $_->title for @movies;
####################################

use strict;
use warnings;
use XML::Twig;
$|=1;

package My::DBI;
use base 'Class::DBI::AutoIncrement::Simple';
use base 'Class::DBI::DDL';
# ==> Any valid DSN/user/password should work here.
__PACKAGE__->set_db('Main', 'dbi:SQLite:dbname=catalog.db', '', '');

sub create_table {
  my $self = shift;
  my $is_auto_pk = shift;
  my $pk = $self->primary_column;
  $self->column_definitions([
#	[ id         => 'int',  'not null', ($is_auto_pk?'auto_increment':'') ],
	[ id         => 'int',  'not null' ],  # let Class::DBI::AutoIncrement::Simple take care of it
	map { [ $_ => (/_id$/?'int':'varchar') ] }
		grep { $_ ne $pk }
		$self->columns('Essential')
  ]);
  return $self->SUPER::create_table(@_);
}

package My::Titles;
use base 'My::DBI';
__PACKAGE__->table('titles');
__PACKAGE__->columns(Primary => 'id');
__PACKAGE__->columns(Essential => qw/ href title release_year updated /);
__PACKAGE__->has_many( categories => 'My::TitleCategories', 'title_id' );
__PACKAGE__->has_many( persons => 'My::TitlePersons', 'title_id' );
sub directors {
  my $self = shift;
  return $self->persons( @_, person_type => 'director' );
}
sub actors {
  my $self = shift;
  return $self->persons( @_, person_type => 'actor' );
}
__PACKAGE__->create_table(0);

package My::Categories;
use base 'My::DBI';
__PACKAGE__->table('categories');
__PACKAGE__->columns(Primary => 'id');
__PACKAGE__->columns(Essential => qw/ term label scheme status /);
__PACKAGE__->index_definitions([
	[ Unique => qw/ term label scheme / ],
]);
__PACKAGE__->create_table(1);

package My::Persons;
use base 'My::DBI';
__PACKAGE__->table('person');
__PACKAGE__->columns(Primary => 'id');
__PACKAGE__->columns(Essential => qw/ href title /);
__PACKAGE__->has_many( titles => 'My::TitlePersons', 'person_id' );
__PACKAGE__->create_table(0);

package My::TitlePersons;
use base 'My::DBI';
__PACKAGE__->table('title_person');
__PACKAGE__->columns(Primary => 'id');
__PACKAGE__->columns(Essential => qw/ title_id person_id person_type /);
__PACKAGE__->has_a( title_id => 'My::Titles' );
__PACKAGE__->has_a( person_id => 'My::Persons' );
__PACKAGE__->index_definitions([
	[ Unique => qw/ title_id person_type person_id / ],
	[ Unique => qw/ person_id title_id person_type / ],
	[ Unique => qw/ person_type person_id title_id / ],
	[ Unique => qw/ person_type title_id person_id / ],
	[ Foreign => 'title_id', 'My::Titles', 'id' ],
	[ Foreign => 'person_id', 'My::Persons', 'id' ],
]);
__PACKAGE__->create_table(1);

package My::TitleCategories;
use base 'My::DBI';
__PACKAGE__->table('title_category');
__PACKAGE__->columns(Primary => 'id');
__PACKAGE__->columns(Essential => qw/ title_id category_id /);
__PACKAGE__->has_a( title_id => 'My::Titles' );
__PACKAGE__->has_a( category_id => 'My::Categories' );
__PACKAGE__->index_definitions([
	[ Unique => qw/ title_id category_id / ],
	[ Unique => qw/ category_id title_id / ],
	[ Foreign => 'title_id', 'My::Titles', 'id' ],
	[ Foreign => 'category_id', 'My::Categories', 'id' ],
]);
__PACKAGE__->create_table(1);

package main;

# cache the existing 'updated' timestamps from the db.
my $UPDATED = My::Titles->db_Main->selectall_hashref('select id, updated from titles', 'id');
$_ = $_->{updated} for values %$UPDATED;  # de-hashref-ify the hash values

my $t = XML::Twig->new( twig_handlers => {
	title_index_item => \&title_index_item,
}, );
$t->parsefile( 'catalog.xml');
$t->purge;

sub url2id {
  $_[0] =~ m#/(\d+)# ? $1 : undef
}

sub title_index_item {
  my( $t, $x)= @_;
  my %info;
  $info{$_} = $x->first_child($_)->text for qw/ release_year title updated /;
  $info{href} = $x->first_child('id')->text;
  my $id = url2id($info{href});

  if( $info{updated} > ($UPDATED->{$id}||0) ){
    warn "UPDATING: " . join " / ", $id, $UPDATED->{$id}||0, $info{updated};

    my $obj = My::Titles->find_or_create({ id => url2id($info{href}) });
    $obj->set( %info );
    $obj->update;

    $obj->categories->delete_all;
    foreach my $atts ( map { $_->atts } $x->children('category') ){
      my %cat_key;
      @cat_key{qw/ term label scheme /} = @$atts{qw/ term label scheme /};
      my ($cat) = My::Categories->search( %cat_key );
      $cat ||= My::Categories->insert( $atts );
      $cat->status( $atts->{status} ) if $atts->{status} && ! $cat->status;  # backfill newly added status column
      $obj->add_to_categories({ category_id => $cat->id });
    }

    $obj->persons->delete_all;
    foreach my $atts ( map { $_->atts } $x->children('link') ){
      next unless $atts->{rel} =~ m#/person\.(.+?)$#;
      my $person_type = $1;
      delete $atts->{rel};
      $atts->{id} = url2id( $atts->{href} );
      my $person = My::Persons->retrieve( $atts->{id} ) || My::Persons->create( $atts );
      $obj->add_to_persons({ person_id => $person->id, person_type => $person_type });
    }

  }

  $x->purge;
}

