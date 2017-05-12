
use strict;
use Test;
use XML::SAX::ParserFactory qw();
use XML::RDDL               qw();
use XML::RDDL::Resource     qw();
BEGIN {plan tests => 52}

my $rddl =<<'EORDDL';
<foo
    xml:base='http://foo/'
    xml:lang='en'
    xmlns:xlink='http://www.w3.org/1999/xlink'
    xmlns:rddl='http://www.rddl.org/'
    >

    <rddl:resource
                    id='first'
                    xlink:title='RDDL One'
                    xlink:role='http://www.rddl.org/'
                    xlink:arcrole='http://www.rddl.org/purposes#directory'
                    xlink:href='http://www.rddl.org/natures.html'
                    >
        <div />
    </rddl:resource>

    <rddl:resource
                    id='second'
                    xlink:title='RDDL Two'
                    xlink:role='http://www.rddl.org/Two'
                    xlink:arcrole='http://www.rddl.org/purposes#module'
                    xlink:href='http://www.rddl.org/modules'
                    xml:base='http://foo/two'
                    xml:lang='fr'
                    >
        <div />
    </rddl:resource>

    <div xml:lang='de' xml:base='http://bar/'>
        <rddl:resource
                        id='third'
                        xlink:title='RDDL Three'
                        xlink:role='http://www.rddl.org/Three'
                        xlink:arcrole='http://haha.org/'
                        xlink:href='http://hoho.net/natures.html'
                        />
    </div>
</foo>
EORDDL

# test the parser and the resources
my $h = XML::RDDL->new;
my $d = XML::SAX::ParserFactory->parser(Handler => $h);
my $r = $d->parse(Source => {String => $rddl });
ok($r);                                                                     # 1

my @res = $r->get_resources;
ok(@res == 3);
ok($res[0]->get_id eq 'first');
ok($res[1]->get_id eq 'second');
ok($res[2]->get_id eq 'third');                                             # 5
ok($res[0]->get_href eq 'http://www.rddl.org/natures.html');
ok($res[1]->get_href eq 'http://www.rddl.org/modules');
ok($res[2]->get_href eq 'http://hoho.net/natures.html');
ok($res[0]->get_nature eq 'http://www.rddl.org/');
ok($res[1]->get_nature eq 'http://www.rddl.org/Two');                       # 10
ok($res[2]->get_nature eq 'http://www.rddl.org/Three');
ok($res[0]->get_purpose eq 'http://www.rddl.org/purposes#directory');
ok($res[1]->get_purpose eq 'http://www.rddl.org/purposes#module');
ok($res[2]->get_purpose eq 'http://haha.org/');
ok($res[0]->get_title eq 'RDDL One');                                       # 15
ok($res[1]->get_title eq 'RDDL Two');
ok($res[2]->get_title eq 'RDDL Three');
ok($res[0]->get_base_uri eq 'http://foo/');
ok($res[1]->get_base_uri eq 'http://foo/two');
ok($res[2]->get_base_uri eq 'http://bar/');                                 # 20
ok($res[0]->get_lang eq 'en');
ok($res[1]->get_lang eq 'fr');
ok($res[2]->get_lang eq 'de');

# test the Resource on its own
my $nr = XML::RDDL::Resource->new(
                                    id          => 'new',
                                    base_uri    => 'http://new/',
                                    href        => 'http://foo-new/',
                                    nature      => 'newness',
                                    purpose     => 'test',
                                    title       => 'RDDL New',
                                    lang        => 'oz',
                                 );
ok($nr->get_id eq 'new');
eval { $nr->set_id('newnew') };
ok(not $@);                                                                 # 25
ok($nr->get_id eq 'newnew');

ok($nr->get_base_uri eq 'http://new/');
eval { $nr->set_base_uri('http://newnew/') };
ok(not $@);
ok($nr->get_base_uri eq 'http://newnew/');

ok($nr->get_href eq 'http://foo-new/');                                     # 30
eval { $nr->set_href('http://foo-newnew/') };
ok(not $@);
ok($nr->get_href eq 'http://foo-newnew/');

ok($nr->get_nature eq 'newness');
eval { $nr->set_nature('newnessnew') };
ok(not $@);
ok($nr->get_nature eq 'newnessnew');                                        # 35

ok($nr->get_purpose eq 'test');
eval { $nr->set_purpose('testnew') };
ok(not $@);
ok($nr->get_purpose eq 'testnew');

ok($nr->get_title eq 'RDDL New');
eval { $nr->set_title('RDDL NewNew') };
ok(not $@);                                                                 # 40
ok($nr->get_title eq 'RDDL NewNew');

ok($nr->get_lang eq 'oz');
eval { $nr->set_lang('oz-new') };
ok(not $@);
ok($nr->get_lang eq 'oz-new');

# test the Directory
$r->add_resource($nr);
ok($r->get_resources == 4);                                                 # 45
$r->delete_resource($res[1]);
ok($r->get_resources == 3);
my $r3 = $r->get_resource_by_id('third');
ok($r3);
ok($r3->get_title eq 'RDDL Three');
my @n = $r->get_resources_by_nature('http://www.rddl.org/');
ok(@n == 1);
ok($n[0]->get_id eq 'first');                                               # 50
my @p = $r->get_resources_by_purpose('testnew');
ok(@p == 1);
ok($p[0]->get_id eq 'newnew');                                              # 52


