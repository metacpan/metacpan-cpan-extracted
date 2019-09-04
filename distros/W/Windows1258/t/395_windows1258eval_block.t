# encoding: Windows1258
# This file is encoded in Windows-1258.
die "This file is not encoded in Windows-1258.\n" if q{ } ne "\x82\xa0";

use Windows1258;

print "1..12\n";

# Windows1258::eval {...} has Windows1258::eval "..."
if (Windows1258::eval { Windows1258::eval " if ('้ม' =~ /[แ]/i) { return 1 } else { return 0 } " }) {
    print qq{ok - 1 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 1 $^X @{[__FILE__]}\n};
}

# Windows1258::eval {...} has Windows1258::eval qq{...}
if (Windows1258::eval { Windows1258::eval qq{ if ('้ม' =~ /[แ]/i) { return 1 } else { return 0 } } }) {
    print qq{ok - 2 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 2 $^X @{[__FILE__]}\n};
}

# Windows1258::eval {...} has Windows1258::eval '...'
if (Windows1258::eval { Windows1258::eval ' if (qq{้ม} =~ /[แ]/i) { return 1 } else { return 0 } ' }) {
    print qq{ok - 3 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 3 $^X @{[__FILE__]}\n};
}

# Windows1258::eval {...} has Windows1258::eval q{...}
if (Windows1258::eval { Windows1258::eval q{ if ('้ม' =~ /[แ]/i) { return 1 } else { return 0 } } }) {
    print qq{ok - 4 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 4 $^X @{[__FILE__]}\n};
}

# Windows1258::eval {...} has Windows1258::eval $var
my $var = q{ if ('้ม' =~ /[แ]/i) { return 1 } else { return 0 } };
if (Windows1258::eval { Windows1258::eval $var }) {
    print qq{ok - 5 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 5 $^X @{[__FILE__]}\n};
}

# Windows1258::eval {...} has Windows1258::eval (omit)
$_ = "if ('้ม' =~ /[แ]/i) { return 1 } else { return 0 }";
if (Windows1258::eval { Windows1258::eval }) {
    print qq{ok - 6 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 6 $^X @{[__FILE__]}\n};
}

# Windows1258::eval {...} has Windows1258::eval {...}
if (Windows1258::eval { Windows1258::eval { if ('้ม' =~ /[แ]/i) { return 1 } else { return 0 } } }) {
    print qq{ok - 7 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 7 $^X @{[__FILE__]}\n};
}

# Windows1258::eval {...} has "..."
if (Windows1258::eval { if ('้ม' =~ /[แ]/i) { return "1" } else { return "0" } }) {
    print qq{ok - 8 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 8 $^X @{[__FILE__]}\n};
}

# Windows1258::eval {...} has qq{...}
if (Windows1258::eval { if ('้ม' =~ /[แ]/i) { return qq{1} } else { return qq{0} } }) {
    print qq{ok - 9 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 9 $^X @{[__FILE__]}\n};
}

# Windows1258::eval {...} has '...'
if (Windows1258::eval { if ('้ม' =~ /[แ]/i) { return '1' } else { return '0' } }) {
    print qq{ok - 10 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 10 $^X @{[__FILE__]}\n};
}

# Windows1258::eval {...} has q{...}
if (Windows1258::eval { if ('้ม' =~ /[แ]/i) { return q{1} } else { return q{0} } }) {
    print qq{ok - 11 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 11 $^X @{[__FILE__]}\n};
}

# Windows1258::eval {...} has $var
my $var1 = 1;
my $var0 = 0;
if (Windows1258::eval { if ('้ม' =~ /[แ]/i) { return $var1 } else { return $var0 } }) {
    print qq{ok - 12 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 12 $^X @{[__FILE__]}\n};
}

__END__
