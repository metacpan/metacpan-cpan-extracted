
use Test::More 'no_plan';
use Test::Legal::Util qw/load_meta/;

* find_license = *Test::Legal::Util::find_license;

#my $version = '5.01000';

my $dir     = $ENV{PWD} =~ m#\/t$#  ? 'dat' : 't/dat';

my $meta = load_meta( $dir );

is find_license($dir),  'Perl_5';
is find_license($meta), 'Perl_5';


# Returns undef
ok ! find_license();
ok ! find_license(undef);
ok ! find_license('');
ok ! find_license('/etc');




