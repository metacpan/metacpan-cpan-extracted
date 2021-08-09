use strict;
use warnings;
use Test::More;

use Unix::Sudo qw(sudo);

use lib 't/lib';
use sudosanity;

sudosanity::checks && do {
    my $scalar = 'foo';
    my %hash   = (
        scalar => 11,
        hash   => { yow => { wooee => 9, owie => [qw(cats and dogs)] } },
        array  => [11, { lemon => 'curry' }, [42, 41]],
        code   => sub { 4 }
    );
    my @array  = reverse @{$hash{array}};
    my $code = sub {
        eval "use Data::Compare";
        if(
            $hash{code}->() == 4 &&  # check it's passed properly
            delete($hash{code}) &&   # delete from hash because comparing coderefs is a pain
            Compare(
                [$scalar, \%hash, \@array],
                [
                    'foo',
                    {
                        scalar => 11,
                        hash   => { yow => { wooee => 9, owie => [qw(cats and dogs)] } },
                        array  => [11, { lemon => 'curry' }, [42, 41]],
                    },
                    [ [42, 41], { lemon => 'curry' }, 11],
                ]
            )
        ) { return 11; }
         else { return 94; }
    };

    is(sudo { $code->() }, 11, "Can read variables from the parent context");
};

done_testing();
