package PerlBench;

use strict;
use base 'Exporter';
our @EXPORT_OK = qw(timeit make_timeit_sub_code sec_f);

our $VERSION = "0.93";

use PerlBench::Stats qw(calc_stats);
use Time::HiRes qw(gettimeofday);
use Carp qw(croak);


sub timeit {
    my($code, %opt) = @_;
    my $init = $opt{init};

    # XXX auto determine how long we need to time stuff
    my $enough = $opt{enough} || 0.5;

    # auto determine $loop_count and $repeat_count
    print STDERR "# Determine loop count - enough is " . sec_f($enough) . "\n"
	if $opt{verbose};
    my($loop_count, $repeat_count) = do {
	my $count = 1;
	my $repeat = $opt{repeat} || 1;
	while (1) {
	    print STDERR "#  $count ==> " if $opt{verbose};
	    my $t = timeit_once($code, $init, $count, $repeat);
	    print STDERR sec_f($t, undef), "\n" if $opt{verbose};
	    last if $t > $enough;
	    if ($t < 0.00001) {
		$count *= 1000;
		next;
	    }
	    elsif ($t < 0.01) {
		$count *= 2;
		next;
	    }
	    $count = int($count * ($enough / $t) * 1.05) + 1;
	}
	($count, $repeat);
    };

    my @experiment;
    push(@experiment, {
        loop_count => $loop_count,
        repeat_count => $repeat_count,
    });
    $loop_count++ if $loop_count % 2;
    push(@experiment, {
        loop_count => $loop_count / 2,
        repeat_count => $repeat_count * 2,
    });

    my $pl = "tt$$.pl";
    open(my $fh, ">", $pl) || die "Can't create $pl: $!";
    print $fh "#!perl\n";
    print $fh "use strict;\n";
    print $fh "require Time::HiRes;\n";
    print $fh "{\n    $init;\n" if $init;
    print $fh "my \@TIMEIT = (\n";
    for my $e (@experiment) {
	print $fh &make_timeit_sub_code($code, undef, $e->{loop_count}, $e->{repeat_count}), ",\n";
    }
    print $fh ");\n";

    print $fh <<'EOT';

my $e = shift || die;
my $trials = shift || die;
my $loop_count = shift || die;
my @t;
my $sum = 0;
for (1.. $trials) {
    print "t$e=", $TIMEIT[$e-1]->(), "\n";
}
print "---\n";
EOT
    print $fh "}\n" if $init;
    close($fh) || die "Can't write $pl: $!";

    print STDERR "# Running tests...\n" if $opt{verbose};
    my $rounds = 4;
    for my $round (1..$rounds) {
	printf STDERR "#  %.0f%%\n", (($round-1)/$rounds)*100 if $opt{verbose} && $round > 1;
	my $e_num = 0;
	for my $e (@experiment) {
	    $e_num++;
	    open($fh, "$^X $pl $e_num 7 $loop_count |") || die "Can't run $pl: $!";
	    while (<$fh>) {
		#print "XXX $_";
		if (/^t(\d+)=(.*)/) {
		    die unless $1 eq $e_num;
		    my $t = $2+0;
		    push(@{$e->{t}}, $t);
		}
	    }
	    close($fh);
	}
    }
    unlink($pl);
    print STDERR "# done\n" if $opt{verbose};

    for my $e (@experiment) {
	my $t = $e->{t} ||return;
	calc_stats($e->{t}, $e);

	my $count = $e->{loop_count} * $e->{repeat_count};
	$e->{count} = $count;
    }

    my $loop_overhead = do {
	my $e1 = $experiment[0];
	my $e2 = $experiment[-1];
	my $t1 = $e1->{med} / $e1->{loop_count};
	my $t2 = $e2->{med} / $e2->{loop_count};
	my $f = $e2->{repeat_count} / $e1->{repeat_count};
	$f * $t1 - $t2;
    };

    for my $e (@experiment) {
	$e->{loop_overhead} = $loop_overhead * $e->{loop_count};
	$e->{loop_overhead_relative} = $e->{loop_overhead} / $e->{med};
    }

    my %res;
    $res{x} = \@experiment;

    # calculate combined stats
    my @t;
    for my $e (@experiment) {
	my $c = $e->{count};
	my $o = $e->{loop_overhead};
	push(@t, map { ($_-$o)/$c } @{$e->{t}});
    }
    calc_stats(\@t, \%res);

    for my $f (qw(count loop_overhead_relative)) {
	# XXX avg
	$res{$f} = $experiment[0]{$f};
    }

    return \%res;
}

sub timeit_once {
    return make_timeit_sub(@_)->();
}

sub make_timeit_sub {
    my $code = make_timeit_sub_code(@_);
    my $sub = eval $code;
    die $@ if $@;
    return $sub;
}

sub make_timeit_sub_code {
    my($code, $init, $loop_count, $repeat_count) = @_;
    $loop_count = int($loop_count);
    die unless $loop_count > 0;
    die if $loop_count + 1 == $loop_count;  # too large
    $repeat_count ||= 1;
    $init = "" unless defined $init;
    return <<EOT1 . "$init;$code" . <<'EOT2' . ($code x $repeat_count) . <<'EOT3';
sub {
    my \$COUNT = $loop_count;
    \$COUNT++;
    package main;
EOT1

    my($BEFORE_S, $BEFORE_US) = Time::HiRes::gettimeofday();
    while (--$COUNT) {
EOT2

    }
    my($AFTER_S, $AFTER_US) = Time::HiRes::gettimeofday();
    return ($AFTER_S - $BEFORE_S) + ($AFTER_US - $BEFORE_US)/1e6;
}
EOT3
}

BEGIN {
    my %UNITS = (
        "h" => 1/3600,
	"min" => 1/60,
	"s" => 1,
	"ms" => 1e3,
        "µs" => 1e6,
        "ns" => 1e9,
    );

    my @UNITS =
	sort { $b->[1] <=> $a->[1] }
	map  { [$_ => $UNITS{$_}] }
	     keys %UNITS;

    sub sec_f {
	my($t, $d, $u) = @_;
	my $f;
	if (defined $u) {
	    $f = $UNITS{$u} || croak("Unknown unit '$u'");
	}
	else {
	    for (my $i = 1; $i < @UNITS; $i++) {
		if ($t < 1/$UNITS[$i][1]) {
		    ($u, $f) = @{$UNITS[$i-1]};
		    last;
		}
	    }
	    unless ($u) {
		($u, $f) = @{$UNITS[-1]};
	    }
	}

	my $dev = defined($d) ? 1 : "";
	$d = $t unless $dev;

	if ($f != 1) {
	    $_ *= $f for $t, $d;
	}

	my $p = 0;
	if ($d < 0.05) {
	    $p = 3;
	}
	elsif ($d < 0.5) {
	    $p = 2;
	}
	elsif ($d < 5) {
	    $p = 1;
	}

	$dev = sprintf(" ±%.*f", $p, $d) if $dev;
	return sprintf("%.*f %s%s", $p, $t, $u, $dev);
    }
}

1;
