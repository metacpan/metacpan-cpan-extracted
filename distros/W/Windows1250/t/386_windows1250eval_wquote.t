# encoding: Windows1250
# This file is encoded in Windows-1250.
die "This file is not encoded in Windows-1250.\n" if q{��} ne "\x82\xa0";

use Windows1250;

print "1..12\n";

# Windows1250::eval "..." has Windows1250::eval "..."
if (Windows1250::eval " Windows1250::eval \" if ('��' =~ /[��]/i) { return 1 } else { return 0 } \" ") {
    print qq{ok - 1 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 1 $^X @{[__FILE__]}\n};
}

# Windows1250::eval "..." has Windows1250::eval qq{...}
if (Windows1250::eval " Windows1250::eval qq{ if ('��' =~ /[��]/i) { return 1 } else { return 0 } } ") {
    print qq{ok - 2 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 2 $^X @{[__FILE__]}\n};
}

# Windows1250::eval "..." has Windows1250::eval '...'
if (Windows1250::eval " Windows1250::eval ' if (qq{��} =~ /[��]/i) { return 1 } else { return 0 } ' ") {
    print qq{ok - 3 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 3 $^X @{[__FILE__]}\n};
}

# Windows1250::eval "..." has Windows1250::eval q{...}
if (Windows1250::eval " Windows1250::eval q{ if ('��' =~ /[��]/i) { return 1 } else { return 0 } } ") {
    print qq{ok - 4 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 4 $^X @{[__FILE__]}\n};
}

# Windows1250::eval "..." has Windows1250::eval $var
my $var = q{q{ if ('��' =~ /[��]/i) { return 1 } else { return 0 } }};
if (Windows1250::eval " Windows1250::eval $var ") {
    print qq{ok - 5 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 5 $^X @{[__FILE__]}\n};
}

# Windows1250::eval "..." has Windows1250::eval (omit)
$_ = "if ('��' =~ /[��]/i) { return 1 } else { return 0 }";
if (Windows1250::eval " Windows1250::eval ") {
    print qq{ok - 6 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 6 $^X @{[__FILE__]}\n};
}

# Windows1250::eval "..." has Windows1250::eval {...}
if (Windows1250::eval " Windows1250::eval { if ('��' =~ /[��]/i) { return 1 } else { return 0 } } ") {
    print qq{ok - 7 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 7 $^X @{[__FILE__]}\n};
}

# Windows1250::eval "..." has "..."
if (Windows1250::eval " if ('��' =~ /[��]/i) { return \"1\" } else { return \"0\" } ") {
    print qq{ok - 8 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 8 $^X @{[__FILE__]}\n};
}

# Windows1250::eval "..." has qq{...}
if (Windows1250::eval " if ('��' =~ /[��]/i) { return qq{1} } else { return qq{0} } ") {
    print qq{ok - 9 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 9 $^X @{[__FILE__]}\n};
}

# Windows1250::eval "..." has '...'
if (Windows1250::eval " if ('��' =~ /[��]/i) { return '1' } else { return '0' } ") {
    print qq{ok - 10 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 10 $^X @{[__FILE__]}\n};
}

# Windows1250::eval "..." has q{...}
if (Windows1250::eval " if ('��' =~ /[��]/i) { return q{1} } else { return q{0} } ") {
    print qq{ok - 11 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 11 $^X @{[__FILE__]}\n};
}

# Windows1250::eval "..." has $var
my $var1 = 1;
my $var0 = 0;
if (Windows1250::eval " if ('��' =~ /[��]/i) { return $var1 } else { return $var0 } ") {
    print qq{ok - 12 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 12 $^X @{[__FILE__]}\n};
}

__END__
