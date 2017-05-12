
# $Id: status.t,v 1.7 2008-04-05 17:54:53 Martin Exp $

use ExtUtils::testlib;

use Test::More no_plan;

use IO::Capture::Stderr;
my $oICE =  IO::Capture::Stderr->new;

use vars qw( $sMod );
BEGIN
  {
  $sMod = 'WWW::Ebay::Status';
  use_ok($sMod);
  } # end of BEGIN block

my $o1 = new WWW::Ebay::Status;
isa_ok($o1, $sMod);
# Test the various ways to call new_from_integer:
my $o2 = new_from_integer WWW::Ebay::Status(9);
isa_ok($o2, $sMod);
ok($o2->listed);
ok(! $o2->ended);
ok(! $o2->congratulated);
ok($o2->paid);
ok(! $o2->payment_cleared);
ok(! $o2->shipped);
ok(! $o2->received);
ok(! $o2->left_feedback);
ok(! $o2->got_feedback);
my $o3 = WWW::Ebay::Status::new_from_integer(46);
isa_ok($o3, $sMod);
ok(! $o3->listed);
ok($o3->ended);
ok($o3->congratulated);
ok($o3->paid);
ok(! $o3->payment_cleared);
ok($o3->shipped);
ok(! $o3->received);
ok(! $o3->left_feedback);
ok(! $o3->got_feedback);
my $o4 = $o2->new_from_integer(255);
isa_ok($o4, $sMod);
ok($o4->listed);
ok($o4->ended);
ok($o4->congratulated);
ok($o4->paid);
ok($o4->payment_cleared);
ok($o4->shipped);
ok($o4->received);
ok($o4->left_feedback);
ok(! $o4->got_feedback);
# Test the reset method:
$o4->reset;
ok(! $o4->listed);
ok(! $o4->ended);
ok(! $o4->congratulated);
ok(! $o4->paid);
ok(! $o4->payment_cleared);
ok(! $o4->shipped);
ok(! $o4->received);
ok(! $o4->left_feedback);
ok(! $o4->got_feedback);
# Test any_local_actions (with full coverage):
$o4->reset;
ok(! $o4->any_local_actions);
$o4->reset;
$o4->archived(1);
ok($o4->any_local_actions);
$o4->reset;
$o4->got_feedback(1);
ok($o4->any_local_actions);
$o4->reset;
$o4->left_feedback(1);
ok($o4->any_local_actions);
$o4->reset;
$o4->received(1);
ok($o4->any_local_actions);
$o4->reset;
$o4->shipped(1);
ok($o4->any_local_actions);
$o4->reset;
$o4->paid(1);
ok($o4->any_local_actions);
$o4->reset;
$o4->congratulated(1);
ok($o4->any_local_actions);
# Test the other way(s) to call new:
my $o5 = $o1->new;
isa_ok($o5, $sMod);
$oICE->start;
my $o6 = WWW::Ebay::Status::new;
$oICE->stop;
isa_ok($o6, 'FAIL');
# Test as_integer:
$o5->reset;
$o5->listed(1);
$o5->paid(1);
is($o5->as_integer, 9);
$o5->reset;
$o5->ended(1);
$o5->congratulated(1);
$o5->paid(1);
$o5->shipped(1);
is($o5->as_integer, 46);
my $s = $o5->as_text;
# diag($s);
like($s, qr/ended/);
like($s, qr/congratulated/);
like($s, qr/paid/);
like($s, qr/shipped/);
unlike($s, qr/feedback/);

# The rest of this file used to be in the module itself (and tested via Test::Inline):

my $oStatus = new WWW::Ebay::Status;
ok(ref $oStatus);
# Get ready to test all the fields:
my @asField = qw( listed ended congratulated paid payment_cleared shipped received left_feedback got_feedback archived );
my @asOn = qw( on -1 1 99 yes ok positive ON YES );
# Make sure all fields are zero to start with:
foreach my $s (@asField)
  {
  is($oStatus->$s, 0);
  } # foreach
# Now turn them all on...
foreach my $s (@asField)
  {
  $oStatus->$s($asOn[int(rand(scalar(@asOn)))]);
  } # foreach
# ...And make sure they stayed on:
foreach my $s (@asField)
  {
  ok($oStatus->$s);
  } # foreach
# Set a few bits:
my @asTestOff = qw( listed congratulated payment_cleared received left_feedback got_feedback archived );
my @asTestOn = qw( ended paid shipped );
foreach my $s (@asTestOn)
  {
  $oStatus->$s(1);
  is($oStatus->$s, 1);
  } # foreach
foreach my $s (@asTestOff)
  {
  $oStatus->$s(0);
  is($oStatus->$s, 0);
  } # foreach
# Freeze it..
my $i = $oStatus->as_integer;
# ...And thaw it again:
my $oNew = $oStatus->new_from_integer($i);
# Make sure exactly the same fields are set:
foreach my $s (@asTestOn)
  {
  is($oNew->$s, 1);
  } # foreach
foreach my $s (@asTestOff)
  {
  is($oNew->$s, 0);
  } # foreach


__END__

