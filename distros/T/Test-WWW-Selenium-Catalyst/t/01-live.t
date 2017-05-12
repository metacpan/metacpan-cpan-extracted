#!/usr/bin/perl
# 01-live.t 
# Copyright (c) 2006 Jonathan Rockway <jrockway@cpan.org>

use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";

use IPC::Cmd qw/can_run/;

my $have_apps = 
  can_run('java') &&
  ( can_run('firefox') || can_run('firefox-bin') ) ||
  $ENV{WE_HAVE_SELENIUM};
                
SKIP: {
  unless ($have_apps) {
    # Missing Java or firefox, just do a use_ok test
    use_ok('Test::WWW::Selenium::Catalyst', 'TestApp',
      -no_selenium_server => 1);
    skip "java and firefox requires for further testing", 79;
  } else {
    diag("You need to have firefox(-bin) in your path for this to work!");

    my $port = int(20000+rand()*20000);
    # Try to cope with case when selenium is already running or something is on port 4444
    my $sel = eval { 

      use_ok('Test::WWW::Selenium::Catalyst', 'TestApp',
        -selenium_args => "-singleWindow -port $port");

      Test::WWW::Selenium::Catalyst->start( {
        browser => '*firefox', 
        selenium_port => $port 
      } ); 
    };

    skip $@, 79 if $@;

    $sel->open_ok('/');
    $sel->text_is("link=Click here", "Click here");
    $sel->click_ok("link=Click here");
    $sel->wait_for_page_to_load_ok("30000", 'wait');
    for my $i (1..10){
        $sel->open_ok("/words/$i");
        $sel->is_text_present_ok(
      qq{Here you'll find all things "words" printed $i time(s)!});
        
        for my $j (1..$i){
      $sel->is_text_present_ok("$j: foo bar baz bat qux quux");
        }
    }
  }
}

done_testing;
