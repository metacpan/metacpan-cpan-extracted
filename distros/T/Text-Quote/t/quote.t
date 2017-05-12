use Test::More tests => 52;
use strict;
use warnings;
use vars qw/$Class $quoter/;
BEGIN {
	$Class="Text::Quote";
	use_ok( $Class );
}

sub clean {
	my $here=shift;
	chomp $here;
	$here=~s/^\t//gm;
	return $here;
}

$quoter=Text::Quote->new();
isa_ok($quoter, $Class);
my $binary=join("",map chr,0..31);
my $all=join("",map chr,0..255);
my $long=$all x 100;
my $repeat="abcdefg"x 20;
{
	my ($qq,$qbegin,$qend,$needs_type)=$quoter->best_quotes('"Abracadabra"');
	is($qq.$qbegin.$qend.$needs_type,"q''0","best_quotes 1");
    ($qq,$qbegin,$qend,$needs_type)=$quoter->best_quotes(q!'"Abracadabra"'!);
	is($qq.$qbegin.$qend.$needs_type,"q//1","best_quotes 2");

    is($quoter->quote($binary),clean(<<'	EOTEST'),"Binary Escape");
	"\0\1\2\3\4\5\6\a\b\t\n\13\f\r\16\17\20\21\22\23\24\25\26\27\30\31\32\e\34\35".
	"\36\37"
	EOTEST

	#print $quoter->quote($binary.$binary),"\n";
	is($quoter->quote($binary.$binary),clean(<<'	EOTEST'),"Binary pack");
	pack('H*','000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f00'.
	'0102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f')
	EOTEST

	#print $quoter->quote($all),"\n";
    is($quoter->quote($all),clean(<<'	EOTEST'),"base64 All");
	Text::Quote->decode64('AAECAwQFBgcICQoLDA0ODxAREhMUFRYXGBkaGxwdHh8gISIjJCUmJy'.
	'gpKissLS4vMDEyMzQ1Njc4OTo7PD0+P0BBQkNERUZHSElKS0xNTk9QUVJTVFVWV1hZWltcXV5fYG'.
	'FiY2RlZmdoaWprbG1ub3BxcnN0dXZ3eHl6e3x9fn+AgYKDhIWGh4iJiouMjY6PkJGSk5SVlpeYmZ'.
	'qbnJ2en6ChoqOkpaanqKmqq6ytrq+wsbKztLW2t7i5uru8vb6/wMHCw8TFxsfIycrLzM3Oz9DR0t'.
	'PU1dbX2Nna29zd3t/g4eLj5OXm5+jp6uvs7e7v8PHy8/T19vf4+fr7/P3+/w==')
	EOTEST

	#print $quoter->quote($long),"\n";
	is($quoter->quote($long),clean(<<'	EOTEST'),"Long");
	Text::Quote->decompress64('eJztz9dCCAAAQNFSaCChQRqEopQiJRoyk7Q0kBKVkQiJVBrIbF'.
	'AUlXYymnYUaVmVMlP2jrKirT7C6z1/cAQE+wgJ9+3XX0RUTHzAwEESgyWHDB0mJS0jO3yE3Eh5BU'.
	'WlUaOVx4wdp6I6foKa+kQNzUla2pOn6EzV1ZumP32GgaGR8UyTWbPnzJ0333SB2ULzRRaWVtY2i2'.
	'3t7B2WLF3muNzJeYXLylWubu6r16xd57Hec8NGr02bt3hv9dm23XeHn3/AzsCg4JBdu/eE7t23/8'.
	'DBQ2HhEZGHj0RFHz0WE3v8RFx8wsnEpOSU1LT0jFOZp8+cPZeVnZObl3/+wsVLl69cLbh2vbDoxs'.
	'3iWyWlZeUVt+/cvXe/sqr6QU3tw0ePnzx9Vve8vuHFy1ev37x99/7Dx0+fvzR+/dbU/P3Hz1+/W/'.
	'78bW1r7+js6v7XI8CfP3/+/Pnz58+fP3/+/Pnz58+fP3/+/Pnz58+fP3/+/Pnz58+fP3/+/Pnz58'.
	'+fP3/+/Pnz58+fP3/+/Pnz58+fP3/+/Pnz58+fP3/+/Pnz58+fP3/+/Pnz58+fP3/+/Pnz58+fP3'.
	'/+/Pnz58+f/3/8ewF0f9Dg')
	EOTEST
    is($quoter->quote($repeat),"('abcdefg' x 20)","Repeat Pattern");
    # Numbers
    is($quoter->quote(0),"0","Quote Number - 0");
    is($quoter->quote('00'),"'00'","Quote Number - '00'"); #special case!
    is($quoter->quote(1),"1","Quote Number - 1");
    is($quoter->quote(10),"10","Quote Number - 10");
    is($quoter->quote(100),"100","Quote Number - 100");
    is($quoter->quote(1000),"1000","Quote Number - 1000");
    is($quoter->quote(22/7),"".(22/7),"Quote Number - 22/7 = ".(22/7));

    my $x=-10;
    my $y=11;
    while ($x<11) {
    	is($quoter->quote($x/$y),"".($x/$y),"Quote Fraction : $x/$y =".($x/$y));
    	$x++;
    	$y=7 unless --$y;
    }

    is($quoter->quote(undef),"undef","Quote undef");

    # the serialization (aka stringification) format for regexps
    # changed in 5.14.0, so this test is slightly different for
    # older / newer versions of Perl
    if ($] < 5.014) {
        is($quoter->quote_regexp(qr/ABCDEF/),'qr/ABCDEF/',"Quote Regexp");
    }
    else {
        is($quoter->quote_regexp(qr/ABCDEF/),'qr/(?^:ABCDEF)/',"Quote Regexp");
    }

}
{
	$quoter->quote_prop("key_quote","0");
	is($quoter->quote_key('+a'),"+a","Never quote key.");
	$quoter->quote_prop("key_quote","1");
	is($quoter->quote_key('a'),"'a'","Always quote key.");
	$quoter->quote_prop("key_quote","auto");
	is($quoter->quote_key('+a'),"'+a'","Auto quote key (needs quote +a).");
	is($quoter->quote_key('1a'),"'1a'","Auto quote key (needs quote 1a).");
	is($quoter->quote_key('a-a'),"'a-a'","Auto quote key (needs quote a-a).");
	is($quoter->quote_key('.'),"'.'","Auto quote key (needs quote .).");
	is($quoter->quote_key('-a'),"-a","Auto quote key (no quote -a).");
	is($quoter->quote_key('a'),"a","Auto quote key (no quote a).");
	is($quoter->quote_key('a1'),"a1","Auto quote key (no quote a1).");
	is($quoter->quote_key('a1a'),"a1a","Auto quote key (no quote a1a).");
	is($quoter->quote_key('_a1a'),"_a1a","Auto quote key (no quote _a1a).");
	is($quoter->quote_key('1'),"1","Auto quote key (no quote 1).");
}

{
	my @quotes=map{Text::Quote->quote($_,indent=>6,col_width=>60)}('"The time has come"
	the	walrus said,
	"to speak of many things..."',"\0\1\2\3\4\5\6\a\b\t\n\13\f\r\16\17\20\21\22\23\24\25\26\27\30\31\32\e\34\35".
	"\36\37",("\6\a\b\t\n\13\f\r\32\e\34" x 5),2/3,10,'£20','00',);
	my $res;
	for my $i (1..@quotes) {
		$res.= "\$var$i=".$quotes[$i-1].";\n";
	}
	is($res,<<'',"Multi test");
$var1=qq'"The time has come"\n\tthe\twalrus said,\n\t"to speak of man'.
      qq'y things..."';
$var2="\0\1\2\3\4\5\6\a\b\t\n\13\f\r\16\17\20\21\22\23\24\25\26\27".
      "\30\31\32\e\34\35\36\37";
$var3=("\6\a\b\t\n\13\f\r\32\e\34" x 5);
$var4=0.666666666666667;
$var5=10;
$var6='£20';
$var7='00';

}
