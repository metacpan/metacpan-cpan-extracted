use Test::More;
use lib 'inc';
use Devel::CheckOS qw(os_isnt);

eval "use Test::Pod::Coverage 1.00";
plan skip_all => "Test::Pod::Coverage 1.00 required for testing POD coverage"
  if $@;

my @all_modules;

foreach ( all_modules() ) {

    push( @all_modules, $_ )
      unless ( ( os_isnt('UNIX') ) and ( $_ eq 'Siebel::Srvrmgr::OS::Unix' ) );

}

plan tests => scalar(@all_modules);

foreach my $module (@all_modules) {

    pod_coverage_ok( $module, "Pod coverage for $module is OK" );

}
