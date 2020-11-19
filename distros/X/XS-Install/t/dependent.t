use strict;
use warnings;
use Test::More;
use XS::Install;

# modules & their dependencies
# A1: ()
# A2: ()
# B1: (A1)
# B2: (A2, A1)
# B3: (A2)
# C1: (A1)
# C2: (B2, B3)
# C3: (B3)
# linearized: A1 A2 B1 B3 C1 B2 C3 C2

no warnings 'redefine';

*XS::Install::Payload::binary_module_info = sub {
    my $m = shift;
    my $d;
       if ($m eq 'A1') { $d = []; }
    elsif ($m eq 'A2') { $d = []; }
    elsif ($m eq 'B1') { $d = [qw/A1/]; }
    elsif ($m eq 'B2') { $d = [qw/A2 A1/]; }
    elsif ($m eq 'B3') { $d = [qw/A2/]; }
    elsif ($m eq 'C1') { $d = [qw/A1/]; }
    elsif ($m eq 'C2') { $d = [qw/B2 A3/]; }
    elsif ($m eq 'C3') { $d = [qw/B3/]; }

    die("should not happen") unless $d;
    return { BIN_DEPENDENT => $d };
};

my $list = XS::Install::Util::linearize_dependent([qw/C3 C2 C1 B3 B2 B1 A2 A1/]);
is_deeply $list, [qw/A1 A2 B1 B3 C1 B2 C3 C2/];

done_testing();
