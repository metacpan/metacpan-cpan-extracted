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
--- usrc/uuid/parse.c	Wed Nov 29 23:03:41 2023
+++ usrcP/uuid/parse.c	Wed Dec  6 00:31:30 2023
@@ -40,9 +40,9 @@
 
 #include "uuidP.h"
 
-int uuid_parse(const char *in, uuid_t uu)
+int myuuid_parse(const char *in, myuuid_t uu)
 {
-	struct uuid	uuid;
+	struct myuuid	uuid;
 	int 		i;
 	const char	*cp;
 	char		buf[3];
@@ -75,6 +75,6 @@
 		uuid.node[i] = strtoul(buf, NULL, 16);
 	}
 
-	uuid_pack(&uuid, uu);
+	myuuid_pack(&uuid, uu);
 	return 0;
 }

