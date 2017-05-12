# This code runs on perl4.036 and newer perls.  Usage:
#
#   require 'benchlib.pl';
#   runtest(1000, <<'ENDTEST');
#       # some testing code here
#   ENDTEST

package benchlib;

$cpu_factor = shift;
if (!$cpu_factor) {
    die "No CPU factor specified\n";
}
$empty_cycles_per_sec = shift;

sub main'runtest
{
    local($scale, $code) = @_;
    print "Date: " . &time2iso() . "\n";
    print "Test: $0\n";
    print "Perl: $^X $]\n";
    $scale = int($scale * $cpu_factor);
    $scale = 1 if $scale < 1;
    $code = <<'EOT1' . $code . <<EOT2 . $code . <<'EOT3';
# warm up
for ($i = 0; $i < 2; $i++) {
   package main;
   #---- test code ----
EOT1
   #-------------------
}

\$before_r = time;
(\$before_u, \$before_s, \$before_cu, \$before_cs) = times;
for (\$i = 0; \$i < $scale; \$i++) {
   package main;
   #---- test code ----
EOT2
   #-------------------
}
($after_u, $after_s, $after_cu, $after_cs) = times;
$after_r = time;

$user   = ($after_u - $before_u) + ($after_cu - $before_cu);
$system = ($after_s - $before_s) + ($after_cs - $before_cs);
$real   = ($after_r - $before_r);
$used   = $user + $system;

print "Cycles: $scale\n";
print "User-Time: $user\n";
print "System-Time: $system\n";
printf "Real-Time: %.*f\n", ($hires ? 3 : 0), $real;
printf "CPU: %.0f%%\n", 100*$used/$real if $real > 0;
if ($used > 0.1) {
    my $cps = $scale / $used;
    printf "Cycles-Per-Sec: %.*f\n", ($cps < 100 ? 3 : 0), $cps;
    if (defined $empty_cycles_per_sec) {
	printf "Empty-Cycles-Per-Sec: %.0f\n", $empty_cycles_per_sec;
	$loop_overhead = $scale / $empty_cycles_per_sec;
	$p = 100 * $loop_overhead / $used;
        printf "Loop-Overhead: %.1f%%\n", $p;
	$used -= $loop_overhead;
	print "Adjusted-Used-Time: $used\n";
    }
    printf "Bench-Points: %.5g\n", 1000 / $used if $used > 0;
}
EOT3

    if ($] >= 5.002) {
	$code = <<'EOT' . $code;
BEGIN {
    # If Time::HiRes is available, we can get better resolution
    eval {
        require Time::HiRes;
        Time::HiRes->import('time');
        $hires++;
    };
}

EOT
    }

    print $code if $main'debug;
    eval $code;
    if ($@) {
        die $@;
    }
}

sub time2iso
{
    my $time = shift;
    $time = time unless defined $time;
    my($sec,$min,$hour,$mday,$mon,$year) = localtime($time);
    return sprintf("%04d-%02d-%02d %02d:%02d:%02d",
            $year+1900, $mon+1, $mday, $hour, $min, $sec);
}


1;
