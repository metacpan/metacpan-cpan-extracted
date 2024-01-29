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
--- usrc/uuid/uuid.h.in	Wed Nov 29 23:03:41 2023
+++ usrcP/uuid/uuid.h.in	Wed Dec  6 00:45:35 2023
@@ -41,7 +41,7 @@
 #endif
 #include <time.h>
 
-typedef unsigned char uuid_t[16];
+typedef unsigned char myuuid_t[16];
 
 /* UUID Variant definitions */
 #define UUID_VARIANT_NCS 	0
@@ -67,34 +67,34 @@
 #endif
 
 /* clear.c */
-void uuid_clear(uuid_t uu);
+void myuuid_clear(myuuid_t uu);
 
 /* compare.c */
-int uuid_compare(const uuid_t uu1, const uuid_t uu2);
+int myuuid_compare(const myuuid_t uu1, const myuuid_t uu2);
 
 /* copy.c */
-void uuid_copy(uuid_t dst, const uuid_t src);
+void myuuid_copy(myuuid_t dst, const myuuid_t src);
 
 /* gen_uuid.c */
-void uuid_generate(uuid_t out);
-void uuid_generate_random(uuid_t out);
-void uuid_generate_time(uuid_t out);
+void myuuid_generate(myuuid_t out);
+void myuuid_generate_random(myuuid_t out);
+void myuuid_generate_time(myuuid_t out);
 
 /* isnull.c */
-int uuid_is_null(const uuid_t uu);
+int myuuid_is_null(const myuuid_t uu);
 
 /* parse.c */
-int uuid_parse(const char *in, uuid_t uu);
+int myuuid_parse(const char *in, myuuid_t uu);
 
 /* unparse.c */
-void uuid_unparse(const uuid_t uu, char *out);
-void uuid_unparse_lower(const uuid_t uu, char *out);
-void uuid_unparse_upper(const uuid_t uu, char *out);
+void myuuid_unparse(const myuuid_t uu, char *out);
+void myuuid_unparse_lower(const myuuid_t uu, char *out);
+void myuuid_unparse_upper(const myuuid_t uu, char *out);
 
 /* uuid_time.c */
-time_t uuid_time(const uuid_t uu, struct timeval *ret_tv);
-int uuid_type(const uuid_t uu);
-int uuid_variant(const uuid_t uu);
+time_t myuuid_time(const myuuid_t uu, struct timeval *ret_tv);
+int myuuid_type(const myuuid_t uu);
+int myuuid_variant(const myuuid_t uu);
 
 #ifdef __cplusplus
 }

