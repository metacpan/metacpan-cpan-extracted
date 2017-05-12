

package Devel::callsfrom;
use Data::Dumper;

# From perldoc perlvar
# Debugger flags, so you can see what we turn on below.
#
# 0x01  Debug subroutine enter/exit.
#
# 0x02  Line-by-line debugging.
#
# 0x04  Switch off optimizations.
#
# 0x08  Preserve more data for future interactive inspections.
#
# 0x10  Keep info about source lines on which a subroutine is defined.
#
# 0x20  Start with single-step on.
#
# 0x40  Use subroutine address instead of name when reporting.
#
# 0x80  Report "goto &subroutine" as well.
#
# 0x100 Provide informative "file" names for evals based on the place they were com-
#         piled.
#
# 0x200 Provide informative names to anonymous subroutines based on the place they
#         were compiled.
#
# 0x400 Debug assertion subroutines enter/exit.
#

BEGIN { $^P |= (0x01 | 0x80 | 0x100 | 0x200); };
#BEGIN { $^P |= (0x004 | 0x100 ); };

sub import { }

package DB;

# Any debugger needs to have a sub DB. It doesn't need to do anything.
sub DB{};

# We want to track how deep our subroutines go
our $CALL_DEPTH = 0;
our %CALLED;
our $CALL_WATCH = $ENV{CALL_WATCH};

sub sub {
    local $DB::CALL_DEPTH = $DB::CALL_DEPTH+1;
    no strict;
    no warnings;
    my @c0 = caller(0);
    my @c1 = caller(-1);
    my ($pkg,$file,$line) = @c1;
    my $csub = $c0[3] || '-';
    my $caller = join(",", $file,$line,$pkg,$csub);
    print STDERR ((' ' x $DB::CALL_DEPTH) . $DB::sub{$DB::sub} . ' > ' . $DB::sub . "(@_) : " . $caller . "\n") if $CALL_WATCH;
    $DB::CALLED{$DB::sub}{$caller}++;
    &{$DB::sub};
}


END {
    use strict;
    use warnings;
    my %counts;
    for my $sub (keys %DB::sub) {
        my $cases = $DB::CALLED{$sub};
        my @callers = keys %$cases;
        my $call_count = scalar(@callers);
        $counts{$call_count}{$sub} = $cases;
    }
    my @counts = keys %counts;
    my $call_min = $ENV{CALL_MIN};
    if (defined $call_min) {
        @counts = grep { $_ >= $call_min } @counts;
    }
    my $call_max = $ENV{CALL_MAX};
    if (defined $call_max) {
        @counts = grep { $_ <= $call_max } @counts;
    }
    my $fh;
    if (my $fname = $ENV{CALL_COUNT_OUTFILE}) {
        open($fh,">$fname");
        unless ($fh) { die "failed to open outfile for call count for $0!" };
    }
    else {
        open($fh,">$0.callcount");
        $fh or die "failed to open output file $0.callcount: $!";
    }
    for my $c (sort { $a <=> $b } @counts) {
        my $subs = $counts{$c};
        for my $sub (sort keys %$subs) {
            my $cases = $subs->{$sub};
            my @calls = sort keys %$cases;
            print $fh join("\t",$c, $sub,$DB::sub{$sub},@calls),"\n";
        }
    }
}

1;

