
use strict;
use warnings;
use lib("./lib");
use Data::Dumper;

use Test::More ;
BEGIN { use_ok('Told::Client') };

ok( my $told = Told::Client->new(), 'Can create instance of Told::Client');
my $p = $told->getParams();
is ($p->{'host'}, '', 'Host is empty on simple initialisation');
is ($p->{'type'}, '', 'Type is empty on simple initialisation');
is ($p->{'defaulttags'}, undef, 'defaulttags has size 0 on simple initialisation');
is ($p->{'tags'}, undef, 'tags has size 0 on simple initialisation');

done_testing();