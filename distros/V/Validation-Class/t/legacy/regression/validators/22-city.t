use Test::More;

package main;

use utf8;
use Validation::Class::Simple;

my $r = Validation::Class::Simple->new(fields => {city => {city => 1}});

# failures

$r->params->{city} = 'bumfuck';
ok !$r->validate(), 'bumfuck is invalid';
$r->params->{city} = 'prison';
ok !$r->validate(), 'prison is invalid';
$r->params->{city} = 'st louis';
ok !$r->validate(), 'st louis is invalid';

# successes

$r->params->{city} = 'new york';
ok $r->validate(), 'new york is valid';
$r->params->{city} = 'st. louis';
ok $r->validate(), 'st. louis is valid';
$r->params->{city} = 'atlanta';
ok $r->validate(), 'atlanta is valid';
$r->params->{city} = 'philadelphia';
ok $r->validate(), 'philadelphia is valid';
$r->params->{city} = 'santa monica';
ok $r->validate(), 'santa monica is valid';
$r->params->{city} = 'baltimore';
ok $r->validate(), 'baltimore is valid';
$r->params->{city} = 'santa bárbara';
ok $r->validate(), 'santa bárbara is valid';

done_testing;
