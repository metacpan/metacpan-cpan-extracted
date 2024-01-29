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
--- usrc/uuid/uuid_time.c	Wed Nov 29 23:03:41 2023
+++ usrcP/uuid/uuid_time.c	Wed Dec  6 02:31:36 2023
@@ -49,19 +49,19 @@
 
 #include "uuidP.h"
 
-time_t uuid_time(const uuid_t uu, struct timeval *ret_tv)
+time_t myuuid_time(const myuuid_t uu, struct timeval *ret_tv)
 {
 	struct timeval		tv;
-	struct uuid		uuid;
-	uint32_t		high;
-	uint64_t		clock_reg;
+	struct myuuid		uuid;
+	myuint32_t		high;
+	myuint64_t		clock_reg;
 
-	uuid_unpack(uu, &uuid);
+	myuuid_unpack(uu, &uuid);
 
 	high = uuid.time_mid | ((uuid.time_hi_and_version & 0xFFF) << 16);
-	clock_reg = uuid.time_low | ((uint64_t) high << 32);
+	clock_reg = uuid.time_low | ((myuint64_t) high << 32);
 
-	clock_reg -= (((uint64_t) 0x01B21DD2) << 32) + 0x13814000;
+	clock_reg -= (((myuint64_t) 0x01B21DD2) << 32) + 0x13814000;
 	tv.tv_sec = clock_reg / 10000000;
 	tv.tv_usec = (clock_reg % 10000000) / 10;
 
@@ -71,20 +71,20 @@
 	return tv.tv_sec;
 }
 
-int uuid_type(const uuid_t uu)
+int myuuid_type(const myuuid_t uu)
 {
-	struct uuid		uuid;
+	struct myuuid		uuid;
 
-	uuid_unpack(uu, &uuid);
+	myuuid_unpack(uu, &uuid);
 	return ((uuid.time_hi_and_version >> 12) & 0xF);
 }
 
-int uuid_variant(const uuid_t uu)
+int myuuid_variant(const myuuid_t uu)
 {
-	struct uuid		uuid;
+	struct myuuid		uuid;
 	int			var;
 
-	uuid_unpack(uu, &uuid);
+	myuuid_unpack(uu, &uuid);
 	var = uuid.clock_seq;
 
 	if ((var & 0x8000) == 0)
@@ -97,7 +97,7 @@
 }
 
 #ifdef DEBUG
-static const char *variant_string(int variant)
+static const char *myvariant_string(int variant)
 {
 	switch (variant) {
 	case UUID_VARIANT_NCS:
@@ -115,7 +115,7 @@
 int
 main(int argc, char **argv)
 {
-	uuid_t		buf;
+	myuuid_t		buf;
 	time_t		time_reg;
 	struct timeval	tv;
 	int		type, variant;
@@ -124,15 +124,15 @@
 		fprintf(stderr, "Usage: %s uuid\n", argv[0]);
 		exit(1);
 	}
-	if (uuid_parse(argv[1], buf)) {
+	if (myuuid_parse(argv[1], buf)) {
 		fprintf(stderr, "Invalid UUID: %s\n", argv[1]);
 		exit(1);
 	}
-	variant = uuid_variant(buf);
-	type = uuid_type(buf);
-	time_reg = uuid_time(buf, &tv);
+	variant = myuuid_variant(buf);
+	type = myuuid_type(buf);
+	time_reg = myuuid_time(buf, &tv);
 
-	printf("UUID variant is %d (%s)\n", variant, variant_string(variant));
+	printf("UUID variant is %d (%s)\n", variant, myvariant_string(variant));
 	if (variant != UUID_VARIANT_DCE) {
 		printf("Warning: This program only knows how to interpret "
 		       "DCE UUIDs.\n\tThe rest of the output is likely "

