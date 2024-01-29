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
--- usrc/uuid/gen_uuid_nt.c	Wed Nov 29 23:03:41 2023
+++ usrcP/uuid/gen_uuid_nt.c	Wed Dec  6 01:47:26 2023
@@ -79,7 +79,7 @@
 
 
 
-void uuid_generate(uuid_t out)
+void myuuid_generate(myuuid_t out)
 {
 	if(Nt5())
 	{

