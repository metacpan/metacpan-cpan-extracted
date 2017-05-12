#!/usr/bin/perl

=pod

This script populates a catalog.db SQLite database with the contents of
the Lovefilm catalog from catalog.xml. For Lovefilm this file has to
be created by catalog-lwp_handlers.pl first.

It uses DBIx::Class, hence you can do nice things like:

    my @titles = $schema->resultset('Person')->find({ name => 'Matt Damon'} )->titles;
    print "Matt Damon has been in : \n";

    foreach my $title (@titles) {
        my @categories = $title->categories;
        my $categories_str = join(', ', map {$_->term} @categories);

        print "  ". $title->title . " which has a rating of ".$title->rating." and is in these catagories: $categories_str\n";
    }

=head1 RUNNING

cd examples
perl catalog-lwp_handlers.pl
perl catalog2db.pl

=head1 NOTES

This creates a database, i.e. it creates a brand new sqlite DB on the fly
from the packages defined in MyDB::Schema::*.
To do this it needs SQL::Translator to be installed.

=cut

use strict;
use warnings;
use XML::Twig;
use FindBin;
use lib "$FindBin::Bin/../examples/lib";
use MyDB::Schema;
$|=1;


package main;

my $schema = MyDB::Schema->connect('dbi:SQLite:dbname=catalog.db', '', '');

unless (-e 'catalog.db') {
    $schema->deploy; # Create the sqlite file catalog.db
}

my $source = $schema->resultset('Datasource')->find_or_create({ name => 'LOVEFiLM', href => 'http://www.lovefilm.com' });

my $t = XML::Twig->new( twig_handlers => {
	catalog_title => \&catalog_title,
}, );
$t->parsefile( "catalog.xml");
$t->purge;

#
#
#

my @titles = $schema->resultset('Person')->find({ name => 'Matt Damon'} )->titles;
print "Matt Damon has been in : \n";

foreach my $title (@titles) {
    my @categories = $title->categories;
    my $categories_str = join(', ', map {$_->term} @categories);

    print "  ". $title->title . " which has a rating of ".$title->rating." and is in these catagories: $categories_str\n";
}




sub url2id {
  $_[0] =~ m#/(\d+)# ? $1 : undef
}

sub catalog_title {
    my( $t, $x)= @_;
    my %info = (datasource_id => $source->id);

    for (qw/ release_date title number_of_ratings rating run_time can_rent adult/) {
        my $first_child = $x->first_child($_);
        $info{$_}    = $first_child->text if $first_child;
    }

    $info{href}                   = $x->first_child('id')->text;
    $info{title}                  = $x->first_child('title')->att('clean');
    my $id                        = url2id($info{href});
    $info{datasource_internal_id} = $id;

    my $title = $schema->resultset('Title')->find_or_create({ %info });

    foreach my $atts ( map { $_->atts } $x->children('category') ){
        my %cat_key;
        @cat_key{qw/ term scheme /} = @$atts{qw/ term scheme /};

        my $cat = $schema->resultset('Category')->find_or_create({ %cat_key });
        $schema->resultset('TitleCategories')->find_or_create({title_id => $title->id, category_id => $cat->id});
    }

    foreach my $link ( $x->children('link') ){
        my $atts        = $link->atts;
        my $person_type = $atts->{title};

        next unless ($person_type eq 'actors' || $person_type eq 'directors');

        my ($people) = $link->child("people");

        if ($people) {
            foreach my $person_link ( $people->children('link') ){

                $atts->{id} = url2id( $person_link->atts->{href} );

                my $person = $schema->resultset('Person')->find( { name => $person_link->atts->{title} } );
    
                unless ($person) {
                    $person = $schema->resultset('Person')->create( {
                        name        => $person_link->atts->{title},
                        href        => $person_link->atts->{href},
                        person_type => $person_type,
                    } );
                }
    
                my $title_person = $schema->resultset('TitlePerson')->find_or_create({
                    title_id    => $title->id,
                    person_id   => $person->id,
                    person_type => $person_type,
                });
            }
        }
    }

    $x->purge;
}

