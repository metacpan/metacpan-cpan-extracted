#!/usr/bin/env perl
use strict;
use warnings;
use File::Basename;
use lib File::Basename::dirname(__FILE__)."/../../../../lib";
use lib File::Basename::dirname(__FILE__)."/../../..";
use URT;
use Test::More tests => 21;

use IO::File;
use File::Temp;
use Sub::Install;

# map people to their rank and serial nubmer
my @people = ( Hudson => { rank => 'Sergent', serial => 499 },
               Bob => { rank => 'General', serial => 678 },
               Carter => { rank => 'Sergent', serial => 456 },
               Snorkel => { rank => 'Sergent', serial => 345 },
               Bailey => { rank => 'Private', serial => 234 },
               Halftrack => { rank => 'General', serial => 567 },
               Pyle => { rank => 'Private', serial => 123 },
               Hudson => { rank => 'Private', serial => 299 },
             );

my $tmpdir = File::Temp::tempdir(CLEANUP => 1);
ok($tmpdir, "Created temp dir $tmpdir");
for (my $i = 0; $i < @people; $i += 2) {
    my $name = $people[$i];
    my $data = $people[$i+1];
    ok(_create_data_file($tmpdir,$data->{'rank'},$name,$data->{'serial'}), "Create file for $name");
}


ok(UR::Object::Type->define(
    class_name => 'URT::Soldier',
    id_by => [
        serial => { is => 'Number' }
    ],
    has => [
        name => { is => 'String' },
        rank => { is => 'String' },
    ],
    #data_source => { uri => "file:$tmpdir/\$rank.dat" }
    data_source => { is => 'UR::DataSource::Filesystem',
                     path  => $tmpdir.'/$rank.dat',
                     columns => ['name','serial'],
                     delimiter => "\t",
                   },
    ),
    'Defined class for soldiers');


my @objs = URT::Soldier->get(name => 'Pyle', rank => 'Private');
is(scalar(@objs), 1, 'Got one Private named Pyle');
ok(_compare_to_expected($objs[0],
                        { name => 'Pyle', rank => 'Private', serial => 123} ),
    'Object has the correct data');

@objs = URT::Soldier->get(rank => 'General');
is(scalar(@objs), 2, 'Got two soldiers with rank General');
ok(_compare_to_expected($objs[0],
                        { name => 'Halftrack', rank => 'General', serial => 567 }),
    'First object has correct data');
ok(_compare_to_expected($objs[1],
                        { name => 'Bob', rank => 'General', serial => 678 }),
    'Second object has correct data');


@objs = URT::Soldier->get(name => 'no one');
is(scalar(@objs), 0, 'Found no soldiers named "no one"');


@objs = URT::Soldier->get(name => 'Hudson');
is(scalar(@objs), 2, 'Matched two soldiers named Hudson');
ok(_compare_to_expected($objs[0],
                        { name => 'Hudson', rank => 'Private', serial => 299 }),
    'First object has correct data');
ok(_compare_to_expected($objs[1],
                        { name => 'Hudson', rank => 'Sergent', serial => 499 }),
    'Second object has correct data');

@objs = URT::Soldier->get(456);
is(scalar(@objs), 1, 'Got 1 soldier by ID');
ok(_compare_to_expected($objs[0],
                        { name => 'Carter', rank => 'Sergent', serial => 456 }),
    'Object has correct data');


sub _compare_to_expected {
    my($obj,$expected) = @_;

    return unless $obj->name eq $expected->{'name'};
    return unless $obj->id eq $expected->{'serial'};
    return unless $obj->serial eq $expected->{'serial'};
    return unless $obj->rank eq $expected->{'rank'};
    return 1;
}

sub _create_data_file {
    my($dir,$rank,$name,$serial) = @_;

    my $pathname = $dir . '/' . $rank . '.dat';
    my $f = IO::File->new($pathname, '>>');
    die "Can't create file $pathname: $!" unless $f;

    $f->print("$name\t$serial\n");
    $f->close;
    1;
}
