use strict;
use warnings;
use Test::More tests=> 13;
use File::Basename;
use lib File::Basename::dirname(__FILE__)."/../../../lib";
use lib File::Basename::dirname(__FILE__).'/../namespace';
use lib File::Basename::dirname(__FILE__).'/../classes';
use lib File::Basename::dirname(__FILE__).'/../data_source';
use lib File::Basename::dirname(__FILE__).'/../more_classes';

use URTAlternate;

is(URTAlternate->class, 'URTAlternate', 'Namespace name');

my $class_meta = URTAlternate->get_member_class('URTAlternate::Person');
ok($class_meta, 'get_member_class');
is($class_meta->class_name, 'URTAlternate::Person', 'get_member_class returned the right class');

# This is basically the list of Perl modules under URT/
# note that the 38* classes do not compile because they use data sources that exist
# only during that test, and so are not returned by get_material_classes()
my @expected_class_names = sort 
                           map { 'URTAlternate::' . $_ }
                           qw( Person Car DataSource::Meta DataSource::TheDB Vocabulary );
my @class_metas = sort URTAlternate->get_material_classes;
is(scalar(@class_metas), scalar(@expected_class_names), 'get_material_classes returned expected number of items');
foreach (@class_metas) {
    isa_ok($_, 'UR::Object::Type');
}
my @class_names = sort map { $_->class_name } @class_metas;
is_deeply(\@class_names, \@expected_class_names, 'get_material_classes');

my @data_sources = sort URTAlternate->get_data_sources;
foreach ( @data_sources) {
    isa_ok($_, 'UR::DataSource');
}
my @expected_ds_names = map { 'URTAlternate::' . $_ }
                        qw( DataSource::Meta DataSource::TheDB );
my @data_source_names = sort map { $_->class } @data_sources;
is_deeply(\@data_source_names, \@expected_ds_names, 'get_data_sources');

