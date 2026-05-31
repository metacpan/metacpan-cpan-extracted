use strict;
use warnings;
use Test::More;
use WWW::Crawl4AI::Result ();

# -- from_attempt with response_headers

my %page = (
  url         => 'https://example.com',
  final_url   => 'https://example.com',
  status_code => 200,
  markdown    => 'the content',
  html        => '<p>the content</p>',
  title       => 'Example',
  links       => { internal => [], external => [] },
  response_headers => {
    'Link'           => '</.well-known/api-catalog>; rel="api-catalog"',
    'X-Robots-Tag'   => 'noindex',
    'Content-Type'   => 'text/html; charset=utf-8',
  },
);

my $attempt = TestAttempt->new( page => \%page, ok => 1 );
my $result  = WWW::Crawl4AI::Result->from_attempt($attempt);

ok( exists $result->response_headers->{link},
  'link header lowercased to link key' );
ok( exists $result->response_headers->{'x-robots-tag'},
  'x-robots-tag header lowercased' );
is( $result->response_headers->{link},
  '</.well-known/api-catalog>; rel="api-catalog"',
  'link header value preserved' );
is( $result->response_headers->{'content-type'},
  'text/html; charset=utf-8',
  'content-type header value preserved' );

# -- missing response_headers yields empty hash default

my %page_no_headers = (
  url         => 'https://example.com',
  final_url   => 'https://example.com',
  status_code => 200,
  markdown    => 'content',
  links       => { internal => [], external => [] },
);

my $result2 = WWW::Crawl4AI::Result->from_attempt(
  TestAttempt->new( page => \%page_no_headers, ok => 1 )
);

is( ref $result2->response_headers, 'HASH',
  'response_headers is a hashref when absent' );
is( scalar keys %{ $result2->response_headers }, 0,
  'response_headers empty when no headers in page' );

# -- to_hash round-trip

my $hash = $result->to_hash;
ok( exists $hash->{response_headers}, 'to_hash includes response_headers' );
is( $hash->{response_headers}{link}, $result->response_headers->{link},
  'to_hash response_headers value matches' );

done_testing();

# -- TestAttempt helper (minimal stub)

package TestAttempt;
sub new { my ( $class, %p ) = @_; bless \%p, $class }
sub ok         { $_[0]->{ok} }
sub page       { $_[0]->{page} }
sub backend    { 'crawl4ai_plain' }
sub cost_class { 'cheap' }
sub signals    { {} }
sub why_failed { undef }
sub to_hash    { $_[0]->{page} }

1;
