#
# Patch given file with DATA hunks and print to STDOUT.
#
#
# Patch to:
#   - Add explicit casts to silence warnings.
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
--- usrcP/uuid/parse.c	Sat Dec  9 02:18:40 2023
+++ ulib/uuid/parse.c	Sat Dec  9 03:00:51 2023
@@ -64,15 +64,15 @@
 			return -1;
 	}
 	uuid.time_low = strtoul(in, NULL, 16);
-	uuid.time_mid = strtoul(in+9, NULL, 16);
-	uuid.time_hi_and_version = strtoul(in+14, NULL, 16);
-	uuid.clock_seq = strtoul(in+19, NULL, 16);
+	uuid.time_mid = (myuint16_t)strtoul(in+9, NULL, 16);
+	uuid.time_hi_and_version = (myuint16_t)strtoul(in+14, NULL, 16);
+	uuid.clock_seq = (myuint16_t)strtoul(in+19, NULL, 16);
 	cp = in+24;
 	buf[2] = 0;
 	for (i=0; i < 6; i++) {
 		buf[0] = *cp++;
 		buf[1] = *cp++;
-		uuid.node[i] = strtoul(buf, NULL, 16);
+		uuid.node[i] = (myuint8_t)strtoul(buf, NULL, 16);
 	}
 
 	myuuid_pack(&uuid, uu);

