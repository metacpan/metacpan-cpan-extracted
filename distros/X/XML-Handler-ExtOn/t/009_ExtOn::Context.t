#use Test::More qw( no_plan);
use Test::More tests=>5;
use strict;
use warnings;
use Data::Dumper;

BEGIN {
    use_ok 'XML::Handler::ExtOn::Context';
}
my $context1 = new XML::Handler::ExtOn::Context::;
my $map1 = $context1->get_map;
my $context2 = $context1->sub_context();
my $map2 = $context2->get_map;
$map2->{'ord'}="http://org.com/ns";
$map2->{'ord3'}="http://org3.com/ns";

is_deeply $map2,{
'ord' => 'http://org.com/ns',
                        'ord3' => 'http://org3.com/ns',
                        'xmlns' => 'http://www.w3.org/2000/xmlns/'
}, 'check map2';
is_deeply$context2->get_changes, {           'ord' => 'http://org.com/ns',
           'ord3' => 'http://org3.com/ns'
}, 'check get_changes after add to 2';

my $context3 = $context2->sub_context();
my $map3 = $context3->get_map;

#diag Dumper $map3;
is $context3->get_uri(''), 'http://www.w3.org/2000/xmlns/', 'check default uri';
$context3->declare_prefix(''=>"http://localhost/doc_com");
is $context3->get_uri(''), 'http://localhost/doc_com', 'check default uri';

#diag Dumper $map3;
#is $context3->get_uri(''), 'http://www.w3.org/2000/xmlns/' 'check default uri';
#diag Dumper { '$map1'=>$map1, '$map2'=>$map2,'$map3'=>$map3,};
#diag Dumper $context2->get_changes;
exit;

