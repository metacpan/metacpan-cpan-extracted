# encoding: Windows1254
# This file is encoded in Windows-1254.
die "This file is not encoded in Windows-1254.\n" if q{‚ } ne "\x82\xa0";

use strict;
use Windows1254;
print "1..11\n";

my $__FILE__ = __FILE__;

$_ = 'ABC123XYZ456';
if ($_ =~ m/([0-9]+)/) {
    if ($& eq '123') {
        print qq{ok - 1 \$& $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 1 \$& $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 1 \$& $^X $__FILE__\n};
}

$_ = 'ABC123XYZ456';
if ($_ =~ m/([0-9]+)/) {
    if ("$&" eq '123') {
        print qq{ok - 2 "\$&" $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 2 "\$&" $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 2 "\$&" $^X $__FILE__\n};
}

$_ = 'ABC123XYZ456';
if ($_ =~ m/([0-9]+)/) {
    if (qq{$&} eq '123') {
        print qq{ok - 3 qq{\$&} $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 3 qq{\$&} $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 3 qq{\$&} $^X $__FILE__\n};
}

$_ = 'ABC123XYZ456';
if ($_ =~ m/([0-9]+)/) {
    if (<<END eq "123\n") {
$&
END
        print qq{ok - 4 <<END\$&END $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 4 <<END\$&END $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 4 <<END\$&END $^X $__FILE__\n};
}

$_ = 'ABC123XYZ456';
if ($_ =~ m/([0-9]+)/) {
    if (<<"END" eq "123\n") {
$&
END
        print qq{ok - 5 <<"END"\$&END $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 5 <<"END"\$&END $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 5 <<"END"\$&END $^X $__FILE__\n};
}

$_ = 'ABC123XYZ456';
if ($_ =~ m/([0-9]+)/) {
    if ('987123456' =~ /($&)/) {
        if ($& eq '123') {
            print qq{ok - 6 /\$&/ $^X $__FILE__\n};
        }
        else {
            print qq{not ok - 6 /\$&/ $^X $__FILE__\n};
        }
    }
    else {
        print qq{not ok - 6 /\$&/ $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 6 /\$&/ $^X $__FILE__\n};
}

$_ = 'ABC123XYZ456';
if ($_ =~ m/([0-9]+)/) {
    if ('987123456' =~ m/($&)/) {
        if ($& eq '123') {
            print qq{ok - 7 m/\$&/ $^X $__FILE__\n};
        }
        else {
            print qq{not ok - 7 m/\$&/ $^X $__FILE__\n};
        }
    }
    else {
        print qq{not ok - 7 m/\$&/ $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 7 m/\$&/ $^X $__FILE__\n};
}

$_ = 'ABC123XYZ456';
if ($_ =~ m/([0-9]+)/) {
    $_ = '987123456';
    if ($_ =~ s/($&)/jkl/) {
        if ($_ eq '987jkl456') {
            print qq{ok - 8 s/\$&// $^X $__FILE__\n};
        }
        else {
            print qq{not ok - 8 s/\$&// $^X $__FILE__\n};
        }
    }
    else {
        print qq{not ok - 8 s/\$&// $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 8 s/\$&// $^X $__FILE__\n};
}

$_ = '123,456,789';
if ($_ =~ m/(,)/) {
    @_ = split(/$&/,'AAA,BBB,CCC,DDD');
    if (join('+',@_) eq 'AAA+BBB+CCC+DDD') {
        print qq{ok - 9 split(/$&/) $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 9 split(/$&/) $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 9 split(/$&/) $^X $__FILE__\n};
}

$_ = '123,456,789';
if ($_ =~ m/(,)/) {
    @_ = split(m/$&/,'AAA,BBB,CCC,DDD');
    if (join('+',@_) eq 'AAA+BBB+CCC+DDD') {
        print qq{ok - 10 split(m/$&/) $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 10 split(m/$&/) $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 10 split(m/$&/) $^X $__FILE__\n};
}

$_ = '123,456,789';
if ($_ =~ m/(,)/) {
    @_ = split(qr/$&/,'AAA,BBB,CCC,DDD');
    if (join('+',@_) eq 'AAA+BBB+CCC+DDD') {
        print qq{ok - 11 split(qr/$&/) $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 11 split(qr/$&/) $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 11 split(qr/$&/) $^X $__FILE__\n};
}

__END__

