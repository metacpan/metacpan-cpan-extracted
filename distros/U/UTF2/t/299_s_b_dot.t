# encoding: UTF2
# This file is encoded in UTF-2.
die "This file is not encoded in UTF-2.\n" if q{あ} ne "\xe3\x81\x82";

use strict;
use UTF2;
print "1..2\n";

my $__FILE__ = __FILE__;

$_ = 'あ';
if ($_ =~ s/(.)//b) {
    if (length($1) == 1) {
        print qq{ok - 1 \$_='あ'; \$_=~s/(.)//b; length(\$1)==1 $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 1 \$_='あ'; \$_=~s/(.)//b; length(\$1)==1 $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 1 \$_='あ'; \$_=~s/(.)//b; length(\$1)==1 $^X $__FILE__\n};
}

$_ = 'あ';
if ($_ =~ s'(.)''b) {
    if (length($1) == 1) {
        print qq{ok - 2 \$_='あ'; \$_=~s'(.)''b; length(\$1)==1 $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 2 \$_='あ'; \$_=~s'(.)''b; length(\$1)==1 $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 2 \$_='あ'; \$_=~s'(.)''b; length(\$1)==1 $^X $__FILE__\n};
}

__END__

