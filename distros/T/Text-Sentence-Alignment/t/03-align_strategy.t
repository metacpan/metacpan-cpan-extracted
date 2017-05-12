use Test::More tests => 3;

BEGIN {
    use_ok( 'Text::Sentence::Alignment' );
    my $TSA = Text::Sentence::Alignment->new();
    $TSA->is_local(1);
    my $s1 = "W R I J N T T E E R S M";
    my $s2 = "V I K N T Q T E E R K M";
    my @result = split("\t",$TSA->do_alignment($s1,$s2));
    is($result[0],"N T - T E E R S M","Test aligned s1");
    is($result[1],"N T Q T E E R K M","Test aligned s2");
}

