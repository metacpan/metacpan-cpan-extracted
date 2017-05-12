#!/usr/local/bin/perl -w
BEGIN {
    if ($ENV{PERL_CORE}) {
        chdir 't' if -d 't';
        @INC = '../lib';
    } elsif (!grep /blib/, @INC) {
        chdir 't' if -d 't';
        unshift @INC, ('../blib/lib', '../blib/arch');
    }
}

BEGIN {delete $ENV{THREADS_DEBUG}} # no debugging during testing!

use Test::More tests => 7;

use Scalar::Util;
use File::Spec;
use Acme::Damn ();
use Storable ();
use List::MoreUtils;
use Sys::SigAction;

ok(!(grep { /set_prototype/ } @Scalar::Util::EXPORT_FAIL), "Scalar::Util appears to have been compiled without XS features: set_prototype.  Try rebuilding Scalar::Util package with `perl Makefile.PL -xs`");
can_ok( 'Scalar::Util',qw(set_prototype reftype blessed refaddr weaken) );
can_ok( 'File::Spec',qw(tmpdir) );
can_ok( 'Acme::Damn',qw(damn) );
can_ok( 'Storable',qw(freeze thaw) );
can_ok( 'List::MoreUtils',qw(firstidx minmax uniq) );
can_ok( 'Sys::SigAction', qw(set_sig_handler) );
