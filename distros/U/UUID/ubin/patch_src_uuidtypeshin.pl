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
--- usrc/uuid/uuid_types.h.in	Wed Nov 29 23:03:41 2023
+++ usrcP/uuid/uuid_types.h.in	Tue Dec  5 23:54:38 2023
@@ -3,46 +3,46 @@
  * everything we need.  (cross fingers)  Other header files may have
  * also defined the types that we need.
  */
-#if (!defined(_STDINT_H) && !defined(_UUID_STDINT_H))
+#if !defined(_UUID_STDINT_H)
 #define _UUID_STDINT_H
 
-typedef unsigned char uint8_t;
-typedef signed char int8_t;
+typedef unsigned char myuint8_t;
+typedef signed char myint8_t;
 
 #if (@SIZEOF_INT@ == 8)
-typedef int		int64_t;
-typedef unsigned int	uint64_t;
+typedef int		myint64_t;
+typedef unsigned int	myuint64_t;
 #elif (@SIZEOF_LONG@ == 8)
-typedef long		int64_t;
-typedef unsigned long	uint64_t;
+typedef long		myint64_t;
+typedef unsigned long	myuint64_t;
 #elif (@SIZEOF_LONG_LONG@ == 8)
 #if defined(__GNUC__)
-typedef __signed__ long long 	int64_t;
+typedef __signed__ long long 	myint64_t;
 #else
-typedef signed long long 	int64_t;
+typedef signed long long 	myint64_t;
 #endif
-typedef unsigned long long	uint64_t;
+typedef unsigned long long	myuint64_t;
 #endif
 
 #if (@SIZEOF_INT@ == 2)
-typedef	int		int16_t;
-typedef	unsigned int	uint16_t;
+typedef	int		myint16_t;
+typedef	unsigned int	myuint16_t;
 #elif (@SIZEOF_SHORT@ == 2)
-typedef	short		int16_t;
-typedef	unsigned short	uint16_t;
+typedef	short		myint16_t;
+typedef	unsigned short	myuint16_t;
 #else
   ?==error: undefined 16 bit type
 #endif
 
 #if (@SIZEOF_INT@ == 4)
-typedef	int		int32_t;
-typedef	unsigned int	uint32_t;
+typedef	int		myint32_t;
+typedef	unsigned int	myuint32_t;
 #elif (@SIZEOF_LONG@ == 4)
-typedef	long		int32_t;
-typedef	unsigned long	uint32_t;
+typedef	long		myint32_t;
+typedef	unsigned long	myuint32_t;
 #elif (@SIZEOF_SHORT@ == 4)
-typedef	short		int32_t;
-typedef	unsigned short	uint32_t;
+typedef	short		myint32_t;
+typedef	unsigned short	myuint32_t;
 #else
  ?== error: undefined 32 bit type
 #endif

