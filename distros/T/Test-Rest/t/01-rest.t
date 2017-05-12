#!perl

use Test::More skip_all => "Need to update these";
use Test::Rest;
use Test::MockObject;

my $ua = Test::MockObject->new;
$ua->mock('get', sub{
   HTTP::Response->new( 200, 'OK', ['Content-Type'=>'application/xml'], '<pong/>' ) 
});
$ua->mock('post', sub{
   HTTP::Response->new( 200, 'OK', ['Content-Type'=>'application/xml'], '<pong/>' ) 
});
my $tests = Test::Rest->new(
    base => 'http://webservice.example.com/',
    ua => $ua,
);

# get
$tests->run_test(string => <<'EOT');
<tests>
  <get location="ping"/>
</tests>
EOT
is($ua->call_pos(1), 'get');
is_deeply([$ua->call_args(1)], [$ua, 'http://webservice.example.com/ping']);
$ua->clear;

# post
$tests->run_test(string => <<'EOT');
<tests>
  <set name="random">RANDOM</set>
  <set name="mail">test+[% random %]@example.com</set>
  <set name="pass">[% random %]</set>
  <post location="ping">
    <Content>
      <user>
        <firstname>Testy</firstname>
        <lastname>McTester</lastname>
        <mail>[% mail %]</mail>
        <pass>[% pass %]</pass>
      </user>
   </Content>
  </post>
</tests>
EOT
is($ua->call_pos(1), 'post');
is_deeply([$ua->call_args(1)], [
  $ua, 
  'http://webservice.example.com/ping', 
  'Content-Type' => 'application/xml',
  'Content' => '<user>
        <firstname>Testy</firstname>
        <lastname>McTester</lastname>
        <mail>test+RANDOM@example.com</mail>
        <pass>RANDOM</pass>
      </user>'
]);
$ua->clear;

# post w/ content/type
$tests->run_test(string => <<'EOT');
<tests>
  <set name="random">RANDOM</set>
  <set name="mail">test+[% random %]@example.com</set>
  <set name="pass">[% random %]</set>
  <post location="ping">
    <Content-Type>text/xml</Content-Type>
    <Content>
      <user>
        <firstname>Testy</firstname>
        <lastname>McTester</lastname>
        <mail>[% mail %]</mail>
        <pass>[% pass %]</pass>
      </user>
   </Content>
  </post>
</tests>
EOT
is($ua->call_pos(1), 'post');
is_deeply([$ua->call_args(1)], [
  $ua, 
  'http://webservice.example.com/ping', 
  'Content-Type' => 'text/xml',
  'Content' => '<user>
        <firstname>Testy</firstname>
        <lastname>McTester</lastname>
        <mail>test+RANDOM@example.com</mail>
        <pass>RANDOM</pass>
      </user>'
]);
$ua->clear;
