use 5.016;
use warnings;

use JSON::PP ();
use Test::More;

use Twilio::Http::FakeClient;
use Twilio::Json;
use Twilio::Rest::Client;

# The t/data/contract-*.json files are written from Twilio's specs by tools/generate.pl. They say
# what each operation must send, and this test checks that the real classes send exactly that.
my @FILES = glob 't/data/contract-*.json';

my $operations = [map { @{ read_rules($_) } } @FILES];
ok(@{$operations} > 190, 'the contract covers the API');

for my $entry (@{$operations}) {
  subtest $entry->{id} => sub { check($entry) };
}

done_testing;

# The request is the same for each answer, so it is checked once.
sub check {
  my ($entry) = @_;

  my $checked_request;
  for my $answer (@{ $entry->{answers} }) {
    my ($result, $request) = call($entry, $answer) or return;
    check_request($entry, $request) if !$checked_request++;
    check_answer($entry, $answer, $result);
  }
  return;
}

sub call {
  my ($entry, $answer) = @_;

  my $http = Twilio::Http::FakeClient->new;
  my $client =
    Twilio::Rest::Client->new('ACxx', 'token', { http_client => $http, environment => {} });
  $http->mock($answer->{status}, $answer->{body} // q{});

  my $target = object_for($client, $entry->{chain});
  my $method = $entry->{method};
  ok($target->can($method), "the object has $method") or return;

  my @arguments = map { with_dates($_) } @{ $entry->{required} };
  push @arguments, { map { $_ => with_dates($entry->{body}{$_}) } keys %{ $entry->{body} } }
    if $entry->{body};
  push @arguments, { map { $_ => with_dates($entry->{options}{$_}) } keys %{ $entry->{options} } }
    if %{ $entry->{options} };
  my $result = $target->$method(@arguments);

  my ($request) = $http->requests;
  return ($result, $request);
}

# Each field must come back through its method as the spec says it is read. One comparison for
# the whole record keeps the output short, and shows every field that differs at once.
sub check_answer {
  my ($entry, $answer, $result) = @_;

  my $status = $answer->{status};
  if (!$answer->{body}) {
    is($result, 1, "$status with no body: true");
    return;
  }

  my $records_key = $entry->{records_key};
  my $instance    = $result;
  my $sent        = $answer->{body};
  if (defined $records_key) {
    my @records = $result->records;
    is(scalar @records, 1, "$status: the page has the record") or return;
    ($instance, $sent) = ($records[0], $sent->{$records_key}[0]);
  }
  isa_ok($instance, 'Twilio::InstanceResource', "$status: the answer") or return;

  my (%got, %expected);
  for my $field (@{ $answer->{fields} }) {
    my ($method, $name, $kind, $epoch) = @{$field};
    $expected{$method} =
      $kind eq 'date' ? $epoch : $kind eq 'capabilities' ? $kind : $sent->{$name};
    $got{$method} = read_field($instance, $method, $kind);
  }
  is_deeply(\%got, \%expected, "$status: every field");
  return;
}

sub read_field {
  my ($instance, $method, $kind) = @_;

  return 'no such method' if !$instance->can($method);
  my $value = $instance->$method;
  return eval { $value->epoch } // 'not a date' if $kind eq 'date';
  return ref $value eq 'Twilio::Base::PhoneNumberCapabilities' ? $kind : 'not capabilities'
    if $kind eq 'capabilities';
  return $value;
}

sub check_request {
  my ($entry, $request) = @_;

  is($request->{method}, $entry->{http}, 'HTTP method');

  # Values can arrive in the query string and in a form body at once.
  my ($url, $query) = split /[?]/, $request->{url}, 2;
  is($url, $entry->{url}, 'URL');
  my $form = $entry->{json} ? undef : $request->{content};
  is_deeply(
    sorted([@{ pairs($query) }, @{ pairs($form) }]),
    sorted($entry->{expected}),
    'values on the wire'
  );

  # As text, because 1 and true are equal to is_deeply, and not to Twilio.
  is(
    canonical(Twilio::Json::decode($request->{content})),
    canonical($entry->{json}),
    'the JSON body'
  ) if $entry->{json};
  is($request->{headers}{$_}, $entry->{headers}{$_}, "header $_")
    for sort keys %{ $entry->{headers} // {} };
  return;
}

sub canonical {
  my ($data) = @_;
  return JSON::PP->new->canonical->encode($data);
}

sub with_dates {
  my ($value) = @_;
  return ref $value eq 'HASH' && exists $value->{epoch}
    ? bless { %{$value} }, 'Local::Moment'
    : $value;
}

sub object_for {
  my ($client, $chain) = @_;

  my $object  = $client;
  my $next_id = 0;

  # Each link says how many ids its call takes. Most take none or one, and a few take more, like
  # archived_calls($date, $sid).
  for my $link (@{$chain}) {
    my ($mount, $ids) = @{$link};
    $object = $object->$mount(map { 'id' . ++$next_id } 1 .. $ids);
  }
  return $object;
}

sub pairs {
  my ($encoded) = @_;

  my @pairs = map {
    [map { decoded($_) } split /=/, $_, 2]
  } split /&/, $encoded // q{};
  return sorted(\@pairs);
}

sub decoded {
  my ($text) = @_;
  $text =~ tr/+/ /;
  $text =~ s/%([0-9A-Fa-f]{2})/chr hex $1/ge;
  return $text;
}

sub sorted {
  my ($pairs) = @_;
  return [sort { $a->[0] cmp $b->[0] || $a->[1] cmp $b->[1] } @{$pairs}];
}

sub read_rules {
  my ($file) = @_;

  open my $handle, '<:raw', $file or die "Cannot read $file: $!\n";
  my $content = do { local $/ = undef; <$handle> };
  close $handle or die "Cannot read $file: $!\n";
  return Twilio::Json::decode($content);
}

package Local::Moment;

sub epoch { return $_[0]{epoch} }
