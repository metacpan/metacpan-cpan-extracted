
# $Id: customer.t,v 1.6 2006-01-08 03:27:27 Daddy Exp $

use ExtUtils::testlib;

use Test::More no_plan;

use IO::Capture::Stderr;
my $oICE =  IO::Capture::Stderr->new;

use vars qw( $sMod );
BEGIN
  {
  $sMod = 'WWW::Ebay::Customer';
  use_ok($sMod);
  } # end of BEGIN block

my $o1 = new $sMod;
isa_ok($o1, $sMod);
$o1->ebayid('my_ebayid');
$o1->email('my_email');
$o1->paypalid('my_paypalid');
$o1->name('my_name');
$o1->address1('my_address1');
$o1->address2('my_address2');
$o1->address3('my_address3');
ok($o1->ebayid eq 'my_ebayid');
ok($o1->email eq 'my_email');
ok($o1->paypalid eq 'my_paypalid');
ok($o1->name eq 'my_name');
ok($o1->address1 eq 'my_address1');
ok($o1->address2 eq 'my_address2');
ok($o1->address3 eq 'my_address3');
$oICE->start;
ok(! eval { $o1->not_a_method(1) });
$oICE->stop;
# Test all the ways of calling new:
$oICE->start;
my $o2 = eval '&'. $sMod .'::new()';
$oICE->stop;
isa_ok($o2, 'FAIL');
$o2 = new $sMod;
isa_ok($o2, $sMod);
my $o3 = $o2->new;
isa_ok($o3, $sMod);
my $o4 = $o1->clone;
ok($o4->ebayid eq 'my_ebayid');
ok($o4->email eq 'my_email');
ok($o4->paypalid eq 'my_paypalid');
ok($o4->name eq 'my_name');
ok($o4->address1 eq 'my_address1');
ok($o4->address2 eq 'my_address2');
ok($o4->address3 eq 'my_address3');
$o1->copy_to($o2);
ok($o2->ebayid eq 'my_ebayid');
ok($o2->email eq 'my_email');
ok($o2->paypalid eq 'my_paypalid');
ok($o2->name eq 'my_name');
ok($o2->address1 eq 'my_address1');
$oICE->start;
ok($o2->address2 eq 'my_address2');
$oICE->stop;
ok($o2->address3 eq 'my_address3');
$oICE->start;
$o1->copy_to(undef);
$oICE->stop;

__END__

