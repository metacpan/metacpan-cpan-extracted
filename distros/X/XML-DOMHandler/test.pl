# Simple test script for DOMHandler

#
# Test document
#
my $data = <<END;
<doc>
<?pi data?>
<A a="1"><a>abcdefg</a><b>abcdefg</b><c>abcdefg</c></A>
<B a="2"><a>abcdefg</a><b>abcdefg</b><c>abcdefg</c></B>
<C a="3"><a>abcdefg</a><b>abcdefg</b><c>abcdefg</c></C>
<D><![CDATA[<>]]></D>
</doc>
END

#
# List of tests to run
#
my @tests = 
    (
     'require XML::DOMHandler',
     'require XML::LibXML',
     '$p = new XML::LibXML;
      $doc = $p->parse_string( $data );
      $dh = new XML::DOMHandler( handler_package => new testhandler );
      $dh->traverse( $doc );',
     'die unless( $acount == 3)',
     'die unless( $ccount == 1)',
     'die unless( $ecount == 14)',
     'die unless( $tcount == 69 )',
     );

#
# run the tests
#
my( $test, $score, $total ) = ( 1, 0, $#tests+1 );
my( $acount, $ccount, $ecount, $pcount, $tcount ) = (0,0,0,0,0);
foreach my $t ( @tests ) { 
    print "$test/$total...";
    eval( $t );
    if( $@ ) { 
	print "not ok\n"; 
    } else { 
	print "ok\n"; 
	$score++;
    }
    $test++;
    sleep(1);
}
print "$score out of $total tests succeeded.\n";

#
# test handler package
#
package testhandler;
sub new {
    return bless {};
}
sub a {
    $acount ++;
}
sub generic_element {
    $ecount ++;
}
sub generic_text {
    my( $self, $agent, $node ) = @_;
    $tcount += length( $node->nodeValue );
}
sub generic_PI {
    $pcount ++;
}
sub generic_CDATA {
    $ccount ++;
}
