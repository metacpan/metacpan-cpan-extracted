use Test::More tests => 17;

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

# year export okay?
ok (defined &normalize_year, 'normalize_year sub imported');

# Year tests (12)
my ($cur_cc, $cur_yy) = ((localtime)[5]+1900) =~ /^(\d\d)(\d\d)$/;
my @cases;
if ($cur_yy <= 50)   # e.g. 2005
{
    my $prv_cc = sprintf '%02d', $cur_cc - 1;
    my $c75 = $cur_yy > 25? $cur_cc : $prv_cc;
    @cases = (
              ['00' => "${cur_cc}00"],
              ['25' => "${cur_cc}25"],
              ['50' => "${cur_cc}50"],
              ['75' => "${c75}75"],
              ['99' => "${prv_cc}99"],
              [$cur_yy => "$cur_cc$cur_yy"]
             );

}
else   # As if this module will be around in 2050.. :-P
{
    my $nxt_cc = sprintf '%02d', $cur_cc + 1;
    my $c25 = $cur_yy < 75? $cur_cc : $nxt_cc;
    @cases = (
              ['00' => "${nxt_cc}00"],
              ['25' => "${c25}25"],
              ['50' => "${cur_cc}50"],
              ['75' => "${cur_cc}75"],
              ['99' => "${cur_cc}99"],
              [$cur_yy => "$cur_cc$cur_yy"]
             );

}

for my $case (@cases)
{
    my $year;
    my ($y2, $y4) = @$case;
    eval {$year = normalize_year($y2) };
    is ($@,    '', qq{$y2 test: no error});
    is ($year, $y4, "$y2 => $y4");
}

# Bad years (3)
my $year;

eval {$year = normalize_year(5) };
ok (begins_with ($@, 'Time::Normalize: Invalid year: "5"'), q{bad year (1 digit)});

eval {$year = normalize_year(205) };
ok (begins_with ($@, 'Time::Normalize: Invalid year: "205"'), q{bad year (3 digits)});

eval {$year = normalize_year(20005) };
ok (begins_with ($@, 'Time::Normalize: Invalid year: "20005"'), q{bad year (5 digits)});

