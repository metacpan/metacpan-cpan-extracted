use Test::Simple 'no_plan';
use Cwd;
use strict;
use warnings;
use lib './lib';
use WWW::Autosite qw(:handler :feed);
use Smart::Comments '###';
use Pod::Html;


$ENV{DOCUMENT_ROOT} = cwd().'/public_html';
$ENV{AUTOSITE_TMPL} = cwd().'/public_html/.tmpl';# set some stuff
my $_abs_content = cwd().'/public_html/tmp/test.pod';# control
my $_abs_sgc = "$_abs_content.html"; #control
@ARGV = ($_abs_content);



ok( handler_filename() eq 'pod.html.t',"handler_filename()");



my ($content_ext, $sgc_ext) = handler_exts();
ok($content_ext eq 'pod');
ok($sgc_ext eq 'html');

my $abs_content = handler_content();
ok($abs_content);
ok($abs_content eq $_abs_content);

my $abs_sgc = handler_sgc();
ok($abs_sgc);
ok($abs_sgc eq $_abs_sgc);

unlink $abs_sgc;


my $tmpl = handler_tmpl();
ok($tmpl,'handler_tmpl()');


ok( feed_META($tmpl,$abs_content) );
ok( feed_ENV($tmpl) );
ok( feed_FILE($tmpl,$abs_content));


feed_POD($tmpl,$abs_content);

# write it
ok( handler_write_sgc($tmpl));







sub feed_POD {
	my $tmpl = shift;	
	my $abs_content = shift;
	
	my $command = qq{pod2html --infile=$abs_content}; # WORKS for LINKING
	my $page = `$command`;
	$page=~/<body[^>]*>(.+)<\/body>/si or die('cant match body'); # rip junk out, die? just return error instead?
	my $body = $1;

	$tmpl->param( BODY => $body ); 
	
	return $tmpl;
}



