#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
use open qw/:std :locale/;
use FindBin; BEGIN {
  local @_ = "$FindBin::Bin/.."; do "$FindBin::Bin/../t_lib.pl";
}

use File::Spec;

(my $psgi = untaint_any(File::Spec->rel2abs(__FILE__))) =~ s/\.t/\.psgi/;

use Test::More;
use Test::WWW::Mechanize::PSGI;
use Time::Piece;

use YATT::Lite::Factory;
use YATT::Lite::Util::File qw/wait_if_near_deadline/;

ok(my $SITE = YATT::Lite::Factory->load_factory_script($psgi));

{
  my $mech = Test::WWW::Mechanize::PSGI->new(app => $SITE->to_app);

  subtest "No cookie, no state", sub {
    unless ($mech->get_ok("/")) {
      diag "DIAG: ".($mech->content // '');
    }

    $mech->content_contains("No session state");
    $mech->content_contains("No sid cookie");
    $mech->content_lacks("Logged in at");
  };

  my $sample_text = "good enough sample value";
  my $logged_in_at;
  subtest "Start session with other_value", sub {
    my $next = "~start";

    if (my $slept = wait_if_near_deadline(my $goal = time+1)) {
      diag "slept: $slept, goal was: $goal, now: ". Time::HiRes::time;
    }

    $mech->submit_form_ok(
      {button => $next, fields => {$next => 1, other_value => $sample_text}},
      "-> $next",
    );

    $logged_in_at = localtime->strftime('%Y-%m-%d %H:%M:');

    $mech->content_contains("Has session state");
    $mech->content_contains("No sid cookie"); # because it is just assigned.
  };

  my $cur_sid;
  subtest "Top page now contains login info", sub {
    unless ($mech->follow_link_ok({id => "go_top"})) {
      diag "DIAG: ".($mech->content // '');
    }

    $mech->content_contains("Has session state");

    ok((($cur_sid) = $mech->content =~ /Has sid cookie: ([0-9a-f]+)/)
       , "Has sid cookie");

    $mech->content_contains("Logged in at $logged_in_at");
    $mech->content_contains("other_value = $sample_text");
  };

  subtest "Reloading the top page shows same info", sub {
    unless ($mech->get_ok("/")) {
      diag "DIAG: ".($mech->content // '');
    }

    $mech->content_contains("Has session state");

    ok((my ($sid) = $mech->content =~ /Has sid cookie: ([0-9a-f]+)/)
       , "Has sid cookie");

    is($cur_sid, $sid, "Same sid");

    $mech->content_contains("Logged in at $logged_in_at");
    $mech->content_contains("other_value = $sample_text");
  };

  subtest "change_id (without loosing the state)", sub {

    unless ($mech->follow_link_ok({id => "change_id"})) {
      diag "DIAG: ".($mech->content // '');
    }

    ok((my ($new_sid) = $mech->content =~ /New sid: ([0-9a-f]+)/)
       , "New sid");

    isnt($cur_sid, $new_sid, "sid is changed");
    $cur_sid = $new_sid;

    #----------------------------------------
    unless ($mech->follow_link_ok({id => "go_top"})) {
      diag "DIAG: ".($mech->content // '');
    }

    ok((my ($sid) = $mech->content =~ /Has sid cookie: ([0-9a-f]+)/)
       , "Has sid cookie");

    is($cur_sid, $sid, "Same sid");

    $mech->content_contains("Logged in at $logged_in_at");
    $mech->content_contains("other_value = $sample_text");
  };

  subtest "change_id (clearing the state)", sub {

    if (my $slept = wait_if_near_deadline(my $goal = time+1)) {
      diag "slept: $slept, goal was: $goal, now: ". Time::HiRes::time;
    }

    unless ($mech->follow_link_ok({id => "fresh_session"})) {
      diag "DIAG: ".($mech->content // '');
    }

    ok((my ($new_sid) = $mech->content =~ /New sid: ([0-9a-f]+)/)
       , "New sid");

    isnt($cur_sid, $new_sid, "sid is changed");
    $cur_sid = $new_sid;

    #----------------------------------------

    unless ($mech->follow_link_ok({id => "go_top"})) {
      diag "DIAG: ".($mech->content // '');
    }

    $logged_in_at = localtime->strftime('%Y-%m-%d %H:%M:');

    ok((my ($sid) = $mech->content =~ /Has sid cookie: ([0-9a-f]+)/)
       , "Has sid cookie");

    is($cur_sid, $sid, "Same sid");

    $mech->content_contains("Logged in at $logged_in_at");
    $mech->content_contains("other_value =");
    $mech->content_lacks("other_value = $sample_text");
  };

  subtest "logout", sub {
    $mech->follow_link_ok({id => "logout"});
    #----------------------------------------

    $mech->follow_link_ok({id => "go_top"});

    $mech->content_contains("No session state");
    $mech->content_contains("No sid cookie");
    $mech->content_lacks("Logged in at");
  };

  my $localhost = 'localhost.local';
  subtest "residual cookie sid", sub {

    is_deeply($mech->cookie_jar->get_cookies($localhost), +{}, "cookie_jar is empty");

    $mech->cookie_jar->set_cookie(
      0, sid => $cur_sid, '/', $localhost
    );

    is_deeply($mech->cookie_jar->get_cookies($localhost), +{
      sid => $cur_sid
    }, "cookie is successfully injected to cookie_jar");

    $mech->get_ok("/?dont_start=1");

    $mech->content_contains("No session state");
    $mech->content_contains("Has sid cookie: $cur_sid");
    $mech->content_lacks("Logged in at");

  };

}

done_testing;
