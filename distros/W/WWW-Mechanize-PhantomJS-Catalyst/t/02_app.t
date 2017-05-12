#! /usr/bin/perl
use warnings;
use strict;

package TestApp::Controller::Root;
use base 'Catalyst::Controller';
$INC{'TestApp/Controller/Root.pm'} = 1;

__PACKAGE__->config->{namespace} = '';

sub test :Path('test.html')
{
	my ( $self, $c) = @_;
	$c->response->header('Content-Type' => 'text/html');
	$c->response->body(<<'HTML');
<html><body>
<div id="foo">no</div>
<script type="text/javascript">
var foo = document.getElementById('foo');
foo.innerHTML = "yes";
</script>
</body></html>
HTML
}

sub error :Path('error.html')
{
	my ( $self, $c) = @_;
	$c->response->header('Content-Type' => 'text/html');
	$c->response->body(<<'HTML');
<html><body>
<script type="text/javascript">
function x()
{
unexistent_function()
}

x()
</script>
</body></html>
HTML
}

sub escape
{
	my $s = shift;
	$s =~ s/(\\)/\\$1/g;
	$s =~ s/(\n)/\\n/g;
	$s =~ s/(\r)//g;
	return $s;
}

sub form: Path('form.html')
{
	my ( $self, $c) = @_;
	$c->response->header('Content-Type' => 'text/html');
	if ( $c->request->method eq 'GET') {
		$c->response->body(<<'HTML');
<html><body><form method="post" action="form.html">
<input type="hidden"   name="a" value="a">
<textarea name="b">b</textarea>
<input type="checkbox" name="c">
<input type="checkbox" name="d" value="d">
<input type="checkbox" name="e" value="e">
<input type="checkbox" name="f" value="f" checked="on">
<input type="checkbox" name="g" value="g" checked="on">
<input type="submit"   name="submit1" value="submit1">
<input type="submit"   name="submit2" value="submit2">
</form></body></html>
HTML
	} else {
		my $p = $c->req->parameters;
		my $text = join(',', map { "'$_':'".escape($$p{$_})."'" } keys %$p);
		$c->response->body("<html><body>$text</body></text>");
	}
}

package TestApp;
use Catalyst qw/Server/;
TestApp->setup;

package Test;
use strict;
use warnings;
use Test::More tests => 9;
use Test::WWW::Mechanize::PhantomJS::Catalyst 'TestApp';

sub unescape
{
	my $s = shift;
	$s =~ s/\\n/\n/g;
	$s =~ s/\\\\/\\/g;
	return $s;
}

my $mech = Test::WWW::Mechanize::PhantomJS::Catalyst->new(
	debug => 0,
	report_js_errors => 0,
);
ok( $mech, 'Created mechanize object' );
$mech->get_ok("/test.html", "HTML page served ok");
$mech->content_contains('<div id="foo">yes</div>', 'JavaScript works');

$mech->get_ok("/error.html", "Error page ok");
ok( 1 == $mech->js_errors, "JS failed as expected");

$mech->get_ok("/form.html", "Form served ok");
$mech->submit_form_ok({with_fields=>{
	a => 'A\\',
	b => "B\n2",
	c => 1,
	d => 1,
	g => 0,
}, button => 'submit2'}, 'Form submitted ok');
my $content = $mech->content;
$content =~ s/(<.*?>|')//g;
my %p = map { split ':', unescape($_) } split ',', $content;
ok(6 == keys %p, "6 params found");
ok($p{a} eq 'A\\' && $p{b} eq "B\n2" && $p{c} eq 'on' && $p{d} eq 'd' && $p{f} eq 'f', "all params correct");
