#!/usr/bin/perl -Tw

use strict;
use Config;
use Test::More $Config{ccflags} =~ /-DSILENT_NO_TAINT_SUPPORT/
    ? ( skip_all => 'No taint support' ) : ( tests => 2 );

use UNIVERSAL::require;

my $tainted = $0;
$tainted =~ s/\A.*\z/bananas/;

ok !eval { $tainted->require or die $@ };
like $@, '/^Insecure dependency in require /';
