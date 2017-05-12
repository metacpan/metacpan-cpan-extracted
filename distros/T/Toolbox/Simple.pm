#
# Toolbox::Simple   - Some tools (mostly math-related) to make life easier.
#                       Wrote it for myself, anyone else is welcome to it.
#
# (c) 2002 Jason Leane <alphamethyl@mac.com>
#
# See "README" for help.
#

BEGIN {
	srand;
}

package Toolbox::Simple;

$VERSION = "0.52";

use Exporter;
use Socket;
use Sys::Hostname;
use MIME::Base64;
use Digest::MD5;
use IO::File;

@ISA 		= qw(Exporter);

@EXPORT 	= qw();

@EXPORT_OK 	= qw(c32 _nl send_mail md5_file b64_encode b64_decode my_hostname my_ip round_money commify_number hex2ascii ip2name name2ip fibo gcd gcf lcm is_prime dec2hex hex2dec dec2bin bin2dec dec2oct oct2dec time_now time_english);


sub average {
	my $nums = scalar(@_);
	my $n = 0;
	my $total = 0;
	
	foreach $n (@_) {
		$total = $total + $n;
	}
	
	my $avg = $total / $nums;
	return($avg);
}

sub fibo {
	my ($n, $s) = (shift, sqrt(5));
	return int((((0.5 + 0.5*$s) ** $n) - ((0.5 - 0.5*$s) ** $n)) / $s);
}

sub gcd {
	use integer;
	my $gcd = shift || 1;
	while (@_) {
		my $next = shift;
		while($next) {
			my $r = $gcd % $next;
			$r += $next if $r < 0;
			$gcd = $next;
			$next = $r;
		}
	}
	no integer;
	return $gcd;
}

sub gcf {
	use integer;
	my $gcf = shift || 1;
	while (@_) {
		my $next = shift;
		while($next) {
			my $r = $gcf % $next;
			$r += $next if $r < 0;
			$gcf = $next;
			$next = $r;
		}
	}
	no integer;
	return $gcf;
}

sub lcm {
	use integer;
	my $lcm = shift;
	foreach (@_) { $lcm *= $_ / gcd($_, $lcm) }
	no integer;
	return $lcm;
}

sub is_prime {
	# Hella props to Miller & Rabin
	use integer;
	my $n = shift;
	my $n1 = $n - 1;
	my $one = $n - $n1;
	my $wit = $one * 100;
	my $wit_count;
	
	my $p2 = $one;
	my $p2i = -1;
	++$p2i, $p2 *= 2 while $p2 <= $n1;
	$p2 /= 2;
	
	my $last_wit = 5;
	$last_wit += (260 - $p2i)/13 if $p2i < 260;
	
	for $wit_count ( 1..$last_wit ) {
		$wit *= 1024;
		$wit += rand(1024);
		$wit = $wit % $n if $wit > $n;
		$wit = $one * 100, redo if $wit == 0;
		
		my $prod = $one;
		my $n1bits = $n1;
		my $p2next = $p2;
		
		while(1) {
			my $rootone = $prod == 1 || $prod == $n1;
			$prod = ($prod * $prod) % $n;
			return 0 if $prod == 1 && !$rootone;
			
			if($n1bits >= $p2next) {
				$prod = ($prod * $wit) % $n;
				$n1bits -= $p2next;
			}
			
			last if $p2next == 1;
			$p2next /= 2;
		}
		return 0 unless $prod == 1;
	}
	no integer;
	return 1;
}

sub dec2hex {
	my $dec = int(shift);
	my $pref;
	if(shift) { $pref = '0x' } else { $pref = '' }
	my $hex = $pref . sprintf("%x", $dec);
	return($hex);
}

sub hex2dec {
	my $h = shift;
	$h =~ s/^0x//g;
	return(hex($h));
}

sub dec2oct {
	my $dec = int(shift);
	my $oct = sprintf("%o", $dec);
	return($oct);
}

sub oct2dec {
	my $o = shift;
	return(oct($o));
}

sub dec2bin {
	my $dec = int(shift);
	my $bits = shift;
	my $bin = unpack("B32", pack("N", $dec));
	substr($bin, 0, (32 - $bits)) = '';
	return($bin);
}

sub bin2dec {
	my $bin = shift;
	my $bits = length($bin);
	$bin = (32 - $bits) x '0' . $bin;
	my $dec = unpack("N", pack("B32", substr("0" x 32 . $bin, -32)));
	return($dec);
}

sub round_money {
	my $f = shift;
	if($f == int($f)) { return($f); }
	my $r = sprintf("%.2f", $f);
	return($r);
}

sub time_english {
	# Format = time | date_short | date_long | weekday | month | year | date_lf
	my $fmt = shift;
	my @days = qw(Sunday Monday Tuesday Wednesday Thursday Friday);
	my @months = qw(January February March April May June July August September October November December);
	my @t = localtime(time);
	if(length($t[0]) == 1) { $t[0] = '0' . $t[0] }
	if(length($t[1]) == 1) { $t[1] = '0' . $t[1] }
	if(length($t[2]) == 1) { $t[2] = '0' . $t[2] }
	my $tm = $t[2] . ':' . $t[1] . ':' . $t[0];
	my $d_long = $days[$t[6]] . ", " . $months[$t[4]] . " $t[3], " . ($t[5] + 1900);
	return $tm if $fmt eq 'time';
	$t[3]++; if(length($t[3]) == 1) { $t[3] = '0' . $t[3] }
	$t[4]++; if(length($t[4]) == 1) { $t[4] = '0' . $t[4] }
	my $d_short = $t[4] . '/' . $t[3] . '/' . ($t[5] + 1900);
	my $d_lf = $t[3] . '/' . $t[4] . '/' . ($t[5] + 1900);
	return $d_long if $fmt eq 'date_long';
	return $d_short if $fmt eq 'date_short';
	return $d_lf if $fmt eq 'date_lf';
	return $days[(localtime(time))[6]] if $fmt eq 'weekday';
	return $months[(localtime(time))[4]] if $fmt eq 'month';
	return $t[5] + 1900 if $fmt eq 'year';
	return 0;
}

sub time_now {
	my @t = localtime(time);
	if(length($t[0]) == 1) { $t[0] = '0' . $t[0] }
	if(length($t[1]) == 1) { $t[1] = '0' . $t[1] }
	if(length($t[2]) == 1) { $t[2] = '0' . $t[2] }
	my $tm = $t[2] . ':' . $t[1] . ':' . $t[0];
	return($tm);
}

sub name2ip {
	my $host = shift;
	my ($addr) = (gethostbyname($host))[4];
	my $ip = join(".", unpack("C4", $addr));
	return($ip);
}

sub ip2name {
	my $ip = shift;
	my $ia = inet_aton($ip);
	my $name = scalar(gethostbyaddr($ia, AF_INET));
	if($name) { return($name) } else { return(0) }
}

sub hex2ascii {
	my $hex = shift;
	return(chr(hex($hex)));
}

sub commify_number {
	# Props to Larry, as always
	my $num = shift;
	1 while $num =~ s/(\d)(\d\d\d)(?!\d)/$1,$2/;
	return($num);
}

sub send_mail {
	my $srv = shift;
	my $to = shift;
	my $from = shift;
	my $subject = shift;
	my $msg = shift;
	my @msglines = split(/\n/, $msg);
	unless($msg =~ /\n/) { $msglines[0] = $msg; }
	
	use Net::SMTP;
	
	my $smtp = Net::SMTP->new($srv) or return(0);
	$smtp->mail($from);
	$smtp->to($to);
	$smtp->data();
	$smtp->datasend("To: $to\n");
	$smtp->datasend("From: $from\n");
	$smtp->datasend("Subject: $subject\n");
	$smtp->datasend("X-Mailer: Toolbox-Simple v0.5 (Perl)\n\n");
	foreach $e (@msglines) {
		$smtp->datasend("$e\n");
	}
	$smtp->dataend();
	$smtp->quit;
	return(1);
}

sub my_hostname {
	return(hostname);
}

sub my_ip {
	return(&name2ip(hostname));
}

sub b64_encode {
	my $file = shift;
	my $out = shift || "$file.b64";
	open(BINP, $file) or return(0);
	open(BOUTP, ">$out") or return(0);
	while(read(BINP, $buf, 60*57)) {
		print(BOUTP encode_base64($buf));
	}
	close(BINP);
	close(BOUTP);
	return(1);
}

sub b64_decode {
	my $file = shift;
	my $out = shift || "$file.out";
	open(BINP, $file) or return(0);
	open(BOUTP, ">$out") or return(0);
	while(<BINP>) {
		print(BOUTP decode_base64($_));
	}
	close(BINP);
	close(BOUTP);
	return(1);
}

sub md5_file {
	my $file = shift;
	my $md5 = Digest::MD5->new;
	open(MDFILE, "<$file") or return(0);
	binmode(MDFILE);
	$md5->addfile(*MDFILE);
	my $dig = $md5->hexdigest;
	close(MDFILE);
	undef $md5;
	return($dig);
}

sub _nl {
	return("\n");
}

sub c32 {
	my $data = shift;
	my $c = unpack("%32C*", $data) % 32767;
	return(sprintf("%x", $c));
}

return 1;

__END__


=head1 NAME

C<Toolbox::Simple> - Simplfy some common tasks in Perl

=head1 SYNOPSIS

	use Toolbox::Simple qw(lcm is_prime send_mail);
	
	
	$num = 7;
	if(is_prime($num)) { print("$num is prime!"); } else { print("$num is not prime."); }
	
	
	
	@nums = (3, 8, 24); 
	$lcm = lcm(@nums);    ### $lcm = 24
	

	# Send an e-mail message, with the body as a string with embedded newlines.
	$msg[0] = "Hi there Dave!";
	$msg[1] = "Just saying hi.";
	$msg[2] = "See you!";
	$message = join("\n", @msg);  # Join lines with \n's
	
	# Do the actual sending
	send_mail(
	
			'smtp.isp.com',		# SMTP server
			'dave@dave.com',	# Recipient
			'me@myhost.com',	# Sender
			'Saying hi',		# Subject
			$message			# Message body
				
	) or die("Error sending mail!");
	
	
	
=head1 DESCRIPTION

Descriptions for each available function follow.


=head2 B<c32('string')>

Attempts to calculate a checksum of sorts for its argument, and returns it.


=head2 B<send_mail('server', 'recipient', 'sender', 'subject', $string)>

Sends mail using the Net::SMTP module, with the info given. 
Addresses should be in raw "user@host.com" form, and SMTP server should accept
mail from your machine. Message body ($string) is arbitrary-length, with embedded newlines.
It is sent all at once to the SMTP server.

Returns 0 on failure.


=head2 B<md5_file("filename.foo")>

Returns the hexadecimal MD5 checksum for the specified filename.

Returns checksum on success, 0 on failure.


=head2 B<b64_encode("filename.foo", "filename.b64")>

Base64 encodes the file specified in the first argument, putting the result in a file
specified by the second argument. If no second argument is given, ".b64" is appended to the
input file's name.

Returns 0 on failure.


=head2 B<b64_decode("filename.b64", "filename.txt")>

Base64-decodes the file in the first argument, saving the decoded version in the filename 
specified by the second argument (or the input file with ".out" appended, if no second
arg is provided.)

Returns 0 on failure.


=head2 B<my_hostname()>

Returns your hostname as reported by Sys::Hostname.

Returns 0 on failure.


=head2 B<my_ip()> 

Returns your IP address (111.111.111.111) by running B<name2ip> on 
he name returned by Sys::Hostname.

Returns 0 on failure.


=head2 B<round_money('12345.678')>

Returns the argument, rounded to two decimal places (as is done with money).
In the example, "12345.67" would be returned.


=head2 B<commify_number('1000000')>

Returns the argument, with a comma every 3 places, as is common when writing large
numbers. For the example, it would return "1,000,000".


=head2 B<hex2ascii('41')>

Returns the ASCII character corresponding to the given hex number.
("A" in the example.)


=head2 B<ip2name('24.82.17.121')>

Returns the resolved name for the given IP address, or 0 on failure.


=head2 B<name2ip('h24-82-17-121.vc.shawcable.net')>

Returns the IP address corresponding to the given name, or 0 on failure.


=head2 B<fibo(number)>

Returns the (C<number>)th number in the Fibonacci sequence.


=head2 B<gcd(num, num, num)  /  gcf(num, num, num)>

Both (identical) functions return the greatest common divisor/factor
for the numbers given in their arguments.


=head2 B<lcm(num, num, num)>

Returns the lowest common multiple for the numbers in its argument.


=head2 B<is_prime(num)>

Tests a number for primeness. If it is, returns 1. If it isn't prime, returns 0.


=head2 B<dec2hex(65)>

Converts given decimal number into hexadecimal. Result in example is '41'.


=head2 B<hex2dec(1A)>

Converts given hex number into decimal. Result in example is '31'.


=head2 B<dec2bin(decimalnumber, bits)>

Converts C<decimalnumber> into a big-endian binary string consisting of C<bits>
bits total (C<bits> can be between 4 and 32).


=head2 B<bin2dec(1010)>

Converts given binary string into decimal. Returns "10" in example.


=head2 B<dec2oct()  oct2dec()>

Converts given decimal num to octal, and vice versa.


=head2 B<time_now()>

Returns the current time in format "16:20:00".


=head2 B<time_english('timeformat')>

Returns the date / time as specified by C<timeformat>.  Examples of
output with different values for C<timeformat>:

	time			16:20:00						(hh:mm:ss)
	date_short		02/22/02  						(mm/dd/yy)
	date_lf         22/02/02  						(dd/mm/yy)
	date_long		Friday, February 22, 2002
	weekday			Friday
	month			February
	year			2002
	
C<date_short> is the American way, C<date_lf> is the rest of the world...


=head1 EXPORTABLE FUNCTIONS

All functions can be exported. Specify which you want using...

	use Toolbox::Simple qw(time_english md5_file);
	
And only those will be imported.

=head1 BUGS

None that i know about.

=head1 TO DO

Add more useful things as I think of them... Send me suggestions!

=head1 AUTHOR

Jason Leane (alphamethyl@mac.com)

Copyright 2002 Jason Leane

Thanks to B<LucyFerr> for getting me out of a rut and renewing my enthusiasm for Perl
with her own brand of persevereance as she learned Perl for the first time.

I<"Now quick, what's 0xDEADBEEF in octal?">

=cut
