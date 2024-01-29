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
--- usrc/uuid/tst_uuid.c	Wed Nov 29 23:03:41 2023
+++ usrcP/uuid/tst_uuid.c	Wed Dec  6 01:58:47 2023
@@ -39,13 +39,13 @@
 
 #include <uuid/uuid.h>
 
-static int test_uuid(const char * uuid, int isValid)
+static int mytest_uuid(const char * uuid, int isValid)
 {
 	static const char * validStr[2] = {"invalid", "valid"};
-	uuid_t uuidBits;
+	myuuid_t uuidBits;
 	int parsedOk;
 
-	parsedOk = uuid_parse(uuid, uuidBits) == 0;
+	parsedOk = myuuid_parse(uuid, uuidBits) == 0;
 
 	printf("%s is %s", uuid, validStr[isValid]);
 	if (parsedOk != isValid) {
@@ -65,7 +65,7 @@
 int
 main(int argc ATTR((unused)) , char **argv ATTR((unused)))
 {
-	uuid_t		buf, tst;
+	myuuid_t		buf, tst;
 	char		str[100];
 	struct timeval	tv;
 	time_t		time_reg, time_gen;
@@ -74,15 +74,15 @@
 	int failed = 0;
 	int type, variant;
 
-	uuid_generate(buf);
-	uuid_unparse(buf, str);
+	myuuid_generate(buf);
+	myuuid_unparse(buf, str);
 	printf("UUID generate = %s\n", str);
 	printf("UUID: ");
 	for (i=0, cp = (unsigned char *) &buf; i < 16; i++) {
 		printf("%02x", *cp++);
 	}
 	printf("\n");
-	type = uuid_type(buf); 	variant = uuid_variant(buf);
+	type = myuuid_type(buf); 	variant = myuuid_variant(buf);
 	printf("UUID type = %d, UUID variant = %d\n", type, variant);
 	if (variant != UUID_VARIANT_DCE) {
 		printf("Incorrect UUID Variant; was expecting DCE!\n");
@@ -90,16 +90,16 @@
 	}
 	printf("\n");
 
-	uuid_generate_random(buf);
-	uuid_unparse(buf, str);
+	myuuid_generate_random(buf);
+	myuuid_unparse(buf, str);
 	printf("UUID random string = %s\n", str);
 	printf("UUID: ");
 	for (i=0, cp = (unsigned char *) &buf; i < 16; i++) {
 		printf("%02x", *cp++);
 	}
 	printf("\n");
-	type = uuid_type(buf);
-	variant = uuid_variant(buf);
+	type = myuuid_type(buf);
+	variant = myuuid_variant(buf);
 	printf("UUID type = %d, UUID variant = %d\n", type, variant);
 	if (variant != UUID_VARIANT_DCE) {
 		printf("Incorrect UUID Variant; was expecting DCE!\n");
@@ -113,16 +113,16 @@
 	printf("\n");
 
 	time_gen = time(0);
-	uuid_generate_time(buf);
-	uuid_unparse(buf, str);
+	myuuid_generate_time(buf);
+	myuuid_unparse(buf, str);
 	printf("UUID string = %s\n", str);
 	printf("UUID time: ");
 	for (i=0, cp = (unsigned char *) &buf; i < 16; i++) {
 		printf("%02x", *cp++);
 	}
 	printf("\n");
-	type = uuid_type(buf);
-	variant = uuid_variant(buf);
+	type = myuuid_type(buf);
+	variant = myuuid_variant(buf);
 	printf("UUID type = %d, UUID variant = %d\n", type, variant);
 	if (variant != UUID_VARIANT_DCE) {
 		printf("Incorrect UUID Variant; was expecting DCE!\n");
@@ -136,7 +136,7 @@
 
 	tv.tv_sec = 0;
 	tv.tv_usec = 0;
-	time_reg = uuid_time(buf, &tv);
+	time_reg = myuuid_time(buf, &tv);
 	printf("UUID generated at %lu reports %lu (%ld.%ld)\n",
 	       (unsigned long)time_gen, (unsigned long)time_reg,
 	       (long)tv.tv_sec, (long)tv.tv_usec);
@@ -149,42 +149,42 @@
 		printf("UUID time comparison succeeded.\n");
 	}
 
-	if (uuid_parse(str, tst) < 0) {
+	if (myuuid_parse(str, tst) < 0) {
 		printf("UUID parse failed\n");
 		failed++;
 	}
-	if (!uuid_compare(buf, tst)) {
+	if (!myuuid_compare(buf, tst)) {
 		printf("UUID parse and compare succeeded.\n");
 	} else {
 		printf("UUID parse and compare failed!\n");
 		failed++;
 	}
-	uuid_clear(tst);
-	if (uuid_is_null(tst))
+	myuuid_clear(tst);
+	if (myuuid_is_null(tst))
 		printf("UUID clear and is null succeeded.\n");
 	else {
 		printf("UUID clear and is null failed!\n");
 		failed++;
 	}
-	uuid_copy(buf, tst);
-	if (!uuid_compare(buf, tst))
+	myuuid_copy(buf, tst);
+	if (!myuuid_compare(buf, tst))
 		printf("UUID copy and compare succeeded.\n");
 	else {
 		printf("UUID copy and compare failed!\n");
 		failed++;
 	}
 
-	failed += test_uuid("84949cc5-4701-4a84-895b-354c584a981b", 1);
-	failed += test_uuid("84949CC5-4701-4A84-895B-354C584A981B", 1);
-	failed += test_uuid("84949cc5-4701-4a84-895b-354c584a981bc", 0);
-	failed += test_uuid("84949cc5-4701-4a84-895b-354c584a981", 0);
-	failed += test_uuid("84949cc5x4701-4a84-895b-354c584a981b", 0);
-	failed += test_uuid("84949cc504701-4a84-895b-354c584a981b", 0);
-	failed += test_uuid("84949cc5-470104a84-895b-354c584a981b", 0);
-	failed += test_uuid("84949cc5-4701-4a840895b-354c584a981b", 0);
-	failed += test_uuid("84949cc5-4701-4a84-895b0354c584a981b", 0);
-	failed += test_uuid("g4949cc5-4701-4a84-895b-354c584a981b", 0);
-	failed += test_uuid("84949cc5-4701-4a84-895b-354c584a981g", 0);
+	failed += mytest_uuid("84949cc5-4701-4a84-895b-354c584a981b", 1);
+	failed += mytest_uuid("84949CC5-4701-4A84-895B-354C584A981B", 1);
+	failed += mytest_uuid("84949cc5-4701-4a84-895b-354c584a981bc", 0);
+	failed += mytest_uuid("84949cc5-4701-4a84-895b-354c584a981", 0);
+	failed += mytest_uuid("84949cc5x4701-4a84-895b-354c584a981b", 0);
+	failed += mytest_uuid("84949cc504701-4a84-895b-354c584a981b", 0);
+	failed += mytest_uuid("84949cc5-470104a84-895b-354c584a981b", 0);
+	failed += mytest_uuid("84949cc5-4701-4a840895b-354c584a981b", 0);
+	failed += mytest_uuid("84949cc5-4701-4a84-895b0354c584a981b", 0);
+	failed += mytest_uuid("g4949cc5-4701-4a84-895b-354c584a981b", 0);
+	failed += mytest_uuid("84949cc5-4701-4a84-895b-354c584a981g", 0);
 
 	if (failed) {
 		printf("%d failures.\n", failed);

