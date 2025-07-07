use v5.14;
use warnings;

use Test2::V0;

use Test2::Util::DistFiles qw( manifest_files is_perl_file );

my @all = manifest_files();
ok !!@all, "manifest_files";

my @perl = manifest_files( \&is_perl_file);
ok !!@perl, "manifest_files( is_perl_file )";

is \@perl, array { all_items in_set(@all); etc }, 'subset';

done_testing;
