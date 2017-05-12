
use strict;
use Test;
use XML::RDDL::Driver       qw();
use XML::RDDL::Resource     qw();
use XML::RDDL::Directory    qw();
BEGIN {plan tests => 53}


package RDDLTestHandler;
use Test;

sub new { return bless []; }
sub start_document { ok(1) };
sub end_document { ok(1) };
sub start_prefix_mapping {
    shift;
    my $pm = shift;
    ok(1) if $pm->{Prefix} eq 'rddl' and $pm->{NamespaceURI} eq $XML::RDDL::Driver::NS_RDDL;    # 1
    ok(1) if $pm->{Prefix} eq 'xlink' and $pm->{NamespaceURI} eq $XML::RDDL::Driver::NS_XLINK;
}
sub end_prefix_mapping {
    shift;
    my $pm = shift;
    ok(1) if $pm->{Prefix} eq 'rddl' and $pm->{NamespaceURI} eq $XML::RDDL::Driver::NS_RDDL;
    ok(1) if $pm->{Prefix} eq 'xlink' and $pm->{NamespaceURI} eq $XML::RDDL::Driver::NS_XLINK;
}
sub start_element {
    shift;
    my $e = shift;
    ok($e->{Name} eq 'rddl:resource');                                                          # 5
    ok($e->{LocalName} eq 'resource');
    ok($e->{Prefix} eq 'rddl');
    ok($e->{NamespaceURI} eq $XML::RDDL::Driver::NS_RDDL);

    for my $at (values %{$e->{Attributes}}) {
        if ($at->{Name} eq 'id') {
            ok(1);
            ok($at->{LocalName} eq 'id');                                                       # 10
            ok($at->{Prefix} eq '');
            ok($at->{NamespaceURI} eq '');
            ok($at->{Value} eq 'test-id');
        }
        elsif ($at->{Name} eq 'xml:base') {
            ok(1);
            ok($at->{LocalName} eq 'base');                                                     # 15
            ok($at->{Prefix} eq 'xml');
            ok($at->{NamespaceURI} eq $XML::RDDL::Driver::NS_XML);
            ok($at->{Value} eq 'test-uri');
        }
        elsif ($at->{Name} eq 'xml:lang') {
            ok(1);
            ok($at->{LocalName} eq 'lang');                                                     # 20
            ok($at->{Prefix} eq 'xml');
            ok($at->{NamespaceURI} eq $XML::RDDL::Driver::NS_XML);
            ok($at->{Value} eq 'test-lang');
        }
        elsif ($at->{Name} eq 'xlink:href') {
            ok(1);
            ok($at->{LocalName} eq 'href');                                                     # 25
            ok($at->{Prefix} eq 'xlink');
            ok($at->{NamespaceURI} eq $XML::RDDL::Driver::NS_XLINK);
            ok($at->{Value} eq 'test-href');
        }
        elsif ($at->{Name} eq 'xlink:role') {
            ok(1);
            ok($at->{LocalName} eq 'role');                                                     # 30
            ok($at->{Prefix} eq 'xlink');
            ok($at->{NamespaceURI} eq $XML::RDDL::Driver::NS_XLINK);
            ok($at->{Value} eq 'test-nature');
        }
        elsif ($at->{Name} eq 'xlink:arcrole') {
            ok(1);
            ok($at->{LocalName} eq 'arcrole');                                                  # 35
            ok($at->{Prefix} eq 'xlink');
            ok($at->{NamespaceURI} eq $XML::RDDL::Driver::NS_XLINK);
            ok($at->{Value} eq 'test-purpose');
        }
        elsif ($at->{Name} eq 'xlink:title') {
            ok(1);
            ok($at->{LocalName} eq 'title');                                                    # 40
            ok($at->{Prefix} eq 'xlink');
            ok($at->{NamespaceURI} eq $XML::RDDL::Driver::NS_XLINK);
            ok($at->{Value} eq 'test-title');
        }
    }
}
sub end_element {
    shift;
    my $e = shift;
    ok($e->{Name} eq 'rddl:resource');
    ok($e->{LocalName} eq 'resource');                                                          # 45
    ok($e->{Prefix} eq 'rddl');
    ok($e->{NamespaceURI} eq $XML::RDDL::Driver::NS_RDDL);
}

package main;

my $nr = XML::RDDL::Resource->new(
                                    id          => 'test-id',
                                    base_uri    => 'test-uri',
                                    href        => 'test-href',
                                    nature      => 'test-nature',
                                    purpose     => 'test-purpose',
                                    title       => 'test-title',
                                    lang        => 'test-lang',
                                 );
ok($nr);
my $dir = XML::RDDL::Directory->new;
ok($dir);
$dir->add_resource($nr);

my $h = RDDLTestHandler->new;
ok($h);                                                                                         # 50
my $d = XML::RDDL::Driver->new(Handler => $h);
ok($d);                                                                                         # 51 (??)
$d->parse($dir);

