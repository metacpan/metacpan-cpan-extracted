use Test;
$Test::Harness::verbose = 1;

BEGIN { plan tests => 12, todo => [2,3,6,8] }

use Toolbox::Simple qw(md5_file my_hostname round_money commify_number hex2ascii ip2name name2ip fibo gcd gcf lcm is_prime dec2hex hex2dec dec2bin bin2dec dec2oct oct2dec time_now time_english);

ok(hex2dec('20'), oct2dec('40'));		# Make sure bases are loaded

ok(hex2dec('FF'), hex2dec('0A'));		# FAIL (but aren't all returning 0)


ok(100000, commify_number('100000'));	# FAIL (and commas work)


ok(is_prime(3), is_prime(29));			# Bignums, I know.

										# Intel Inside (tm)
ok(round_money('100.014'), round_money('100.013'));
ok(round_money('100.014'), round_money('100.015'));

										# Hash test dummies...
										
open(TST, ">temp"); print(TST "Hello!\nI like hash!\n"); close(TST);
open(TSTT, ">temp2"); print(TSTT "Hello!\nI like hash!\n"); close(TSTT);

										# Non-brain-damage mode assumed
ok(md5_file('temp'), md5_file('temp2'));

unlink('temp', 'temp2');				# Clean up mess

ok(length(my_hostname), 0);				# nslookup ergo sum
										
ok(1, fibo(2));							# Amazing Science!

ok(bin2dec('1010'), 10);				# Obfuscation...  ** 12 **

ok(hex2ascii('41'), "A");				# Alienating freakish locales...

ok(time_now, time_english('time'));		# Vitally important, of course.