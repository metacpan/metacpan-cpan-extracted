use Test::More tests => 72;
use strict;
use warnings;

BEGIN {
    diag('Module loading');
    use_ok( 'XML::LibXML::Fixup'); 
}
require_ok( 'XML::LibXML::Fixup');

my $v = XML::LibXML::Fixup->new();
ok(!$v->throw_exceptions(0), 'throw_exceptions off');
isa_ok($v, 'XML::LibXML::Fixup');

diag('Checking method existence');
can_ok($v, 'valid');
can_ok($v, 'fixed_up');
can_ok($v, 'add_fixup');
can_ok($v, 'clear_fixups');

can_ok($v, 'throw_exceptions');
can_ok($v, 'get_errors');
can_ok($v, 'first_error');
can_ok($v, 'next_error');


diag('XML::LibXML method inheritance');
isa_ok($v, 'XML::LibXML');
can_ok($v, 'get_last_error');
can_ok($v, 'parse_string');
can_ok($v, 'validation');
 TODO: {
     local $TODO = "parsing files not yet implemented";
     can_ok($v, 'parse_fh');
     can_ok($v, 'parse_file');
     can_ok($v, 'parse_html_fh');
     can_ok($v, 'parse_html_file');
     can_ok($v, 'parse_html_string');
 }

my $xml;

diag('Testing with first valid XML file');
open FOOTY,"<sampleXML/footballnews.xml" or die("couldn't open");
{
    local $/ = undef;
    $xml = <FOOTY>;
}
close FOOTY;

$v->validation(0);
$v->parse_string($xml);
ok($v->valid(), 'footballnews.xml parses');
ok(!$v->next_error(), 'no parse errors in next_error');
ok(!$v->get_last_error(), 'no parse errors in get_last_error');

$v->validation(1);
$v->parse_string($xml);
ok($v->valid(), 'footballnews.xml validates');
ok(!$v->next_error(), 'no validation errors in next_error');
ok(!$v->get_last_error(), 'no validation errors in get_last_error');

diag('Testing with second valid XML file');
open FOOTY,"<sampleXML/footballlatestnews.xml" or die("couldn't open");
{
    local $/ = undef;
    $xml = <FOOTY>;
}
close FOOTY;

$v->validation(0);
$v->parse_string($xml);
ok($v->valid(), 'footballlatestnews.xml parses');
ok(!$v->next_error(), 'no parse errors in next_error');
ok(!$v->get_last_error(), 'no parse errors in get_last_error');
ok(!$v->fixed_up(), 'no fixups applied');

$v->validation(1);
$v->parse_string($xml);
ok($v->valid(), 'footballlatestnews.xml validates');
ok(!$v->next_error(), 'no validation errors in next_error');
ok(!$v->get_last_error(), 'no validation errors in get_last_error');
ok(!$v->fixed_up(), 'no fixups applied');

diag('Testing with first invalid XML file');
open FOOTY,"<sampleXML/badfootballnews.xml" or die("couldn't open");
{
    local $/ = undef;
    $xml = <FOOTY>;
}
close FOOTY;

$v->validation(0);
$v->parse_string($xml);
ok($v->valid(), 'badfootballnews.xml parses');
ok(!$v->next_error(), 'no parse errors in next_error');
ok(!$v->get_last_error(), 'no parse errors in get_last_error');
ok(!$v->fixed_up(), 'no fixups applied');

$v->validation(1);
$v->parse_string($xml);
ok(!$v->valid(), 'badfootballnews.xml doesn\'t validate');
ok($v->next_error(), 'validation errors exist in next_error');
ok($v->get_last_error(), 'validation errors exist in get_last_error');
$v->first_error();
ok($v->next_error(), 'still exist in next_error');
$v->first_error();
ok($v->next_error(), 'really, really exist in next_error!');
ok(!$v->next_error(), 'but now they don\'t');
ok(!$v->fixed_up(), 'no fixups applied');

diag('Fixing first bad XML file');
$v->add_fixup('s#<wrong-tag/>##gs', 'removing <wrong_tag/>');
$v->add_fixup('s#<wrong-tag/>##gs', 'removing <wrong_tag/>');
$v->add_fixup('s#<wrong-tag/>##gs', 'removing <wrong_tag/>');
$v->validation(0);
$v->parse_string($xml);
ok($v->valid(), 'badfootballnews.xml parses');
ok(!$v->next_error(), 'no parse errors in next_error');
ok(!$v->get_last_error(), 'no parse errors in get_last_error');
ok(!$v->fixed_up(), 'no fixups applied');

$v->validation(1);
$v->parse_string($xml);
ok($v->valid(), 'badfootballnews.xml validates');
ok($v->next_error(), 'validation errors exist in next_error');
ok($v->get_last_error(), 'validation errors exist in get_last_error');
ok($v->fixed_up(), 'fixups have been applied');
$v->clear_fixups();
ok(!$v->fixed_up(), 'fixups have been cleared');

diag('Testing with second invalid XML file');
open FOOTY,"<sampleXML/badfootballlatestnews.xml" or die("couldn't open");
{
    local $/ = undef;
    $xml = <FOOTY>;
}
close FOOTY;

$v->add_fixup('s#<wrong-tag/>##gs', 'removing <wrong_tag/>');
$v->add_fixup('s#<wrong-tag/>##gs', 'removing <wrong_tag/>');
$v->add_fixup('s#<wrong-tag/>##gs', 'removing <wrong_tag/>');
ok(!$v->throw_exceptions(), 'throw_exceptions off');
ok($v->throw_exceptions(1), 'throw_exceptions on');
$v->validation(0);
eval{$v->parse_string($xml)};
ok(!$v->valid(), 'badfootballlatestnews.xml doesn\'t parse');
ok($@, '$@ has been set');
ok($v->next_error(), 'parse errors exist');
ok(!$v->fixed_up(), 'no fixups applied');

$v->validation(1);
eval{$v->parse_string($xml)};
ok(!$v->valid(), 'badfootballlatestnews.xml doesn\'t validate');
ok($@, '$@ has been set');
ok($v->next_error(), 'validation errors exist in next_error');
ok(!$v->fixed_up(), 'no fixups applied');
$v->clear_fixups();

diag('Fixing second bad XML file');
$v->add_fixup('s#</para>#</Para>#gs', 'fixing lower-case </para> tags');
$v->add_fixup('s#<wrong-tag/>##gs', 'removing <wrong_tag/>');
$v->add_fixup('s#<wrong-tag/>##gs', 'removing <wrong_tag/>');
$v->add_fixup('s#<wrong-tag/>##gs', 'removing <wrong_tag/>');
$v->validation(0);
$v->parse_string($xml);
ok($v->valid(), 'badfootballlatestnews.xml parses');
ok($v->get_last_error(), 'parse errors exist');
is(scalar $v->fixed_up(),1, 'one fixup has been applied');
$v->clear_fixups();
ok(!$v->fixed_up(), 'fixups have been cleared');

$v->add_fixup(sub{
    my $xml = shift;
    $xml =~ s!(</?)para>!$1Para>!gs;
    return $xml;
}, 'upper-case para tags');
$v->add_fixup('s#</?foobar/?>##sig', 'removing <foobar> tags');
$v->validation(1);
$v->parse_string($xml);
ok($v->valid(), 'badfootballlatestnews.xml validates');
ok($v->get_last_error(), 'validation errors exist');
is(scalar $v->fixed_up(),2, 'two fixups have been applied');
