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
--- usrc/uuid/compare.c	Wed Nov 29 23:03:41 2023
+++ usrcP/uuid/compare.c	Wed Dec  6 00:54:07 2023
@@ -40,12 +40,12 @@
 
 #define UUCMP(u1,u2) if (u1 != u2) return((u1 < u2) ? -1 : 1);
 
-int uuid_compare(const uuid_t uu1, const uuid_t uu2)
+int myuuid_compare(const myuuid_t uu1, const myuuid_t uu2)
 {
-	struct uuid	uuid1, uuid2;
+	struct myuuid	uuid1, uuid2;
 
-	uuid_unpack(uu1, &uuid1);
-	uuid_unpack(uu2, &uuid2);
+	myuuid_unpack(uu1, &uuid1);
+	myuuid_unpack(uu2, &uuid2);
 
 	UUCMP(uuid1.time_low, uuid2.time_low);
 	UUCMP(uuid1.time_mid, uuid2.time_mid);

