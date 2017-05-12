
use Test::More 'no_plan';
use Test::Legal::Util qw/load_meta/;

* check_META_file = *Test::Legal::Util::check_META_file;


#my $version = '5.01000';

my $dir     = $ENV{PWD} =~ m#\/t$#  ? 'dat' : 't/dat';


isa_ok check_META_file($_),  'Software::License::Perl_5'    for ($dir, load_meta($dir) );

ok ! check_META_file($_)     for (      "$dir/wrong",
										load_meta("$dir/wrong"),
										"$dir/wrong/gpi.yml",
										load_meta("$dir/wrong/gpi.yml"),
										"$dir/wrong/META.json",
										"$dir/wrong/butthead.yml",
										"$dir/wrong/noauthor.yml",
);

# Returns undef
ok ! check_META_file($_)        for (undef,'','/etc');



