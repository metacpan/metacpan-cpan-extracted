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
--- usrc/uuid/isnull.c	Wed Nov 29 23:03:41 2023
+++ usrcP/uuid/isnull.c	Wed Dec  6 01:52:46 2023
@@ -36,7 +36,7 @@
 #include "uuidP.h"
 
 /* Returns 1 if the uuid is the NULL uuid */
-int uuid_is_null(const uuid_t uu)
+int myuuid_is_null(const myuuid_t uu)
 {
 	const unsigned char 	*cp;
 	int			i;

