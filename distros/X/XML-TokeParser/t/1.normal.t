# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'
#print "#",q[],"\n";
#print "#",q[],"\n";
#print "#",q[],"\n";

use Test;
BEGIN { plan tests => 34, todo => [] }

use XML::TokeParser;

ok(1);

#parse from file
my $p = XML::TokeParser->new('TokeParser.xml');

ok($p);

my @tokens = (
          [
            'S',
            qq[\Q<pod xmlns="http://axkit.org/ns/2000/pod2xml">]
          ],
          [
            'T',
            '\s+'
          ],
          [
            'S',
            qq[\Q<head>]
          ],
          [
            'T',
            '\s+'
          ],
          [
            'S',
            qq[\Q<title>]
          ],
          [
            'T',
            qq[\QXML::TokeParser - Simplified interface to XML::Parser]
          ],
          [
            'E',
            qq[\Q</title>]
          ],
          [
            'T',
            '\s+'
          ],
          [
            'E',
            qq[\Q</head>]
          ],
          [
            'T',
            '\s+'
          ],
          [
            'S',
            qq[\Q<sect1>]
          ],
          [
            'T',
            '\s+'
          ],
          [
            'S',
            qq[\Q<title>]
          ],
          [
            'T',
            qq[\QSYNOPSIS]
          ],
          [
            'E',
            qq[\Q</title>]
          ],
          [
            'T',
            '\s+'
          ],
          [
            'S',
            qq[\Q<verbatim>]
          ],
          [
            'T',
            qq[\Quse XML::TokeParser;]
          ],
          [
            'E',
            qq[\Q</verbatim>]
          ],
          [
            'T',
            '\s+'
          ]
);


for( 0.. $#tokens ) {
    my $token = $p->get_token();
    ok(2+$_) if $tokens[$_][0] eq $token->[0] and $token->[-1] =~ m{$tokens[$_][1]};
}

print "#",q[],"\n";
print "#",q[ Now testing get_tag, get_trimmed_text],"\n";
ok( $p->get_tag('title') );
print "#",q[$p->get_tag('title')],"\n";

ok( $p->get_trimmed_text('/title') eq 'DESCRIPTION' );
print "#",q[$p->get_trimmed_text('/title')],"\n";

ok( $p->get_tag('item') );
print "#",q[$p->get_tag('item')],"\n";

ok( $p->get_tag('itemtext') );
print "#",q[$p->get_tag('itemtext')],"\n";

ok( $p->get_trimmed_text('/itemtext') eq 'Start tag' );
print "#",q[$p->get_trimmed_text('/itemtext')],"\n";

print "#",q[],"\n";
print "#",q[ Now testing saving tokens so you can go return to this point in the stream],"\n";
ok( not $p->begin_saving() );
print "#",q[$p->begin_saving() ],"\n";

ok( $p->get_tag('para') );
print "#",q[$p->get_tag('para') 1],"\n";

ok( $p->get_tag('para') );
print "#",q[$p->get_tag('para') 2],"\n";

ok( $p->restore_saved() );
print "#",q[$p->restore_saved()],"\n";

print "#",q[],"\n";
print "#",q[ Now to see if we've backed up correctly (i think so)],"\n";
ok( $p->get_tag('para') );
print "#",q[$p->get_tag('para') 1],"\n";
ok( $p->get_tag('para') );
print "#",q[$p->get_tag('para') 2],"\n";

ok( $p->get_trimmed_text('/para') eq "The token has three elements: 'E', the element's name, and the literal text." );

#use Data::Dumper;die Dumper(  );
#push @tokens, $p->get_token() for 1..10;use Data::Dumper;die Dumper\@tokens;
