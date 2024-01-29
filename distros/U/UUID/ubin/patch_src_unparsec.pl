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
--- usrc/uuid/unparse.c	Wed Nov 29 23:03:41 2023
+++ usrcP/uuid/unparse.c	Wed Dec  6 02:23:38 2023
@@ -49,11 +49,11 @@
 #define FMT_DEFAULT fmt_lower
 #endif
 
-static void uuid_unparse_x(const uuid_t uu, char *out, const char *fmt)
+static void myuuid_unparse_x(const myuuid_t uu, char *out, const char *fmt)
 {
-	struct uuid uuid;
+	struct myuuid uuid;
 
-	uuid_unpack(uu, &uuid);
+	myuuid_unpack(uu, &uuid);
 	sprintf(out, fmt,
 		uuid.time_low, uuid.time_mid, uuid.time_hi_and_version,
 		uuid.clock_seq >> 8, uuid.clock_seq & 0xFF,
@@ -61,17 +61,17 @@
 		uuid.node[3], uuid.node[4], uuid.node[5]);
 }
 
-void uuid_unparse_lower(const uuid_t uu, char *out)
+void myuuid_unparse_lower(const myuuid_t uu, char *out)
 {
-	uuid_unparse_x(uu, out,	fmt_lower);
+	myuuid_unparse_x(uu, out,	fmt_lower);
 }
 
-void uuid_unparse_upper(const uuid_t uu, char *out)
+void myuuid_unparse_upper(const myuuid_t uu, char *out)
 {
-	uuid_unparse_x(uu, out,	fmt_upper);
+	myuuid_unparse_x(uu, out,	fmt_upper);
 }
 
-void uuid_unparse(const uuid_t uu, char *out)
+void myuuid_unparse(const myuuid_t uu, char *out)
 {
-	uuid_unparse_x(uu, out, FMT_DEFAULT);
+	myuuid_unparse_x(uu, out, FMT_DEFAULT);
 }

