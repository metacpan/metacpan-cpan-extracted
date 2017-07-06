#===============================================================================
#
#  DESCRIPTION:  Test lexer
#
#       AUTHOR:  Aliaksandr P. Zahatski, <zag@cpan.org>
#===============================================================================

package main;
#use Test::More tests => 1;    # last test to print
use Test::More no_plan;    # last test to print
use WebDAO::Lex;
use Data::Dumper;

my $l2 = new WebDAO::Lex::;
my $ts = $l2->split_template(<<TMP);
test
<!-- <wd:fetch> -->
s
<!-- </wd:fetch> -->
sd
TMP
is scalar(@$ts), 3, 'split_template: 3 parts';
$ts = $l2->split_template(<<TMP);
test
TMP
is scalar(@$ts), 3, 'split_template: 1 parts';

$ts = $l2->split_template(<<TMP);
test1
<!-- <wd:fetch> -->
test2
TMP
is scalar(@$ts), 3, 'split_template: 2 parts';


my $p = new WebDAO::Lex::;
ok $p,'create lex'; 
isa_ok $p->parse('<wd><regclass class="ArtPers::Comp::LinkAuth" alias="link_auth"/></wd>')->[0], 'WebDAO::Lexer::regclass';
isa_ok $p->parse('<wd><method path="/page/menu"/></wd>')->[0], 'WebDAO::Lexer::method';
isa_ok $p->parse('<wd><object class="registr" id="reg" /></wd>')->[0], 'WebDAO::Lexer::object';
my $r = $p->parse(<<TXT);
<wd><object class="isauth" id="auth_switch">
      <auth> 
        <object class="comp_unauth" id="ExitCP"/>
      </auth>
    </object></wd>
TXT
is_deeply  $r->[0]->attr, {
           'id' => 'auth_switch',
           'class' => 'isauth'
         }, 'check attr';


BEGIN {
    use_ok('WebDAO::SessionSH');
    use_ok('WebDAO::Engine');
    use_ok('WebDAO::Container');
    use_ok('WebDAO::Test');
}

my $ID = "extra";
ok my $session = ( new WebDAO::SessionSH::),
  "Create session";
$session->U_id($ID);

my $eng = new WebDAO::Engine:: session => $session;
our $tlib = new WebDAO::Test eng => $eng;

$eng->register_class(
    'WebDAO::Container' => 'isw',
    'TestTraverse'      => 'traverse',
    'TestContainer'     => 'testcont'
);


my $p = new WebDAO::Lex:: 'tmpl'=><<TXT;
<object class="isauth" id="auth_switch">
<!-- <wd:fetch> -->
<wd><regclass class="WebDAO::Container" alias="isauth"/>
<object class="isauth" id="auth_switch"/></wd>
<!-- </wd:fetch> -->
<object class="isauth" id="auth_switch">
TXT

my ($p1, $f, $b ) = @{$p->split_template($p->{tmpl})}; 
isa_ok $p->buld_tree($eng, $f, )->[0], 'WebDAO::Container';
my $p1 = new WebDAO::Lex::(tmpl=><<TXT);
test
<!-- <wd:fetch> -->
ss
<!-- </wd:fetch> -->
s
TXT

