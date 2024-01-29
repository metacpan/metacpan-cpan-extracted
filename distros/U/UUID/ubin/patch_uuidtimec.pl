#
# Patch given file with DATA hunks and print to STDOUT.
#
#
# Patch to:
#   * Include Windows.h.
#   * Cast to silence warning.
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
--- usrcP/uuid/uuid_time.c	Sat Dec  9 02:18:40 2023
+++ ulib/uuid/uuid_time.c	Sat Dec  9 02:50:06 2023
@@ -46,6 +46,10 @@
 #include <sys/time.h>
 #endif
 #include <time.h>
+#ifdef HAVE_WINDOWS_H
+#include <Windows.h>
+#include <stdint.h>
+#endif
 
 #include "uuidP.h"
 
@@ -62,7 +66,7 @@
 	clock_reg = uuid.time_low | ((myuint64_t) high << 32);
 
 	clock_reg -= (((myuint64_t) 0x01B21DD2) << 32) + 0x13814000;
-	tv.tv_sec = clock_reg / 10000000;
+	tv.tv_sec = (long)(clock_reg / 10000000);
 	tv.tv_usec = (clock_reg % 10000000) / 10;
 
 	if (ret_tv)

