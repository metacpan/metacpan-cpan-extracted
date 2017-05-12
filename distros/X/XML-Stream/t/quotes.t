use strict;
use warnings;

use Test::More tests => 3;

# Test for RT#17325

BEGIN { use_ok('XML::Stream', 'Parser'); }

my @test_strings = (
    {
        xml     => q[<presence xmlns='jabber:client' from='sparrow@itn.pl/PowerBook G4 15"' to='jogger@jogger.pl'><show>away</show><status>Away</status></presence>],
        message => 'one double quote',
    },
    {
        xml     => q[<presence xmlns="jabber:client" from="sparrow@itn.pl/PowerBook G4 15'" to="jogger@jogger.pl"><show>away</show><status>Away</status></presence>],
        message => 'one single quote',
    }
);

foreach my $test_string ( @test_strings ) {
    my $p = XML::Stream::Parser->new();
    my $return;
    my $message = $test_string->{'message'};

    # The nature of the bug which this test aims to prove is such that an
    # infinite loop is caused on failure, hence this timeout code
    eval {
        local $SIG{ALRM} = sub { die "TIMED OUT\n" };
        alarm 3;
        $return = $p->parse( $test_string->{'xml'} );
    } or do {
        $return = '';
        $message .= ' - ' . $@;
    };

    isa_ok ( $return, 'ARRAY', $message );
}

