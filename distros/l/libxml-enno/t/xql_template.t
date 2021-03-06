BEGIN {print "1..2\n";}
END {print "not ok 1\n" unless $loaded;}
use XML::XQL;
use XML::XQL::DOM;
use XML::XQL::Debug;
$loaded = 1;
print "ok 1\n";

my $test = 1;
sub assert_ok
{
    my $ok = shift;
    print "not " unless $ok;
    ++$test;
    print "ok $test\n";
    $ok;
}

sub assert_output
{
    my $str = shift;
    $^W=0;
    my $data = join('',<DATA>);
#print "{{$data}}\n{{$str}}\n";
    assert_ok ($str eq $data);
}
#Test 2

$dom = new XML::DOM::Parser;
my $str = <<END;
<DATA>
<DATE>1993-02-14</DATE>
<CKL cklAttr="cklAttrVal1">
<CKLID>P001</CKLID>
<SEGMENT> </SEGMENT>
<COUNTRY>USA</COUNTRY>
<LOCALCONTACT>
<ADDRESS>HNLLHIWP</ADDRESS>
</LOCALCONTACT>
</CKL>
<CKL cklAttr="cklAttrVal2">
<CKLID>0002</CKLID>
<SEGMENT> </SEGMENT>
<COUNTRY>USA</COUNTRY>
<LOCALCONTACT>
<ADDRESS>45 HOLOMOA STREET</ADDRESS>
</LOCALCONTACT>
</CKL>
</DATA>
END

my $doc = $dom->parse ($str);
assert_ok ($doc); 

@result = XML::XQL::solve ('DATA/CKL', $doc);

$result = XML::XQL::Debug::str (\@result);

#print $result;
#assert_output ($result);

__DATA__
