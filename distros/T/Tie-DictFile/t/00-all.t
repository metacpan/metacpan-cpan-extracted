
use Test::More tests => 17;
use strict;

my $file= 't/data/miniwords';

use_ok('Carp'); 
use_ok('Tie::DictFile'); 

my %words; 
tie %words, 'Tie::DictFile',$file;

ok(keys(%words),"tie succeeded"); 

ok(exists $words{'hello'},"'hello' defined in dictionary"); 
is($words{'hello'},$words{'Hello'},"varying case of keys returns same values"); 
ok(! exists $words{'goodbye'},"'goodbye' not defined in dictionary"); 

untie %words;

tie %words, 'Tie::DictFile',$file;

ok(keys(%words),"second tie succeeded"); 

ok(exists $words{'hello'},"'hello' defined in dictionary"); 
ok(! exists $words{'goodbye'},"'goodbye' not defined in dictionary"); 
is_deeply(['hello','world'],[keys %words],"all keys expected in dictionary found");

$words{'goodbye'}=1;
undef $words{'hello'};

ok(! exists $words{'hello'},"'hello' no longer defined in dictionary"); 
ok( exists $words{'goodbye'},"'goodbye' now defined in dictionary"); 
untie %words;



tie %words, 'Tie::DictFile',$file;

ok(keys(%words),"third tie succeeded"); 

ok(! exists $words{'hello'},"'hello' not defined in dictionary"); 
ok(exists $words{'goodbye'},"'goodbye' is defined in dictionary"); 


$words{'goodbye'}=undef;
$words{'hello'}=1;

ok(exists $words{'hello'},"'hello' defined in dictionary"); 
ok(! exists $words{'goodbye'},"'goodbye' not defined in dictionary"); 

untie %words;
