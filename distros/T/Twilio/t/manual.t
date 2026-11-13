use 5.016;
use warnings;

use File::Spec;
use File::Temp qw(tempdir);
use Test::More;

# An example that calls exit must not end this test.
our $IN_EXAMPLE;

BEGIN {
  *CORE::GLOBAL::exit = sub {
    die "Local::Exit\n" if $IN_EXAMPLE;    ## no critic (ErrorHandling::RequireCarping)
    CORE::exit(@_ ? $_[0] : 0);
  };
}

use Twilio;
use Twilio::Http::Response;
use Twilio::Http::TinyClient;
use Twilio::Json;
use Twilio::Security::RequestValidator;

# Runs the examples of Twilio::Manual, and the SYNOPSIS of the TwiML responses, so the
# documentation can't drift from what the library does. Requests never leave: HTTP::Tiny's
# client answers from a queue instead.
my (@SENT, @ANSWERS);
{
  no warnings 'redefine';    ## no critic (TestingAndDebugging::ProhibitNoWarnings)
  *Twilio::Http::TinyClient::send_request = sub {
    my ($self, $request) = @_;
    push @SENT, $request;
    my $answer = shift @ANSWERS or die "No answer queued for $request->{method} $request->{url}\n";
    my ($status, $body, $headers) = @{$answer};
    return Twilio::Http::Response->new($status, ref $body ? Twilio::Json::encode($body) : $body,
      $headers);
  };
}

delete @ENV{ grep { /\ATWILIO_|\ADEBUG_HTTP_TRAFFIC\z/ } keys %ENV };

my $API             = 'https://api.twilio.com/2010-04-01/Accounts/ACxx';
my $ROBOTS          = 'The Robots are coming! Head for the hills!';
my $XML_DECLARATION = qr{<[?]xml version="1[.]0" encoding="UTF-8"[?]>};
my %EXAMPLE         = examples('lib/Twilio/Manual.pod');
my %MESSAGE = (sid => 'SM123', account_sid => 'ACxx', from => '+15017122661', to => '+15558675310');
my %CHECK   = checks();
my $has_mojo = eval { require Mojolicious; require Test::Mojo; 1 };

# multi_param, which the manual uses, came in CGI 4.08; Perl 5.16 ships CGI 3.59.
my $has_cgi = eval { require CGI; CGI->VERSION('4.08'); 1 };

subtest 'every example has a check, and every check an example' => sub {
  is_deeply([sort keys %EXAMPLE], [sort keys %CHECK], 'the same names');
};

for my $name (sort keys %EXAMPLE) {
  next if !$CHECK{$name};
  subtest $name => sub {
    @SENT    = ();
    @ANSWERS = ();
    $CHECK{$name}->($EXAMPLE{$name});
  };
}

for my $root (qw(VoiceResponse MessagingResponse FaxResponse)) {
  subtest "the SYNOPSIS of $root" => sub {
    my ($code, $expected) = synopsis("lib/Twilio/TwiML/$root.pm");
    my (undef, $printed)  = run($code);
    like($printed, qr{\AContent-Type: text/xml\n\n$XML_DECLARATION\n<Response>},
      'a TwiML document');
    is($printed, "Content-Type: text/xml\n\n$expected", 'what the comment says')
      if defined $expected;
  };
}

# These only compile: they are short fragments of what the manual runs in full above.
subtest 'the examples in Twilio.pm and the README compile' => sub {
  my ($synopsis) = synopsis('lib/Twilio.pm');
  my @readme     = slurp('README.md') =~ /^```perl\n(.*?)^```/msg;
  my @cases      = (
    ['the SYNOPSIS of Twilio.pm', $synopsis],
    map { ["README example $_", $readme[$_ - 1]] } 1 .. @readme
  );
  for my $case (@cases) {
    my ($name, $code) = @{$case};
    if ($code =~ /^use CGI;/m && !$has_cgi) {
      pass("$name needs CGI 4.08 or later, which is not installed");
      next;
    }
    my $compiled = eval "no strict; no warnings; sub { $code }";    ## no critic (BuiltinFunctions::ProhibitStringyEval, TestingAndDebugging::ProhibitNoStrict, TestingAndDebugging::ProhibitNoWarnings)
    ok($compiled, "$name compiles") or diag($@);
  }
  ok(@readme >= 3, 'the README examples were found');
};

done_testing;

sub checks {
  return (
    'credentials-from-environment' => sub {
      local @ENV{qw(TWILIO_ACCOUNT_SID TWILIO_AUTH_TOKEN)} = qw(ACenv tokenenv);
      my ($got) = run(shift);
      is($got->{client}->get_username, 'ACenv',    'the account from the environment');
      is($got->{client}->get_password, 'tokenenv', 'and the token');
    },
    'credentials-given' => sub {
      my ($got) = run(shift);
      is($got->{client}->get_username,    'ACxx', 'the account');
      is($got->{client}->get_account_sid, 'ACxx', 'acts on it');
    },
    'credentials-api-key' => sub {
      my ($got) = run(shift);
      is($got->{client}->get_username,    'SKxx', 'signs in with the key');
      is($got->{client}->get_account_sid, 'ACxx', 'acts on the account');
    },
    'send-sms' => sub {
      answer(201, {%MESSAGE});
      my (undef, $printed) = run(shift);
      my $sent = only_request();
      is("$sent->{method} $sent->{url}", "POST $API/Messages.json", 'creates a message');
      like($sent->{content}, qr/(?:\A|&)To=%2B15558675310(?:&|\z)/,   'to the recipient');
      like($sent->{content}, qr/(?:\A|&)From=%2B15017122661(?:&|\z)/, 'from the Twilio number');
      like($sent->{content}, qr/(?:\A|&)Body=Join\+Earth%27s/,        'with the text');
      is($printed, "SM123\n", 'prints its sid');
    },
    'message-status' => sub {
      answer(201, {%MESSAGE});
      answer(200, { %MESSAGE, status => 'delivered' });
      my (undef,   $printed) = run(shift);
      my ($create, $fetch)   = @SENT;
      like($create->{content}, qr/StatusCallback=https%3A%2F%2Fexample\.com%2Fstatus/,
        'a callback');
      is("$fetch->{method} $fetch->{url}", "GET $API/Messages/SM123.json", 'fetched again');
      is($printed,                         "delivered\n",                  'the status');
    },
    'send-mms-and-whatsapp' => sub {
      answer(201, {%MESSAGE}) for 1 .. 2;
      run(shift);
      my ($mms, $whatsapp) = @SENT;
      like($mms->{content}, qr/MediaUrl=https%3A%2F%2Fdemo\.twilio\.com%2Fowl\.png/, 'a picture');
      like($whatsapp->{content}, qr/To=whatsapp%3A%2B15558675310/,   'to WhatsApp');
      like($whatsapp->{content}, qr/From=whatsapp%3A%2B14155238886/, 'from WhatsApp');
    },
    'reply-sms-mojolicious' => sub {
      my $t = mojo_app(shift) or return;
      $t->post_ok('/reply_sms', form => { From => '+15558675310', Body => 'Hi' })
        ->status_is(200)
        ->content_type_like(qr{\Atext/xml})
        ->content_like(qr{<Response><Message>\Q$ROBOTS\E</Message>});
    },
    'reply-sms-cgi' => sub {
      plan skip_all => 'CGI 4.08 or later is not installed' if !$has_cgi;
      my $printed = run_cgi(shift, { From => '+15558675310', Body => 'Hi' });
      like($printed, qr{\AContent-Type: text/xml; charset=UTF-8\r?\n}i, 'XML');
      my $reply = 'Thanks for your message, +15558675310. You said: Hi';
      like($printed, qr{<Message>\Q$reply\E</Message>}, 'the reply');
    },
    'make-call-url' => sub {
      answer(201, { sid => 'CA123' });
      my (undef, $printed) = run(shift);
      my $sent = only_request();
      is("$sent->{method} $sent->{url}", "POST $API/Calls.json", 'creates a call');
      like($sent->{content}, qr/Url=http%3A%2F%2Fdemo\.twilio\.com%2Fdocs%2Fvoice\.xml/,
        'with its URL');
      like($sent->{content}, qr/(?:\A|&)From=%2B15017122661(?:&|\z)/, 'from');
      like($sent->{content}, qr/(?:\A|&)To=%2B15558675310(?:&|\z)/,   'to');
      is($printed, "CA123\n", 'prints its sid');
    },
    'make-call-twiml' => sub {
      answer(201, { sid => 'CA123' });
      run(shift);
      my ($twiml) = only_request()->{content} =~ /(?:\A|&)Twiml=([^&]*)/;
      $twiml =~ tr/+/ /;
      $twiml =~ s/%([0-9A-F]{2})/chr hex $1/ge;
      like($twiml, qr{<Response><Say>Ahoy, World!</Say></Response>}, 'the TwiML object, as XML');
    },
    'end-call' => sub {
      answer(200, { sid => 'CAxx', status => 'completed' });
      run(shift);
      my $sent = only_request();
      is("$sent->{method} $sent->{url}", "POST $API/Calls/CAxx.json", 'updates the call');
      is($sent->{content},               'Status=completed',          'to completed');
    },
    'answer-call-mojolicious' => sub {
      my $t = mojo_app(shift) or return;
      $t->post_ok('/voice')
        ->status_is(200)
        ->content_type_like(qr{\Atext/xml})
        ->content_like(qr{<Gather action="/gather" numDigits="1">})
        ->content_like(qr{<Say>For sales, press 1[.]})
        ->content_like(qr{<Redirect>/voice</Redirect>});
      $t->post_ok('/gather', form => { Digits => 1 })
        ->content_like(qr{<Say>You chose sales\. Goodbye\.</Say>});
      $t->post_ok('/gather', form => { Digits => 9 })
        ->content_like(qr{<Redirect>/voice</Redirect>});
    },
    'validate-mojolicious' => sub {
      local $ENV{TWILIO_AUTH_TOKEN} = 'token';
      my $t    = mojo_app(shift) or return;
      my %form = (From => '+15558675310', Body => 'Hi');
      my $url  = $t->ua->server->url->path('/reply_sms')->to_string;
      my $signature =
        Twilio::Security::RequestValidator->new('token')->compute_signature($url, \%form);

      $t->post_ok('/reply_sms', { 'X-Twilio-Signature' => $signature }, form => \%form)
        ->status_is(200)
        ->content_like(qr{Checked, and from Twilio});
      $t->post_ok('/reply_sms', { 'X-Twilio-Signature' => 'forged' }, form => \%form)
        ->status_is(403);
      $t->post_ok('/reply_sms', form => \%form)->status_is(403);
    },
    'validate-cgi' => sub {
      plan skip_all => 'CGI 4.08 or later is not installed' if !$has_cgi;
      local $ENV{TWILIO_AUTH_TOKEN}         = 'token';
      local @ENV{qw(HTTP_HOST REQUEST_URI)} = ('example.com', '/sms');
      my %form      = (From => '+15558675310', Body => 'Hi');
      my $signature = Twilio::Security::RequestValidator->new('token')
        ->compute_signature('https://example.com/sms', \%form);

      local $ENV{HTTP_X_TWILIO_SIGNATURE} = $signature;
      my ($printed, $exited) = run_cgi(shift, \%form);
      ok(!$exited, 'a signed request goes on');
      is($printed, q{}, 'with nothing printed yet');

      local $ENV{HTTP_X_TWILIO_SIGNATURE} = 'forged';
      ($printed, $exited) = run_cgi($EXAMPLE{'validate-cgi'}, \%form);
      ok($exited, 'a forged one stops');
      like($printed, qr/\AStatus: 403 Forbidden/, 'with 403');
    },
    'read-list' => sub {
      answer(200,
        message_page({ %MESSAGE, date_sent => 'Thu, 01 Jan 2026 10:00:00 +0000', body => 'Hello' })
      );
      my (undef, $printed) = run(shift);
      like(only_request()->{url}, qr/[?]PageSize=20&To=%2B15558675310\z/, 'filtered, 20 at most');
      like($printed, qr/\AThu Jan +1 10:00:00 2026 \+15017122661 Hello\n\z/, 'each message');
    },
    'stream-list' => sub {
      answer(200, message_page({ %MESSAGE, sid => 'SM1' }, { %MESSAGE, sid => 'SM2' }));
      my (undef, $printed) = run(shift);
      like(only_request()->{url}, qr/[?]PageSize=500\z/, 'a page of 500');
      is($printed, "SM1\nSM2\n", 'each message');
    },
    'errors' => sub {
      answer(
        400,
        {
          code      => 21211,
          message   => q{Invalid 'To' Phone Number},
          more_info => 'https://www.twilio.com/docs/errors/21211',
          status    => 400,
        }
      );
      my @warnings;
      local $SIG{__WARN__} = sub { push @warnings, @_ };
      run(shift);
      is(scalar @warnings, 1, 'one warning');
      like(
        $warnings[0] // q{},
        qr/\ATwilio error 21211 [(]HTTP 400[)]: \[HTTP 400\] /,
        'with the code, the status and the message'
      );
      like($warnings[0] // q{}, qr{See https://www\.twilio\.com/docs/errors/21211}, 'and the link');
    },
    'verify' => sub {
      answer(201, { sid => 'VE123', status => 'pending' });
      answer(200, { sid => 'VE123', status => 'approved' });
      my (undef,  $printed) = run(shift);
      my ($start, $check)   = @SENT;
      is(
        $start->{url},
        'https://verify.twilio.com/v2/Services/VAxx/Verifications',
        'a verification'
      );
      like($start->{content}, qr/Channel=sms/, 'by SMS');
      is($check->{url}, 'https://verify.twilio.com/v2/Services/VAxx/VerificationCheck',
        'its check');
      like($check->{content}, qr/Code=123456/, 'with the code');
      is($printed, "approved\n", 'approved');
    },
    'translate-php' => sub {
      answer(201, { sid => 'CA123' });
      my (undef, $printed) = run(shift);
      like(only_request()->{content}, qr/Url=http%3A%2F%2Fdemo\.twilio\.com/, 'the call');
      is($printed, "CA123\n", 'prints its sid');
    },
    'translate-python' => sub {
      answer(201, { %MESSAGE, body => q{Join Earth's mightiest heroes. Like Kevin Bacon.} });
      my (undef, $printed) = run(shift);
      like(only_request()->{content}, qr/(?:\A|&)To=%2B15558675310(?:&|\z)/, 'to first');
      is($printed, "Join Earth's mightiest heroes. Like Kevin Bacon.\n", 'prints the body');
    },
    'metadata' => sub {
      answer(201, {%MESSAGE}, { 'twilio-request-id' => 'RQ123' });
      my ($got, $printed) = run(shift);
      is($printed,             "201\nRQ123\n", 'the status and the request id');
      is($got->{message}->sid, 'SM123',        'and the message');
    },
    'region-edge' => sub {
      my ($got) = run(shift);
      answer(200, message_page());
      $got->{client}->messages->read({}, 1);
      like(only_request()->{url}, qr{\Ahttps://api\.sydney\.au1\.twilio\.com/}, 'routed there');
    },
  );
}

# The verbatim block after each "=for test NAME" line, by name.
sub examples {
  my ($file) = @_;
  my @lines  = split /\n/, slurp($file);
  my %found;
  while (defined(my $line = shift @lines)) {
    my ($name) = $line =~ /\A=for test (\S+)\s*\z/ or next;
    die "Two examples named $name\n" if exists $found{$name};
    shift @lines while @lines && $lines[0] !~ /\S/;
    my @code;
    push @code, shift @lines while @lines && ($lines[0] !~ /\S/ || $lines[0] =~ /\A /);
    pop @code while @code && $code[-1] !~ /\S/;
    $found{$name} = join "\n", map { s/\A  //r } @code;
  }
  return %found;
}

# The code of a SYNOPSIS, and the TwiML its trailing comment shows, if it has one.
sub synopsis {
  my ($file)    = @_;
  my ($section) = slurp($file) =~ /^=head1 SYNOPSIS\n\n(.*?)^=head1/ms;
  my @lines     = map { s/\A  //r } split /\n/, $section;
  my @comment;
  unshift @comment, pop @lines while @lines && ($lines[-1] =~ /\A# / || $lines[-1] !~ /\S/);
  @comment = grep { /\S/ } map { s/\A# //r } @comment;
  my $expected = @comment ? shift(@comment) . "\n" . join(q{ }, @comment) . "\n" : undef;
  return (join("\n", @lines), $expected);
}

# Runs an example with the variables it uses but doesn't declare, and returns the values of
# the ones it declares, and what it printed.
sub run {
  my ($code) = @_;
  my %given = (
    account_sid        => 'ACxx',
    auth_token         => 'token',
    api_key_sid        => 'SKxx',
    api_key_secret     => 'secret',
    from               => '+15017122661',
    call_sid           => 'CAxx',
    verify_service_sid => 'VAxx',
    code               => '123456',
  );
  my $declared = sub { $code =~ /\bmy\s+\$$_[0]\b/ };
  my $needed   = sub { $code =~ /\$$_[0]\b/ && !$declared->($_[0]) };
  my @lines    = map { "my \$$_ = \$given->{$_};" } grep { $needed->($_) } sort keys %given;
  push @lines, 'my $client = Twilio->new("ACxx", "token");' if $needed->('client');
  push @lines, 'my $twilio = Twilio->new("ACxx", "token");' if $needed->('twilio');
  my @kept = grep { $code =~ /^my\s+\$$_\s*=/m }
    qw(client message call answer latest check verification twiml);
  my $keep = join q{, }, map { "$_ => \$$_" } @kept;

  my $source = join "\n", 'sub {', 'my ($given) = @_;', @lines, '#line 1 "example"', $code,
    ";\nreturn { $keep };", '}';
  my $example = eval $source or die "The example does not compile: $@\n$code\n";    ## no critic (BuiltinFunctions::ProhibitStringyEval)

  my $printed = q{};
  open my $out, '>', \$printed or die "Cannot capture output: $!\n";
  my $previous = select $out;                                                       ## no critic (InputOutput::ProhibitOneArgSelect)
  my $got      = eval { local $IN_EXAMPLE = 1; $example->(\%given) };
  my $error    = $@;
  select $previous;                                                                 ## no critic (InputOutput::ProhibitOneArgSelect)
  close $out or die "Cannot capture output: $!\n";
  die $error if $error && $error ne "Local::Exit\n";                                ## no critic (ErrorHandling::RequireCarping)
  return ($got, $printed, $error eq "Local::Exit\n");
}

sub run_cgi {
  my ($code, $form) = @_;
  my $body = join q{&},
    map { "$_=" . ($form->{$_} =~ s/([^A-Za-z0-9])/sprintf '%%%02X', ord $1/ger) }
    sort keys %{$form};
  local @ENV{qw(REQUEST_METHOD CONTENT_TYPE CONTENT_LENGTH QUERY_STRING)} =
    ('POST', 'application/x-www-form-urlencoded', length $body, q{});

  # CGI reads the real STDIN, so the global handle itself is replaced.
  open local *STDIN, '<', \$body or die "Cannot fake STDIN: $!\n";    ## no critic (InputOutput::ProhibitBarewordFileHandles)
  CGI::initialize_globals();
  my (undef, $printed, $exited) = run($code);
  return wantarray ? ($printed, $exited) : $printed;
}

sub mojo_app {
  my ($code) = @_;
  if (!$has_mojo) {
    plan skip_all => 'Mojolicious is not installed';
    return;
  }
  my $file = File::Spec->catfile(tempdir(CLEANUP => 1), 'app.pl');
  open my $handle, '>:raw', $file or die "$file: $!\n";
  print {$handle} $code, "\n";
  close $handle or die "$file: $!\n";
  require Mojo::File;
  return Test::Mojo->new(Mojo::File->new($file));
}

sub answer {
  my ($status, $body, $headers) = @_;
  push @ANSWERS, [$status, $body, $headers];
  return;
}

sub only_request {
  is(scalar @SENT, 1, 'one request');
  return $SENT[0];
}

sub message_page {
  my (@messages) = @_;
  return { messages => \@messages, next_page_uri => undef };
}

sub slurp {
  my ($file) = @_;
  open my $handle, '<:raw', $file or die "$file: $!\n";
  my $content = do { local $/ = undef; <$handle> };
  close $handle or die "$file: $!\n";
  return $content;
}
