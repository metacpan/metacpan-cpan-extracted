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
--- usrc/uuid/gen_uuid.c	Wed Nov 29 23:03:41 2023
+++ usrcP/uuid/gen_uuid.c	Wed Dec  6 02:28:10 2023
@@ -112,7 +112,7 @@
 THREAD_LOCAL unsigned short jrand_seed[3];
 #endif
 
-static int get_random_fd(void)
+static int myget_random_fd(void)
 {
 	struct timeval	tv;
 	static int	fd = -2;
@@ -154,7 +154,7 @@
  * Generate a series of random bytes.  Use /dev/urandom if possible,
  * and if not, use srandom/random.
  */
-static void get_random_bytes(void *buf, int nbytes)
+static void myget_random_bytes(void *buf, int nbytes)
 {
 	int i, n = nbytes, fd;
 	int lose_counter = 0;
@@ -170,7 +170,7 @@
 		return;
 #endif
 
-	fd = get_random_fd();
+	fd = myget_random_fd();
 	if (fd >= 0) {
 		while (n > 0) {
 			i = read(fd, cp, n);
@@ -215,7 +215,7 @@
  * commenting out get_node_id just to get gen_uuid to compile under windows
  * is not the right way to go!
  */
-static int get_node_id(unsigned char *node_id)
+static int myget_node_id(unsigned char *node_id)
 {
 #ifdef HAVE_NET_IF_H
 	int 		sd;
@@ -300,19 +300,19 @@
 /* Assume that the gettimeofday() has microsecond granularity */
 #define MAX_ADJUSTMENT 10
 
-static int get_clock(uint32_t *clock_high, uint32_t *clock_low,
-		     uint16_t *ret_clock_seq, int *num)
+static int myget_clock(myuint32_t *clock_high, myuint32_t *clock_low,
+		     myuint16_t *ret_clock_seq, int *num)
 {
 	THREAD_LOCAL int		adjustment = 0;
 	THREAD_LOCAL struct timeval	last = {0, 0};
 	THREAD_LOCAL int		state_fd = -2;
 	THREAD_LOCAL FILE		*state_f;
-	THREAD_LOCAL uint16_t		clock_seq;
+	THREAD_LOCAL myuint16_t		clock_seq;
 	struct timeval 			tv;
 #ifndef _WIN32
 	struct flock			fl;
 #endif
-	uint64_t			clock_reg;
+	myuint64_t			clock_reg;
 	mode_t				save_umask;
 	int				len;
 
@@ -361,7 +361,7 @@
 	}
 
 	if ((last.tv_sec == 0) && (last.tv_usec == 0)) {
-		get_random_bytes(&clock_seq, sizeof(clock_seq));
+		myget_random_bytes(&clock_seq, sizeof(clock_seq));
 		clock_seq &= 0x3FFF;
 		gettimeofday(&last, 0);
 		last.tv_sec--;
@@ -386,8 +386,8 @@
 	}
 
 	clock_reg = tv.tv_usec*10 + adjustment;
-	clock_reg += ((uint64_t) tv.tv_sec)*10000000;
-	clock_reg += (((uint64_t) 0x01B21DD2) << 32) + 0x13814000;
+	clock_reg += ((myuint64_t) tv.tv_sec)*10000000;
+	clock_reg += (((myuint64_t) 0x01B21DD2) << 32) + 0x13814000;
 
 	if (num && (*num > 1)) {
 		adjustment += *num - 1;
@@ -425,7 +425,7 @@
 }
 
 #if defined(USE_UUIDD) && defined(HAVE_SYS_UN_H)
-static ssize_t read_all(int fd, char *buf, size_t count)
+static ssize_t myread_all(int fd, char *buf, size_t count)
 {
 	ssize_t ret;
 	ssize_t c = 0;
@@ -452,7 +452,7 @@
 /*
  * Close all file descriptors
  */
-static void close_all_fds(void)
+static void myclose_all_fds(void)
 {
 	int i, max;
 
@@ -488,14 +488,14 @@
  *
  * Returns 0 on success, non-zero on failure.
  */
-static int get_uuid_via_daemon(int op, uuid_t out, int *num)
+static int myget_uuid_via_daemon(int op, myuuid_t out, int *num)
 {
 #if defined(USE_UUIDD) && defined(HAVE_SYS_UN_H)
 	char op_buf[64];
 	int op_len;
 	int s;
 	ssize_t ret;
-	int32_t reply_len = 0, expected = 16;
+	myint32_t reply_len = 0, expected = 16;
 	struct sockaddr_un srv_addr;
 	struct stat st;
 	pid_t pid;
@@ -569,16 +569,16 @@
 #pragma GCC diagnostic pop
 #endif
 
-void uuid__generate_time(uuid_t out, int *num)
+void myuuid__generate_time(myuuid_t out, int *num)
 {
 	static unsigned char node_id[6];
 	static int has_init = 0;
-	struct uuid uu;
-	uint32_t	clock_mid;
+	struct myuuid uu;
+	myuint32_t	clock_mid;
 
 	if (!has_init) {
-		if (get_node_id(node_id) <= 0) {
-			get_random_bytes(node_id, 6);
+		if (myget_node_id(node_id) <= 0) {
+			myget_random_bytes(node_id, 6);
 			/*
 			 * Set multicast bit, to prevent conflicts
 			 * with IEEE 802 addresses obtained from
@@ -588,19 +588,19 @@
 		}
 		has_init = 1;
 	}
-	get_clock(&clock_mid, &uu.time_low, &uu.clock_seq, num);
+	myget_clock(&clock_mid, &uu.time_low, &uu.clock_seq, num);
 	uu.clock_seq |= 0x8000;
-	uu.time_mid = (uint16_t) clock_mid;
+	uu.time_mid = (myuint16_t) clock_mid;
 	uu.time_hi_and_version = ((clock_mid >> 16) & 0x0FFF) | 0x1000;
 	memcpy(uu.node, node_id, 6);
-	uuid_pack(&uu, out);
+	myuuid_pack(&uu, out);
 }
 
-void uuid_generate_time(uuid_t out)
+void myuuid_generate_time(myuuid_t out)
 {
 #ifdef TLS
 	THREAD_LOCAL int		num = 0;
-	THREAD_LOCAL struct uuid	uu;
+	THREAD_LOCAL struct myuuid	uu;
 	THREAD_LOCAL time_t		last_time = 0;
 	time_t				now;
 
@@ -611,10 +611,10 @@
 	}
 	if (num <= 0) {
 		num = 1000;
-		if (get_uuid_via_daemon(UUIDD_OP_BULK_TIME_UUID,
+		if (myget_uuid_via_daemon(UUIDD_OP_BULK_TIME_UUID,
 					out, &num) == 0) {
 			last_time = time(0);
-			uuid_unpack(out, &uu);
+			myuuid_unpack(out, &uu);
 			num--;
 			return;
 		}
@@ -628,22 +628,22 @@
 				uu.time_hi_and_version++;
 		}
 		num--;
-		uuid_pack(&uu, out);
+		myuuid_pack(&uu, out);
 		return;
 	}
 #else
-	if (get_uuid_via_daemon(UUIDD_OP_TIME_UUID, out, 0) == 0)
+	if (myget_uuid_via_daemon(UUIDD_OP_TIME_UUID, out, 0) == 0)
 		return;
 #endif
 
-	uuid__generate_time(out, 0);
+	myuuid__generate_time(out, 0);
 }
 
 
-void uuid__generate_random(uuid_t out, int *num)
+void myuuid__generate_random(myuuid_t out, int *num)
 {
-	uuid_t	buf;
-	struct uuid uu;
+	myuuid_t	buf;
+	struct myuuid uu;
 	int i, n;
 
 	if (!num || !*num)
@@ -652,23 +652,23 @@
 		n = *num;
 
 	for (i = 0; i < n; i++) {
-		get_random_bytes(buf, sizeof(buf));
-		uuid_unpack(buf, &uu);
+		myget_random_bytes(buf, sizeof(buf));
+		myuuid_unpack(buf, &uu);
 
 		uu.clock_seq = (uu.clock_seq & 0x3FFF) | 0x8000;
 		uu.time_hi_and_version = (uu.time_hi_and_version & 0x0FFF)
 			| 0x4000;
-		uuid_pack(&uu, out);
-		out += sizeof(uuid_t);
+		myuuid_pack(&uu, out);
+		out += sizeof(myuuid_t);
 	}
 }
 
-void uuid_generate_random(uuid_t out)
+void myuuid_generate_random(myuuid_t out)
 {
 	int	num = 1;
 	/* No real reason to use the daemon for random uuid's -- yet */
 
-	uuid__generate_random(out, &num);
+	myuuid__generate_random(out, &num);
 }
 
 
@@ -678,10 +678,10 @@
  * /dev/urandom is available, since otherwise we won't have
  * high-quality randomness.
  */
-void uuid_generate(uuid_t out)
+void myuuid_generate(myuuid_t out)
 {
-	if (get_random_fd() >= 0)
-		uuid_generate_random(out);
+	if (myget_random_fd() >= 0)
+		myuuid_generate_random(out);
 	else
-		uuid_generate_time(out);
+		myuuid_generate_time(out);
 }

