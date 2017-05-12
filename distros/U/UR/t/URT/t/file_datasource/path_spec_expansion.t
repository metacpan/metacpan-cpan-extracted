#!/usr/bin/env perl
use strict;
use warnings;
use File::Basename;
use lib File::Basename::dirname(__FILE__)."/../../../../lib";
use lib File::Basename::dirname(__FILE__)."/../../..";
use URT;
use Test::More tests => 60;

use IO::File;
use File::Temp;
use Sub::Install;

# map people to their rank and serial nubmer
my %people = ( Pyle => { rank => 'Private', serial => 123 },
               Bailey => { rank => 'Private', serial => 234 },
               Snorkel => { rank => 'Sergent', serial => 345 },
               Carter => { rank => 'Sergent', serial => 456 },
               Halftrack => { rank => 'General', serial => 567 },
             );

my $tmpdir = File::Temp::tempdir(CLEANUP => 1);
ok($tmpdir, 'Created temp dir');
my $tmpdir_strlen = length($tmpdir);

my $dir = $tmpdir . '/extra_dir';
ok(mkdir($dir), 'Created extra_dir within temp dir');
my $dir_strlen = length($dir);
while (my($name,$data) = each %people) {
    ok(_create_data_file($dir,$data->{'rank'},$name,$data->{'serial'}), "Create file for $name");
}


my $ds = UR::DataSource::Filesystem->create(
    path => $dir.'/$rank/${name}.dat',
    columns => ['serial'],
);
ok($ds, 'Created data source');

class URT::Thing {
    has => [
        other => { is => 'String' },
        other2 => { is => 'String' },
        name => { is => 'String' },
        rank => { is => 'String' },
        serial => { is => 'Number' },
    ],
    data_source_id => $ds->id,
};


# First, test the low-level replacement methods for variables

# A simple one with single values for both properties
my $bx = URT::Thing->define_boolexpr(name => 'Pyle', rank => 'Private');
ok($bx, 'Create boolexpr matching a name and rank');
my @data = UR::DataSource::Filesystem->_replace_vars_with_values_in_pathname(
               $bx,
               ${dir}.'/$rank/$name'
            );
is(scalar(@data), 1, 'property replacement yielded one pathname');
is_deeply(\@data, [ [ "${dir}/Private/Pyle", { name => 'Pyle', rank => 'Private'} ]],
          'Path resolution data is correct');

@data = UR::DataSource::Filesystem->_replace_vars_with_values_in_pathname(
               $bx,
               ${dir}.'/$rank/${name}.dat'
            );
is(scalar(@data), 1, 'property replacement yielded one pathname, with extension');
is_deeply(\@data, [ [ "${dir}/Private/Pyle.dat", { name => 'Pyle', rank => 'Private'} ]],
          'Path resolution data is correct');


# Give 2 values for each property
$bx = URT::Thing->define_boolexpr(rank => ['General','Sergent'], name => ['Pyle','Washington']);
ok($bx, 'Create boolexpr matching name and rank with in-clauses');
@data = UR::DataSource::Filesystem->_replace_vars_with_values_in_pathname(
               $bx,
               ${dir}.'/$rank/$name.dat'
            );
is(scalar(@data), 4, 'Property replacement yields 4 pathnames');
@data = sort {$a->[0] cmp $b->[0]} @data;
is_deeply(\@data,
         [
           [ "${dir}/General/Pyle.dat",       { name => 'Pyle', rank => 'General' } ],
           [ "${dir}/General/Washington.dat", { name => 'Washington', rank => 'General' } ],
           [ "${dir}/Sergent/Pyle.dat",       { name => 'Pyle', rank => 'Sergent' } ],
           [ "${dir}/Sergent/Washington.dat", { name => 'Washington', rank => 'Sergent' } ],
         ],
         'Path resolution data is correct');



# This one only supplies a value for one property.  It'll have to glob the filesystem for the other value
$bx = URT::Thing->define_boolexpr(name => 'Pyle');
ok($bx, 'Create boolexpr with just name');
@data = UR::DataSource::Filesystem->_replace_vars_with_values_in_pathname(
               $bx,
               ${dir}.'/$rank/${name}.dat'
            );
is(scalar(@data), 1, 'property replacement yielded one pathname, with extension');
#print Data::Dumper::Dumper(\@data);
is_deeply(\@data,
           [ [ "${dir}/*/Pyle.dat",
               { name => 'Pyle', '.__glob_positions__' => [ [$dir_strlen+1, 'rank' ] ] }
             ]
           ],
           'Path resolution data is correct');

@data = UR::DataSource::Filesystem->_replace_glob_with_values_in_pathname(@{$data[0]});
is(scalar(@data), 3, 'Glob replacement yielded three possible pathnames');
@data = sort { $a->[0] cmp $b->[0] } @data;
is_deeply(\@data,
          [
              [ "${dir}/General/Pyle.dat", { name => 'Pyle', rank => 'General' } ],
              [ "${dir}/Private/Pyle.dat", { name => 'Pyle', rank => 'Private' } ],
              [ "${dir}/Sergent/Pyle.dat", { name => 'Pyle', rank => 'Sergent' } ],
          ],
          'Path resolution data is correct');


# This path spec has a hardcoded glob in it already
$bx = $bx = URT::Thing->define_boolexpr(name => 'Pyle');
ok($bx, 'Create boolexpr with just name');
@data = UR::DataSource::Filesystem->_replace_vars_with_values_in_pathname(
               $bx,
               ${tmpdir}.'/*/$rank/${name}.dat'
            );
is(scalar(@data), 1, 'property replacement for spec including a glob yielded one pathname');
#print Data::Dumper::Dumper(\@data);
is_deeply(\@data,
           [ [ "$tmpdir/*/*/Pyle.dat", { name => 'Pyle', '.__glob_positions__' => [ [$tmpdir_strlen+3, 'rank' ] ] }
             ]
           ],
           'Path resolution data is correct');

@data = UR::DataSource::Filesystem->_replace_glob_with_values_in_pathname(@{$data[0]});
is(scalar(@data), 3, 'Glob replacement yielded three possible pathnames');
@data = sort { $a->[0] cmp $b->[0] } @data;
is_deeply(\@data,
          [
              [ "${dir}/General/Pyle.dat", { name => 'Pyle', rank => 'General' } ],
              [ "${dir}/Private/Pyle.dat", { name => 'Pyle', rank => 'Private' } ],
              [ "${dir}/Sergent/Pyle.dat", { name => 'Pyle', rank => 'Sergent' } ],
          ],
          'Path resolution data is correct');



# Make a bx with no filters and two properties in the path spec
$bx = $bx = URT::Thing->define_boolexpr();
ok($bx, 'Create boolexpr with no filters');
@data = UR::DataSource::Filesystem->_replace_vars_with_values_in_pathname(
               $bx,
               ${tmpdir}.'/*/$rank/${name}.dat'
            );
is(scalar(@data), 1, 'property replacement for spec including a glob yielded one pathname');
#print Data::Dumper::Dumper(\@data);
is_deeply(\@data,
           [ [ "$tmpdir/*/*/*.dat", { '.__glob_positions__' => [ [$tmpdir_strlen+3, 'rank' ],[$tmpdir_strlen+5,'name' ] ] }
             ]
           ],
           'Path resolution data is correct');

@data = UR::DataSource::Filesystem->_replace_glob_with_values_in_pathname(@{$data[0]});
is(scalar(@data), 5, 'Glob replacement yielded five possible pathname');
@data = sort { $a->[0] cmp $b->[0] } @data;
is_deeply(\@data,
          [
              [ "${dir}/General/Halftrack.dat", { name => 'Halftrack', rank => 'General' } ],
              [ "${dir}/Private/Bailey.dat", { name => 'Bailey', rank => 'Private' } ],
              [ "${dir}/Private/Pyle.dat", { name => 'Pyle', rank => 'Private' } ],
              [ "${dir}/Sergent/Carter.dat", { name => 'Carter', rank => 'Sergent' } ],
              [ "${dir}/Sergent/Snorkel.dat", { name => 'Snorkel', rank => 'Sergent' } ],
          ],
          'Path resolution data is correct');



# a bx with no filters and three properties in the path spec
$bx = URT::Thing->define_boolexpr();
ok($bx, 'Create boolexpr with no filters');
@data = UR::DataSource::Filesystem->_replace_vars_with_values_in_pathname(
               $bx,
               ${tmpdir}.'/$other/$rank/${name}.dat'
        );
is(scalar(@data), 1, 'property replacement for spec including a glob yielded one pathname');
#print Data::Dumper::Dumper(\@data);
is_deeply(\@data,
           [ [ "$tmpdir/*/*/*.dat", { '.__glob_positions__' => [
                                                                 [$tmpdir_strlen+1, 'other' ],
                                                                 [$tmpdir_strlen+3,'rank'],
                                                                 [$tmpdir_strlen+5,'name' ],
                                                               ] }
             ]
           ],
           'Path resolution data is correct');

@data = UR::DataSource::Filesystem->_replace_glob_with_values_in_pathname(@{$data[0]});
is(scalar(@data), 5, 'Glob replacement yielded five possible pathname');
@data = sort { $a->[0] cmp $b->[0] } @data;
is_deeply(\@data,
          [
              [ "${dir}/General/Halftrack.dat", { other => 'extra_dir', name => 'Halftrack', rank => 'General' } ],
              [ "${dir}/Private/Bailey.dat",    { other => 'extra_dir', name => 'Bailey',    rank => 'Private' } ],
              [ "${dir}/Private/Pyle.dat",      { other => 'extra_dir', name => 'Pyle',      rank => 'Private' } ],
              [ "${dir}/Sergent/Carter.dat",    { other => 'extra_dir', name => 'Carter',    rank => 'Sergent' } ],
              [ "${dir}/Sergent/Snorkel.dat",   { other => 'extra_dir', name => 'Snorkel',   rank => 'Sergent' } ],
          ],
          'Path resolution data is correct');



# This one has multiple variables in the same path portion
$bx = URT::Thing->define_boolexpr();
ok($bx, 'Create boolexpr with no filters');
@data = UR::DataSource::Filesystem->_replace_vars_with_values_in_pathname(
               $bx,
               ${tmpdir}.'/${other}_${other2}/$rank/${name}.dat'
        );
is(scalar(@data), 1, 'property replacement for spec including a glob yielded one pathname');
#print Data::Dumper::Dumper(\@data);
is_deeply(\@data,
           [ [ "$tmpdir/*_*/*/*.dat", { '.__glob_positions__' => [
                                                                 [$tmpdir_strlen+1, 'other' ],
                                                                 [$tmpdir_strlen+3, 'other2' ],
                                                                 [$tmpdir_strlen+5,'rank'],
                                                                 [$tmpdir_strlen+7,'name' ],
                                                               ] }
             ]
           ],
           'Path resolution data is correct');
@data = UR::DataSource::Filesystem->_replace_glob_with_values_in_pathname(@{$data[0]});
is(scalar(@data), 5, 'Glob replacement yielded five possible pathname');
@data = sort { $a->[0] cmp $b->[0] } @data;
is_deeply(\@data,
          [
              [ "${dir}/General/Halftrack.dat", { other => 'extra', other2 => 'dir', name => 'Halftrack', rank => 'General' } ],
              [ "${dir}/Private/Bailey.dat",    { other => 'extra', other2 => 'dir', name => 'Bailey',    rank => 'Private' } ],
              [ "${dir}/Private/Pyle.dat",      { other => 'extra', other2 => 'dir', name => 'Pyle',      rank => 'Private' } ],
              [ "${dir}/Sergent/Carter.dat",    { other => 'extra', other2 => 'dir', name => 'Carter',    rank => 'Sergent' } ],
              [ "${dir}/Sergent/Snorkel.dat",   { other => 'extra', other2 => 'dir', name => 'Snorkel',   rank => 'Sergent' } ],
          ],
          'Path resolution data is correct');


# Try it on a method call
my $is_sub_called = 0;
my $bx_from_sub;
my $class_from_sub;
my $resolver = sub {
    my($class,$rule) = @_;
    $class_from_sub = $class;
    $bx_from_sub = $bx;
    $is_sub_called++;
    return 'extra_dir';
};
Sub::Install::install_sub({
    code => $resolver,
    into => 'URT::Thing',
    as => 'extra_path_resolver'
});
$bx = URT::Thing->define_boolexpr();
ok($bx, 'Created boolexpr with no filters');
@data = UR::DataSource::Filesystem->_replace_subs_with_values_in_pathname(
             $bx,
             ${tmpdir}.'/&extra_path_resolver/General/Halftrack.dat'
);
is(scalar(@data), 1, 'property replacement for spec including a method call yielded one pathname');
#print Data::Dumper::Dumper(\@data);
is_deeply(\@data,
           [ [ "$tmpdir/extra_dir/General/Halftrack.dat", {'.__glob_positions__' => []} ] ],
          'Path resolution data is correct');
is($is_sub_called, 1, 'The resolver sub was called');
is($class_from_sub, 'URT::Thing', 'The resolver sub was passed the right class name');
is($bx_from_sub, $bx, 'The resolver sub was passed the right boolexpr');



# pair of method calls
Sub::Install::install_sub({ code => sub { 'dat' }, into => 'URT::Thing', as => 'data_file_extension'});
$bx = URT::Thing->define_boolexpr();
ok($bx, 'Created boolexpr with no filters');
@data = UR::DataSource::Filesystem->_replace_subs_with_values_in_pathname(
             $bx,
             ${tmpdir}.'/&extra_path_resolver/General/Halftrack.&data_file_extension'
);
is(scalar(@data), 1, 'property replacement for spec including two method calls yielded one pathname');
#print Data::Dumper::Dumper(\@data);
is_deeply(\@data,
           [ [ "$tmpdir/extra_dir/General/Halftrack.dat", {'.__glob_positions__' => []} ] ],
          'Path resolution data is correct');


# pair of methods in the same path part
Sub::Install::install_sub({ code => sub { 'extra' }, into => 'URT::Thing', as => 'extra_word'});
Sub::Install::install_sub({ code => sub { 'dir' }, into => 'URT::Thing', as => 'dir_word'});
ok($bx, 'Created boolexpr with no filters');
@data = UR::DataSource::Filesystem->_replace_subs_with_values_in_pathname(
             $bx,
             ${tmpdir}.'/&{extra_word}_&{dir_word}/General/Halftrack.&data_file_extension'
);
is(scalar(@data), 1, 'property replacement for spec including three yielded one pathname');
#print Data::Dumper::Dumper(\@data);
is_deeply(\@data,
           [ [ "$tmpdir/extra_dir/General/Halftrack.dat", {'.__glob_positions__' => []} ] ],
          'Path resolution data is correct');





# method call returning multiple values
Sub::Install::install_sub({ code => sub { return ('General','Private','Sergent') }, into => 'URT::Thing', as => 'rank_list'});
$bx = URT::Thing->define_boolexpr();
ok($bx, 'Created boolexpr with no filters');
@data = UR::DataSource::Filesystem->_replace_subs_with_values_in_pathname(
             $bx,
             ${tmpdir}.'/&extra_path_resolver/&rank_list/*.&data_file_extension'
);
is(scalar(@data), 3, 'property replacement for spec including a glob yielded one pathname');
#print Data::Dumper::Dumper(\@data);
is_deeply(\@data,
           [ [ "$tmpdir/extra_dir/General/*.dat", {'.__glob_positions__' => []} ],
             [ "$tmpdir/extra_dir/Private/*.dat", {'.__glob_positions__' => []} ],
             [ "$tmpdir/extra_dir/Sergent/*.dat", {'.__glob_positions__' => []} ] ],
          'Path resolution data is correct');



# put it all together

# a bunch of variables
$bx = URT::Thing->define_boolexpr();
@data = UR::DataSource::Filesystem->resolve_file_info_for_rule_and_path_spec($bx, ${tmpdir}.'/${other}_${other2}/$rank/${name}.dat');
is(scalar(@data), 5, 'resolve_file_info_for_rule_and_path_spec() returns 5 pathnames');
@data = sort { $a->[0] cmp $b->[0] } @data;
is_deeply(\@data,
          [
              [ "${dir}/General/Halftrack.dat", { other => 'extra', other2 => 'dir', name => 'Halftrack', rank => 'General' } ],
              [ "${dir}/Private/Bailey.dat",    { other => 'extra', other2 => 'dir', name => 'Bailey',    rank => 'Private' } ],
              [ "${dir}/Private/Pyle.dat",      { other => 'extra', other2 => 'dir', name => 'Pyle',      rank => 'Private' } ],
              [ "${dir}/Sergent/Carter.dat",    { other => 'extra', other2 => 'dir', name => 'Carter',    rank => 'Sergent' } ],
              [ "${dir}/Sergent/Snorkel.dat",   { other => 'extra', other2 => 'dir', name => 'Snorkel',   rank => 'Sergent' } ],
          ],
          'Path resolution data is correct');


# variables, methods and globs
$bx = URT::Thing->define_boolexpr();
@data = UR::DataSource::Filesystem->resolve_file_info_for_rule_and_path_spec(
            $bx,
            ${tmpdir}.'/${other}_&dir_word/$rank/${name}.&data_file_extension'
);
is(scalar(@data), 5, 'resolve_file_info_for_rule_and_path_spec() returns 5 pathnames');
@data = sort { $a->[0] cmp $b->[0] } @data;
#print Data::Dumper::Dumper(\@data);
is_deeply(\@data,
          [
              [ "${dir}/General/Halftrack.dat", { other => 'extra', name => 'Halftrack', rank => 'General' } ],
              [ "${dir}/Private/Bailey.dat",    { other => 'extra', name => 'Bailey',    rank => 'Private' } ],
              [ "${dir}/Private/Pyle.dat",      { other => 'extra', name => 'Pyle',      rank => 'Private' } ],
              [ "${dir}/Sergent/Carter.dat",    { other => 'extra', name => 'Carter',    rank => 'Sergent' } ],
              [ "${dir}/Sergent/Snorkel.dat",   { other => 'extra', name => 'Snorkel',   rank => 'Sergent' } ],
          ],
          'Path resolution data is correct');




1;



sub _create_data_file {
    my($dir,$rank,$name,$data) = @_;

    my $subdir = $dir . '/' . $rank;
    unless (-d $subdir) {
        mkdir $subdir || die "Can't create subdir $subdir: $!";
    }
    my $pathname = $subdir . '/' . $name . '.dat';
    my $f = IO::File->new($pathname, 'w') || die "Can't create file $pathname: $!";
    $f->print($data);
    1;
}
