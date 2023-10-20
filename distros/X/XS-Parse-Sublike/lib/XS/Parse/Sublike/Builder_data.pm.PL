#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2021 -- leonerd@leonerd.org.uk

use v5.14;
use warnings;

use B qw( perlstring );
use Module::Build;

open my $outh, ">", $ARGV[0] or
   die "Cannot write $ARGV[0] - $!\n";

local $/;

$outh->print( scalar do { <DATA> } );

$outh->print( scalar do {
   open my $in_h, "<", "XSParseSublike.h" or
      die "Cannot open XSParseSublike.h - $!";
   <$in_h> } );

__DATA__
package XS::Parse::Sublike::Builder_data 0.21;

use v5.14;
use warnings;

# The contents of the "XSParseSublike.h" file
my $XSParseSublike_h = do {
   local $/;
   readline DATA;
};
sub XSPARSESUBLIKE_H() { $XSParseSublike_h }

0x55AA;

__DATA__
