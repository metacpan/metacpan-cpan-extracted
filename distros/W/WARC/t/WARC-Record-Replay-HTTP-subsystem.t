# Unit tests for WARC::Record::Replay::HTTP::* subsystem	# -*- CPerl -*-

use strict;
use warnings;

use if $ENV{AUTOMATED_TESTING}, Carp => 'verbose';

use FindBin qw($Bin);

use Test::More tests =>
     6	# loading tests
  + 12	# fast slurp
  + 10	# slurp
  + 16	# deferred content loading
  +  4;	# deferred request loading

BEGIN { use_ok('WARC::Record::Replay::HTTP::Message')
	  or BAIL_OUT "WARC::Record::Replay::HTTP::Message failed to load" }
BEGIN { use_ok('WARC::Record::Replay::HTTP::Request')
	  or BAIL_OUT "WARC::Record::Replay::HTTP::Request failed to load" }
BEGIN { use_ok('WARC::Record::Replay::HTTP::Response')
	  or BAIL_OUT "WARC::Record::Replay::HTTP::Response failed to load" }

BEGIN {
  my $fail = 0;
  eval q{use WARC::Record::Replay::HTTP::Message v9999.1.2.3; $fail = 1};
  ok($fail == 0
     && $@ =~ m/ version v9999.*required--this is only version/,
     'WARC::Record::Replay::HTTP::Message version check');

  $fail = 0;
  eval q{use WARC::Record::Replay::HTTP::Request v9999.1.2.3; $fail = 1};
  ok($fail == 0
     && $@ =~ m/ version v9999.*required--this is only version/,
     'WARC::Record::Replay::HTTP::Request version check');

  $fail = 0;
  eval q{use WARC::Record::Replay::HTTP::Response v9999.1.2.3; $fail = 1};
  ok($fail == 0
     && $@ =~ m/ version v9999.*required--this is only version/,
     'WARC::Record::Replay::HTTP::Response version check');
}

use File::Spec;

BAIL_OUT 'sample WARC file not found'
  unless -f File::Spec->catfile($Bin, 'test-file-2.warc');

require WARC::Volume;
require WARC::Index::Volatile;

my $Volume = mount WARC::Volume File::Spec->catfile($Bin, 'test-file-2.warc');

sub run_request_tests {
  my $record = shift;
  my $opt = shift;

  my $id = $opt->{id};
  $id = $record->id unless $id;
  my $request = $opt->{request};
  $request = $record->replay unless $request;

  if ($id eq '<urn:test:file-2:record-1>') {
    plan tests => 7;

    is($request->method,	'GET',		'verify request method');
    is($request->uri,	'http://example.test/',	'verify request URI');
    is($request->protocol,	'HTTP/1.1',	'verify request protocol');

    is($request->header('Accept'), '*/*',	'verify "Accept" header');
    is($request->header('Host'), 'example.test','verify "Host" header');
    if ($opt->{read_ref_first}) {
      is(${$request->content_ref},'',		'verify empty content buffer');
      is($request->content,	'',		'verify no content');
    } else {
      is($request->content,	'',		'verify no content');
      is(${$request->content_ref},'',		'verify empty content buffer');
    }
  } elsif ($id eq '<urn:test:file-2:record-3>') {
    plan tests => 6;

    is($request->method,	'OPTIONS',	'verify request method');
    is($request->uri,		'*',		'verify request URI');
    is($request->protocol,	'HTTP/1.1',	'verify request protocol');

    is($request->headers->as_string, '',	'verify no headers');
    if ($opt->{read_ref_first}) {
      is(${$request->content_ref},'',		'verify empty content buffer');
      is($request->content,	'',		'verify no content');
    } else {
      is($request->content,	'',		'verify no content');
      is(${$request->content_ref},'',		'verify empty content buffer');
    }
  } elsif ($id eq '<urn:test:file-2:record-5>') {
    plan tests => 8;

    is($request->method,	'POST',		'verify request method');
    is($request->uri,	'http://example.test/',	'verify request URI');
    is($request->protocol,	'HTTP/1.1',	'verify request protocol');

    is($request->header('Accept'), '*/*',	'verify "Accept" header');
    is($request->header('Host'), 'example.test','verify "Host" header');
    is($request->header('Content-Length'), 183,
       'verify "Content-Length" header');
    is($request->header('Content-Type'), 'text/plain',
       'verify "Content-Type" header');

    is($request->content, <<'EOT', 'verify request content');
And don't tell me there isn't one bit of difference between null and space,
because that's exactly how much difference there is. :-)
--- Larry Wall in <10209@jpl-devvax.JPL.NASA.GOV>
EOT
  } elsif ($id eq '<urn:test:file-2:record-7>') {
    plan tests => 7;

    is($request->method,	'GET',		'verify request method');
    is($request->uri,	'http://example.test/1','verify request URI');
    is($request->protocol,	'HTTP/1.1',	'verify request protocol');

    is($request->header('Accept'), '*/*',	'verify "Accept" header');
    is($request->header('Host'), 'example.test','verify "Host" header');
    like($request->header('X-Long-Header'),
	 qr/^This is a very long header value.*handling a LWS token\.$/s,
	 'verify special long header');

    is($request->content,	'',		'verify no content');
  } else
    { BAIL_OUT 'unknown record '.$id }
}

sub run_response_tests {
  my $record = shift;
  my $opt = shift;

  my $id = $opt->{id};
  $id = $record->id unless $id;
  my $response = $opt->{response};
  $response = $record->replay unless $response;

  if ($id eq '<urn:test:file-2:record-2>') {
    plan tests => 7;

    is($response->code,		200,		'verify response code');
    is($response->message,	'OK',		'verify response message');
    is($response->protocol,	'HTTP/1.1',	'verify response protocol');

    is($response->header('Content-Length'), 158,
       'verify "Content-Length" header');
    is($response->header('Content-Type'), 'text/plain',
       'verify "Content-Type" header');
my $text = <<EOT;
"What is the sound of Perl? Is it not the sound of a wall that
people have stopped banging their heads against?"
--Larry Wall in <1992Aug26.184221.29627.com>
EOT
    if ($opt->{read_ref_first}) {
      is(${$response->content_ref}, $text, 'verify response content buffer');
      is($response->content, $text,        'verify response content');
    } else {
      is($response->content, $text,        'verify response content');
      is(${$response->content_ref}, $text, 'verify response content buffer');
    }
  } elsif ($id eq '<urn:test:file-2:record-4>') {
    plan tests => 3 + 10 + 2;

    is($response->code,		200,		'verify response code');
    is($response->message,	'OK',		'verify response message');
    is($response->protocol,	'HTTP/1.1',	'verify response protocol');

    foreach ([Connection => 'Keep-Alive'],	['Content-Language' => 'en'],
	     ['Content-Length' => 0],		['Keep-Alive' => 'timeout=10'],
	     ['Date' => 'Mon, 16 Dec 2019 23:22:00 GMT'],
	     ['Accept-Encoding' => 'gzip, deflate, identity'],
	     [Allow => 'GET, HEAD, OPTIONS, POST, PUT'],
	     [Server => 'CUPS/2.2 IPP/2.1'],	['X-Frame-Options' => 'DENY'],
	     ['Content-Security-Policy' => q[frame-ancestors 'none']])
      { is($response->header($_->[0]), $_->[1], 'verify "'.$_->[0].'" header') }

    if ($opt->{read_ref_first}) {
      is(${$response->content_ref},'',		'verify empty content buffer');
      is($response->content,	'',		'verify no content');
    } else {
      is($response->content,	'',		'verify no content');
      is(${$response->content_ref},'',		'verify empty content buffer');
    }
  } elsif ($id eq '<urn:test:file-2:record-6>') {
    plan tests => 5;

    is($response->code,		204,		'verify response code');
    is($response->message,	'No Content',	'verify response message');
    is($response->protocol,	'HTTP/1.1',	'verify response protocol');

    is($response->headers->as_string, '',	'verify no headers');
    is($response->content,	'',		'verify no content');
  } elsif ($id eq '<urn:test:file-2:record-8>') {
    plan tests => 7;

    is($response->code,		200,		'verify response code');
    is($response->message,	'OK',		'verify response message');
    is($response->protocol,	'HTTP/1.1',	'verify response protocol');

    is($response->header('Content-Length'), 100,
       'verify "Content-Length" header');
    is($response->header('Content-Type'), 'text/plain',
       'verify "Content-Type" header');
    like($response->header('X-Long-Header'),
	 qr/^This is a very long header value.*handling a LWS token\.$/s,
	 'verify special long header');

    is($response->content, <<'EOT', 'verify response content');
Let us be charitable, and call it a misleading feature :-)
--Larry Wall in <2609@jato.Jpl.Nasa.Gov>
EOT
  } else
    { BAIL_OUT 'unknown record '.$id }
}

note('*' x 60);

# Fast slurp tests
{
  my $record = $Volume->first_record;

  $record = $record->next until $record->id eq '<urn:test:file-2:record-1>';
  subtest "fast slurp plain request" => \&run_request_tests, $record;

  $record = $record->next until $record->id eq '<urn:test:file-2:record-2>';
  subtest "fast slurp plain response" => \&run_response_tests, $record;

  $record = $record->next until $record->id eq '<urn:test:file-2:record-3>';
  subtest "fast slurp OPTIONS request" => \&run_request_tests, $record;

  $record = $record->next until $record->id eq '<urn:test:file-2:record-4>';
  subtest "fast slurp OPTIONS response" => \&run_response_tests, $record;

  $record = $record->next until $record->id eq '<urn:test:file-2:record-5>';
  subtest "fast slurp POST request" => \&run_request_tests, $record;

  $record = $record->next until $record->id eq '<urn:test:file-2:record-6>';
  subtest "fast slurp POST response" => \&run_response_tests, $record;

  $record = $record->next until $record->id eq '<urn:test:file-2:record-7>';
  subtest "fast slurp request with long header" =>
    \&run_request_tests, $record;

  $record = $record->next until $record->id eq '<urn:test:file-2:record-8>';
  subtest "fast slurp response with long header" =>
    \&run_response_tests, $record;
  is($record->replay->request, undef,
     'no request loadable without collection');
  is($record->replay->previous, undef,
     'no previous response loadable without collection');

  $record = $record->next
    until $record->id eq '<urn:test:file-2:record-9:bogus>';
  is($record->replay, undef, 'fast slurp bogus request');

  $record = $record->next
    until $record->id eq '<urn:test:file-2:record-10:bogus>';
  is($record->replay, undef, 'fast slurp bogus response');
}

# Slurp tests
{
  my $record = $Volume->first_record;

  local $WARC::Record::Replay::HTTP::Content_Deferred_Loading_Threshold = 64;
  $record = $record->next until $record->id eq '<urn:test:file-2:record-1>';
  subtest "slurp plain request" => \&run_request_tests, $record;

  $WARC::Record::Replay::HTTP::Content_Deferred_Loading_Threshold = 200;
  $record = $record->next until $record->id eq '<urn:test:file-2:record-2>';
  subtest "slurp plain response" => \&run_response_tests, $record;

  $WARC::Record::Replay::HTTP::Content_Deferred_Loading_Threshold = 20;
  $record = $record->next until $record->id eq '<urn:test:file-2:record-3>';
  subtest "slurp OPTIONS request" => \&run_request_tests, $record;

  $WARC::Record::Replay::HTTP::Content_Deferred_Loading_Threshold = 200;
  $record = $record->next until $record->id eq '<urn:test:file-2:record-4>';
  subtest "slurp OPTIONS response" => \&run_response_tests, $record;

  $WARC::Record::Replay::HTTP::Content_Deferred_Loading_Threshold = 200;
  $record = $record->next until $record->id eq '<urn:test:file-2:record-5>';
  subtest "slurp POST request" => \&run_request_tests, $record;

  $WARC::Record::Replay::HTTP::Content_Deferred_Loading_Threshold = 20;
  $record = $record->next until $record->id eq '<urn:test:file-2:record-6>';
  subtest "slurp POST response" => \&run_response_tests, $record;

  $WARC::Record::Replay::HTTP::Content_Deferred_Loading_Threshold = 100;
  $record = $record->next until $record->id eq '<urn:test:file-2:record-7>';
  subtest "slurp request with long header" => \&run_request_tests, $record;

  $WARC::Record::Replay::HTTP::Content_Deferred_Loading_Threshold = 200;
  $record = $record->next until $record->id eq '<urn:test:file-2:record-8>';
  subtest "slurp response with long header" => \&run_response_tests, $record;

  $WARC::Record::Replay::HTTP::Content_Deferred_Loading_Threshold = 20;
  $record = $record->next
    until $record->id eq '<urn:test:file-2:record-9:bogus>';
  is($record->replay, undef, 'slurp bogus request');

  $WARC::Record::Replay::HTTP::Content_Deferred_Loading_Threshold = 20;
  $record = $record->next
    until $record->id eq '<urn:test:file-2:record-10:bogus>';
  is($record->replay, undef, 'slurp bogus response');
}

# Deferred content loading tests
{
  my $record = $Volume->first_record;

  local $WARC::Record::Replay::HTTP::Content_Deferred_Loading_Threshold = 0;
  $record = $record->next until $record->id eq '<urn:test:file-2:record-1>';
  subtest "deferred load plain request" => \&run_request_tests, $record;
  subtest "deferred load plain request with buffer" =>
    \&run_request_tests, $record, {read_ref_first => 1};

  $WARC::Record::Replay::HTTP::Content_Deferred_Loading_Threshold = 100;
  $record = $record->next until $record->id eq '<urn:test:file-2:record-2>';
  subtest "deferred load plain response" => \&run_response_tests, $record;
  subtest "deferred load plain response with buffer" =>
    \&run_response_tests, $record, {read_ref_first => 1};

  {
    my $response = $record->replay;

    my $fail = 0;
    my $content = eval {
      local $WARC::Record::Replay::HTTP::Content_Maximum_Length = 10;
      ($response->content, $fail = 1)[0] };
    ok($fail == 0 && $@ =~ m/content.*maximum.*length/,
       'loading content fails if maximum length exceeded');

    $content = $response->content;
    like($content, qr/Larry Wall/,
	 'loading content succeeds with adequate limit');
  }

  $WARC::Record::Replay::HTTP::Content_Deferred_Loading_Threshold = 0;
  $record = $record->next until $record->id eq '<urn:test:file-2:record-3>';
  subtest "deferred load OPTIONS request" => \&run_request_tests, $record;
  subtest "deferred load OPTIONS request with buffer" =>
    \&run_request_tests, $record, {read_ref_first => 1};

  $WARC::Record::Replay::HTTP::Content_Deferred_Loading_Threshold = 0;
  $record = $record->next until $record->id eq '<urn:test:file-2:record-4>';
  subtest "deferred load OPTIONS response" => \&run_response_tests, $record;
  subtest "deferred load OPTIONS response with buffer" =>
    \&run_response_tests, $record, {read_ref_first => 1};

  $WARC::Record::Replay::HTTP::Content_Deferred_Loading_Threshold = 100;
  $record = $record->next until $record->id eq '<urn:test:file-2:record-5>';
  subtest "deferred load POST request" => \&run_request_tests, $record;

  $WARC::Record::Replay::HTTP::Content_Deferred_Loading_Threshold = 0;
  $record = $record->next until $record->id eq '<urn:test:file-2:record-6>';
  subtest "deferred load POST response" => \&run_response_tests, $record;

  $WARC::Record::Replay::HTTP::Content_Deferred_Loading_Threshold = 0;
  $record = $record->next until $record->id eq '<urn:test:file-2:record-7>';
  subtest "deferred load request with long header" =>
    \&run_request_tests, $record;

  $WARC::Record::Replay::HTTP::Content_Deferred_Loading_Threshold = 10;
  $record = $record->next until $record->id eq '<urn:test:file-2:record-8>';
  subtest "deferred load response with long header" =>
    \&run_response_tests, $record;

  $WARC::Record::Replay::HTTP::Content_Deferred_Loading_Threshold = 0;
  $record = $record->next
    until $record->id eq '<urn:test:file-2:record-9:bogus>';
  is($record->replay, undef, 'deferred load bogus request');

  $WARC::Record::Replay::HTTP::Content_Deferred_Loading_Threshold = 0;
  $record = $record->next
    until $record->id eq '<urn:test:file-2:record-10:bogus>';
  is($record->replay, undef, 'deferred load bogus response');
}

note('*' x 60);

# Deferred request loading
{
  my $collection = assemble WARC::Collection
    from => build WARC::Index::Volatile (from => [$Volume],
					 columns => [qw/record_id url/]);

  BAIL_OUT 'collection not searchable by record ID'
    unless $collection->searchable('record_id');

  my $record = $collection->search(record_id => '<urn:test:file-2:record-4>');
  my $response = $record->replay;
  my $request = $response->request;
  subtest "load request from response" => \&run_request_tests, undef,
    {id => '<urn:test:file-2:record-3>', request => $request};
  is($response->request, $request, 'loaded request cached');

  subtest "walk redirect chain" => sub {
    plan tests => 6;

    my $url = 'http://example.test/r5';
    my ($step) =
      grep { $_->type eq 'response' } $collection->search(url => $url);
    my $prev = $step;

    my $response = $step->replay;
    while ($response->code == 302) {
      is($response->request->uri, $url, 'request URI as expected');
      $url = $response->header('Location');
    } continue {
      ($step) = grep { $_->type eq 'response' }
	$collection->search(url => $url, time => $step->date);
      $response = $step->replay;
    }

    is($response->content,<<'EOT', 'final document as expected');
Let's say the docs present a simplified view of reality... :-)
--- Larry Wall in <6940@jpl-devvax.JPL.NASA.GOV>
EOT
  };

  $record = $collection->search(record_id => '<urn:test:file-2:record-23>');
  $response = $record->replay;
  is($response->request, undef,
     'no request for response record lacking a request record');
}
