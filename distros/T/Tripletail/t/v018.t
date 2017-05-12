#! /usr/bin/perl -w
use strict;
use warnings FATAL => 'all';
use Test::More tests => 2;
use Test::Exception;
use File::Spec;
use Tripletail File::Spec->devnull;
use lib 't';

my $msg1 = q{[error] message: Can't locate v018.nofile1.pl in @INC};
throws_ok(sub{require "v018.nofile1.pl"}, qr/^\Q$msg1\E/, 'message when require is failed');
my $msg2 = q{[error] message: Can't locate v018.nofile2.pl in @INC};
throws_ok(sub{require "v018.reqnon.pl"}, qr/^\Q$msg2\E/, 'message when nested require is failed');

# -----------------------------------------------------------------------------
# End of File.
# -----------------------------------------------------------------------------
