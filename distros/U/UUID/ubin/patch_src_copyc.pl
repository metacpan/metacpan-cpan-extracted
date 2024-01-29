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
--- usrc/uuid/copy.c	2023-11-29 23:03:41.791859643 -0500
+++ usrcP/uuid/copy.c	2023-12-05 04:20:44.596737007 -0500
@@ -35,7 +35,7 @@
 #include "config.h"
 #include "uuidP.h"
 
-void uuid_copy(uuid_t dst, const uuid_t src)
+void myuuid_copy(myuuid_t dst, const myuuid_t src)
 {
 	unsigned char		*cp1;
 	const unsigned char	*cp2;
