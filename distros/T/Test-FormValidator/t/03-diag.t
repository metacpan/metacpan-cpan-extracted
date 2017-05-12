
use strict;

use Test::More 'no_plan';
use Data::Dumper;

use Data::FormValidator::Constraints qw(:closures);
use Test::FormValidator;

my $tfv = Test::FormValidator->new({}, {
    msgs => {
        prefix            => 'err_',
        invalid           => 'invalid',
        missing           => 'missing',
        format            => '%s',
    },
});

$tfv->profile({
    required => ['foo', 'bar', 'baz'],
    optional => ['biz', 'bam', 'boom'],
    constraint_methods => {
        foo => email(),
        biz => [
            sub {
                my $dfv = shift;
                $dfv->name_this('biz_bad1!');
                return;
            },
            sub {
                my $dfv = shift;
                $dfv->name_this('biz_bad2!');
                return;
            }
        ],
        boom => sub {
            my $dfv = shift;
            $dfv->name_this('boom_bad!');
            return;
        }
    },
});

eval {
    $tfv->_results_diagnostics;
};
ok($@, "prevented from getting diagnostics before check");

my $results = $tfv->check(
    foo  => 1,
    biz  => 1,
    boom => 1,
);

my $expected_diag = <<EOF;
Validation Results:
  missing: bar, baz
  invalid:
     biz     =>  biz_bad1!, biz_bad2!
     boom    =>  boom_bad!
     foo     =>  email
EOF

my $expected_msgs = <<EOF;
    {
      'err_bar' => 'missing',
      'err_baz' => 'missing',
      'err_biz' => 'invalid invalid',
      'err_boom' => 'invalid',
      'err_foo' => 'invalid'
    }
EOF

ok(!$results, "profile working");

my @missing = sort $results->missing;
my @invalid = sort $results->invalid;

is_deeply(\@missing, ['bar', 'baz'],         "results: caught missing fields");
is_deeply(\@invalid, ['biz', 'boom', 'foo'], "results: caught invalid fields");

my $diag = $tfv->_results_diagnostics;
my $msgs;

($diag, $msgs) = split /^\s*msgs:\s*$/ms, $diag;

ok(compare_diag($diag, $expected_diag), "non-messages diagnostics match");
ok(compare_diag($msgs, $expected_msgs), "messages diagnostics match");

# Pull the messages from the results object and generate a dump like
# T::FV does - this should match the messages dump that T::FV produces

my $messages_dump = get_msgs_dump($results->msgs);
ok(compare_diag($msgs, $messages_dump), "messages diagnostics match messages dump");


# Now test the diagnostics message with valid input

$tfv->check({}, {});
$expected_diag = <<EOF;
    Validation Results:
    input is valid!
EOF
ok(compare_diag($tfv->_results_diagnostics, $expected_diag), "valid input: diagnostics match");



# Pull the messages from the results object and generate a dump like T::FV does
sub get_msgs_dump {
    my $messages = shift;
    my $dumper = Data::Dumper->new([$results->msgs]);
    $dumper->Terse(1);
    $dumper->Sortkeys(1);
    my $messages_dump = $dumper->Dump;
    return $messages_dump;
}

sub compare_diag {
    my ($first, $second) = @_;

    # split on newlines
    my @first  = split /[\r\n]+/, $first;
    my @second = split /[\r\n]+/, $second;

    # remove blank lines
    foreach my $lines (\@first, \@second) {
        @$lines = grep { /\S/ } @$lines;
    }

    if (@first != @second) {
        diag "diagnostics mismatch:\ngot:\n$first\nexpected:\n$second";
        return;
    }

    for (my $i = 0; $i < @first; $i++) {
        for my $line ($first[$i], $second[$i]) {
            $line =~ s/^\s+//g;
            $line =~ s/\s+$//g;
        }
        if ($first[$i] ne $second[$i]) {
            diag qq{diagnostics mismatch at line $i. Got: "$first[$i]", but expected: "$second[$i]"};
            return;
        }
    }

    return 1;
}

