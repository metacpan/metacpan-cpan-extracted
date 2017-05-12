use Test::More tests => 80;

sub begins_with
{
    my ($got, $exp) = @_;
    my $ok = substr($got,0,length $exp) eq $exp;
    if (!$ok)
    {
        diag "expected '$exp...'\n",
             "     got '$got'\n";
    }
    return $ok;
}

use_ok ('Time::Normalize');

# HMS export okay?
ok (defined &normalize_hms, 'normalize_hms sub imported');


my ($h24, $min, $sec, $h12, $ampm, $ssm, $hash);

# Simple basic case
($h24, $min, $sec, $h12, $ampm, $ssm) = ();
eval {($h24, $min, $sec, $h12, $ampm, $ssm) = normalize_hms(10, 23, 45, 'pm') };
is ($@,    '', q{basic test: no error});
is_deeply ([$h24, $min, $sec, $h12, $ampm, $ssm], [22, 23, 45, 10, 'p', 80_625], 'basic test');

# hashref test
undef $hash;
eval {$hash = normalize_hms(10, 23, 45, 'pm') };
is ($@,    '', q{basic hash: no error});
is_deeply ([@$hash{qw(h24 hour min sec h12 ampm since_midnight)}], [22, 22, 23, 45, 10, 'p', 80_625], 'basic hash');

# Optional am/pm indicator
($h24, $min, $sec, $h12, $ampm, $ssm) = ();
eval {($h24, $min, $sec, $h12, $ampm, $ssm) = normalize_hms(10, 23, 45) };
is ($@,    '', q{no am/pm ind: no error});
is_deeply ([$h24, $min, $sec, $h12, $ampm, $ssm], [10, 23, 45, 10, 'a', 37_425], 'no am/pm ind');

# Optional second
($h24, $min, $sec, $h12, $ampm, $ssm) = ();
eval {($h24, $min, $sec, $h12, $ampm, $ssm) = normalize_hms(10, 23, undef, 'pm') };
is ($@,    '', q{no second (1): no error});
is_deeply ([$h24, $min, $sec, $h12, $ampm, $ssm], [22, 23, '00', 10, 'p', 80_580], 'no second (1)');

($h24, $min, $sec, $h12, $ampm, $ssm) = ();
eval {($h24, $min, $sec, $h12, $ampm, $ssm) = normalize_hms(10, 23, '', 'pm') };
is ($@,    '', q{no second (2): no error});
is_deeply ([$h24, $min, $sec, $h12, $ampm, $ssm], [22, 23, '00', 10, 'p', 80_580], 'no second (2)');

# neither second nor am/pm
($h24, $min, $sec, $h12, $ampm, $ssm) = ();
eval {($h24, $min, $sec, $h12, $ampm, $ssm) = normalize_hms(10, 23) };
is ($@,    '', q{no sec or am/pm ind: no error});
is_deeply ([$h24, $min, $sec, $h12, $ampm, $ssm], [10, 23, '00', 10, 'a', 37_380], 'no sec or am/pm ind');

# hashref leading-zero removal test
undef $hash;
eval {$hash = normalize_hms('09', 23, 45) };
is ($@,    '', q{leading-zero: no error});
is_deeply ([@$hash{qw(h24 hour min sec h12 ampm since_midnight)}], ['09', '09', 23, 45, 9, 'a', 33_825], 'leading-zero');

# Too few args
eval {($h24, $min, $sec, $h12, $ampm, $ssm) = normalize_hms(99) };
ok (begins_with ($@, 'Too few arguments to normalize_hms'), q{too few hms args});

# Too many args
eval {($h24, $min, $sec, $h12, $ampm, $ssm) = normalize_hms(20, 23, 45, 'pm', 'Saturday') };
ok (begins_with ($@, 'Too many arguments to normalize_hms'), q{too many hms args});

# Hour tests
eval {($h24, $min, $sec, $h12, $ampm, $ssm) = normalize_hms(0, 23, 45, 'pm') };
ok (begins_with ($@, 'Time::Normalize: Invalid hour: "0"'), q{hour 0 (pm): invalid});

($h24, $min, $sec, $h12, $ampm, $ssm) = ();
eval {($h24, $min, $sec, $h12, $ampm, $ssm) = normalize_hms(12, 23, 45, 'pm') };
is ($@, '', q{hour 12 (pm): valid});
is_deeply ([$h24, $min, $sec, $h12, $ampm, $ssm], [12, 23, 45, 12, 'p', 44_625], 'hour 12 (pm) values');

($h24, $min, $sec, $h12, $ampm, $ssm) = ();
eval {($h24, $min, $sec, $h12, $ampm, $ssm) = normalize_hms(12, 23, 45, 'am') };
is ($@, '', q{hour 12 (am): valid});
is_deeply ([$h24, $min, $sec, $h12, $ampm, $ssm], ['00', 23, 45, 12, 'a', 1_425], 'hour 12 (am) values');

eval {($h24, $min, $sec, $h12, $ampm, $ssm) = normalize_hms(13, 23, 45, 'pm') };
ok (begins_with ($@, 'Time::Normalize: Invalid hour: "13"'), q{hour 13 (pm): invalid});

($h24, $min, $sec, $h12, $ampm, $ssm) = ();
eval {($h24, $min, $sec, $h12, $ampm, $ssm) = normalize_hms(0, 23, 45) };
is ($@, '', q{hour 0: valid});
is_deeply ([$h24, $min, $sec, $h12, $ampm, $ssm], ['00', 23, 45, 12, 'a', 1_425], 'hour 0 values');

($h24, $min, $sec, $h12, $ampm, $ssm) = ();
eval {($h24, $min, $sec, $h12, $ampm, $ssm) = normalize_hms(13, 23, 45) };
is ($@, '', q{hour 13: valid});
is_deeply ([$h24, $min, $sec, $h12, $ampm, $ssm], [13, 23, 45, 1, 'p', 48_225], 'hour 13 values');

($h24, $min, $sec, $h12, $ampm, $ssm) = ();
eval {($h24, $min, $sec, $h12, $ampm, $ssm) = normalize_hms(23, 23, 45) };
is ($@, '', q{hour 23: valid});
is_deeply ([$h24, $min, $sec, $h12, $ampm, $ssm], [23, 23, 45, 11, 'p', 84_225], 'hour 23 values');

eval {($h24, $min, $sec, $h12, $ampm, $ssm) = normalize_hms(24, 23, 45) };
ok (begins_with ($@, 'Time::Normalize: Invalid hour: "24"'), q{hour 24: invalid});

eval {($h24, $min, $sec, $h12, $ampm, $ssm) = normalize_hms(24, 0) };
ok (begins_with ($@, 'Time::Normalize: Invalid hour: "24"'), q{hour 24:00:00: invalid});

eval {($h24, $min, $sec, $h12, $ampm, $ssm) = normalize_hms('abc', 0) };
ok (begins_with ($@, 'Time::Normalize: Invalid hour: "abc"'), q{alpha hour: invalid});

eval {($h24, $min, $sec, $h12, $ampm, $ssm) = normalize_hms(-1, 0) };
ok (begins_with ($@, 'Time::Normalize: Invalid hour: "-1"'), q{negative hour: invalid});

# am/pm calculations based on hour
($h24, $min, $sec, $h12, $ampm, $ssm) = ();
eval {($h24, $min, $sec, $h12, $ampm, $ssm) = normalize_hms(0, 0) };
is ($@, '', q{hour 0 am/pm calc: no err});
is_deeply ([$h24, $min, $sec, $h12, $ampm, $ssm], ['00', '00', '00', 12, 'a', 0], 'hour 0 am/pm calc values');

($h24, $min, $sec, $h12, $ampm, $ssm) = ();
eval {($h24, $min, $sec, $h12, $ampm, $ssm) = normalize_hms(12, 0) };
is ($@, '', q{hour 12 am/pm calc: no err});
is_deeply ([$h24, $min, $sec, $h12, $ampm, $ssm], [12, '00', '00', 12, 'p', 43_200], 'hour 12 am/pm calc values');

# Minute tests
($h24, $min, $sec, $h12, $ampm, $ssm) = ();
eval {($h24, $min, $sec, $h12, $ampm, $ssm) = normalize_hms(10,  0, 45, 'am') };
is ($@, '', q{minute 0: valid});
is_deeply ([$h24, $min, $sec, $h12, $ampm, $ssm], [10, '00', 45, 10, 'a', 36_045], 'minute 0 values');

($h24, $min, $sec, $h12, $ampm, $ssm) = ();
eval {($h24, $min, $sec, $h12, $ampm, $ssm) = normalize_hms(10, 59, 45, 'am') };
is ($@, '', q{minute 59: valid});
is_deeply ([$h24, $min, $sec, $h12, $ampm, $ssm], [10, 59, 45, 10, 'a', 39_585], 'minute 59 values');

eval {($h24, $min, $sec, $h12, $ampm, $ssm) = normalize_hms(10, 60, 45, 'am') };
ok (begins_with ($@, 'Time::Normalize: Invalid minute: "60"'), q{minute 60: invalid});

eval {($h24, $min, $sec, $h12, $ampm, $ssm) = normalize_hms(10, 'abc', 45, 'am') };
ok (begins_with ($@, 'Time::Normalize: Invalid minute: "abc"'), q{alpha minute: invalid});

eval {($h24, $min, $sec, $h12, $ampm, $ssm) = normalize_hms(10, -1, 45, 'am') };
ok (begins_with ($@, 'Time::Normalize: Invalid minute: "-1"'), q{negative minute: invalid});

# Second tests
($h24, $min, $sec, $h12, $ampm, $ssm) = ();
eval {($h24, $min, $sec, $h12, $ampm, $ssm) = normalize_hms(10, 23, 0, 'am') };
is ($@, '', q{second 0: valid});
is_deeply ([$h24, $min, $sec, $h12, $ampm, $ssm], [10, 23, '00', 10, 'a', 37_380], 'second 0 values');

($h24, $min, $sec, $h12, $ampm, $ssm) = ();
eval {($h24, $min, $sec, $h12, $ampm, $ssm) = normalize_hms(10, 23, 59, 'am') };
is ($@, '', q{second 59: valid});
is_deeply ([$h24, $min, $sec, $h12, $ampm, $ssm], [10, 23, 59, 10, 'a', 37_439], 'second 59 values');

eval {($h24, $min, $sec, $h12, $ampm, $ssm) = normalize_hms(10, 23, 60, 'am') };
ok (begins_with ($@, 'Time::Normalize: Invalid second: "60"'), q{second 60: invalid});

eval {($h24, $min, $sec, $h12, $ampm, $ssm) = normalize_hms(10, 23, 'abc', 'am') };
ok (begins_with ($@, 'Time::Normalize: Invalid second: "abc"'), q{alpha second: invalid});

eval {($h24, $min, $sec, $h12, $ampm, $ssm) = normalize_hms(10, 23, -1, 'am') };
ok (begins_with ($@, 'Time::Normalize: Invalid second: "-1"'), q{negative second: invalid});

# am/pm cases
($h24, $min, $sec, $h12, $ampm, $ssm) = ();
eval {($h24, $min, $sec, $h12, $ampm, $ssm) = normalize_hms(10, 23, 45, 'p') };
is ($@,    '', q{ampm "p": no error});
is_deeply ([$h24, $min, $sec, $h12, $ampm, $ssm], [22, 23, 45, 10, 'p', 80_625], 'ampm "p" values');

($h24, $min, $sec, $h12, $ampm, $ssm) = ();
eval {($h24, $min, $sec, $h12, $ampm, $ssm) = normalize_hms(10, 23, 45, 'pm') };
is ($@,    '', q{ampm "pm": no error});
is_deeply ([$h24, $min, $sec, $h12, $ampm, $ssm], [22, 23, 45, 10, 'p', 80_625], 'ampm "pm" values');

($h24, $min, $sec, $h12, $ampm, $ssm) = ();
eval {($h24, $min, $sec, $h12, $ampm, $ssm) = normalize_hms(10, 23, 45, 'p.m.') };
is ($@,    '', q{ampm "p.m.": no error});
is_deeply ([$h24, $min, $sec, $h12, $ampm, $ssm], [22, 23, 45, 10, 'p', 80_625], 'ampm "p.m." values');

($h24, $min, $sec, $h12, $ampm, $ssm) = ();
eval {($h24, $min, $sec, $h12, $ampm, $ssm) = normalize_hms(10, 23, 45, 'P') };
is ($@,    '', q{ampm "P": no error});
is_deeply ([$h24, $min, $sec, $h12, $ampm, $ssm], [22, 23, 45, 10, 'p', 80_625], 'ampm "P" values');

($h24, $min, $sec, $h12, $ampm, $ssm) = ();
eval {($h24, $min, $sec, $h12, $ampm, $ssm) = normalize_hms(10, 23, 45, 'PM') };
is ($@,    '', q{ampm "PM": no error});
is_deeply ([$h24, $min, $sec, $h12, $ampm, $ssm], [22, 23, 45, 10, 'p', 80_625], 'ampm "PM" values');

($h24, $min, $sec, $h12, $ampm, $ssm) = ();
eval {($h24, $min, $sec, $h12, $ampm, $ssm) = normalize_hms(10, 23, 45, 'P.M.') };
is ($@,    '', q{ampm "P.M.": no error});
is_deeply ([$h24, $min, $sec, $h12, $ampm, $ssm], [22, 23, 45, 10, 'p', 80_625], 'ampm "P.M." values');

($h24, $min, $sec, $h12, $ampm, $ssm) = ();
eval {($h24, $min, $sec, $h12, $ampm, $ssm) = normalize_hms(10, 23, 45, 'a') };
is ($@,    '', q{ampm "a": no error});
is_deeply ([$h24, $min, $sec, $h12, $ampm, $ssm], [10, 23, 45, 10, 'a', 37_425], 'ampm "a" values');

($h24, $min, $sec, $h12, $ampm, $ssm) = ();
eval {($h24, $min, $sec, $h12, $ampm, $ssm) = normalize_hms(10, 23, 45, 'am') };
is ($@,    '', q{ampm "am": no error});
is_deeply ([$h24, $min, $sec, $h12, $ampm, $ssm], [10, 23, 45, 10, 'a', 37_425], 'ampm "am" values');

($h24, $min, $sec, $h12, $ampm, $ssm) = ();
eval {($h24, $min, $sec, $h12, $ampm, $ssm) = normalize_hms(10, 23, 45, 'a.m.') };
is ($@,    '', q{ampm "a.m.": no error});
is_deeply ([$h24, $min, $sec, $h12, $ampm, $ssm], [10, 23, 45, 10, 'a', 37_425], 'ampm "a.m." values');

($h24, $min, $sec, $h12, $ampm, $ssm) = ();
eval {($h24, $min, $sec, $h12, $ampm, $ssm) = normalize_hms(10, 23, 45, 'A') };
is ($@,    '', q{ampm "A": no error});
is_deeply ([$h24, $min, $sec, $h12, $ampm, $ssm], [10, 23, 45, 10, 'a', 37_425], 'ampm "A" values');

($h24, $min, $sec, $h12, $ampm, $ssm) = ();
eval {($h24, $min, $sec, $h12, $ampm, $ssm) = normalize_hms(10, 23, 45, 'AM') };
is ($@,    '', q{ampm "AM": no error});
is_deeply ([$h24, $min, $sec, $h12, $ampm, $ssm], [10, 23, 45, 10, 'a', 37_425], 'ampm "AM" values');

($h24, $min, $sec, $h12, $ampm, $ssm) = ();
eval {($h24, $min, $sec, $h12, $ampm, $ssm) = normalize_hms(10, 23, 45, 'A.M.') };
is ($@,    '', q{ampm "A.M.": no error});
is_deeply ([$h24, $min, $sec, $h12, $ampm, $ssm], [10, 23, 45, 10, 'a', 37_425], 'ampm "A.M." values');

eval {($h24, $min, $sec, $h12, $ampm, $ssm) = normalize_hms(10, 23, 45, 'xm') };
ok (begins_with ($@, 'Time::Normalize: Invalid am/pm indicator: "xm"'), q{ampm "xm": invalid});

eval {($h24, $min, $sec, $h12, $ampm, $ssm) = normalize_hms(10, 23, 45, 'p:m:') };
ok (begins_with ($@, 'Time::Normalize: Invalid am/pm indicator: "p:m:"'), q{ampm "p:m:": invalid});

eval {($h24, $min, $sec, $h12, $ampm, $ssm) = normalize_hms(10, 23, 45, 'p.m') };
ok (begins_with ($@, 'Time::Normalize: Invalid am/pm indicator: "p.m"'), q{ampm "p.m": invalid});

eval {($h24, $min, $sec, $h12, $ampm, $ssm) = normalize_hms(10, 23, 45, 'pm.') };
ok (begins_with ($@, 'Time::Normalize: Invalid am/pm indicator: "pm."'), q{ampm "pm.": invalid});

