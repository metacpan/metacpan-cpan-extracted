#!/usr/bin/perl 

use strict;
use warnings;

use Test::More qw{no_plan};

#-----------------------------------------------------------------
#  
#-----------------------------------------------------------------
BEGIN {

   use_ok('Test::Structure');
   can_ok('main', qw{ has_includes 
                      has_subs 
                      has_comments 
                      has_pod
   });

};
#-----------------------------------------------------------------
#  
#-----------------------------------------------------------------

require_ok( 'Test::Structure' );
has_includes( 'Test::Structure', qw{PPI File::Spec::Functions} );
has_subs( 'Test::Structure', qw{has_includes has_subs has_comments has_pod _pkg2path _doc} );
has_comments( 'Test::Structure' );
has_pod( 'Test::Structure' );




