use strict;
use warnings;
use Test::More;
use File::Basename;
use lib File::Basename::dirname(__FILE__)."/../../../lib";
use lib File::Basename::dirname(__FILE__).'/../..';

use URT;

if ($^O eq 'darwin') {
    plan skip_all => 'known to fail OS X'
}
else {
    plan tests => 31
}

is(URT->class, 'URT', 'Namespace name');

my $class_meta = URT->get_member_class('URT::Thingy');
ok($class_meta, 'get_member_class');
is($class_meta->class_name, 'URT::Thingy', 'get_member_class returned the right class');

# This is basically the list of Perl modules under URT/
# note that the 38* classes do not compile because they use data sources that exist
# only during that test, and so are not returned by get_material_classes()
my @expected_class_names = map { 'URT::' . $_ }
                           qw( 34Baseclass 34Subclass 43Primary 43Related
                               Context::Testing DataSource::CircFk DataSource::Meta
                               DataSource::SomeFile DataSource::SomeFileMux
                               DataSource::SomeMySQL DataSource::SomeOracle
                               DataSource::SomePostgreSQL DataSource::SomeSQLite
                               ObjWithHash RAMThingy Thingy Vocabulary );
my @class_metas = URT->get_material_classes;
is(scalar(@class_metas), scalar(@expected_class_names), 'get_material_classes returned expected number of items');
foreach (@class_metas) {
    isa_ok($_, 'UR::Object::Type');
}
my @class_names = sort map { $_->class_name } @class_metas;
is_deeply(\@class_names, \@expected_class_names, 'get_material_classes');

my @data_sources = sort URT->get_data_sources;
foreach ( @data_sources) {
    isa_ok($_, 'UR::DataSource');
}
my @expected_ds_names = map { 'URT::' . $_ }
                        qw( DataSource::CircFk DataSource::Meta
                            DataSource::SomeFile DataSource::SomeFileMux
                            DataSource::SomeMySQL DataSource::SomeOracle
                            DataSource::SomePostgreSQL DataSource::SomeSQLite );
my @data_source_names = sort map { $_->class } @data_sources;
is_deeply(\@data_source_names, \@expected_ds_names, 'get_data_sources');

