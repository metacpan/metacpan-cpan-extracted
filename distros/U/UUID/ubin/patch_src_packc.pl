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
--- usrc/uuid/pack.c	Wed Nov 29 23:03:41 2023
+++ usrcP/uuid/pack.c	Wed Dec  6 00:30:46 2023
@@ -36,9 +36,9 @@
 #include <string.h>
 #include "uuidP.h"
 
-void uuid_pack(const struct uuid *uu, uuid_t ptr)
+void myuuid_pack(const struct myuuid *uu, myuuid_t ptr)
 {
-	uint32_t	tmp;
+	myuint32_t	tmp;
 	unsigned char	*out = ptr;
 
 	tmp = uu->time_low;

