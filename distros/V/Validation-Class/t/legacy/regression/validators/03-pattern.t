use Test::More tests => 5;

package MyVal;
use Validation::Class;

package main;

my $r = MyVal->new(
    fields => {
        telephone => {pattern => '### ###-####'},
        url       => {pattern => qr/https?:\/\/.+/}
    },
    params => {
        telephone => '123 456-7890',
        url       => 'dept.site.com'
    }
);

ok $r->validate('telephone'), 'telephone validates';
$r->params->{telephone} = '1234567890';

ok !$r->validate('telephone'), 'telephone doesnt validate';
ok $r->errors_to_string() =~ /is not formatted properly/,
  'displays proper error message';

ok !$r->validate('url'), 'url doesnt validate';
$r->params->{url} = 'http://dept.site.com/';

ok $r->validate('url'), 'url validates';
