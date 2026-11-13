use 5.016;
use warnings;

use JSON::PP ();
use Test::More;

use Twilio::TwiML::MessagingResponse;
use Twilio::TwiML::VoiceResponse;

subtest 'every element matches twilio-php' => sub {
  my $vectors = read_vectors('t/data/vectors-twiml-elements.json');
  ok(@{$vectors} > 60, 'vectors were read');

  for my $vector (@{$vectors}) {
    my $expected = $vector->{expected};
    utf8::encode($expected);

    my $class = "Twilio::TwiML::$vector->{class}";
    my $file  = ($class =~ s{::}{/}gr) . '.pm';
    require $file;

    is(from_attributes($class, $vector)->as_xml, $expected, "$vector->{class} with attributes");
    is(from_setters($class, $vector)->as_xml,    $expected, "$vector->{class} with setters");
  }
};

subtest 'a typical response' => sub {
  my $response = Twilio::TwiML::VoiceResponse->new;
  $response->say('Hola', { voice => 'alice', language => 'es-MX' });
  my $dial = $response->dial(q{}, { timeout => 20, hangup_on_star => 1 });
  $dial->number('+15551234567', { send_digits => 'ww1' });

  is(
    body($response),
    '<Response><Say language="es-MX" voice="alice">Hola</Say>'
      . '<Dial hangupOnStar="true" timeout="20"><Number sendDigits="ww1">+15551234567</Number></Dial>'
      . '</Response>',
    'the document'
  );
};

subtest 'a child method returns the child' => sub {
  my $response = Twilio::TwiML::VoiceResponse->new;

  my $gather = $response->gather({ input => ['dtmf', 'speech'] });
  isa_ok($gather, 'Twilio::TwiML::Voice::Gather');

  my $say = $gather->say('Press one');
  isa_ok($say, 'Twilio::TwiML::Voice::Say');

  is($say->set_loop(2), $say, 'a setter returns the element');
  like(body($response), qr/<Gather input="dtmf speech"><Say loop="2">/, 'a list of values');
};

subtest 'names' => sub {
  my $response = Twilio::TwiML::VoiceResponse->new;
  my $say      = $response->say('Hi');

  $say->say_as('12', { interpret_as => 'cardinal' });
  $say->lang('Bonjour', { xml_lang => 'fr-FR' });
  $say->break({ strength => 'weak' });
  $response->echo;
  $response->pay->prompt({ for => 'payment-card-number' });

  my $xml = body($response);
  like($xml, qr/<say-as interpret-as="cardinal">12<\/say-as>/, 'a dash');
  like($xml, qr/<lang xml:lang="fr-FR">Bonjour<\/lang>/,       'a colon');
  like($xml, qr/<break strength="weak"\/>/,                    'a name PHP has to change');
  like($xml, qr/<Echo\/>/,                                     'another');
  like($xml, qr/<Prompt for="payment-card-number"\/>/,         'the name Twilio expects');
};

subtest 'the name in the documentation works too' => sub {
  my $number = Twilio::TwiML::VoiceResponse->new->dial(q{}, { hangupOnStar => 1 });
  like(body($number), qr/hangupOnStar="true"/, 'and it is still a boolean');
};

subtest 'booleans' => sub {
  my @cases = (
    ['one',       1,                'true'],
    ['zero',      0,                'false'],
    ['the word',  'true',           'true'],
    ['false',     'false',          'false'],
    ['JSON true', JSON::PP::true(), 'true'],
  );
  for my $case (@cases) {
    my ($name, $value, $expected) = @{$case};
    my $dial = Twilio::TwiML::VoiceResponse->new->dial(q{}, { hangup_on_star => $value });
    like(body($dial), qr/hangupOnStar="$expected"/, $name);
  }

  my $dial = Twilio::TwiML::VoiceResponse->new->dial(q{}, { hangup_on_star => undef });
  unlike(body($dial), qr/hangupOnStar/, 'undefined is left out');
};

subtest 'an attribute this library does not know' => sub {
  my $say = Twilio::TwiML::VoiceResponse->new->say('Hi', { new_thing => 'x' });
  like(body($say), qr/new_thing="x"/, 'written as it is');
};

subtest 'text is escaped in every element' => sub {
  my $message = Twilio::TwiML::MessagingResponse->new->message('a & b');
  is(body($message), '<Message>a &amp; b</Message>', 'escaped');
};

subtest 'generic children still work' => sub {
  my $response = Twilio::TwiML::VoiceResponse->new;
  $response->say('Hi')->add_child('newThing', 'x');
  like(body($response), qr/<Say>Hi<newThing>x<\/newThing><\/Say>/, 'added');
};

done_testing;

sub body {
  my ($element) = @_;
  return $element->as_xml =~ s/\A<[?]xml[^>]*>\n//r =~ s/\n\z//r;
}

sub from_attributes {
  my ($class, $vector) = @_;

  my $has_value  = @{ $vector->{arguments} };
  my @attributes = %{ $vector->{attributes} } ? ($vector->{attributes}) : ();
  my $element    = $class->new(@{ $vector->{arguments} }, @attributes);
  return with_children($element, $vector);
}

sub from_setters {
  my ($class, $vector) = @_;

  my $element = $class->new(@{ $vector->{arguments} });
  for my $setter (sort keys %{ $vector->{setters} }) {
    $element->$setter($vector->{setters}{$setter});
  }
  return with_children($element, $vector);
}

sub with_children {
  my ($element, $vector) = @_;

  for my $child (@{ $vector->{children} }) {
    my $method = $child->{method};
    $element->$method(@{ $child->{arguments} });
  }
  return $element;
}

sub read_vectors {
  my ($file) = @_;

  open my $handle, '<:raw', $file or die "Cannot read $file: $!\n";
  my $content = do { local $/ = undef; <$handle> };
  close $handle or die "Cannot read $file: $!\n";
  return JSON::PP->new->utf8->decode($content);
}
