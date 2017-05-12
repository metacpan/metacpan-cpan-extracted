# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More;
use strict;
use Text::Diff;
use Text::Patch;


# tests are disabled untill Text::Diff problem with missing newlines is fixed
# otherwise separated offline tests will be added, sorry :(
# //vladi
plan tests => 1;
ok(1);
exit;






#use Log::Trace;
#import Log::Trace 'warn' => { Deep => 0 };

my @styles = qw/Unified Context OldStyle/;

my $t1 = 'The Way that can be told of is not the eternal Way;
The name that can be named is not the eternal name.
The Nameless is the origin of Heaven and Earth;
The Named is the mother of all things.
Therefore let there always be non-being,
  so we may see their subtlety,
And let there always be being,
  so we may see their outcome.
The two are the same,
But after they are produced,
  they have different names.
';

my $t2 = 'The Nameless is the origin of Heaven and Earth;
The named is the mother of all things.

Therefore let there always be non-being,
  so we may see their subtlety,
And let there always be being,
  so we may see their outcome.
The two are the same,
But after they are produced,
  they have different names.
They both may be called deep and profound.
Deeper and more profound,
The door of all subtleties!
';

chomp(my $t1b = $t1);
chomp(my $t2b = $t2);

my @data; # [ text1, text2, style, break, testname, require Text-Diff > 0.35]

# test different styles with different data
for my $style (@styles) {
    push @data, [$t1,  $t2,  $style, 0, "normal"];
    push @data, [$t1,  $t2b, $style, 0, "t2 no newline"];
    push @data, [$t1b, $t2,  $style, 0, "t1 no newline", 1];
    push @data, [$t1b, $t2b, $style, 0, "t1,t2 no newline", 1];
}

# test breaking it with bad hunks
for my $style (@styles) {
    push @data, [$t1, $t2, $style, 1, "bad hunk"];
}

plan tests => scalar @data;

for my $d (@data) {
    my($test1, $test2, $style, $break, $name, $td_035) = @$d;
    my $patch = diff( \$test1, \$test2, { STYLE => $style } );

ok('***NODIFFFOUND***'), next if $patch eq '***NODIFFFOUND***';

    $test1 =~ s/(\r\n|\n)/ -- broken --$1/ if $break;

    SKIP: {
        skip "Text::Diff > 0.35 required", 1
            if $td_035 && $Text::Diff::VERSION <= 0.35;

        #warn "using patch: >>$patch<<\n";
        my $test3 = eval { patch( $test1, $patch, { STYLE => $style } ) };
        my $error = $@;
        my $testname = "patch $style ($name)";
        my $ok = $break ? $error : !$error && $test2 eq $test3;

        unless(ok($ok, "patch $style ($name)")) {
            diag "error: $error" if $error;
            DUMP("\n\n\n\n\n\n$style patch ($name)********************************************************");
            DUMP("text1:---------------------------------\n", $test1);
            DUMP("text2:---------------------------------\n", $test2);
            DUMP("$style patch:---------------------------------\n", $patch);
            DUMP("original:---------------------------------\n", $test2);
            DUMP("patched:---------------------------------\n", $test3);
        }
    }
}


sub diff_1
{

#### Text-Diff-1.37 seems broken, meanwhile use native diff(1)

  my $t1 = shift;
  my $t2 = shift;
  my $opt = shift;

  # Unified Context OldStyle

  open( my $o1, ">/tmp/__________t1" );
  print $o1 $$t1;
  close $o1;

  open( my $o2, ">/tmp/__________t2" );
  print $o2 $$t2;
  close $o2;

  my $diff;

  $diff = "/bin/diff" if -x "/bin/diff";
  $diff = "/usr/bin/diff" if -x "/usr/bin/diff";

  return '***NODIFFFOUND***' unless $diff;

  system "$diff -u /tmp/__________t1 /tmp/__________t2 > /tmp/__________t3" if $opt->{ STYLE } eq 'Unified';
  system "$diff -c /tmp/__________t1 /tmp/__________t2 > /tmp/__________t3" if $opt->{ STYLE } eq 'Context';
  system "$diff    /tmp/__________t1 /tmp/__________t2 > /tmp/__________t3" if $opt->{ STYLE } eq 'OldStyle';

  open( my $o3, "/tmp/__________t3" );
  my $t3 = join '', <$o3>;
  close $o3;

  unlink "/tmp/__________t1";
  unlink "/tmp/__________t2";
  unlink "/tmp/__________t3";

  return $t3;
}


#$t1 = 'here';
#$t2 = 'there';
#for my $style (@styles)
#  {
#  skip "Text::Diff > 0.35 required", 1
#      if $Text::Diff::VERSION <= 0.35;
#  my $patch  = diff( \$t1, \$t2, { STYLE => $style } );
#  my $result = patch( $t1, $patch, { STYLE => $style } );
#  ok( $result eq $t2, "patch $style (single no-nl lines)" );
#  }

sub TRACE {}
sub DUMP { print STDERR @_, "\n"; }

