use Test::More tests => 12;

# begin
package MyVal;
use Validation::Class;

package main;

my $dpre = MyVal->new(
    fields => {foobar => {filters => 'alphanumeric'}},
    params => {foobar => '1@%23abc45@%#@#%6d666ef..'}
);

ok $dpre->params->{foobar} =~ /^123abc456d666ef$/, 'default pre-filtering ok';

my $pre = MyVal->new(
    fields    => {foobar => {filters => 'alphanumeric'}},
    params    => {foobar => '1@%23abc45@%#@#%6d666ef..'},
    filtering => 'pre'
);

ok $pre->params->{foobar} =~ /^123abc456d666ef$/, 'explicit pre-filtering ok';

my $post = MyVal->new(
    fields    => {foobar => {filters => 'alphanumeric'}},
    params    => {foobar => '1@%23abc45@%#@#%6d666ef..'},
    filtering => 'post'
);

ok $post->params->{foobar} =~ /^1@%23abc45@%#@#%6d666ef\.\.$/,
  'explicit post-filtering ok';

$post->validate;
ok $post->params->{foobar} =~ /^123abc456d666ef$/,
  'explicit post-filtering after validate ok';

my $nope = MyVal->new(
    fields    => {foobar => {filters => 'alphanumeric'}},
    params    => {foobar => '1@%23abc45@%#@#%6d666ef..'},
    filtering => 'off'
);

ok $nope->params->{foobar} =~ /^1@%23abc45@%#@#%6d666ef\.\.$/,
  'explicit no-filtering ok';

$nope->validate;
ok $nope->params->{foobar} =~ /^1@%23abc45@%#@#%6d666ef\.\.$/,
  'explicit no-filtering after validate ok';

$nope = MyVal->new(
    fields    => {foobar => {filters => 'alphanumeric'}},
    params    => {foobar => '1@%23abc45@%#@#%6d666ef..'},
    filtering => 'manual'
);

ok $nope->params->{foobar} =~ /^1@%23abc45@%#@#%6d666ef\.\.$/,
  'explicit no pre/post filtering ok';

$nope->validate;

ok $nope->params->{foobar} =~ /^1@%23abc45@%#@#%6d666ef\.\.$/,
  'explicit no-filtering after validate ok';

# ok $nope->apply_filters('manual'), 'applying filters manually'; - DEPRECATED
ok $nope->proto->apply_filters('manual'), 'applying filters manually';
ok $nope->params->{foobar} =~ /^123abc456d666ef$/,
  'filtering applied manually';

$nope = MyVal->new(
    fields    => {foobar => {filters => 'alphanumeric'}},
    params    => {foobar => '1@%23abc45@%#@#%6d666ef..'},
    filtering => 'pre'
);

ok $nope->filtering('pre'), 'changing filtering behavior: pre';

$nope->fields->{foobar}->{pattern} = qr/^\d{3}\w{3}\d{3}\w\d{3}\w{2}$/;
$nope->params->{foobar} = '1@%23abc45@%#@#%6d666ef..';

ok $nope->validate, 'pre-filtering allowed validation';
