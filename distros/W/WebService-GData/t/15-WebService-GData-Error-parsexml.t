use Test::More tests => 5;
use WebService::GData::Error;

my $xml=<<'XML';

<?xml version='1.0' encoding='UTF-8'?>
<errors>
  <error>
    <domain>yt:validation</domain>
    <code>invalid_character</code>
    <location type='xpath'>media:group/media:title/text()</location>
  </error>
  <error>
    <domain>yt:validation</domain>
    <code>too_long</code>
    <location type='xpath'>media:group/media:title/text()</location>
  </error>
  <error>
    <domain>yt:authentication</domain>
    <code>TokenExpired</code>
    <location type='header'>Authorization: GoogleLogin</location>
  </error>
</errors>

XML

my $error  = new WebService::GData::Error(401,$xml);
my $errors = $error->errors;

ok($error->code ==401,'code is properly set.');
ok($error->content eq $xml,'content is properly set.');
ok(@$errors==3,'errors does contain 3 errors.');
ok($errors->[0]->isa('WebService::GData::Error::Entry'),'errors contain WebService::GData::Error::Entry instances.');

$error  = new WebService::GData::Error();
$errors = $error->errors;
ok(@$errors==0,'errors should be empty');

