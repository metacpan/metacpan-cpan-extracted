# $Id: xmlxpath_09a_string_length.t,v 1.1.1.1 2003/12/04 20:40:43 mrodrigu Exp $

use Test;

plan ( tests => 6); 

use XML::DOM::XPath;
ok(1);

my $doc_one = qq|<doc><para>para one</para></doc>|;

my $parser= XML::DOM::Parser->new;
my $t= $parser->parse( $doc_one); 

ok( $t);

my $doc_one_chars = $t->find( 'string-length(/doc/text())');
ok($doc_one_chars == 0, 1);

my $doc_two = qq|
<doc>
  <para>para one has <b>bold</b> text</para>
</doc>
|;

$t= $parser->parse( $doc_two);
ok( $t);

my $doc_two_chars = $t->find( 'string-length(/doc/text())');
ok($doc_two_chars == 3, 1);

my $doc_two_para_chars = $t->find( 'string-length(/doc/para/text())');
ok($doc_two_para_chars == 13, 1);

