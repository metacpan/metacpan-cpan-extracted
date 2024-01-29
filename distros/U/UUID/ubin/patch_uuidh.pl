#
# Patch given file with DATA hunks and print to STDOUT.
#
# This patch fixes the incorrect assumption that Win32 is missing
# sys/time.h in all cases.
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
--- a Fri Dec  1 23:41:31 2023
+++ b Fri Dec  1 23:52:55 2023
@@ -36,7 +36,7 @@
 #define _UUID_UUID_H
 
 #include <sys/types.h>
-#ifndef _WIN32
+#if ! defined(_WIN32) || defined(HAVE_SYS_TIME_H)
 #include <sys/time.h>
 #endif
 #include <time.h>
