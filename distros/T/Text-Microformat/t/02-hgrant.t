use strict;
use warnings;
use Test::More tests => 6;

use Carp 'confess';
$SIG{__DIE__} = \&confess;

BEGIN { use_ok 'Text::Microformat' }
open IN, 't/hgrant1.html';
local $/;
my $html = <IN>;
my $uformat = Text::Microformat->new($html);
my @things = $uformat->find;
is($things[0]->Get('grantee.fn'), 'Stanford University');
is($things[0]->Get('grantee.url'), 'http://www.stanford.edu');
is($things[1]->Get('grantee.fn'), 'Michigan State University');
is($things[1]->Get('grantee.url'), 'http://www.msu.edu');
is($things[0]->Get('grantor.fn'), 'The William and Flora Hewlett Foundation');
