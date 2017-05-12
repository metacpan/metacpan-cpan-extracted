use Test::Simple 'no_plan';
use Cwd;
use strict;
use warnings;
use lib './lib';
use WWW::Autosite qw(:all);
use Smart::Comments '###';
WWW::Autosite::DEBUG = 1;
use constant DEBUG=>1;
my $cwd = cwd;
$ENV{DOCUMENT_ROOT} = cwd().'/public_html';

my $abs_content = cwd().'/public_html/tmp/test.pod';# control

my $tmpl;
ok( $tmpl = handler_tmpl());


my $hash = WWW::Autosite::_path_to_hash($abs_content);
## $hash


# test router's ability to find handler

my $script_dir = cwd().'/cgi-bin/autosite';

my $tdir = "$cwd/public_html/tmp";

my $testfile = {
"$tdir/test.cgi.html" => "$script_dir/pod.html.pl",

"$tdir/test.css.html" => "$script_dir/text.html.pl",
"$tdir/test.txt.html" => "$script_dir/text.html.pl",

"$tdir/test.pod.hi"	 => "$script_dir/text.hi.pl",
"$tdir/test.css.hi"   => "$script_dir/text.hi.pl",

"$tdir/test.pod.html" => "$script_dir/pod.html.pl",   


"$tdir/test.jpg.html" => "$script_dir/image.html.pl",
"$tdir/image.duh.html"=> "$script_dir/image.html.pl", # real image with faux ext

#"$tdir/test.jpg.im10" => "$script_dir/image.im_.pl", # image magic
"$tdir/test.jpg.im10b" => 0,


};


for (keys %$testfile){
	my $sgc_request = $_;
	my $control_handler = $testfile->{$_};
	
	my $handler = request_has_handler($sgc_request,$script_dir);
	$handler ||=0;
	
	
	
	ok($handler eq $control_handler, "request:[$sgc_request]"); 
	print STDERR "\t-sgc_request      : $sgc_request\n" if DEBUG;
	print STDERR "\t-returned handler : $handler\n" if DEBUG;
	print STDERR "\t-control handler  : $control_handler\n\n" if DEBUG;

	

}
