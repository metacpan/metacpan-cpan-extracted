#-*- mode: cperl -*-#
use Test::More tests => 17;
BEGIN { use_ok('WWW::Twilio::TwiML') };

#########################

##
## new()
##
my $ex_1 = q!<?xml version="1.0" encoding="UTF-8" ?>
<Response>
  <Say voice="man">Kilroy was here</Say>
</Response>
!;

{
  my $say = new WWW::Twilio::TwiML;
  $say->name('Say');
  $say->content("Kilroy was here");
  $say->attributes({voice => "man"});

  my $resp = new WWW::Twilio::TwiML;
  $resp->name('Response');
  $resp->content($say);  ## see also add_child()

  my $tw = new WWW::Twilio::TwiML;
  $tw->content($resp);

  is( $tw->to_string, $ex_1, "new example 1" );
}

{
    my $say = new WWW::Twilio::TwiML(name => 'Say',
                                     content => "Kilroy was here",
                                     attributes => {voice => "man"});

    my $tw = new WWW::Twilio::TwiML;
    $tw->Response->add_child($say);

    is( $tw->to_string, $ex_1, "new example 2" );
}

{
    my $tw = new WWW::Twilio::TwiML;
    $tw->Response->Say({voice => "man"}, "Kilroy was here");

    is( $tw->to_string, $ex_1, "new example 3" );
}

{
    is( WWW::Twilio::TwiML->new
        ->Response
        ->Say({voice => "man"}, "Kilroy was here")
        ->root->to_string, $ex_1, "new example 4" );
}

##
## any twiml verb
##
{
    my $tw = new WWW::Twilio::TwiML;
    $tw->Response
      ->Say("I'm calling you.")
        ->parent
      ->Dial("+17175558309");
    is( $tw->to_string, q!<?xml version="1.0" encoding="UTF-8" ?>
<Response>
  <Say>I&apos;m calling you.</Say>
  <Dial>+17175558309</Dial>
</Response>
!, "any twiml verb example" );
}


##
## name
##
{
    my $elem = new WWW::Twilio::TwiML;
    $elem->name('Dial');
    $elem->content("+1234567890");

    is( $elem->to_string, '<Dial>+1234567890</Dial>', "name example" );
}

##
## content
##
{
    my $elem = new WWW::Twilio::TwiML(name => 'Say');
    $elem->content("Eat at Joe's!");

    is( $elem->to_string, '<Say>Eat at Joe&apos;s!</Say>', "content example 1" );
}


{
    my $elem = new WWW::Twilio::TwiML(name => 'Say');
    $elem->content("Eat at Joe's!");

    my $parent = new WWW::Twilio::TwiML(name => 'Response');
    $parent->content($elem);

    is( $parent->to_string, q{<Response>
  <Say>Eat at Joe&apos;s!</Say>
</Response>}, "content example 2" );
}

##
## add_child, content-type header
##
{
    my $tw = new WWW::Twilio::TwiML;
    my $resp = $tw->Response;
    $resp->add_child(new WWW::Twilio::TwiML(name => 'Say',
                                            content => 'Soooey!'));

    my $email = uri_escape('biff@example.com');
    my $msg = uri_escape("Heeer piiiig!");
    my $url = "http://twimlets.com/voicemail?Email=$email&Message=$msg";
    $resp->add_child(new WWW::Twilio::TwiML(name => 'Redirect',
                                            content => $url));

    is( $tw->to_string({'Content-type' => 'text/xml'}),
        q{Content-type: text/xml

<?xml version="1.0" encoding="UTF-8" ?>
<Response>
  <Say>Soooey!</Say>
  <Redirect>http://twimlets.com/voicemail?Email=biff%40example.com&amp;Message=Heeer%20piiiig!</Redirect>
</Response>
}, "add_child example" );
}

##
## attributes
##
{
    my $elem = new WWW::Twilio::TwiML(name => 'Say');
    $elem->attributes({voice => 'woman'});
    $elem->content("gimme another donut");

    is( $elem->to_string, q!<Say voice="woman">gimme another donut</Say>!, "attributes example" );
}

##
## root
##
{
    is( WWW::Twilio::TwiML->new
        ->Response
        ->Say("All men are brothers,")
        ->parent
        ->Say("Like Jacob and Esau.")
        ->root->to_string, q!<?xml version="1.0" encoding="UTF-8" ?>
<Response>
  <Say>All men are brothers,</Say>
  <Say>Like Jacob and Esau.</Say>
</Response>
!, "root example" );
}

##
## to_string
##
{
    is( WWW::Twilio::TwiML->new->to_string, q!<?xml version="1.0" encoding="UTF-8" ?>
!, "to_string example 1" );
}

{
    my $tw = new WWW::Twilio::TwiML;
    $tw->Response->Say('Arf!');
    is( $tw->to_string({'Content-type' => 'text/xml'}),
        q{Content-type: text/xml

<?xml version="1.0" encoding="UTF-8" ?>
<Response>
  <Say>Arf!</Say>
</Response>
}, "to_string example 2" );
}

{
    is( WWW::Twilio::TwiML->new->Response->Say("plugh")->root->to_string,
        q!<?xml version="1.0" encoding="UTF-8" ?>
<Response>
  <Say>plugh</Say>
</Response>
!, "to_string example 3" );
}

{
    is( WWW::Twilio::TwiML->new->Response->Say("plugh")->to_string,
        q!<Say>plugh</Say>!, "to_string example 4" );
}

##
## parent
##
{
    is( WWW::Twilio::TwiML->new
        ->Response
        ->Gather({action => "/process_gather.php", method => "GET"})
        ->Say("Please enter your account number.")
        ->parent  ## Say's parent, Gather
        ->parent  ## Gather's parent, Response
        ->Say("We didn't receive any input. Goodbye!")
        ->root->to_string,
        q{<?xml version="1.0" encoding="UTF-8" ?>
<Response>
  <Gather action="/process_gather.php" method="GET">
    <Say>Please enter your account number.</Say>
  </Gather>
  <Say>We didn&apos;t receive any input. Goodbye!</Say>
</Response>
}, "parent example" );

}

exit;

sub uri_escape {
    my $str = shift;
    $str =~ s{ }{%20}g;
    $str =~ s{\@}{%40}g;
    return $str;
}
