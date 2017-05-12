#
# Win32::Watir - test.
#

use Test::More 'no_plan';
BEGIN {
	$| = 1;
	use_ok('Win32::Watir');
};

#########################

use Win32::Watir;

my $codepage = undef;
   $codepage = 'utf8' if (exists($ENV{CYGWIN}));
my $ie = Win32::Watir->new(
	visible => 1,
	maximize => 1,
	warnings => 1,
	codepage => $codepage,
);

## clear cookie and cache.
ok  ($ie->delete_cookie() >= 0, 'delete_cookie() method.');
ok  ($ie->delete_cache()  >= 0, 'delete_cache() method.');

## WinActivate
sleep 3;
$ie->bring_to_front;
sleep 3;

## Google
$ie->goto('http://www.google.co.jp/');
sleep 3;
is  ($ie->URL, 'http://www.google.co.jp/', 'goto www.google.co.jp');

$ie->text_field('name:', 'q')->SetValue('Perl Win32::Watir');
$ie->button('name:', "btnG")->click;
ok  ($ie->URL =~ /\&q=Perl/i, 'google search');

my $i = 1;
foreach my $link ( $ie->getAllLinks() ){
	if ($link->class eq 'l'){
		print "# ($i) [text:".$link->text."] [href:".$link->href."]\n";
		$i++;
	}
}
ok  ($i > 1, 'parse google search result');

END {
	$ie->close() if (ref($ie) eq 'Win32::Watir');
}
