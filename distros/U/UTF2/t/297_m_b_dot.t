# encoding: UTF2
# This file is encoded in UTF-2.
die "This file is not encoded in UTF-2.\n" if q{あ} ne "\xe3\x81\x82";

use strict;
use UTF2;
print "1..6\n";

my $__FILE__ = __FILE__;

if ('あ' =~ /(.)/b) {
    if (length($1) == 1) {
        print qq{ok - 1 'あ'=~/(.)/b; length(\$1)==1 $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 1 'あ'=~/(.)/b; length(\$1)==1 $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 1 'あ'=~/(.)/b; length(\$1)==1 $^X $__FILE__\n};
}

if (@_ = 'あ' =~ /(.)/bg) {
    if (scalar(@_) == length('あ')) {
        if (grep( ! /^1$/, map { length($_) } @_)) {
            print qq{not ok - 2 \@_='あ'=~/(.)/bg; grep(!/^1\$/,map{length(\$_)} \@_) $^X $__FILE__\n};
        }
        else {
            print qq{ok - 2 \@_='あ'=~/(.)/bg; grep(!/^1\$/,map{length(\$_)} \@_) $^X $__FILE__\n};
        }
    }
    else {
        print qq{not ok - 2 \@_='あ'=~/(.)/bg; grep(!/^1\$/,map{length(\$_)} \@_) $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 2 \@_='あ'=~/(.)/bg; grep(!/^1\$/,map{length(\$_)} \@_) $^X $__FILE__\n};
}

if ('あ' =~ m/(.)/b) {
    if (length($1) == 1) {
        print qq{ok - 3 'あ'=~m/(.)/b; length(\$1)==1 $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 3 'あ'=~m/(.)/b; length(\$1)==1 $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 3 'あ'=~m/(.)/b; length(\$1)==1 $^X $__FILE__\n};
}

if (@_ = 'あ' =~ m/(.)/bg) {
    if (scalar(@_) == length('あ')) {
        if (grep( ! /^1$/, map { length($_) } @_)) {
            print qq{not ok - 4 \@_='あ'=~m/(.)/bg; grep(!/^1\$/,map{length(\$_)} \@_) $^X $__FILE__\n};
        }
        else {
            print qq{ok - 4 \@_='あ'=~m/(.)/bg; grep(!/^1\$/,map{length(\$_)} \@_) $^X $__FILE__\n};
        }
    }
    else {
        print qq{not ok - 4 \@_='あ'=~m/(.)/bg; grep(!/^1\$/,map{length(\$_)} \@_) $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 4 \@_='あ'=~m/(.)/bg; grep(!/^1\$/,map{length(\$_)} \@_) $^X $__FILE__\n};
}

if ('あ' =~ m'(.)'b) {
    if (length($1) == 1) {
        print qq{ok - 5 'あ'=~m'(.)'b; length(\$1)==1 $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 5 'あ'=~m'(.)'b; length(\$1)==1 $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 5 'あ'=~m'(.)'b; length(\$1)==1 $^X $__FILE__\n};
}

if (@_ = 'あ' =~ m'(.)'bg) {
    if (scalar(@_) == length('あ')) {
        if (grep( ! /^1$/, map { length($_) } @_)) {
            print qq{not ok - 6 \@_='あ'=~m'(.)'bg; grep(!/^1\$/,map{length(\$_)} \@_) $^X $__FILE__\n};
        }
        else {
            print qq{ok - 6 \@_='あ'=~m'(.)'bg; grep(!/^1\$/,map{length(\$_)} \@_) $^X $__FILE__\n};
        }
    }
    else {
        print qq{not ok - 6 \@_='あ'=~m'(.)'bg; grep(!/^1\$/,map{length(\$_)} \@_) $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 6 \@_='あ'=~m'(.)'bg; grep(!/^1\$/,map{length(\$_)} \@_) $^X $__FILE__\n};
}

__END__

