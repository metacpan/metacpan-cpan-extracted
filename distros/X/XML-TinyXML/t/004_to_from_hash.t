use strict;
use Test::More tests => 8;
BEGIN { use_ok('XML::TinyXML') };

my $testhash = { 
    a => 'b' , 
    c => 'd', 
    d => 0,
    hash => { 
        key1 => 'value1',
        key2 => 'value2' 
    }, 
    array => [ 
        "arrayval1", 
        { subhashkey => 'subhashvalue' }, 
        [  # XXX - sub arrays will be flattened by actual implementation
            { nome1 => 'subarray1' } , 
            { nome2 => 'subarray2' , 'nome2.5' => 'dfsdf'}, 
            { nested => { nested2_1 => 'nestedvalue', nested2_2 => 'nestedvalue2' } },
            "subarrayval1", 
            "subarrayval2" 
        ]
    ]
};

my $txml = XML::TinyXML->new($testhash);

ok( $txml , "XML::TinyXML Object from an hash");

my $newhash = $txml->toHash;
ok( $newhash->{a} eq $testhash->{a}, "simple hash member1" );
ok( $newhash->{c} eq $testhash->{c}, "simple hash member2" );
ok ($newhash->{d} eq "0", "0-values");
ok( scalar(keys(%{$newhash->{hash}})) == 2, "nested hash number of members" );
ok( $newhash->{hash}->{key1} eq $testhash->{hash}->{key1}, "nested hash member1" );
ok( $newhash->{hash}->{key2} eq $testhash->{hash}->{key2}, "nested hash member2" );

