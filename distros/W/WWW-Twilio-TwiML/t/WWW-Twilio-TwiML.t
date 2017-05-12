#-*- mode: cperl -*-#
use Test::More tests => 13;
BEGIN { use_ok('WWW::Twilio::TwiML') };

#########################

my $tw;

##
## simple response
##
$tw = new WWW::Twilio::TwiML;
$tw->Response({version => '2010-04-01'})->Say('hi');

is( $tw->to_string, q!<?xml version="1.0" encoding="UTF-8" ?>
<Response version="2010-04-01">
  <Say>hi</Say>
</Response>
!, "basic response" );


##
## multiple children
##
$tw = new WWW::Twilio::TwiML;
my $resp = $tw->Response({version => '2010-04-01'});
$resp->Say("Humpty dumpty");
$resp->Play("http://api.twilio.com/Cowbell.mp3");

is( $tw->to_string, q!<?xml version="1.0" encoding="UTF-8" ?>
<Response version="2010-04-01">
  <Say>Humpty dumpty</Say>
  <Play>http://api.twilio.com/Cowbell.mp3</Play>
</Response>
!, "multiple children" );


##
## deeper nesting
##
is( WWW::Twilio::TwiML->new->Response->Dial->Conference('1234')
    ->parent->parent->Say("Thanks for conferencing.")
    ->root->to_string, q!<?xml version="1.0" encoding="UTF-8" ?>
<Response>
  <Dial>
    <Conference>1234</Conference>
  </Dial>
  <Say>Thanks for conferencing.</Say>
</Response>
!, "deeper nesting" );

is( WWW::Twilio::TwiML->new->Response({version => "2010-04-01"})
    ->Gather({method => "POST", finishOnKey => "#", action => "/cgi-bin/test"})
    ->Say("Enter the conference room number.")
    ->parent->parent->Say("Sorry you're having trouble.")
    ->root->to_string,

    q!<?xml version="1.0" encoding="UTF-8" ?>
<Response version="2010-04-01">
  <Gather action="/cgi-bin/test" finishOnKey="#" method="POST">
    <Say>Enter the conference room number.</Say>
  </Gather>
  <Say>Sorry you&apos;re having trouble.</Say>
</Response>
!, "deeper nesting" );


##
## built from nodes
##
$tw = new WWW::Twilio::TwiML;
$resp = new WWW::Twilio::TwiML(name => 'Response');
my $say = new WWW::Twilio::TwiML(name => 'Say');
$say->content("Bag o' doorknobs.");
$resp->add_child($say);
$tw->add_child($resp);

my $comp_tw = new WWW::Twilio::TwiML;
$comp_tw->Response->Say("Bag o' doorknobs.");

is_deeply($comp_tw, $tw, "build via add_child" );


##
## complex constructor
##
$resp = WWW::Twilio::TwiML->new->Response;
$resp->Say("Barbara Ann", {voice => 'woman'});  ## content and attributes
is( $resp->root->to_string, q!<?xml version="1.0" encoding="UTF-8" ?>
<Response>
  <Say voice="woman">Barbara Ann</Say>
</Response>
!, "complex constructor" );


##
## more complex node
##
$tw = new WWW::Twilio::TwiML;
$resp = $tw->Response;
for my $i ( qw(foo bar baz) ) {
    my $s = new WWW::Twilio::TwiML(name => 'Say');
    $s->content("I say $i");
    $s->attributes({voice => "woman"});
    $resp->add_child($s);
}
is( $tw->to_string, q!<?xml version="1.0" encoding="UTF-8" ?>
<Response>
  <Say voice="woman">I say foo</Say>
  <Say voice="woman">I say bar</Say>
  <Say voice="woman">I say baz</Say>
</Response>
!, "build via add_child" );


##
## one-liner
##
is( WWW::Twilio::TwiML->new->Response->Say("Hi mom")->root->to_string,
    q!<?xml version="1.0" encoding="UTF-8" ?>
<Response>
  <Say>Hi mom</Say>
</Response>
!, "one-liner" );


##
## headers
##
is( WWW::Twilio::TwiML->new->Response->Say("Plugh")->root
    ->to_string({"Content-type" => "text/xml", "Bumbly-feely" => "Bessy" }),

    q!Bumbly-feely: Bessy
Content-type: text/xml

<?xml version="1.0" encoding="UTF-8" ?>
<Response>
  <Say>Plugh</Say>
</Response>
!, "content-type header" );


##
## strict
##
{
    my @tags = qw(Response Say Play Dial Conference);

    ok( WWW::Twilio::TwiML->can('Barf'), "can method" );

    local $WWW::Twilio::TwiML::STRICT = 1;
    local %WWW::Twilio::TwiML::TAGS = ();
    @WWW::Twilio::TwiML::TAGS{@tags} = (1) x @tags;

    ok( ! WWW::Twilio::TwiML->can('Barf'), "can method strict" );

    eval { WWW::Twilio::TwiML->new->Response->Barf('chunky') };
    like( $@, qr(^Undefined subroutine Barf), "strict method" );
}
