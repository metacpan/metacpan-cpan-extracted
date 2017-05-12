use Test::More tests => 8;

BEGIN {
use_ok( 'Text::Mining::Base' );
}

my $base = Text::Mining::Base->new();
ok( $base, "Text::Mining::Base->new()" );

my $library = $base->library(), "\n";
ok( $library, "\$base->library()" );

my $analysis = $base->analysis();
ok( $analysis, "\$base->analysis()" );

my $root_dir = $base->get_root_dir(), "\n";
ok( $root_dir, "\$base->get_root_dir()" );

my $root_url = $base->get_root_url(), "\n";
ok( $root_url, "\$base->get_root_url()" );

my $data_dir = $base->get_data_dir(), "\n";
ok( $data_dir, "\$base->get_data_dir()" );

my $cfg_file = $base->get_config_filename(), "\n";
ok( $cfg_file, "\$base->get_config_filename()" );


