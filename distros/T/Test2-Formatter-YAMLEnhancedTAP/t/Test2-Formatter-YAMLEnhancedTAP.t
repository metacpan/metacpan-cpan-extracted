use strict;
use warnings;
use v5.16;
use Test::More;
use TAP::Harness;
use TAP::Formatter::File;

my @tests = grep { -f $_ } <t/fixtures/tests/*>;

plan tests => scalar(@tests);

sub slurp {
  my $file = shift;
  open(my $fh, '<', $file) or die "$!. $file";
  local $/ = undef;
  my $content = <$fh>;
  close($fh);
  return $content;
}

foreach my $test (@tests) {
  (my $output = $test) =~ s{(/fixtures)/tests/(.*).st}{$1/output/$2.out};
  my $expected = slurp($output);
  my $received = '';
  open(my $fh, '>', \$received);

  eval {
    my $harness = TAP::Harness->new({
        stdout => $fh,
        merge => 1,
        verbosity => 1,
        formatter_class => 'TAP::Formatter::File',
    });

    $harness->runtests($test);
  };

  my $fail = 0;
  is(rindex($received, $expected, 0), 0, "output of $test matches $output") or ($fail = 1);

  # I'll just pretty print it here.
  # tap output is quite hard to parse for me...
  if ($fail) {

    diag(<<~MSG);
    on $output
      Expected: '$expected'
      Received: '$received'
    MSG

    if ($ENV{TEST_SHOW_FULL_DIFF}) {
      print STDERR "\n== Expected $output ==\n";
      print STDERR $expected;
      print STDERR "\n====\n";

      print STDERR "\n== Received $output ==\n";
      print STDERR $received;
      print STDERR "\n====\n";
    }
  }
}
