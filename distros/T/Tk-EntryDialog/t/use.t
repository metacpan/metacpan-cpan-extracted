#!/usr/bin/env perl -w
use strict;
use Test;
BEGIN { plan tests => 1 }

use Tk::EntryDialog; ok(1);
exit;
__END__

use Test;
BEGIN { plan tests => 1 }

use Your::Module::Here; ok(1);
exit;
__END__

