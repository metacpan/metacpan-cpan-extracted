# encoding: Windows1250
# This file is encoded in Windows-1250.
die "This file is not encoded in Windows-1250.\n" if q{‚ } ne "\x82\xa0";

use Windows1250;

BEGIN {
    print "1..4\n";
    if ($] >= 5.020) {
        require feature;
        feature::->import('postderef');
        feature::->import('postderef_qq');
        require warnings;
        warnings::->unimport('experimental::postderef');
    }
    else{
        for my $tno (1..4) {
            print qq{ok - $tno SKIP $^X @{[__FILE__]}\n};
        }
        exit;
    }
}

# same as ${$sref}  # interpolates
$scalar = 'a scalar value';
$sref = \$scalar;
if ("$sref->$*" eq "${$sref}") {
    print qq{ok - 1 "\$sref->\$*" eq "\${\$sref}" $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 1 "\$sref->\$*" eq "\${\$sref}" $^X @{[__FILE__]}\n};
}

# same as @{$aref}  # interpolates
@array = (5,20,0);
$aref = \@array;
if ("$aref->@*" eq "@{$aref}") {
    print qq{ok - 2 "\$aref->\@*" eq "\@{\$aref}" $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 2 "\$aref->\@*" eq "\@{\$aref}" $^X @{[__FILE__]}\n};
}

# same as @$aref[...]  # interpolates
@array = (5,20,0);
$aref = \@array;
if ("$aref->@[0,2]" eq "@$aref[0,2]") {
    print qq{ok - 3 "\$aref->\@[0,2]" eq "\@\$aref[0,2]" $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 3 "\$aref->\@[0,2]" eq "\@\$aref[0,2]" $^X @{[__FILE__]}\n};
}

# same as @$href{...}  # interpolates
%hash = (red => 1, blue => 2, yellow => 3, violet => 4);
$href = \%hash;
if ("$href->@{qw(red blue yellow violet)}" eq "@$href{qw(red blue yellow violet)}") {
    print qq{ok - 4 "\$href->\@{qw(red blue yellow violet)}" eq "\@\$href{qw(red blue yellow violet)}" $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 4 "\$href->\@{qw(red blue yellow violet)}" eq "\@\$href{qw(red blue yellow violet)}" $^X @{[__FILE__]}\n};
}

__END__
