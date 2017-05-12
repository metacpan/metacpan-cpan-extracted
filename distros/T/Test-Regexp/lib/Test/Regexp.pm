package Test::Regexp;

use 5.010;

BEGIN {
    binmode STDOUT, ":utf8";
}

use strict;
use warnings;
use charnames ":full";
no  warnings 'syntax';

use Exporter ();
use Test::Builder;

our @EXPORT  = qw [match no_match];
our @ISA     = qw [Exporter Test::More];

our $VERSION = '2017040101';


my $Test = Test::Builder -> new;

my $ESCAPE_NONE           = 0;
my $ESCAPE_WHITE_SPACE    = 1;
my $ESCAPE_NAMES          = 2;
my $ESCAPE_CODES          = 3;
my $ESCAPE_NON_PRINTABLE  = 4;
my $ESCAPE_DEFAULT        = ${^UNICODE} ? $ESCAPE_NON_PRINTABLE 
                                        : $ESCAPE_CODES;

sub import {
    my $self = shift;
    my $pkg  = caller;

    my %arg  = @_;

    $Test -> exported_to ($pkg);

    $arg {import} //= [qw [match no_match]];

    while (my ($key, $value) = each %arg) {
        if ($key eq "tests") {
            $Test -> plan ($value);
        }
        elsif ($key eq "import") {
            $self -> export_to_level (1, $self, $_) for @{$value || []};
        }
        else {
            die "Unknown option '$key'\n";
        }
    }
}


my $__ = "    ";

sub escape {
    my ($str, $escape) = @_;
    $escape //= $ESCAPE_DEFAULT;
    return $str if $escape == $ESCAPE_NONE;
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
    $str;
}

sub pretty {
    my $str = shift;
    my %arg = @_;
    substr ($str, 50, -5, "...") if length $str > 55 && !$arg {full_text};
    $str = escape $str, $arg {escape};
    $str;
}


sub mess {
    my $val = shift;
    unless (defined $val) {return 'undefined'}
    my %arg = @_;
    my $pretty = pretty $val, full_text => $arg {full_text},
                              escape    => $arg {escape};
    if ($pretty eq $val && $val !~ /'/) {
        return "eq '$val'";
    }
    elsif ($pretty !~ /"/) {
        return 'eq "' . $pretty . '"';
    }
    else {
        return "eq qq {$pretty}";
    }
}


sub todo {
    my %arg       =  @_;
    my $subject   =  $arg {subject};
    my $comment   =  $arg {comment};
    my $upgrade   =  $arg {upgrade};
    my $downgrade =  $arg {downgrade};
    my $neg       =  $arg {match} ? "" : "not ";
    my $full_text =  $arg {full_text};
    my $escape    =  $arg {escape};

    my $line      = "";

    if ($arg {show_line}) {
        no warnings 'once';
        my ($file, $l_nr)  = (caller ($Test::Builder::deepness // 1)) [1, 2];
        $line = " [$file:$l_nr]";
    }

    my $subject_pretty = pretty $subject, full_text => $full_text,
                                          escape    => $escape;
    my $Comment        = qq {qq {$subject_pretty}};
       $Comment       .= qq { ${neg}matched by "$comment"};

    my @todo = [$subject, $Comment, $line];

    #
    # If the subject isn't already UTF-8, and there are characters in
    # the range "\x{80}" .. "\x{FF}", we do the test a second time,
    # with the subject upgraded to UTF-8.
    #
    # Otherwise, if the subject is in UTF-8 format, and there are *no*
    # characters with code point > 0xFF, but with characters in the 
    # range 0x80 .. 0xFF, we downgrade and test again.
    #
    if ($upgrade && ($upgrade == 2 ||    !utf8::is_utf8 ($subject) 
                                      && $subject =~ /[\x80-\xFF]/)) {
        my $subject_utf8 = $subject;
        if (utf8::upgrade ($subject_utf8)) {
            my $Comment_utf8   = qq {qq {$subject_pretty}};
               $Comment_utf8  .= qq { [UTF-8]};
               $Comment_utf8  .= qq { ${neg}matched by "$comment"};

            push @todo => [$subject_utf8, $Comment_utf8, $line];
        }
    }
    elsif ($downgrade && ($downgrade == 2 ||     utf8::is_utf8 ($subject)
                                             && $subject =~ /[\x80-\xFF]/
                                             && $subject !~ /[^\x00-\xFF]/)) {
        my $subject_non_utf8 = $subject;
        if (utf8::downgrade ($subject_non_utf8)) {
            my $Comment_non_utf8  = qq {qq {$subject_pretty}};
               $Comment_non_utf8 .= qq { [non-UTF-8]};
               $Comment_non_utf8 .= qq { ${neg}matched by "$comment"};

            push @todo => [$subject_non_utf8, $Comment_non_utf8, $line];
        }
    }

    @todo;
}
    


#
# Arguments:
#   name:         'Name' of the pattern.
#   pattern:       Pattern to be tested, without captures.
#   keep_pattern:  Pattern to be tested, with captures.
#   subject:       String to match.
#   captures:      Array of captures; elements are either strings
#                  (match for the corresponding numbered capture),
#                  or an array, where the first element is the name
#                  of the capture and the second its value.
#   comment:       Comment to use, defaults to name or "".
#   utf8_upgrade:  If set, upgrade the string if applicable. Defaults to 1.
#   utf8_downgrade If set, downgrade the string if applicable. Defaults to 1.
#   match          If true, pattern(s) should match, otherwise, should fail
#                  to match. Defaults to 1.
#   reason         The reason a match should fail.
#   test           What is tested.                  
#   todo           This test is a todo test; argument is the reason.
#   show_line      Show file name/line number of call to 'match'.
#   full_text      Don't shorten long messages.
#

sub match {
    my %arg            = @_;

    my $name           = $arg {name};
    my $pattern        = $arg {pattern};
    my $keep_pattern   = $arg {keep_pattern};
    my $subject        = $arg {subject};
    my $captures       = $arg {captures}       // [];
    my $comment        = escape $arg {comment} // $name // "";
    my $upgrade        = $arg {utf8_upgrade}   // 1;
    my $downgrade      = $arg {utf8_downgrade} // 1;
    my $match          = $arg {match}          // 1;
    my $reason         = defined $arg {reason}
                                       ? " [Reason: " . $arg {reason} . "]"
                                       : "";
    my $test           = defined $arg {test}
                                       ? " [Test: "   . $arg {test}   . "]"
                                       : "";
    my $show_line      = $arg {show_line};
    my $full_text      = $arg {full_text};
    my $escape         = $arg {escape};
    my $todo           = $arg {todo};
    my $keep_message   = $arg {no_keep_message} ? "" : " (with -Keep)";

    my $numbered_captures;
    my $named_captures;

    my $pass           = 1;

    #
    # First split the captures into a hash (for named captures) and
    # an array (for numbered captures) so we can check $1 and friends, and %-.
    #
    foreach my $capture (@$captures) {
        if (ref $capture eq 'ARRAY') {
            my ($name, $match) = @$capture;
            push   @$numbered_captures => $match;
            push @{$$named_captures {$name}} => $match;
        }
        else {
            push @$numbered_captures => $capture;
        }
    }
    
    $numbered_captures ||= [];
    $named_captures    ||= {};

    my @todo = todo subject   => $subject,
                    comment   => $comment,
                    upgrade   => $upgrade,
                    downgrade => $downgrade,
                    match     => $match,
                    show_line => $show_line,
                    full_text => $full_text,
                    escape    => $escape;

    $Test -> todo_start ($todo) if defined $todo;

    #
    # Now we will do the tests.
    #
    foreach my $todo (@todo) {
        my $subject = $$todo [0];
        my $comment = $$todo [1];
        my $line    = $$todo [2];

        if ($match && defined $pattern) {
            my $comment = $comment;
            my $pat     =  ref $pattern ?     $pattern
                                        : qr /$pattern/;
               $comment =~ s{""$}{/$pat/};
               $comment .= "$line$test";
            #
            # Test match; match should also be complete, and not
            # have any captures.
            #
            SKIP: {
                my $result = $subject =~ /^$pattern/;
                unless ($Test -> ok ($result, $comment)) {
                    $Test -> skip ("Match failed") for 1 .. 3;
                    $pass = 0;
                    last SKIP;
                }

                #
                # %- contains an entry for *each* named group, regardless
                # whether it's a capture or not.
                #
                my $named_matches  = 0;
                   $named_matches += @$_ for values %-;

                unless ($Test -> is_eq ($&, $subject,
                                       "${__}match is complete")) {
                    $Test -> skip ("Match failed") for 2 .. 3;
                    $pass = 0;
                    last SKIP;
                }
                 
                $pass = 0 unless
                    $Test -> is_eq (scalar @+, 1,
                                    "${__}no numbered captures");
                $pass = 0 unless
                    $Test -> is_eq ($named_matches, 0,
                                   "${__}no named captures");
            }
        }


        if ($match && defined $keep_pattern) {
            my $comment = $comment;
            my $pat     =  ref $keep_pattern ?     $keep_pattern
                                             : qr /$keep_pattern/;
               $comment =~ s{""$}{/$pat/};
               $comment .= $keep_message;
               $comment .= "$line$test";
            #
            # Test keep. Should match, and the parts as well.
            #
            # Total number of tests:
            #   - 1 for match.
            #   - 1 for match complete.
            #   - 1 for each named capture.
            #   - 1 for each capture name.
            #   - 1 for number of different capture names.
            #   - 1 for each capture.
            #   - 1 for number of captures.
            # So, if you only have named captures, and all the names
            # are different, you have 4 + 3 * N tests.
            # If you only have numbered captures, you have 4 + N tests.
            #
            SKIP: {
                my $nr_of_tests  = 0;
                   $nr_of_tests += 1;  # For match.
                   $nr_of_tests += 1;  # For match complete.
                   $nr_of_tests += @{$_} for values %$named_captures;
                                       # Number of named captures.
                   $nr_of_tests += scalar keys %$named_captures;
                                       # Number of different named captures.
                   $nr_of_tests += 1;  # Right number of named captures.
                   $nr_of_tests += @$numbered_captures;
                                       # Number of numbered captures.
                   $nr_of_tests += 1;  # Right number of numbered captures.

                my ($amp, @numbered_matches, %minus);

                my $result = $subject =~ /^$keep_pattern/;
                unless ($Test -> ok ($result, $comment)) {
                    $Test -> skip ("Match failed") for 2 .. $nr_of_tests;
                    $pass = 0;
                    last SKIP;
                }


                #
                # Copy $&, $N and %- before doing anything that
                # migh override them.
                #

                $amp = $&;

                #
                # Grab numbered captures.
                #
                for (my $i = 1; $i < @+; $i ++) {
                    no strict 'refs';
                    push @numbered_matches => $$i;
                }

                #
                # Copy %-;
                #
                while (my ($key, $value) = each %-) {
                    $minus {$key} = [@$value];
                }

                #
                # Test to see if match is complete.
                #
                unless ($Test -> is_eq ($amp, $subject,
                                       "${__}match is complete")) {
                    $Test -> skip ("Match incomplete") for 3 .. $nr_of_tests;
                    $pass = 0;
                    last SKIP;
                }

                #
                # Test named captures.
                #
                while (my ($key, $value) = each %$named_captures) {
                    for (my $i = 0; $i < @$value; $i ++) {
                        $pass = 0 unless
                            $Test -> is_eq (
                                $minus {$key} ? $minus {$key} [$i] : undef,
                                $$value [$i],
                               "${__}\$- {$key} [$i] " .
                                mess ($$value [$i], full_text => $full_text,
                                                    escape    => $escape));
                    }
                    $pass = 0 unless
                        $Test -> is_num (scalar @{$minus {$key} || []},
                                 scalar @$value, "$__${__}capture '$key' has " .
                                 (@$value == 1 ? "1 match" :
                                        @$value . " matches"));
                }
                #
                # Test for the right number of captures.
                #
                $pass = 0 unless
                    $Test -> is_num (scalar keys %minus,
                                     scalar keys %$named_captures,
                              $__ . scalar (keys %$named_captures)
                                  . " named capture groups"
                    );


                #
                # Test numbered captures.
                #
                for (my $i = 0; $i < @$numbered_captures; $i ++) {
                    $pass = 0 unless
                        $Test -> is_eq ($numbered_matches [$i],
                                        $$numbered_captures [$i],
                                       "${__}\$" . ($i + 1) . " " .
                                        mess ($$numbered_captures [$i],
                                                full_text => $full_text,
                                                escape    => $escape));
                }
                $pass = 0 unless
                    $Test -> is_num (scalar @numbered_matches,
                                     scalar @$numbered_captures,
                                     $__ .
                                     (@$numbered_captures == 1     ?
                                        "1 numbered capture group" :
                                      @$numbered_captures .
                                         " numbered capture groups"));
            }
        }

        if (!$match && defined $pattern) {
            my $comment = $comment;
            my $pat     =  ref $pattern ?     $pattern
                                        : qr /$pattern/;
               $comment =~ s{""$}{/$pat/};
               $comment .= "$line$reason";
            my $r = $subject =~ /^$pattern/;
            $pass = 0 unless
                $Test -> ok (!$r || $subject ne $&, $comment);
        }
        if (!$match && defined $keep_pattern) {
            my $comment = $comment;
            my $pat     =  ref $keep_pattern ?     $keep_pattern
                                             : qr /$keep_pattern/;
               $comment =~ s{""$}{/$pat/};
               $comment .= $keep_message;
               $comment .= "$line$reason";
            my $r = $subject =~ /^$keep_pattern/;
            $pass = 0 unless
                $Test -> ok (!$r || $subject ne $&, $comment);
        }
    }

    $Test -> todo_end if defined $todo;

    $pass;
}

sub no_match {
    push @_ => match => 0;
    goto &match;
}

sub new {
    "Test::Regexp::Object" -> new
}

package Test::Regexp::Object;

sub new {
    bless \do {my $var} => shift;
}

use Hash::Util::FieldHash qw [fieldhash];

fieldhash my %pattern;
fieldhash my %keep_pattern;
fieldhash my %name;
fieldhash my %comment;
fieldhash my %utf8_upgrade;
fieldhash my %utf8_downgrade;
fieldhash my %match;
fieldhash my %reason;
fieldhash my %test;
fieldhash my %show_line;
fieldhash my %full_text;
fieldhash my %escape;
fieldhash my %todo;
fieldhash my %tags;
fieldhash my %no_keep_message;

sub init {
    my $self = shift;
    my %arg  = @_;

    $pattern             {$self} = $arg {pattern};
    $keep_pattern        {$self} = $arg {keep_pattern};
    $name                {$self} = $arg {name};
    $comment             {$self} = $arg {comment};
    $utf8_upgrade        {$self} = $arg {utf8_upgrade};
    $utf8_downgrade      {$self} = $arg {utf8_downgrade};
    $match               {$self} = $arg {match};
    $reason              {$self} = $arg {reason};
    $test                {$self} = $arg {test};
    $show_line           {$self} = $arg {show_line};
    $full_text           {$self} = $arg {full_text};
    $escape              {$self} = $arg {escape};
    $todo                {$self} = $arg {todo};
    $tags                {$self} = $arg {tags} if exists $arg {tags};
    $no_keep_message     {$self} = $arg {no_keep_message};

    $self;
}

sub args {
    my  $self = shift;
    (
        pattern             => $pattern             {$self},
        keep_pattern        => $keep_pattern        {$self},
        name                => $name                {$self},
        comment             => $comment             {$self},
        utf8_upgrade        => $utf8_upgrade        {$self},
        utf8_downgrade      => $utf8_downgrade      {$self},
        match               => $match               {$self},
        reason              => $reason              {$self},
        test                => $test                {$self},
        show_line           => $show_line           {$self},
        full_text           => $full_text           {$self},
        escape              => $escape              {$self},
        todo                => $todo                {$self},
        no_keep_message     => $no_keep_message     {$self},
    )
}

sub match {
    my  $self     = shift;
    my  $subject  = shift;
    my  $captures = @_ % 2 ? shift : undef;

    Test::Regexp::match subject  => $subject,
                        captures => $captures,
                        $self    -> args, 
                        @_;
}

sub no_match {
    my  $self    = shift;
    my  $subject = shift;

    Test::Regexp::no_match subject  => $subject,
                           $self    -> args,
                           @_;
}

sub name {$name {+shift}}

sub set_tag {
    my $self = shift;
    $tags {$self} {$_ [0]} = $_ [1];
}
sub tag {
    my $self = shift;
    $tags {$self} {$_ [0]};
}



1;

__END__

=pod

=head1 NAME 

Test::Regexp - Test your regular expressions

=head1 SYNOPSIS

 use Test::Regexp 'no_plan';

 match    subject      => "Foo",
          pattern      => qr /\w+/;

 match    subject      => "Foo bar",
          keep_pattern => qr /(?<first_word>\w+)\s+(\w+)/,
          captures     => [[first_word => 'Foo'], ['bar']];

 no_match subject      => "Baz",
          pattern      => qr /Quux/;

 $checker = Test::Regexp -> new -> init (
    keep_pattern => qr /(\w+)\s+\g{-1}/,
    name         => "Double word matcher",
 );

 $checker -> match    ("foo foo", ["foo"]);
 $checker -> no_match ("foo bar");

=head1 DESCRIPTION

This module is intended to test your regular expressions. Given a subject
string and a regular expression (aka pattern), the module not only tests
whether the regular expression complete matches the subject string, it
performs a C<< utf8::upgrade >> or C<< utf8::downgrade >> on the subject
string and performs the tests again, if necessary. Furthermore, given a
pattern with capturing parenthesis, it checks whether all captures are
present, and in the right order. Both named and unnamed captures are checked.

By default, the module exports two subroutines, C<< match >> and
C<< no_match >>. The latter is actually a thin wrapper around C<< match >>,
calling it with C<< match => 0 >>.

=head2 "Complete matching"

A match is only considered to successfully match if the entire string
is matched - that is, if C<< $& >> matches the subject string. So:

  Subject    Pattern

  "aaabb"    qr /a+b+/     # Considered ok
  "aaabb"    qr /a+/       # Not considered ok

For efficiency reasons, when the matching is performed the pattern
is actually anchored at the start. It's not anchored at the end as
that would potentially influence the matching.

=head2 UTF8 matching

Certain regular expression constructs match differently depending on 
whether UTF8 matching is in effect or not. This is only relevant 
if the subject string has characters with code points between 128 and
255, and no characters above 255 -- in such a case, matching may be
different depending on whether the subject string has the UTF8 flag
on or not. C<< Test::Regexp >> detects such a case, and will then 
run the tests twice; once with the subject string C<< utf8::downgraded >>,
and once with the subject string C<< utf8::upgraded >>.

=head2 Number of tests

There's no fixed number of tests that is run. The number of tests
depends on the number of captures, the number of different names of
captures, and whether there is the need to up- or downgrade the 
subject string.

It is therefore recommended to use
C<< use Text::Regexp tests => 'no_plan'; >>.
In a later version, C<< Test::Regexp >> will use a version of 
C<< Test::Builder >> that allows for nested tests.

=head3 Details

The number of tests is as follows: 

If no match is expected (C<< no_match => 0 >>, or C<< no_match >> is used),
only one test is performed.

Otherwise (we are expecting a match), if C<< pattern >> is used, there
will be three tests. 

For C<< keep_pattern >>, there will be four tests, plus one tests for
each capture, an additional test for each named capture, and a test
for each name used in the set of named captures. So, if there are
C<< N >> captures, there will be at least C<< 4 + N >> tests, and
at most C<< 4 + 3 * N >> tests.

If both C<< pattern >> and C<< keep_pattern >> are used, the number of
tests add up. 

If C<< Test::Regexp >> decides to upgrade or downgrade, the number of 
tests double.

=head2 C<< use >> options

When using C<< Test::Regexp >>, there are a few options you can
give it.

=over 4

=item C<< tests => 'no_plan' >>, C<< tests => 123 >>

The number of tests you are going to run. Since takes some work to
figure out how many tests will be run, for now the recommendation
is to use C<< tests => 'no_plan' >>.

=item C<< import => [methods] >>

By default, the subroutines C<< match >> and C<< no_match >> are 
exported. If you want to import a subset, use the C<< import >>
tag, and give it an arrayref with the names of the subroutines to
import.

=back

=head2 C<< match >>

The subroutine C<< match >> is the workhorse of the module. It takes
a number of named arguments, most of them optional, and runs one or
more tests. It returns 1 if all tests were run successfully, and 0
if one or more tests failed. The following options are available:

=over 4

=item C<< subject => STRING >>

The string against which the pattern is tested is passed to C<< match >>
using the C<< subject >> option. It's an error to not pass in a subject.

=item C<< pattern => PATTERN >>, C<< keep_pattern => PATTERN >>

A pattern (aka regular expression) to test can be passed with one of
C<< pattern >> or C<< keep_pattern >>. The former should be used if the
pattern does not have any matching parenthesis; the latter if the pattern
does have capturing parenthesis. If both C<< pattern >> and C<< keep_pattern >>
are provided, the subject is tested against both. It's an error to not give
either C<< pattern >> or C<< keep_pattern >>.

=item C<< captures => [LIST] >>

If a regular expression is passed with C<< keep_pattern >> you should 
pass in a list of captures using the C<< captures >> option.

This list should contain all the captures, in order. For unnamed captures,
this should just be the string matched by the capture; for a named capture,
this should be a two element array, the first element being the name of
the capture, the second element the capture. Named and unnamed captures
may be mixed, and the same name for a capture may be repeated.

Example:

 match  subject      =>  "Eland Wapiti Caribou",
        keep_pattern =>  qr /(\w+)\s+(?<a>\w+)\s+(\w+)/,
        captures     =>  ["Eland", [a => "Wapiti"], "Caribou"];

=item C<< name => NAME >>

The "name" of the test. It's being used in the test comment.

=item C<< comment => NAME >>

An alternative for C<< name >>. If both are present, C<< comment >> is used.

=item C<< utf8_upgrade => 0 >>, C<< utf8_downgrade => 0 >>

As explained in L<< /UTF8 matching >>, C<< Test::Regexp >> detects whether
a subject may provoke different matching depending on its UTF8 flag, and
then it C<< utf8::upgrades >> or C<< utf8::downgrades >> the subject
string and runs the test again. Setting C<< utf8_upgrade >> to 0 prevents
C<< Test::Regexp >> from downgrading the subject string, while 
setting C<< utf8_upgrade >> to 0 prevents C<< Test::Regexp >> from 
upgrading the subject string.

=item C<< match => BOOLEAN >>

By default, C<< match >> assumes the pattern should match. But it also 
important to test which strings do not match a regular expression. This
can be done by calling C<< match >> with C<< match => 0 >> as parameter.
(Or by calling C<< no_match >> instead of C<< match >>). In this case,
the test is a failure if the pattern completely matches the subject 
string. A C<< captures >> argument is ignored. 

=item C<< reason => STRING >>

If the match is expected to fail (so, when C<< match => 0 >> is passed,
or if C<< no_match >> is called), a reason may be provided with the
C<< reason >> option. The reason is then printed in the comment of the
test.

=item C<< test => STRING >>

If the match is expected to pass (when C<< match >> is called, without
C<< match >> being false), and this option is passed, a message is printed
indicating what this specific test is testing (the argument to C<< test >>).

=item C<< todo => STRING >>

If the C<< todo >> parameter is used (with a defined value), the tests
are assumed to be TODO tests. The argument is used as the TODO message.

=item C<< full_text => BOOL >>

By default, long test messages are truncated; if a true value is passed, 
the message will not get truncated.

=item C<< escape => INTEGER >>

Controls how non-ASCII and non-printables are displayed in generated
test messages:

=over 2

=item B<< 0 >>

No characters are escape, everything is displayed as is.

=item B<< 1 >>

Show newlines, linefeeds and tabs using their usual escape sequences
(C<< \n >>, C<< \r >>, and C<< \t >>).

=item B<< 2 >>

Show any character outside of the printable ASCII characters as named
escapes (C<< \N{UNICODE NAME} >>), or a hex escape if the unicode name
is not found (C<< \x{XX} >>). This is the default if C<< -CO >> is not in
effect (C<< ${^UNICODE} >> is false).

Newlines, linefeeds and tabs are displayed as above.

=item B<< 3 >>

Show any character outside of the printable ASCII characters as hext
escapes (C<< \x{XX} >>).

Newlines, linefeeds and tabs are displayed as above.

=item B<< 4 >>

Show the non-printable ASCII characters as hex escapes (C<< \x{XX} >>);
any non-ASCII character is displayed as is. This is the default if
C<< -CO >> is in effect (C<< ${^UNICODE} >> is true).

Newlines, linefeeds and tabs are displayed as above.

=back

=item C<< no_keep_message => BOOL >>

If matching against a I<< keeping >> pattern, a message C<< (with -Keep) >>
is added to the comment. Setting this parameter suppresses this message.
Mostly useful for C<< Regexp::Common510 >>.

=back

=head2 C<< no_match >>

Similar to C<< match >>, except that it tests whether a pattern does
B<< not >> match a string. Accepts the same arguments as C<< match >>,
except for C<< match >>.

=head2 OO interface

Since one typically checks a pattern with multiple strings, and it can
be tiresome to repeatedly call C<< match >> or C<< no_match >> with the
same arguments, there's also an OO interface. Using a pattern, one constructs
an object and can then repeatedly call the object to match a string.

To construct and initialize the object, call the following:

 my $checker = Test::Regexp -> new -> init (
    pattern      => qr  /PATTERN/,
    keep_pattern => qr /(PATTERN)/,
    ...
 );

C<< init >> takes exactly the same arguments as C<< match >>, with the
exception of C<< subject >> and C<< captures >>. To perform a match,
all C<< match >> (or C<< no_match >>) on the object. The first argument
should be the subject the pattern should match against (see the
C<< subject >> argument of C<< match >> discussed above). If there is a
match against a capturing pattern, the second argument is a reference
to an array with the matches (see the C<< captures >> argument of
C<< match >> discussed above).

Both C<< match >> and C<< no_match >> can take additional (named) arguments,
identical to the none-OO C<< match >> and C<< no_match >> routines.

=head1 RATIONALE

The reason C<< Test::Regexp >> was created is to aid testing for
the rewrite of C<< Regexp::Common >>.

=head1 DEVELOPMENT

The current sources of this module are found on github,
L<< git://github.com/Abigail/Test-Regexp.git >>.

=head1 AUTHOR

Abigail L<< mailto:test-regexp@abigail.be >>.

=head1 COPYRIGHT and LICENSE

Copyright (C) 2009 by Abigail

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:
      
The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.
      
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

=head1 INSTALLATION

To install this module, run, after unpacking the tar-ball, the
following commands:

   perl Makefile.PL
   make
   make test
   make install

=cut
