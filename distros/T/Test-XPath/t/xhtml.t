#!/usr/bin/perl -w

use strict;
use Test::Builder::Tester tests => 7;
use Test::More;
use File::Spec::Functions 'catfile';

BEGIN { use_ok 'Test::XPath' or die; }

my $file = catfile qw(t strongrrl.html);

ok my $xp = Test::XPath->new(
    file => $file,
    options => { no_network => 1, recover_silently => 1 },
), 'Create object for HTML file';

test_out 'not ok 1 - oops';
$xp->ok('/html/head/title', 'oops');
test_test  skip_err => 1, title => 'Should fail without a namespace';

# Try it with a namespace.
ok $xp = Test::XPath->new(
    file => $file,
    xmlns => { x => 'http://www.w3.org/1999/xhtml' },
    options => { no_network => 1, recover_silently => 1 },
), 'Create object with a namespace prefix';

test_out 'ok 1 - yay';
$xp->ok('/x:html/x:head/x:title', 'yay');
test_test  title => 'Should succeed with namespace prefix';

# Now use the HTML parser.
ok $xp = Test::XPath->new(
    file => $file,
    is_html => 1,
), 'Create object that uses the HTML parser';

test_out 'ok 1 - yay';
$xp->ok('/html/head/title', 'yay');
test_test  title => 'Should succeed with no namespace prefix';
