#!perl
use jQuery;
use FindBin qw($Bin);
use Test::More tests => 4;



use Data::Dumper;
my $j = jQuery->new("<div><p>Hi</p><p>Hi</p></div>");
my $t = jQuery('p');
jQuery('p')->data('test','hi');
my $test = jQuery('p:first')->data('test');
#diag Dumper $tt;

$j->jQuery('div')->data('again',{
first => 'first',
second => 'second'
});

my $again = jQuery('div')->data('again');

is($test,'hi');
is($again->{first},'first');




###jQuery->data
#jQuery->data(jQuery('div'),'again',{
#first => 'first',
#second => 'second'
#});
my $again2 = jQuery->data(jQuery('div'),'again');
is($again2->{second},'second');


jQuery->data( jQuery->document->body, 'body', 'in body'   );
my $val = jQuery->data( jQuery->document->body, 'body'  );

is($val,'in body');
