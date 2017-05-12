#!/usr/bin/perl

# Compile testing for Test::Inline

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 12;
use Test::Script;
use File::Spec::Functions ':ALL';

# Check their perl version
ok( $] >= 5.006, "Your perl is new enough" );

# Does the module load
use_ok('Test::Inline::Content'          );
use_ok('Test::Inline::Content::Legacy'  );
use_ok('Test::Inline::Content::Default' );
use_ok('Test::Inline::Content::Simple'  );
use_ok('Test::Inline::Extract'          );
use_ok('Test::Inline::IO::File'         );
use_ok('Test::Inline'                   );
use_ok('Test::Inline::Util'             );
use_ok('Test::Inline::Script'           );
use_ok('Test::Inline::Section'          );

script_compiles_ok('script/inline2test');
