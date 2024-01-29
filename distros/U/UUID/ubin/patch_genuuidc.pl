#
# Patch given file with DATA hunks and print to STDOUT.
#
# This patch:
#   * Fixes missing ifreq.ifr_hwaddr on at least some versions of
#       Solaris.
#       osname=solaris, osvers=2.11, archname=i86pc-solaris-64
#       uname='sunos ouzel 5.11 omnios-r151034-0d278a0cc5 i86pc i386 i86pc '
#   * Explicitly casts some places for g++.
#   * Include Windows.h if exists, and stdint.h and typedef mode_t.
#   * Include gettimeofday() if Windows.h exists.
#   * Add cast to silence warning.
#   * Define getpid() for native Win32.
#   * Includes for native Win32.
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

#print $txt,"\n";
#exit;

my $out = patch( $txt, $patch, STYLE => 'Unified' );

print $out;
exit 0;

__END__
--- usrcP/uuid/gen_uuid.c	Sun Dec 10 10:41:59 2023
+++ ulib/uuid/gen_uuid.c	Sun Dec 10 15:59:31 2023
@@ -40,6 +40,7 @@
 #define _DEFAULT_SOURCE	  /* since glibc 2.20 _SVID_SOURCE is deprecated */
 
 #include "config.h"
+#include <uuid/uuid_types.h>
 
 #include <stdio.h>
 #ifdef HAVE_UNISTD_H
@@ -93,6 +94,19 @@
 #include <sys/resource.h>
 #endif
 
+#ifdef HAVE_WINDOWS_H
+#include <Windows.h>
+#endif
+
+#ifdef USE_WIN32_NATIVE
+#include <io.h>
+#include <stdint.h>
+#include <process.h>
+#define getpid() _getpid()
+#define ftruncate(a,b) _chsize(a,b)
+typedef myuint32_t mode_t;
+#endif
+
 #include "uuidP.h"
 #include "uuidd.h"
 
@@ -112,6 +126,30 @@
 THREAD_LOCAL unsigned short jrand_seed[3];
 #endif
 
+#ifdef USE_WIN32_NATIVE
+int gettimeofday(struct timeval * tp, struct timezone * tzp)
+{
+    // Note: some broken versions only have 8 trailing zero's, the correct epoch has 9 trailing zero's
+    // This magic number is the number of 100 nanosecond intervals since January 1, 1601 (UTC)
+    // until 00:00:00 January 1, 1970 
+    static const myuint64_t EPOCH = ((myuint64_t) 116444736000000000ULL);
+
+    SYSTEMTIME  system_time;
+    FILETIME    file_time;
+    myuint64_t  time;
+
+    GetSystemTime( &system_time );
+    SystemTimeToFileTime( &system_time, &file_time );
+    time =  ((myuint64_t)file_time.dwLowDateTime )      ;
+    time += ((myuint64_t)file_time.dwHighDateTime) << 32;
+
+    tp->tv_sec  = (long) ((time - EPOCH) / 10000000L);
+    tp->tv_usec = (long) (system_time.wMilliseconds * 1000);
+    return 0;
+}
+#endif
+
+
 static int myget_random_fd(void)
 {
 	struct timeval	tv;
@@ -158,7 +196,7 @@
 {
 	int i, n = nbytes, fd;
 	int lose_counter = 0;
-	unsigned char *cp = buf;
+	unsigned char *cp = (unsigned char*)buf;
 
 #ifdef HAVE_GETRANDOM
 	i = getrandom(buf, nbytes, 0);
@@ -189,7 +227,7 @@
 	 * We do this all the time, but this is the only source of
 	 * randomness if /dev/random/urandom is out to lunch.
 	 */
-	for (cp = buf, i = 0; i < nbytes; i++)
+	for (cp = (unsigned char*)buf, i = 0; i < nbytes; i++)
 		*cp++ ^= (rand() >> 7) & 0xFF;
 #ifdef DO_JRAND_MIX
 	{
@@ -197,7 +235,7 @@
 
 		memcpy(tmp_seed, jrand_seed, sizeof(tmp_seed));
 		jrand_seed[2] = jrand_seed[2] ^ syscall(__NR_gettid);
-		for (cp = buf, i = 0; i < nbytes; i++)
+		for (cp = (unsigned char*)buf, i = 0; i < nbytes; i++)
 			*cp++ ^= (jrand48(tmp_seed) >> 7) & 0xFF;
 		memcpy(jrand_seed, tmp_seed,
 		       sizeof(jrand_seed) - sizeof(unsigned short));
@@ -259,11 +297,17 @@
 	for (i = 0; i < n; i+= ifreq_size(*ifrp) ) {
 		ifrp = (struct ifreq *)((char *) ifc.ifc_buf+i);
 		strncpy(ifr.ifr_name, ifrp->ifr_name, IFNAMSIZ);
-#ifdef SIOCGIFHWADDR
+#if defined(SIOCGIFHWADDR) && ( defined(ifr_hwaddr) || defined(ifr_addr) )
 		if (ioctl(sd, SIOCGIFHWADDR, &ifr) < 0)
 			continue;
+#ifdef ifr_hwaddr
 		a = (unsigned char *) &ifr.ifr_hwaddr.sa_data;
 #else
+#ifdef ifr_addr
+		a = (unsigned char *) &ifr.ifr_addr.sa_data;
+#endif /* ifr_addr */
+#endif /* ifr_hwaddr */
+#else
 #ifdef SIOCGENADDR
 		if (ioctl(sd, SIOCGENADDR, &ifr) < 0)
 			continue;
@@ -419,7 +463,7 @@
 	}
 
 	*clock_high = clock_reg >> 32;
-	*clock_low = clock_reg;
+	*clock_low = (myuint32_t)clock_reg;
 	*ret_clock_seq = clock_seq;
 	return 0;
 }

