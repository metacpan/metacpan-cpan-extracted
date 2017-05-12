use Test::More 'no_plan';
use Test::Legal::Util; 

* is_license_type = * Test::Legal::Util::is_license_type;



my $dir     = $ENV{PWD} =~ m#\/t$#  ? 'dat' : 't/dat';


ok is_license_type( $_ )    for qw/ Perl_5 BSD /;
ok ! is_license_type( $_ )  for qw/ perl_5 BsD /;
ok ! is_license_type($_)    for qw/ perl gpl /;

ok ! is_license_type('');
ok ! is_license_type();

