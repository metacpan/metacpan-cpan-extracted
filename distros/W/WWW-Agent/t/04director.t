package main;

use Log::Log4perl;
Log::Log4perl->init("t/log.conf");
our $log = Log::Log4perl->get_logger("Agent");

1;

package TestUA;

sub new {
    return bless {}, 'TestUA';
}

sub request {
    my $self = shift;
    my $req  = shift;

    use HTTP::Response;
    my $resp = HTTP::Response->new( 200, 'OK', [ Rumsti => 'Ramsti' ], "Rumstis will rule" );
    $resp->request ($req);

    return $resp;
}

1;

use strict;
use warnings;
use Test::More qw(no_plan);
use Data::Dumper;

#== TESTS =====================================================================

#sub POE::Kernel::TRACE_DEFAULT  () { 1 }

# hide some comments
close STDERR;
open (STDERR, '/dev/null');

use constant { W => 1,
	       T => 1,
	       F => 0 };

require_ok ('WWW::Agent::Zombie');

use WWW::Agent::Zombie;

if (W) {
    my $z = WWW::Agent::Zombie->new (ua => new TestUA);
    is (ref ($z), 'WWW::Agent::Zombie', 'class');
    eval {
	$z->run;
    }; like ($@, qr/no plan/, 'empty plan');
}

if (W) { # not really a test
    my $z = new WWW::Agent::Zombie ();
    $z->run (q{
warn "do not want to work"
});
    ok (1, 'warn by itself');
}

if (W) { # die with text
    my $z = new WWW::Agent::Zombie ();
    eval {
	$z->run (q{
die "do not want to work"
});
    }; like ($@, qr/not want to work/, 'died texted');
}

if (W) { # dying
    my $z = new WWW::Agent::Zombie ();
    eval {
	$z->run (q{
die
});
    }; like ($@, qr/no particular reason/, 'died untexted');
}

if (W) { # die and then not
    my $z = new WWW::Agent::Zombie ();
    $z->run (q{
die "something" or warn "else"
});
    ok (1, 'die masked by warn');
}

if (W) { # die and then not
    my $z = new WWW::Agent::Zombie ();
    eval {
	$z->run (q{
warn "something" and die "else"
});
    }; like ($@, qr/else/, 'die not masked by warn');
}

if (W) {
    for (1..5) { 
	my $z = new WWW::Agent::Zombie ();
	eval {
	$z->run (q{
warn "something" xor die "else"
});
	ok (1, 'xor: warn is chosen');
    }; like ($@, qr/else/, 'xor: die is chosen') if $@;
    }
}

#-- string termination

if (W) { # strings
    my $z = new WWW::Agent::Zombie ();
    eval {
	$z->run (q{
die "doublequote"
});
    }; like ($@, qr/doublequote/, 'doublequote');
}

if (W) { # strings
    my $z = new WWW::Agent::Zombie ();
    eval {
	$z->run (q{
die 'singlequote'
});
    }; like ($@, qr/singlequote/, 'singlequote');
}

if (W) { # registered functions
    my $mark;
    my $z = new WWW::Agent::Zombie (functions => { 'test' => sub { $mark++; } });
    $z->run (q{
      test
      warn "blabla" and test
});
    is ($mark, 2, 'called function a number of times');
}

if (W) { # comments
    my $mark;
    my $z = new WWW::Agent::Zombie (functions => { 'test' => sub { $mark++; } });
    $z->run (q{
      test
      # test
      test # and test
      
});
    is ($mark, 2, 'called function (commented and uncommented)');
}

#-- subplans

if (W) { # 
    my $mark;
    my $z = new WWW::Agent::Zombie (functions => { test => sub { $mark++; } });
    $z->run (q{
assessment: {
  test
}

test
});
    is ($mark, 1, 'labelled plan not executed');
}

if (W) { # 
    my $mark;
    my $z = new WWW::Agent::Zombie (functions => { test => sub { $mark++; } });
    $z->run (q{
assessment: {
  test
}

test
assessment ()
});
    is ($mark, 2, 'labelled plan executed');
}

#-- labelled block + variable passing

if (W) {
    my $z = new WWW::Agent::Zombie;
    eval {
	$z->run (q{
assessment: {
    die $aaa
}

assessment (aaa => "rumsti", bbb => "ramsti")
});
    }; like ($@, qr/rumsti/, 'variable passing');
}

if (W) {
    my $z = new WWW::Agent::Zombie;
    eval {
	$z->run (q{
block2: {
    die $aaa
}
block1: {
    warn $aaa
    block2 (aaa => $bbb)
}

block1 (aaa => "rumsti", bbb => "ramsti")
});
    }; like ($@, qr/ramsti/, 'variable passing II');
}

if (W) {
    my $mark;
    my $z = new WWW::Agent::Zombie (functions => { test => sub { $mark++; } });
    $z->run (q{
block2: {
    test
    warn "rumsti"
}
block1: {
    warn "ramsti"
    block2 ()
    warn "remsti"
}

warn "romsti"
block1 ()
block2 ()
warn "rimsti"
});
    is ($mark, 2, 'multiple labelled plan executed');
}

#-- time dithering

if (W) {
    eval {
	my $z = new WWW::Agent::Zombie (time_dither => 'rumsti');
    }; like ($@, qr/unsupported/, 'wrong dither format');
}

#-- dithered waiting

if (W) { # wait
    warn "# testing of timing: this takes a while, sorry";
    for (0..4) {
	my @marks;
	my $z = new WWW::Agent::Zombie (time_dither => "100%",
					functions => { 'test' => sub { push @marks, time } });
	$z->run (q{
    test
    wait ~4 sec
    test
});
	my $dither = abs ($marks[1] - $marks[0]);
	ok (0 <= $dither && $dither <= 8, "wait [0,8] secs: $dither");
    }
}

if (W) { # wait
    my @marks;
    my $z = new WWW::Agent::Zombie (functions => { 'test' => sub { push @marks, time } });
    $z->run (
					q{
    test
    wait 2 sec
    test
    wait 3 sec
    test
});

    ok (abs ($marks[1] - $marks[0]) < 2.4, 'wait roughly 2 secs'); # allow %20 error
    ok (abs ($marks[2] - $marks[1]) < 3.6, 'wait roughly 3 secs');
}

#-- goto websites

if (W) { # 
    my $z = new WWW::Agent::Zombie ();
    $z->run (q{
url http://james.bond.edu.au/
});
    ok (1, 'goto, no fail');
}

if (W) { # 
    my $z = new WWW::Agent::Zombie ();
    eval {
	$z->run (q{
url http://james.bond.edu.auxx/
});
    }; like ($@, qr/Can\'t connect/, "goto, fail ($@)");
}

if (W) { # 
    my $z = new WWW::Agent::Zombie ();
    eval {
	$z->run (q{
url http://james.bond.edu.auxx/ or die "wrong website"
});
    }; like ($@, qr/wrong website/, 'url dead and user defined exception');
}

#-- url matching

if (W) { # 
    my $z = new WWW::Agent::Zombie ();
    eval {
	$z->run (q{
url m|^http://james|
});
    }; like ($@, qr/does not match/, 'url match must fail');
}

if (W) { # 
    my $z = new WWW::Agent::Zombie ();
    $z->run (q{
url http://james.bond.edu.au/
url m|^http://james|
});
    ok (1, 'url match with working site');
}

if (W) { # 
    my $z = new WWW::Agent::Zombie ();
    eval {
	$z->run (q{
url http://james.bond.edu.au/
url m|^http://xjames|  or die "wrong website"
});
    }; like ($@, qr/wrong website/, 'url match with broken pattern');
}

#-- random walk

if (W) {
    my $z = new WWW::Agent::Zombie ();
    $z->run (q{

url http://james.bond.edu.au/courses/ xor url http://james.bond.edu.au/faq.mc
url m|courses|                         or url m|faq|
});
    ok (1, 'random walk');
}

if (W) {
    my $z = new WWW::Agent::Zombie ();
    eval {
	$z->run (q{

url http://james.bond.edu.au/courses/ xor url http://james.bond.edu.au/faq.mc
url m|xxx|
});
    }; like ($@, qr/does not match/, 'random walk 2');
}

#-- url catchers

if (W) {
    my $z = new WWW::Agent::Zombie ();
    eval {
	$z->run (q{
m|courses| : {
  die "good boy A"
}

m|faq| : {
  die "good boy B"
}

url http://james.bond.edu.au/courses/ xor url http://james.bond.edu.au/faq.mc
die "you should not be here"
});
    }; like ($@, qr/good boy/, 'random walk & catch');
}

#-- content matching

#-- element matching

if (W) {
    my $z = new WWW::Agent::Zombie;
    $z->run (q{
url http://james.bond.edu.au/
<form> or die "notfound"

});
    ok (1, 'element matching 1');
}

if (W) {
    my $z = new WWW::Agent::Zombie;
    $z->run (q{
url http://james.bond.edu.au/
<form> m|uid| or die "notfound"

});
    ok (1, 'element matching 1');
}

if (W) {
    my $z = new WWW::Agent::Zombie;
    $z->run (q{
url http://james.bond.edu.au/

<table> [1] and
    <tr> and 
        html m|CONTENTS|
});
    ok (1, 'element matching 5');
}

if (W) {
    my $z = new WWW::Agent::Zombie;
    $z->run (q{
url http://james.bond.edu.au/
<table> [30]                  or
<body>  and  html m|CONTENTS|
});
    ok (1, 'element matching 8');
}

if (W) {
    my $z = new WWW::Agent::Zombie;
    $z->run (q{
url http://james.bond.edu.au/

<table> [1] and html m|CONTENTS|
});
    ok (1, 'element matching 9');
}

if (W) {
    my $z = new WWW::Agent::Zombie;
    eval {
        $z->run (q{
url http://james.bond.edu.au/
html m|Welcome| or die "not welcomed"
die "am welcomed"
});
    }; like ($@, qr/am welcomed/, 'content matching');
}

if (W) {
    my $z = new WWW::Agent::Zombie ();
    eval {
        $z->run (q{
url http://james.bond.edu.au/
text m|portal.+IT school| or die "not found"
die "did find it"
});
    }; like ($@, qr/find/, 'content matching');
}

if (W) {
    my $z = new WWW::Agent::Zombie;
    eval {
	$z->run (q{
url http://james.bond.edu.au/
<form> [2] or die "notfound"

});
    }; like ($@, qr/notfound/, 'element matching 3');
}

if (W) {
    my $z = new WWW::Agent::Zombie;
    $z->run (q{
url http://james.bond.edu.au/
<form> [0] or die "notfound"

});
    ok (1, 'element matching 31');
}

if (W) {
    my $z = new WWW::Agent::Zombie;
    eval {
	$z->run (q{
url http://james.bond.edu.au/ and
   <table> [1] and
       <tr> [3] and 
           html m|CONTENTS| or die "notfound"
});
    }; like ($@, qr/notfound/, 'element matching 7');
}

if (W) {
    my $z = new WWW::Agent::Zombie;
    eval {
	$z->run (q{
url http://james.bond.edu.au/

<table> [1] and
    <tr> [3] and 
        html m|CONTENTS| or die "notfound"
});
    }; like ($@, qr/notfound/, 'element matching 6');
}

if (W) {
    my $z = new WWW::Agent::Zombie;
    eval {
	$z->run (q{
url http://james.bond.edu.au/
<form> m|xuid| or die "notfound"

});
    }; like ($@, qr/notfound/, 'element matching 2');
}

if (W) {
    my $z = new WWW::Agent::Zombie;
    $z->run (q{
url http://james.bond.edu.au/

<form> m|uid|
    and fill uid 'rumsti'
    and fill pwd 'remsti'
    and  click login
html m|Invalid user|
});
    ok (1, 'form fill & submit 1');
}

if (W) {
    my $z = new WWW::Agent::Zombie ();
    $z->run (q{
url http://james.bond.edu.au/

<form> m|uid| and
    fill uid 'rumsti' and
    fill pwd 'ramsti' and
    click login
html m|\(rumsti\)|
});
    ok (1, 'form fill & submit 2');
}

#-- reuses

if (W) { # reuse: two ok
    my $z = new WWW::Agent::Zombie;
    $z->run (q{
url http://james.bond.edu.au/
});
    $z->run (q{
url http://james.bond.edu.au/
});
    ok (1, 'reuse: ok and ok');
}

if (F) { # reuse: ok and die
    my $z = new WWW::Agent::Zombie;
    $z->run (q{
url http://james.bond.edu.au/
});
    ok (1, 'reuse: ok and die (I)');
    eval {
	$z->run (q{
url http://james.bond.edu.au/ and die "whatever"
}); 
    }; like ($@, qr/whatever/, 'reuse: ok and die (II)');
}

if (F) { # reuse: die and ok
    my $z = new WWW::Agent::Zombie;
    eval {
	$z->run (q{
url http://james.bond.edu.au/ and die "whatever"
}); 
    }; like ($@, qr/whatever/, 'reuse: die and ok (I)');
    $z->run (q{
url http://james.bond.edu.au/
});
    ok (1, 'reuse: die and ok (II)');
}

if (W) { # reuse: die and die
    my $z = new WWW::Agent::Zombie;
    eval {
	$z->run (q{
url http://james.bond.edu.au/ and die "whatever"
}); 
    }; like ($@, qr/whatever/, 'reuse: die and die (I)');
    eval {
	$z->run (q{
url http://james.bond.edu.au/ and die "whatever"
});
    }; like ($@, qr/whatever/, 'reuse: die and die (II)');
}


__END__

if (2) {
    my $z = new WWW::Agent::Zombie ();
    $z->run (q{
url http://james.bond.edu.au/

<form> m|uid| and
    fill uid 'rumsti' and
    fill pwd 'ramsti' and
    click login
html m|\(rumsti\)|

<a> m|my Bond| and click whatever ????c

html m|My News|

});
    ok (1, 'form fill & submit 2');
}


