
use strict;
use warnings;
use lib("./lib");
use Data::Dumper;

use Test::More ;
BEGIN { use_ok('Told::Client') };

ok( my $told = Told::Client->new(), 'Can create instance of Told::Client');

$told->setDefaulttags('Test');
my $p = $told->getParams();
is(@{$p->{'defaulttags'}}[0], 'Test', '1 Defaulttag is set');
is(@{$p->{'defaulttags'}}[1], undef, '2 Defaulttag is not set');

$told->setDefaulttags('Test', 'Next');
$p = $told->getParams();
is(@{$p->{'defaulttags'}}[0], 'Test', '1 Defaulttag is set');
is(@{$p->{'defaulttags'}}[1], 'Next', '2 Defaulttag are set');


done_testing();