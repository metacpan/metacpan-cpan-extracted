use 5.016;
use warnings;

use lib 't/lib';

use Test::More;

use Local::Resources;

my $NEXT = '/2010-04-01/Accounts/ACxx/Items.json?Page=';

sub page_body {
  my ($next, @sids) = @_;
  return {
    items         => [map { { sid => $_ } } @sids],
    next_page_uri => defined $next ? "$NEXT$next" : undef,
  };
}

sub meta_body {
  my ($next, @sids) = @_;
  return {
    items => [map { { sid => $_ } } @sids],
    meta  => { key => 'items', next_page_url => $next },
  };
}

sub drain {
  my ($stream) = @_;
  my @sids;
  while (my $item = $stream->next) {
    push @sids, $item->sid;
  }
  return \@sids;
}

sub stream_over {
  my ($stream_arguments, @bodies) = @_;
  my ($http, undef, $list) = Local::Resources::build();
  $http->mock(200, $_) for @bodies;

  my $first  = $list->page;
  my $stream = $first->get_version->stream($first, @{$stream_arguments});
  return ($http, $stream);
}

subtest 'records come from every page' => sub {
  my ($http, $stream) =
    stream_over([], page_body(1, 'A', 'B'), page_body(2, 'C'), page_body(undef, 'D'));

  is_deeply(drain($stream), [qw(A B C D)], 'all records in order');
  is(scalar($http->requests), 3,     'one request per page');
  is($stream->next,           undef, 'stays finished');
  is(scalar($http->requests), 3,     'and does not fetch again');
};

subtest 'product format pages' => sub {
  my $next = 'https://verify.twilio.com/v2/Items?Page=1';
  my ($http, $stream) = stream_over([], meta_body($next, 'A'), meta_body(undef, 'B'));

  is_deeply(drain($stream), [qw(A B)], 'all records');
  is(($http->requests)[1]{url}, $next, 'meta url followed');
};

subtest 'a limit stops at the exact record' => sub {
  my ($http, $stream) = stream_over([3], page_body(1, 'A', 'B'), page_body(2, 'C', 'D'));
  is_deeply(drain($stream), [qw(A B C)], 'three records');
  is(scalar($http->requests), 2, 'no page fetched after the limit');
};

subtest 'a limit on a page boundary fetches nothing more' => sub {
  my ($http, $stream) = stream_over([2], page_body(1, 'A', 'B'));
  is_deeply(drain($stream), [qw(A B)], 'two records');
  is(scalar($http->requests), 1, 'next page not fetched');
};

subtest 'a page limit stops after that page' => sub {
  my ($http, $stream) = stream_over([undef, 2], page_body(1, 'A'), page_body(2, 'B'));
  is_deeply(drain($stream), [qw(A B)], 'two pages of records');
  is(scalar($http->requests), 2, 'third page not fetched');
};

subtest 'zero limits mean no limit' => sub {
  my (undef, $stream) = stream_over([0, 0], page_body(1, 'A'), page_body(undef, 'B'));
  is_deeply(drain($stream), [qw(A B)], 'all records');
};

subtest 'an empty first page ends the stream' => sub {
  my ($http, $stream) = stream_over([], page_body(undef));
  is_deeply(drain($stream), [], 'no records');
  is(scalar($http->requests), 1, 'one request');
};

subtest 'an empty page with a next page does not end the stream' => sub {
  my (undef, $stream) = stream_over([], page_body(1, 'A'), page_body(2), page_body(undef, 'B'));
  is_deeply(drain($stream), [qw(A B)], 'records after the gap');
};

subtest 'running out of range mid stream ends it cleanly' => sub {
  my ($http, $stream) = stream_over([], page_body(1, 'A'));
  $http->mock(400, { code => 20006, message => 'Page out of range' });
  is_deeply(drain($stream), ['A'], 'stopped without an error');
};

subtest 'a real error mid stream reaches the caller' => sub {
  my ($http, $stream) = stream_over([], page_body(1, 'A'));
  $http->mock(500, { message => 'Broken' });

  is($stream->next->sid, 'A', 'first page read');

  my $ok    = eval { $stream->next; 1 };
  my $error = $@;
  ok(!$ok, 'died');
  isa_ok($error, 'Twilio::Exceptions::RestException');
  is($error->get_status_code, 500, 'status');
};

subtest 'rewind starts again' => sub {
  my ($http, $stream) = stream_over([3], page_body(1, 'A', 'B'), page_body(undef, 'C', 'D'));
  is_deeply(drain($stream), [qw(A B C)], 'first pass');

  $http->mock(200, page_body(undef, 'C', 'D'));
  $stream->rewind;

  is_deeply(drain($stream), [qw(A B C)], 'second pass, with the limit counted again');
  is(scalar($http->requests), 3, 'first page reused and second fetched again');
};

subtest 'rewind counts the pages again' => sub {
  my ($http, $stream) = stream_over([undef, 2], page_body(1, 'A'), page_body(2, 'B'));
  is_deeply(drain($stream), [qw(A B)], 'first pass');

  $http->mock(200, page_body(2, 'B'));
  $stream->rewind;

  is_deeply(drain($stream), [qw(A B)], 'second pass reaches the page limit again');
};

subtest 'read_records collects the whole list' => sub {
  my ($http, undef, $list) = Local::Resources::build();
  $http->mock(200, page_body(1, 'A'))->mock(200, page_body(undef, 'B'));

  my @records = $list->read_records;

  is_deeply([map { $_->sid } @records], [qw(A B)], 'all records');
  isa_ok($records[0], 'Local::Instance');
  my ($request) = $http->requests;
  unlike($request->{url}, qr/PageSize/, 'no page size is sent without a limit');
};

subtest 'read_records honours the limit and sends it as the page size' => sub {
  my ($http, undef, $list) = Local::Resources::build();
  $http->mock(200, page_body(1, 'A', 'B', 'C'));

  my @records = $list->read_records({ Status => 'sent' }, 2);

  is(scalar @records, 2, 'two records');
  my ($request) = $http->requests;
  like($request->{url}, qr/PageSize=2\b/,  'page size');
  like($request->{url}, qr/Status=sent\b/, 'filters sent');
  is(scalar($http->requests), 1, 'one request');
};

subtest 'an explicit page size is separate from the limit' => sub {
  my ($http, undef, $list) = Local::Resources::build();
  $http->mock(200, page_body(1, 'A'))->mock(200, page_body(undef, 'B'));

  my $stream = $list->stream_records({}, 2, 1);

  isa_ok($stream, 'Twilio::Stream');
  is(scalar($http->requests), 1, 'only the first page is fetched before reading');
  is_deeply(drain($stream), [qw(A B)], 'read through the limit');
  like(($http->requests)[0]{url}, qr/PageSize=1\b/, 'page size');
};

subtest 'page sizes are capped' => sub {
  my ($http, undef, $list) = Local::Resources::build();
  $http->mock(200, page_body(undef, 'A'));

  $list->stream_records({}, 5000);
  like(($http->requests)[0]{url}, qr/PageSize=1000\b/, 'capped at 1000');
};

done_testing;
