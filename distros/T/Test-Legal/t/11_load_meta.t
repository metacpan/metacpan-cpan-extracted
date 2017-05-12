use Test::More 'no_plan';
use Test::Legal::Util 'load_meta';



my $dir = $ENV{PWD} =~ m#\/t$#  ? 'dat' : 't/dat';

isa_ok load_meta($dir), 'CPAN::Meta', 'load from dir';
my $meta = load_meta($dir);
isa_ok load_meta($meta), 'CPAN::Meta', 'load from object';
isa_ok load_meta("$dir/META.yml"), 'CPAN::Meta', 'load from file';

ok ! load_meta()   for (undef, '', bless(\{},'apple'), 3, [3], '/META.yml', '/etc');
ok   load_meta(bless \{}, 'CPAN::Meta');
