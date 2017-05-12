use Test::More tests => 3;

BEGIN {
    use_ok( 'Text::Sentence::Alignment' );
    my $TSA = Text::Sentence::Alignment->new();
    $TSA->is_local(1);
    my $s1 = "W R I T T T E E E R S M";
    my $s2 = "V I N T T N E E E R V M";
    my @result = split("\t",$TSA->do_alignment($s1,$s2,1));
    is($result[0],"T T T E E E R S M");
    is($result[1],"T T N E E E R V M");
}

#diag( "Testing Text::Sentence::Alignment $Text::Sentence::Alignment::VERSION, Perl 5.008006, /usr/local/bin/suidperl" );
