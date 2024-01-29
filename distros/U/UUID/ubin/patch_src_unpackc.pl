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
--- usrc/uuid/unpack.c	Wed Nov 29 23:03:41 2023
+++ usrcP/uuid/unpack.c	Wed Dec  6 00:39:17 2023
@@ -35,11 +35,12 @@
 #include "config.h"
 #include <string.h>
 #include "uuidP.h"
+#include <uuid/uuid_types.h>
 
-void uuid_unpack(const uuid_t in, struct uuid *uu)
+void myuuid_unpack(const myuuid_t in, struct myuuid *uu)
 {
-	const uint8_t	*ptr = in;
-	uint32_t		tmp;
+	const myuint8_t	*ptr = in;
+	myuint32_t		tmp;
 
 	tmp = *ptr++;
 	tmp = (tmp << 8) | *ptr++;

