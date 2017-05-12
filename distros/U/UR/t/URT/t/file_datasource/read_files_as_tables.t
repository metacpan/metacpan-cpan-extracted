#!/usr/bin/env perl
use strict;
use warnings;
use File::Basename;
use lib File::Basename::dirname(__FILE__)."/../../../../lib";
use lib File::Basename::dirname(__FILE__)."/../../..";
use URT;
use Test::More tests => 25;

use IO::File;
use File::Temp;
use Sub::Install;

my $tmpdir = File::Temp::tempdir(CLEANUP => 1);
ok($tmpdir, "Created temp dir $tmpdir");
ok(mkdir($tmpdir."/123/"), 'Create subdir within tmpdir');

my %data = ( 'dogs' => [ [ 1, 'lassie', 11],
                         [ 2, 'benjy', 12 ],
                         [ 3, 'beethoven', 13 ],
                         [ 4, 'ralf', 14 ],
                       ],
             'cats' => [ [ 11, 'garfield', 1 ],
                         [ 12, 'nermal', 2 ],
                         [ 13, 'sassy', 3 ],
                         [ 14, 'fluffy', 4 ],
                       ],
            );

foreach my $species ( keys %data ) {
    my $pathname = "${tmpdir}/123/${species}.dat";
    my $fh = IO::File->new($pathname, 'w') || die  "Can't open $pathname for writing: $!";
    foreach my $animal ( @{ $data{$species} } ) {
        $fh->print(join("\t", @$animal) . "\n");
    }
    ok($fh->close(), "wrote info for $pathname");
}

my $ds = UR::DataSource::Filesystem->create(path => $tmpdir.'/$group/', columns => ['id','name', 'friend_id'], delimiter => "\t");
ok($ds, 'Created Filesystem datasource');

ok(UR::Object::Type->define(
    class_name => 'URT::Cat',
    id_by => [
        cat_id => { is => 'Number', column_name => 'id' }
    ],
    has => [
        group      => { is => 'Number' },
        name       => { is => 'String' },
        friend_id  => { is => 'Number' },
    ],
    data_source_id => $ds->id,
    table_name => 'cats.dat'
    ),
    'Defined class for cats');

ok(UR::Object::Type->define(
    class_name => 'URT::Dog',
    id_by => [
        dog_id => { is => 'Number', column_name => 'id' }
    ],
    has => [
        group => { is => 'Number' },
        name => { is => 'String' },
        friend  => { is => 'URT::Cat', id_by => 'friend_id' },
        friend_name => { via =>'friend', to => 'name' },
    ],
    data_source_id => $ds->id,
    table_name => 'dogs.dat'
    ),
    'Defined class for dogs');

  
my @objs = URT::Dog->get(name => 'benjy');
is(scalar(@objs), 1,'Got one dog named benjy');
is($objs[0]->id, 2, 'It has the right id');
is($objs[0]->name, 'benjy', 'It has the right id');
is($objs[0]->friend_id, 12, 'It has the right friend id');

@objs = $objs[0]->friend;
is(scalar(@objs), 1, 'it has one friend');
is($objs[0]->id, 12, 'with the right ID');
is($objs[0]->name, 'nermal', 'and the right name');

@objs = URT::Dog->get('id <' => 3);
is(scalar(@objs), 2, 'Got 3 dogs with ID < 3');
is($objs[0]->id, 1, 'First has the right ID');
is($objs[1]->id, 2, 'Second has the right ID');


my $cat = URT::Cat->get(name => 'sassy');
ok($cat, 'Got one cat named sassy');
is($cat->name, 'sassy', 'It was the right cat');

@objs = URT::Dog->get(friend => $cat);
is(scalar(@objs), 1, 'There is one dog whose friend is sassy');
is($objs[0]->id, 3, 'its ID is correct');
is($objs[0]->name, 'beethoven', 'its name is correct');


@objs = URT::Dog->get(friend_name => 'fluffy');
is(scalar(@objs), 1, 'Got one dog whose friend name is fluffy');
is($objs[0]->id, 4, 'Its ID is correct');
is($objs[0]->name, 'ralf', 'Its name is correct');

