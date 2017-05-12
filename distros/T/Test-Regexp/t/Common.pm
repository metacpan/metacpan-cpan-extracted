package t::Common;

use strict;
use warnings;
no  warnings 'syntax';

use 5.010;

use Test::More;
use Exporter ();

use charnames ":full";

our @EXPORT    = qw [check];
our @EXPORT_OK = qw [$count $comment $failures $reason $test $line];
our @ISA       = qw [Exporter];

my  $result    = "";
our $count     = 0;
our $failures  = 0;
our $comment;
our $reason;
our $test;
our $line;

sub escape;

my $ESCAPE_NONE           = 0;
my $ESCAPE_WHITE_SPACE    = 1;
my $ESCAPE_NAMES          = 2;
my $ESCAPE_CODES          = 3;
my $ESCAPE_NON_PRINTABLE  = 4;


#
# results:    Arrayref with test results (from Test::Tester)
# premature:  Anything appearing before test results (from Test::Tester)
# match:      Should the pattern match or not? Default 0.
# match_res:  Return value from the "match" function (from Test::Regexp)
# pattern:    Pattern passed to "match" function (pattern or keep_pattern)
# subject:    String the pattern is matched against (subject option for "match")
# expected:   Expected results of the tests. String of 'P', 'F', 'S' 
#             for "Pass", "Fail" and "Skip".
# comment:   (Optional) 'comment' or 'name' option passed to "match".
# keep:      (Optional) If true, the pattern is a keep pattern.
# reason:    (Optional) The "reason" parameter passed to "match".
# todo:      (Optional) Todo tests, with reason.
# escape:    (Optional) Escape style used
#
sub check {
    my %arg = @_;

    my $results   = $arg {results};
    my $premature = $arg {premature};
    my $match     = $arg {match}     || 0;
    my $match_res = $arg {match_res} || 0;
    my $pattern   = $arg {pattern};
    my $expected  = $arg {expected};
    my $subject   = $arg {subject};
    my $comment   = $arg {comment}   // "";
    my $keep      = $arg {keep};
    my $reason    = $arg {reason};
    my $test      = $arg {test};
    my $line      = $arg {line};
    my $todo      = $arg {todo};
    my $escape    = $arg {escape} // (${^UNICODE} ? $ESCAPE_NON_PRINTABLE
                                                  : $ESCAPE_CODES);
    
    my $op        = $match ? "=~" : "!~";
    my $name      = qq {"$subject" $op /$pattern/};

    $expected = [split // => $expected] unless ref $expected;

    pass "Checking tests";

    ok !$premature, "    No preceeding garbage";

    #
    # Number of tests?
    #
    if (@$results == @$expected) {
        pass "    $name: number of tests";
    }
    else {
        fail sprintf "    %s: Got %d tests, expected %d tests" =>
                         $name, scalar @$results, scalar @$expected;
    }

    #
    # Correct return value from match?
    #
    my $match_res_bool =  $match_res                   ? 1 : 0;
    my $expected_bool  = (grep {$_ eq 'F'} @$expected) ? 0 : 1;

    if (defined $todo) {
        pass "    Todo test";
    }
    else {
        is $match_res_bool, $expected_bool, "    $name: (no)match value";
    }

    for (my $i = 0; $i < @$results; $i ++) {
        my $result  =  $$results  [$i];
        my $exp     =  $$expected [$i];
        my $ok      =  $$result {ok};
        my $comment =  $$result {name};
           $comment =~ s/^\s+//;
           $comment =  "Skipped" if $$result {type} eq 'skip';

        ok $ok && $exp =~ /[PS]/ ||
          !$ok && $exp =~ /[FS]/, "    $name: sub-test ($comment)";
    }
    #
    # Check the name of the first test
    #
    my $test_name    = $$results [0] {name} // "";
    my $neg          = $match ? "" : "not ";
    my $exp_comment  = length ($comment) ? qq {"$comment"}
                                         : '/' . (ref $pattern ?     $pattern
                                                               : qr {$pattern})
                                               . '/';
       $exp_comment  = qq {qq {$subject} ${neg}matched by $exp_comment};
       $exp_comment .= " (with -Keep)" if $keep;
       $exp_comment .= sprintf " [%s:%d]" => $$line [1], $$line [0] if $line;
       $exp_comment .= sprintf " [Reason: %s]" => $reason
                                       if defined $reason && !$match;
       $exp_comment .= sprintf " [Test: %s]"   => $test
                                       if defined $test   &&  $match;
       $exp_comment  = escape $exp_comment, $escape;

    is $test_name, $exp_comment, "    Test name";
}


#
# Almost an identical copy from Test::Common. Better would be a
# different implementation.
#
sub escape {
    my ($str, $escape) = @_;
    return if $escape == $ESCAPE_NONE;

    $str =~ s/\n/\\n/g;
    $str =~ s/\t/\\t/g;
    $str =~ s/\r/\\r/g;

    if ($escape == $ESCAPE_NAMES) {
        $str =~ s{([^\x20-\x7E])}
                 {my $name = charnames::viacode (ord $1);
                  $name ? sprintf "\\N{%s}"   => $name
                        : sprintf "\\x{%02X}" => ord $1}eg;
    }
    elsif ($escape == $ESCAPE_CODES) {
        $str =~ s{([^\x20-\x7E])}
                 {sprintf "\\x{%02X}" => ord $1}eg;
    }
    elsif ($escape == $ESCAPE_NON_PRINTABLE) {
        $str =~ s{([\x00-\x1F\xFF])}
                 {sprintf "\\x{%02X}" => ord $1}eg;   
    }

    $str =~ s/#/\\#/g;   # TAP does this
    $str;
}

    
END {done_testing}


1;


__END__
