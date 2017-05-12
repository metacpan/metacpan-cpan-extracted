use Test::More 'no_plan';
use Test::Legal::Util qw/ license_types  /;

* license_text = *Test::Legal::Util::license_text;


my $dir     = $ENV{PWD} =~ m#\/t$#  ? 'dat' : 't/dat';


ok   license_text($_, 'john'), $_    for license_types;

ok ! license_text($_, 'john')   for qw/ Perl GPL /;
ok ! license_text();
ok ! license_text('');
ok ! license_text('',);
ok ! license_text('','');
ok ! license_text('','aa');

TODO: {
	local $TODO = 'should find author';
	ok  license_text('Perl_1','');
}



ok 1;
