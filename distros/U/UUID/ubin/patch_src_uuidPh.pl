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
--- usrc/uuid/uuidP.h	Wed Nov 29 23:03:41 2023
+++ usrcP/uuid/uuidP.h	Wed Dec  6 00:41:01 2023
@@ -32,11 +32,7 @@
  * %End-Header%
  */
 
-#ifdef HAVE_INTTYPES_H
-#include <inttypes.h>
-#else
 #include <uuid/uuid_types.h>
-#endif
 #include <sys/types.h>
 
 #include <uuid/uuid.h>
@@ -47,12 +43,12 @@
 #define TIME_OFFSET_HIGH 0x01B21DD2
 #define TIME_OFFSET_LOW  0x13814000
 
-struct uuid {
-	uint32_t	time_low;
-	uint16_t	time_mid;
-	uint16_t	time_hi_and_version;
-	uint16_t	clock_seq;
-	uint8_t	node[6];
+struct myuuid {
+	myuint32_t	time_low;
+	myuint16_t	time_mid;
+	myuint16_t	time_hi_and_version;
+	myuint16_t	clock_seq;
+	myuint8_t	node[6];
 };
 
 #ifndef __GNUC_PREREQ
@@ -67,5 +63,5 @@
 /*
  * prototypes
  */
-void uuid_pack(const struct uuid *uu, uuid_t ptr);
+void myuuid_pack(const struct myuuid *uu, myuuid_t ptr);
-void uuid_unpack(const uuid_t in, struct uuid *uu);
+void myuuid_unpack(const myuuid_t in, struct myuuid *uu);

