#
# Patch given file with DATA hunks and print to STDOUT.
#
#
# Patch to localize.
#
use strict;
use warnings;
use Text::Patch 'patch';

my $in = $ARGV[0];

my ($txt, $patch);
{
    local $/;
    open my $fh, '<', $in or die "open: $in: $!";
    $txt   = <$fh>;
    $patch = <DATA>;
}

#print $txt;
#print $patch;
#exit;

my $out = patch( $txt, $patch, STYLE => 'Unified' );

print $out;
exit 0;

__END__
--- usrc/uuid/clear.c	2023-11-29 23:03:41.791859643 -0500
+++ usrcP/uuid/clear.c	2023-12-05 04:01:28.586772617 -0500
@@ -37,7 +37,7 @@
 
 #include "uuidP.h"
 
-void uuid_clear(uuid_t uu)
+void myuuid_clear(myuuid_t uu)
 {
 	memset(uu, 0, 16);
 }
