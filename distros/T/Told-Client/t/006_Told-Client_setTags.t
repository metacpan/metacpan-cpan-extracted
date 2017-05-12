
use strict;
use warnings;
use lib("./lib");
use Data::Dumper;

use Test::More ;
BEGIN { use_ok('Told::Client') };

ok( my $told = Told::Client->new(), 'Can create instance of Told::Client');

$told->setTags('Test');
my $p = $told->getParams();
is(@{$p->{'tags'}}[0], 'Test', '1 tag is set');
is(@{$p->{'tags'}}[1], undef, '2 tags are not set');

$told->setTags('Test', 'Next');
$p = $told->getParams();
is(@{$p->{'tags'}}[0], 'Test', '1 tag is set');
is(@{$p->{'tags'}}[1], 'Next', '2 tags are set');


done_testing();