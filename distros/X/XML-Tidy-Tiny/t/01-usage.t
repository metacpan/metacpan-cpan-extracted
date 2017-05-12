#
#===============================================================================
#
#         FILE:  01-usage.t
#
#  DESCRIPTION:  
#
#        FILES:  ---
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:  YOUR NAME (), 
#      COMPANY:  
#      VERSION:  1.0
#      CREATED:  05/23/2011 05:15:16 PM
#     REVISION:  ---
#===============================================================================

use strict;
use warnings;

use Test::More 'no_plan';                      # last test to print
use ExtUtils::testlib;
use XML::Tidy::Tiny qw(xml_tidy);

is( xml_tidy('<a>123</a>'), '<a>123</a>' );
is( xml_tidy('123'), '123' );
is( xml_tidy('<a>123<c/>456</a>'), '<a>123<c/>456</a>' );
is( xml_tidy('<a><b>123</b></a>'), "<a>\n  <b>123</b>\n</a>" );
is( xml_tidy('<?xml?><a>123</a>'), "<?xml?>\n<a>123</a>" );
is( xml_tidy( '<a>9<b>123</b></a>'), "<a>\n  9\n  <b>123</b>\n</a>");
is( xml_tidy( '<html>
            <link/>
            </html>'), 
            '<html><link/></html>');

              
TODO: {
    local $TODO = "next version";
    my $x;
}; 



