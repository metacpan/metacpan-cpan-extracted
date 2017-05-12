#-*- mode: cperl -*-#
use Test::More tests => 12;
use WWW::Twilio::TwiML;

#########################

{
    my $tw = new WWW::Twilio::TwiML;
    $tw->Response
      ->Say({voice => "woman", loop => "2"}, "Hello");

    is( $tw->to_string, q!<?xml version="1.0" encoding="UTF-8" ?>
<Response>
  <Say loop="2" voice="woman">Hello</Say>
</Response>
!, "Say example" );
}

{
    my $tw = new WWW::Twilio::TwiML;
    $tw->Response
      ->Play("http://foo.com/cowbell.mp3");

    is( $tw->to_string, q!<?xml version="1.0" encoding="UTF-8" ?>
<Response>
  <Play>http://foo.com/cowbell.mp3</Play>
</Response>
!, "Play example" );
}

{
    my $tw = new WWW::Twilio::TwiML;
    $tw->Response
      ->Gather({action => "/process_gather.cgi", method => "GET"})
        ->Say("Enter something, or not")
          ->parent
        ->parent
      ->Redirect({method => "GET"}, "/process_gather.cgi?Digits=TIMEOUT");

    is( $tw->to_string, q!<?xml version="1.0" encoding="UTF-8" ?>
<Response>
  <Gather action="/process_gather.cgi" method="GET">
    <Say>Enter something, or not</Say>
  </Gather>
  <Redirect method="GET">/process_gather.cgi?Digits=TIMEOUT</Redirect>
</Response>
!, "Gather example" );
}


{
    my $tw = new WWW::Twilio::TwiML;
    $tw->Response
      ->Say("Please leave a message at the beep. Press the star key when finished.")
        ->parent
      ->Record({action => "http://foo.edu/handleRecording.cgi",
                method => "GET",
                maxLength => "20",
                finishOnKey => "*"})
        ->parent
      ->Say("I did not receive a recording");

    is( $tw->to_string, q!<?xml version="1.0" encoding="UTF-8" ?>
<Response>
  <Say>Please leave a message at the beep. Press the star key when finished.</Say>
  <Record action="http://foo.edu/handleRecording.cgi" finishOnKey="*" maxLength="20" method="GET" />
  <Say>I did not receive a recording</Say>
</Response>
!, "Record example" );
}


{
    my $tw = new WWW::Twilio::TwiML;
    $tw->Response
      ->Say("Our store is located at 123 Easy St.")->parent
      ->Sms({action => "/smsHandler.cgi", method => "POST"},
            "Store Location: 123 Easy St.");

    is( $tw->to_string, q!<?xml version="1.0" encoding="UTF-8" ?>
<Response>
  <Say>Our store is located at 123 Easy St.</Say>
  <Sms action="/smsHandler.cgi" method="POST">Store Location: 123 Easy St.</Sms>
</Response>
!, "Sms example" );
}


{
    my $tw = new WWW::Twilio::TwiML;
    $tw->Response
      ->Dial
        ->Number("858-987-6543")->parent
        ->Number("415-123-4567")->parent
        ->Number("619-765-4321");

    is( $tw->to_string, q!<?xml version="1.0" encoding="UTF-8" ?>
<Response>
  <Dial>
    <Number>858-987-6543</Number>
    <Number>415-123-4567</Number>
    <Number>619-765-4321</Number>
  </Dial>
</Response>
!, "Dial example" );
}

{
    my $tw = new WWW::Twilio::TwiML;
    $tw->Response
      ->Dial
        ->Client("jenny");

    is( $tw->to_string, q!<?xml version="1.0" encoding="UTF-8" ?>
<Response>
  <Dial>
    <Client>jenny</Client>
  </Dial>
</Response>
!, "Client example" );
}


{
    my $tw = new WWW::Twilio::TwiML;
    $tw->Response
      ->Dial
        ->Conference({startConferenceOnEnter => "true",
                      endConferenceOnExit => "true"},
                     "1234");

    is( $tw->to_string, q!<?xml version="1.0" encoding="UTF-8" ?>
<Response>
  <Dial>
    <Conference endConferenceOnExit="true" startConferenceOnEnter="true">1234</Conference>
  </Dial>
</Response>
!, "Conference example" );
}


{
    my $tw = new WWW::Twilio::TwiML;
    $tw->Response->Hangup;

    is( $tw->to_string, q!<?xml version="1.0" encoding="UTF-8" ?>
<Response>
  <Hangup />
</Response>
!, "Hangup example" );
}


{

    my $tw = new WWW::Twilio::TwiML;
    $tw->Response
      ->Dial("415-123-4567")->parent
      ->Redirect("http://www.foo.com/nextInstructions");

    is( $tw->to_string, q!<?xml version="1.0" encoding="UTF-8" ?>
<Response>
  <Dial>415-123-4567</Dial>
  <Redirect>http://www.foo.com/nextInstructions</Redirect>
</Response>
!, "Redirect example" );
}


{
    my $tw = new WWW::Twilio::TwiML;
    $tw->Response
      ->Reject({reason => "busy"});

    is( $tw->to_string, q!<?xml version="1.0" encoding="UTF-8" ?>
<Response>
  <Reject reason="busy" />
</Response>
!, "Reject example" );
}


{
    my $tw = new WWW::Twilio::TwiML;
    $tw->Response
      ->Pause({length => 5})->parent
      ->Say("Hi there.");

    is( $tw->to_string, q!<?xml version="1.0" encoding="UTF-8" ?>
<Response>
  <Pause length="5" />
  <Say>Hi there.</Say>
</Response>
!, "Pause example" );
}
