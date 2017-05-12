#!perl -w
use strict;
use Time::HiRes qw/tv_interval gettimeofday/;
use Test::More;

use lib 'lib';
use WWW::Mechanize::Firefox::Extended;

my $o = eval { WWW::Mechanize::Firefox::Extended->new() };

if (! $o) {
    my $err = $@;
    plan skip_all => "Couldn't connect to MozRepl: $@";
    exit;
} else {
    plan tests => 7;
};

isa_ok $o, 'WWW::Mechanize::Firefox::Extended';

my $DEBUG = 0;
my ($got, $exp, $msg, $tmp);
my ($t0, $elapsed, $wait, $found);

#----- Test waitAll()
=head2 waitAll() - No wait test

Return true immediately if all elements exists.
Verify that it did not wait using tv_interval() function.

=cut
$msg = 'waitAll() - No wait test';
$o->get_local('20-waitAll-waitAny.html');
$t0 = [gettimeofday];
$found = $o->waitAll(2, '#form1', '#username');   # Expect: 1
$elapsed = tv_interval($t0);
$got = $found == 1              # All elements were found
        && $elapsed < 1;        # Waited less than 2 seconds
$exp = 1;
is($got, $exp, $msg);


=head2 Test waitAll - positive test

Test this method as follows:
1. Initially element with id '#username' does not have class "ui".
2. Verify that element does not have class "ui"
3. Run Javascript to add class "ui" in 1 second
4. Verify that element still does not have class "ui"
5. run waitAll to wait 2 seconds
6. Verify that element now has class "ui"

=cut
$msg = 'waitAll() - Positive test';
$o->get_local('20-waitAll-waitAny.html');

my $before_eval = $o->hasAll('#form1', '.ui');  # 0
my $JS = <<JS;
window.setTimeout(function () {
    var e = document.getElementById("username");
    e.setAttribute("class", "ui");
}, 1000);
JS
$o->eval_in_page($JS);
my $after_eval = $o->hasAll('#form1', '.ui');   # 0
$found = $o->waitAll(2, '#form1', '.ui');    # Expect: 1
$got = ($before_eval == 0)
       && ($after_eval == 0) 
       && ($found == 1);
$exp = '1';
is($got, $exp, $msg);

=head2 Test waitAll - wait negative test

Test this method as follows:
1. Initially element with id '#username' does not have class "ui".
2. Verify that element does not have class "ui"
3. Run waitAll to wait 1 seconds
4. Verify that element still does not have class "ui"
5. Verify also that time elapsed more than 1 second

=cut
$msg = 'waitAll() - Negative test';
$o->get_local('20-waitAll-waitAny.html');
$t0 = [gettimeofday];
$found = $o->waitAll(2, '#form1', '.ui');
$elapsed = tv_interval($t0);
$got = ($found == 0)
        && ($elapsed > 2);
$exp = '1';
is($got, $exp, $msg);

#----- Test waitAny()
=head2 waitAny() - No wait test

Return true immediately if any elements exists.
Verify that it did not wait using tv_interval() function.

=cut
$msg = 'waitAny() - No wait test';
$o->get_local('20-waitAll-waitAny.html');
$t0 = [gettimeofday];
$found = $o->waitAny(2, '#no-such-id', '#form1', '#username');   # Expect: 1
$elapsed = tv_interval($t0);
$got = $found == 1              # All elements were found
        && $elapsed < 1;        # Waited less than 2 seconds
$exp = 1;
is($got, $exp, $msg);

=head2 Test waitAny() - Wait positive test

Test this method as follows:
1. Initially element with id '#username' does not have class "ui".
2. Verify that element does not have class "ui"
3. Run Javascript to add class "ui" in 1.2 second
4. Verify that element still does not have class "ui"
5. Run waitAll to wait 2 seconds
6. Verify that element now has class "ui"
7. Verify that it waited for at least 1 second

=cut
$msg = 'waitAny() - Wait positive test';
$o->get_local('20-waitAll-waitAny.html');

my $any_before_eval = $o->hasAny('#no-such', '.ui');  # 0
my $any_JS = <<JS;
window.setTimeout(function () {
    var e = document.getElementById("username");
    e.setAttribute("class", "ui");
}, 1500);
JS
$o->eval_in_page($any_JS);
my $any_after_eval = $o->hasAny('#no-such', '.ui');     # 0
$t0 = [gettimeofday];
$found = $o->waitAny(2, '#no-such', '.ui');             # Expect: 1
$elapsed = tv_interval($t0);
$got = ($any_before_eval == 0)
       && ($any_after_eval == 0) 
       && ($found == 1)
       && ($elapsed > 1.0);
$exp = '1';
is($got, $exp, $msg);

=head2 Test waitAny - wait negative test

Test this method as follows:
1. Initially element with id '#username' does not have class "ui".
2. Verify that element does not have class "ui"
3. Run waitAny to wait 1 seconds
4. Verify that element still does not have class "ui"
5. Verify also that time elapsed more than 1 second

=cut
$msg = 'waitAny() - Negative test';
$o->get_local('20-waitAll-waitAny.html');
$t0 = [gettimeofday];
$found = $o->waitAny(2, '#no-such', '.ui');
$elapsed = tv_interval($t0);
print "Found: $found, Elapsed: $elapsed\n" if $DEBUG;
$got = ($found == 0)
        && ($elapsed > 2);
$exp = '1';
is($got, $exp, $msg);


=pod
# Test waitAny()
    1. positive test without timeout works
    2. negative test with timeout works

=cut
