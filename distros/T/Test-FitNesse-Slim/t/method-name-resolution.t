use strict;
use warnings;

use lib 'lib', 't/lib';

use Test::More;
use Test::FitNesse::Slim::List;
use Test::FitNesse::Slim::ListExecutor;

use Fitnesse::Slim::Test::MethodNameResolution;

sub execute_wire {
  my ($executor, @instructions) = @_;
  my $serialized = Test::FitNesse::Slim::List->new(\@instructions)->serialize;
  return $executor->execute(Test::FitNesse::Slim::List->new($serialized)->list);
}

my $names = Test::FitNesse::Slim::ListExecutor->new;
my @results = execute_wire($names,
  ['make', 'make', 'actor', 'Fitnesse::Slim::Test::MethodNameResolution'],
  ['url', 'call', 'actor', 'fetchURL'],
  ['xml', 'call', 'actor', 'parseXMLDocument'],
  ['http', 'call', 'actor', 'getHTTPResponseCode', '204'],
  ['ipv6', 'call', 'actor', 'isIPv6Enabled', 'yes'],
  ['user-id', 'call', 'actor', 'echoUserID', '73'],
  ['camel', 'call', 'actor', 'directSnakeCase'],
  ['single-letter-word', 'call', 'actor', 'makeATestPage'],
  ['snake', 'call', 'actor', 'get_url'],
  ['exact', 'call', 'actor', 'getURL'],
  ['ordinary', 'call', 'actor', 'reset'],
  ['store', 'call', 'actor', 'setValue', 'retained'],
  ['value', 'call', 'actor', 'getValue'],
  ['assigned', 'callAndAssign', 'saved', 'actor', 'getHTTPResponseCode', '299'],
  ['assigned-symbol', 'call', 'actor', 'getHTTPResponseCode', '$saved'],
  ['sut', 'call', 'actor', 'getSutStatus'],
  ['actor-precedence', 'call', 'actor', 'actorAndSut'],
  ['typed-arity', 'call', 'actor', 'getHTTPResponseCode'],
  ['typed-conversion', 'call', 'actor', 'getHTTPResponseCode', 'not-a-number'],
  ['after-error', 'call', 'actor', 'getHTTPResponseCode', '201'],
  ['missing', 'call', 'actor', 'doesNotExistXML'],
  ['after-missing', 'call', 'actor', 'reset'],
);

is_deeply([@results[0 .. 16]], [
  ['make', 'OK'],
  ['url', 'snake URL'],
  ['xml', 'parsed XML'],
  ['http', '204'],
  ['ipv6', 'true'],
  ['user-id', 'user 73'],
  ['camel', 'camel boundary'],
  ['single-letter-word', 'created test page'],
  ['snake', 'snake URL'],
  ['exact', 'exact URL'],
  ['ordinary', 'reset'],
  ['store', 'stored'],
  ['value', 'retained'],
  ['assigned', '299'],
  ['assigned-symbol', '299'],
  ['sut', 'SUT status'],
  ['actor-precedence', 'actor wins'],
], 'wire-level method resolution supports exact, camelCase, and acronym names');

like($results[17][1], qr/^__EXCEPTION__:message:<<NO_METHOD_IN_CLASS No Method getHTTPResponseCode\[0\]/,
  'typed arity failure reports the original SLiM method name');
like($results[18][1], qr/^__EXCEPTION__:message:<<Can't convert not-a-number to integer/,
  'typed conversion uses the signature of the resolved Perl method');
is($results[19][1], '201', 'executor remains usable after typed dispatch errors');
like($results[20][1], qr/^__EXCEPTION__:message:<<NO_METHOD_IN_CLASS doesNotExistXML\[0\]/,
  'missing-method diagnostics preserve the requested SLiM name');
is($results[21][1], 'reset', 'executor continues after a missing method');

my @library = execute_wire($names,
  ['library', 'make', 'library_http', 'Fitnesse::Slim::Test::MethodNameResolution::Library'],
  ['newer-library', 'make', 'library_http_new', 'Fitnesse::Slim::Test::MethodNameResolution::NewLibrary'],
  ['library-call', 'call', 'actor', 'getHTTPStatus'],
  ['library-only', 'call', 'actor', 'missing'],
);
is_deeply(\@library, [
  ['library', 'OK'],
  ['newer-library', 'OK'],
  ['library-call', 'newest library HTTP status'],
  ['library-only', 'library-only method'],
], 'acronym translation also applies to newest-first library fallback');

my $autoload = Test::FitNesse::Slim::ListExecutor->new;
my @dynamic = execute_wire($autoload,
  ['make', 'make', 'dynamic', 'Fitnesse::Slim::Test::MethodNameResolution::Autoload'],
  ['dynamic', 'call', 'dynamic', 'dynamicHTTPCall', '17'],
  ['missing', 'call', 'dynamic', 'unknownMethod'],
);
is_deeply([@dynamic[0,1]], [
  ['make', 'OK'],
  ['dynamic', 'dynamicHTTPCall:17'],
], 'an explicitly declared Perl AUTOLOAD receives otherwise-unresolved calls');
like($dynamic[2][1], qr/^__EXCEPTION__:message:<<.*unknownMethod/s,
  'AUTOLOAD failures use the existing structured SLiM exception path');

my $translator = $names->executor;
for my $pair (
  ['getURL', 'get_url'],
  ['parseXMLDocument', 'parse_xml_document'],
  ['getHTTPResponseCode', 'get_http_response_code'],
  ['isIPv6Enabled', 'is_ipv6_enabled'],
  ['getUserID', 'get_user_id'],
  ['makeATestPage', 'make_a_test_page'],
  ['reset', 'reset'],
  ['already_snake_case', 'already_snake_case'],
) {
  is($translator->slim_to_perl_method($pair->[0]), $pair->[1],
    "$pair->[0] translates to $pair->[1]");
}

done_testing;
