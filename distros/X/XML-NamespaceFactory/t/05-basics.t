
use Test;
BEGIN { plan tests => 8 };
use XML::NamespaceFactory;
ok(1); 

my $ns = "http://foo.org/ns/";
my $FOO = XML::NamespaceFactory->new($ns);
ok(1);

ok( $ns eq "$FOO" );
ok( $ns eq $FOO );
ok( "hahaha" ne "$FOO" );
ok( "hahaha" ne $FOO );

ok( $FOO->title eq "{$ns}title" );
ok( $FOO->{'bar.baz-toto'} eq "{$ns}bar.baz-toto" );
