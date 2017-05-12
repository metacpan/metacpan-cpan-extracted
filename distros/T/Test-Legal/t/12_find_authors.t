use Test::More 'no_plan';
use Test::Legal::Util qw/load_meta/;

* find_authors = * Test::Legal::Util::find_authors;

#my $version = '5.01000';

my $dir     = $ENV{PWD} =~ m#\/t$#  ? 'dat' : 't/dat';

my $file = "$dir/META.yml";

is find_authors($_), 'Ioannis Tambouras'  for ($dir, load_meta($file), $file);;
is find_authors("$dir/wrong/META.json"), 'Ioannis Tambouras' ;
is find_authors("$dir/wrong/$_.yml"), 'Butthead, Ioannis Tambouras, Sun Trieb'   for qw/butthead gpi/; 

is find_authors("$dir/wrong/noauthor.yml"), 'unknown' ;

# Returns undef
ok ! find_authors($_)  for (undef, '', '/etc');

