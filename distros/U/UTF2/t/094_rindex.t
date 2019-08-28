# encoding: UTF2
# This file is encoded in UTF-2.
die "This file is not encoded in UTF-2.\n" if q{あ} ne "\xe3\x81\x82";

use UTF2;
print "1..4\n";

my $__FILE__ = __FILE__;

$_ = 'あいうえおあいうえお';
if (rindex($_,'いう') == 18) {
    print qq{ok - 1 rindex(\$_,'いう') == 18 $^X $__FILE__\n};
}
else {
    print qq{not ok - 1 rindex(\$_,'いう') == 18 $^X $__FILE__\n};
}

$_ = 'あいうえおあいうえお';
if (rindex($_,'いう',15) == 3) {
    print qq{ok - 2 rindex(\$_,'いう',15) == 3 $^X $__FILE__\n};
}
else {
    print qq{not ok - 2 rindex(\$_,'いう',15) == 3 $^X $__FILE__\n};
}

$_ = 'あいうえおあいうえお';
if (UTF2::rindex($_,'いう') == 6) {
    print qq{ok - 3 UTF2::rindex(\$_,'いう') == 6 $^X $__FILE__\n};
}
else {
    print qq{not ok - 3 UTF2::rindex(\$_,'いう') == 6 $^X $__FILE__\n};
}

$_ = 'あいうえおあいうえお';
if (UTF2::rindex($_,'いう',5) == 1) {
    print qq{ok - 4 UTF2::rindex(\$_,'いう',5) == 1 $^X $__FILE__\n};
}
else {
    print qq{not ok - 4 UTF2::rindex(\$_,'いう',5) == 1 $^X $__FILE__\n};
}

__END__
