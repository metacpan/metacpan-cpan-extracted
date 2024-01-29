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
--- usrc/uuid/uuidd.h	Wed Nov 29 23:03:41 2023
+++ usrcP/uuid/uuidd.h	Tue Dec  5 23:56:38 2023
@@ -48,7 +48,7 @@
 #define UUIDD_OP_BULK_RANDOM_UUID	5
 #define UUIDD_MAX_OP			UUIDD_OP_BULK_RANDOM_UUID
 
-extern void uuid__generate_time(uuid_t out, int *num);
-extern void uuid__generate_random(uuid_t out, int *num);
+extern void myuuid__generate_time(myuuid_t out, int *num);
+extern void myuuid__generate_random(myuuid_t out, int *num);
 
 #endif /* _UUID_UUID_H */

