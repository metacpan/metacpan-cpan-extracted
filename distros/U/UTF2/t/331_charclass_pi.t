# encoding: UTF2
# This file is encoded in UTF-2.
die "This file is not encoded in UTF-2.\n" if q{あ} ne "\xe3\x81\x82";

use UTF2;
print "1..20\n";

my $__FILE__ = __FILE__;

if ("A" =~ /[B-ね]/i) {
    print qq{ok - 1 "A"=~/[B-ね]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 1 "A"=~/[B-ね]/i $^X $__FILE__\n};
}

if ("B" =~ /[B-ね]/i) {
    print qq{ok - 2 "B"=~/[B-ね]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 2 "B"=~/[B-ね]/i $^X $__FILE__\n};
}

if ("ぬ" =~ /[B-ね]/i) {
    print qq{ok - 3 "ぬ"=~/[B-ね]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 3 "ぬ"=~/[B-ね]/i $^X $__FILE__\n};
}

if ("ね" =~ /[B-ね]/i) {
    print qq{ok - 4 "ね"=~/[B-ね]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 4 "ね"=~/[B-ね]/i $^X $__FILE__\n};
}

if ("の" !~ /[B-ね]/i) {
    print qq{ok - 5 "の"!~/[B-ね]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 5 "の"!~/[B-ね]/i $^X $__FILE__\n};
}

my $from = 'B';
if ("A" =~ /[$from-ね]/i) {
    print qq{ok - 6 "A"=~/[\$from-ね]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 6 "A"=~/[\$from-ね]/i $^X $__FILE__\n};
}

if ("B" =~ /[$from-ね]/i) {
    print qq{ok - 7 "B"=~/[\$from-ね]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 7 "B"=~/[\$from-ね]/i $^X $__FILE__\n};
}

if ("ぬ" =~ /[$from-ね]/i) {
    print qq{ok - 8 "ぬ"=~/[\$from-ね]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 8 "ぬ"=~/[\$from-ね]/i $^X $__FILE__\n};
}

if ("ね" =~ /[$from-ね]/i) {
    print qq{ok - 9 "ね"=~/[\$from-ね]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 9 "ね"=~/[\$from-ね]/i $^X $__FILE__\n};
}

if ("の" !~ /[$from-ね]/i) {
    print qq{ok - 10 "の"!~/[\$from-ね]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 10 "の"!~/[\$from-ね]/i $^X $__FILE__\n};
}

my $to = 'ね';
if ("A" =~ /[$from-$to]/i) {
    print qq{ok - 11 "A"=~/[\$from-\$to]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 11 "A"=~/[\$from-\$to]/i $^X $__FILE__\n};
}

if ("B" =~ /[$from-$to]/i) {
    print qq{ok - 12 "B"=~/[\$from-\$to]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 12 "B"=~/[\$from-\$to]/i $^X $__FILE__\n};
}

if ("ぬ" =~ /[$from-$to]/i) {
    print qq{ok - 13 "ぬ"=~/[\$from-\$to]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 13 "ぬ"=~/[\$from-\$to]/i $^X $__FILE__\n};
}

if ("ね" =~ /[$from-$to]/i) {
    print qq{ok - 14 "ね"=~/[\$from-\$to]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 14 "ね"=~/[\$from-\$to]/i $^X $__FILE__\n};
}

if ("の" !~ /[$from-$to]/i) {
    print qq{ok - 15 "の"!~/[\$from-\$to]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 15 "の"!~/[\$from-\$to]/i $^X $__FILE__\n};
}

if ("A" =~ /[${from}-${to}]/i) {
    print qq{ok - 16 "A"=~/[\${from}-\${to}]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 16 "A"=~/[\${from}-\${to}]/i $^X $__FILE__\n};
}

if ("B" =~ /[${from}-${to}]/i) {
    print qq{ok - 17 "B"=~/[\${from}-\${to}]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 17 "B"=~/[\${from}-\${to}]/i $^X $__FILE__\n};
}

if ("ぬ" =~ /[${from}-${to}]/i) {
    print qq{ok - 18 "ぬ"=~/[\${from}-\${to}]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 18 "ぬ"=~/[\${from}-\${to}]/i $^X $__FILE__\n};
}

if ("ね" =~ /[${from}-${to}]/i) {
    print qq{ok - 19 "ね"=~/[\${from}-\${to}]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 19 "ね"=~/[\${from}-\${to}]/i $^X $__FILE__\n};
}

if ("の" !~ /[${from}-${to}]/i) {
    print qq{ok - 20 "の"!~/[\${from}-\${to}]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 20 "の"!~/[\${from}-\${to}]/i $^X $__FILE__\n};
}

__END__
