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

my $build = Module::Build->resume;

my @ccflags = @{ $build->notes( "builder_cflags" ) };
my $quoted_cflags = join ", ", map { perlstring $_ } @ccflags;

$outh->print( scalar do { <DATA> }
   =~ s/__BUILDER_CFLAGS__/$quoted_cflags/r );

$outh->print( scalar do {
   open my $in_h, "<", "XSParseKeyword.h" or
      die "Cannot open XSParseKeyword.h - $!";
   <$in_h> } );

__DATA__
package XS::Parse::Keyword::Builder_data 0.21;

use v5.14;
use warnings;

# Additional CFLAGS arguments to pass during compilation
use constant BUILDER_CFLAGS => __BUILDER_CFLAGS__;

# The contents of the "XSParseKeyword.h" file
my $XSParseKeyword_h = do {
   local $/;
   readline DATA;
};
sub XSPARSEKEYWORD_H() { $XSParseKeyword_h }

0x55AA;

__DATA__
