#!/usr/bin/perl

# This is an example of how to write your own harness using
# Test::Harness::Straps.  It duplicates most of the features of
# Test::Harness.
#
# It uses an undocumented, experimental
# callback interface.  If you like it, don't like it, would like
# to see it become non-experimental, etc... discuss on perl-qa@perl.org
#
#   ./mini_harness.plx *.t

package My::Strap;
use Test::Harness;
use Test::Harness::Straps;
@ISA = qw(Test::Harness::Straps);

$| = 1;

my $s = My::Strap->new;

%handlers = (
    bailout     => sub {
        my($self, $line, $type, $totals) = @_;

        die sprintf "FAILED--Further testing stopped%s\n",
          $self->{bailout_reason} ? ": $self->{bailout_reason}" : '';
    },
    test        => sub {
        my($self, $line, $type, $totals) = @_;
        my $curr = $totals->{seen};

        if( $totals->{details}[-1]{ok} ) {
            $self->_display("ok $curr/$totals->{max}");
        }
        else {
            $self->_display("NOK $curr");
        }

        if( $curr > $self->{'next'} ) {
            $self->_print("Test output counter mismatch [test $curr]\n");
        }
        elsif( $curr < $self->{'next'} ) {
            $self->_print("Confused test output: test $curr answered after ".
                          "test ", $self->{next} - 1, "\n");
#            $self->{'next'} = $curr;
        }
    },
);

$s->{callback} = sub {
    my($self, $line, $type, $totals) = @_;
    print $line if $Test::Harness::Verbose;

    $handlers{$type}->($self, $line, $type, $totals) if $handlers{$type};
};


sub _display {
    my($self, $out) = @_;
    print "$ml$out";
}

sub _print {
    my($self) = shift;
    print @_;
}

my $width = Test::Harness::_leader_width(@ARGV);
foreach my $file (@ARGV) {
    ($leader, $ml) = Test::Harness::_mk_leader($file, $width);
    print $leader;
    my %result = $s->analyze_file($file);
    $s->_display($result{passing} ? 'ok' : 'FAILED');
    print "\n";
}
