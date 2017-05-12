use Test::More tests => 30;
BEGIN { use_ok('WWW::Twittervision') };

my $tv = new WWW::Twittervision();
ok(defined($tv) && ref $tv eq 'WWW::Twittervision', 'new()');

SKIP: {
    skip "We do not test against twittervision.com just yet.", 4, if 1;

    $result = $tv->current_status(screen_name =>'perhenrik');
    ok(defined($result)						, 'current status result');
    ok(ref($result) eq "HASH"					, 'result is hash ref');
    ok(exists($result->{screen_name})				, 'screen_name exists in result');
    
    $result = $tv->update_status(screen_name =>'perhenrik', password => 'xxx', location => 'Fredrikstad,Norway');
    ok(!defined($result)					, 'update status not ok :)');
}

my $message = 'just a test l:Fredrikstad, Norway';
my @locations = $tv->parse_location(message => $message);
ok($#locations == 0,                                            , 'found 1 location');
ok($locations[0] eq 'Fredrikstad, Norway',                      , "message '$message' == " . $locations[0]);

$message = $tv->strip_location(message => $message);
ok($message eq 'just a test',                                 , "message is wrong '$message'");

$message = 'L:work';
@locations = $tv->parse_location(message => $message);
ok($#locations == 0,                                            , 'found 1 location');
ok($locations[0] eq 'work',                                     , "message '$message' == " . $locations[0]);

$message = $tv->strip_location(message => $message);
ok($message eq '',                                              , "message is wrong '$message'");

$message = 'foo L:Fredrikstad, Norway : bar';
@locations = $tv->parse_location(message => $message);
ok($#locations == 0,                                            , 'found 1 location');
ok($locations[0] eq 'Fredrikstad, Norway ',                     , "message '$message' == " . $locations[0]);

$message = $tv->strip_location(message => $message);
ok($message eq 'foo bar',                                      , "message is wrong '$message'");

$message = 'foo L:Fredrikstad, \nNorway : bar';
@locations = $tv->parse_location(message => $message);
ok($#locations == 0,                                            , 'found 1 location');
ok($locations[0] eq 'Fredrikstad, \nNorway ',                   , "message '$message' == " . $locations[0]);

$message = $tv->strip_location(message => $message);
ok($message eq 'foo bar',                                      , "message is wrong '$message'");

$message = 'foo L:loc1: L: loc2: bar l:loc3';
@locations = $tv->parse_location(message => $message);
ok($#locations == 2,                                            , 'found 3 locations');
ok($locations[0] eq 'loc1',                                     , "message '$message' == " . $locations[0]);
ok($locations[1] eq 'loc2',                                     , "message '$message' == " . $locations[1]);
ok($locations[2] eq 'loc3',                                     , "message '$message' == " . $locations[2]);

$message = $tv->strip_location(message => $message);
ok($message eq 'foo bar',                                    , "message is wrong '$message'");

$message = 'L:work=Fredrikstad,Norway';
@locations = $tv->parse_location(message => $message);
ok($#locations == 0,                                            , 'found 1 location');
ok($locations[0] eq 'Fredrikstad,Norway',                       , "message '$message' == " . $locations[0]);

$message = $tv->strip_location(message => $message);
ok($message eq '',                                              , "message is wrong '$message'");

$message = 'foo l:work= Fredrikstad,Norway: bar L:Sarpsborg,Norway';
@locations = $tv->parse_location(message => $message);
ok($#locations == 1,                                            , 'found 2 location');
ok($locations[0] eq 'Fredrikstad,Norway',                       , "message '$message' == " . $locations[0]);
ok($locations[1] eq 'Sarpsborg,Norway',                         , "message '$message' == " . $locations[1]);

$message = $tv->strip_location(message => $message);
ok($message eq 'foo bar',                                     , "message is wrong '$message'");
