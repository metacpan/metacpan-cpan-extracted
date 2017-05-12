# Copyright (c) 2008 Yahoo! Inc. All rights reserved.
# The copyrights to the contents of this file are licensed
# under the Perl Artistic License (ver. 15 Aug 1997)
##########################################################
package Test::Trivial;
##########################################################
use strict;
use warnings;
use IO::Handle;
use POSIX qw(strftime);
use Regexp::Common qw(balanced comment);
use Text::Diff;
use Filter::Simple;
use File::Basename;
use constant IFS => $/;

use version;
our $VERSION = version->declare("1.901.2");

FILTER {
    my @grps;
    my @comments;
    my $group_marker = '****Test::Trivial::Group****';
    while( s/$RE{balanced}{-parens=>'(){}[]'}{-keep}/$group_marker/s ) {
        push @grps, $1;
    }
    my $comment_marker = '****Test::Trivial::Comment****';
    while( s/$RE{comment}{Perl}{-keep}/$comment_marker/s ) {
        push @comments, $1;
    }

    s/TODO\s+(.*?);/do { local \$Test::Trivial::TODO = "Test Know to fail"; $1; };/gs;

    while( my $comment = shift @comments ) {
        s/\Q$comment_marker\E/$comment/;
    }
    while( my $grp = shift @grps ) {
        s/\Q$group_marker\E/$grp/;
    }
};

use Getopt::Long;
Getopt::Long::Configure(
    "pass_through"
);

our $FATAL   = 0;
our $VERBOSE = 0;
our $LEVEL   = 0;
our $DIFF    = "Unified";
our $TODO    = "";
our $LOG     = $ENV{TEST_TRIVIAL_LOG};

GetOptions(
    'fatal'   => \$FATAL,
    'verbose' => \$VERBOSE,
    'diff=s'  => \$DIFF,
    'log:s'   => \$LOG,
);

# rebless the singleton so we can intercept
# the _is_diag function
BEGIN {
    require Test::More;

    # forgive me, for I have sinned ...
    no warnings qw(redefine);

    # replace Test::More _format_stack so 
    # we can call Text::Diff when needed
    *Test::More::_format_stack = \&format_stack;
}

bless Test::More->builder, 'Test::Trivial::Builder';

sub import {
    my $package = shift;

    if ( !@_ ) {
        eval "use Test::More qw( no_plan )";
        if ( $@ ) {
            die "Failed to load Test::More: $@";
        }
    }        
    elsif ( @_ == 1 ) {
        eval "use Test::More qw( $_[0] )";
        if ( $@ ) {
            die "Failed to load Test::More: $@";
        }
    }
    else {
        my %args = @_;
        if( my $tests = delete $args{tests} ) {
            eval "use Test::More tests => \"$tests\"";
        }
        elsif( my $skip = delete $args{skip_all} ) {
            eval "use Test::More skip_all => \"$skip\"";
        }
        if ( $@ ) {
            die "Failed to load Test::More: $@";
        }
        if ( $args{diff} ) {
            $DIFF = $args{diff};
        }
    }

    # crude Exporter
    my ($pkg) = caller();
    for my $func ( qw(ERR OK NOK EQ ID ISA IS ISNT LIKE UNLIKE) ) {
        no strict 'refs';
        *{"${pkg}::$func"} = \&{$func};
    }

    if ( defined $LOG ) {
        my $logfile = $LOG;
        if( !$logfile ) {
            my ($name, $dir) = File::Basename::fileparse($0);
            $logfile = "$dir/$name.log";
        }
        open my $log, ">>$logfile" or die "Could not open $logfile: $!";
        my $tee = tie( *STDOUT, "Test::Trivial::IO::Tee", $log, \*STDOUT);
        tie( *STDERR, "Test::Trivial::IO::Tee", $log, \*STDERR);
        if( $VERBOSE ) {
            $SIG{__WARN__} = sub { print STDERR @_ };
        }
        else {
            $VERBOSE++;
            $SIG{__WARN__} = sub { $tee->log(@_) }
        }
        $SIG{__DIE__} = sub { print STDOUT @_ };
        my $tb = Test::Builder->new();
        $tb->output(\*STDOUT);
        $tb->failure_output(\*STDERR);
        warn "#"x50, "\n";
        warn "#\n";
        warn "# Test: $0\n";
        warn "# Time: ", POSIX::strftime("%Y-%m-%d %X", localtime()), "\n";
        warn "#\n";
        warn "#"x50, "\n";
    }
}

sub ERR (&) {
    my $code = shift;
    local $@;
    my $ret = eval {
        &$code;
    };
    return $@ if $@;
    return $ret;
}

sub OK ($;$) {
    my ($test, $msg) = @_;
    $msg ||= line_to_text();
    if( $VERBOSE ) {
        require Data::Dumper;
        warn "--------------------------------------------------------\n";
        warn Data::Dumper->Dump([$test], ["OK"]);
        warn "--------------------------------------------------------\n";
    }
    check($test) || warn_line_failure(1);
    ok($test, $msg) || ($FATAL && !$TODO && die "All errors Fatal\n");
    
}

sub NOK ($;$) {
    my ($test, $msg) = @_;
    $msg ||= line_to_text();
    if( $VERBOSE ) {
        require Data::Dumper;
        warn "--------------------------------------------------------\n";
        warn Data::Dumper->Dump([$test], ["NOK"]);
        warn "--------------------------------------------------------\n";
    }
    check(!$test) || warn_line_failure(1);
    ok(!$test, "not [$msg]") || ($FATAL && !$TODO && die "All errors Fatal\n");
    
}

sub EQ ($$;$) {
    my ($lhs, $rhs, $msg) = @_;
    $msg ||= line_to_text();
    if( $VERBOSE ) {
        require Data::Dumper;
        warn "--------------------------------------------------------\n";
        warn Data::Dumper->Dump([[$lhs, $rhs]], ["EQ"]);
        warn "--------------------------------------------------------\n";
    }
    no warnings qw(numeric);
    check_is(0+$lhs,0+$rhs) || warn_line_failure(1);
    is(0+$lhs,0+$rhs, $msg) || ($FATAL && !$TODO && die "All errors Fatal\n");
}

sub ID ($$;$) {
    my ($lhs, $rhs, $msg) = @_;
    $msg ||= line_to_text();
    if( $VERBOSE ) {
        require Data::Dumper;
        warn "--------------------------------------------------------\n";
        warn Data::Dumper->Dump([[$lhs,$rhs]], ["ID"]);
        warn "--------------------------------------------------------\n";
    }
    check_is($lhs,$rhs) || warn_line_failure(1);
    is($lhs,$rhs, $msg) || ($FATAL && !$TODO && die "All errors Fatal\n");
}

my ($OFH, $FFH, $TFH);
sub capture_io {
    my $data = shift;
    my $io = IO::Scalar->new($data); 
    my $tb = Test::Builder->new();
    ($OFH, $FFH, $TFH) = (
        $tb->output(),
        $tb->failure_output,
        $tb->todo_output,
    );
    $tb->output($io);
    $tb->failure_output($io);
    $tb->todo_output($io);
}

sub reset_io {
    my $tb = Test::Builder->new();
    $tb->output($OFH) if defined $OFH;
    $tb->failure_output($FFH) if defined $FFH;
    $tb->todo_output($TFH) if defined $TFH;
}    

sub ISA ($$;$) {
    local $LEVEL += 1;
    return OK(UNIVERSAL::isa($_[0],$_[1]),$_[2]);
}

sub IS ($$;$) {
    my ($lhs, $rhs, $msg) = @_;
    $msg ||= line_to_text();
    use IO::Scalar;
    my $output = "";
    if( $VERBOSE ) {
        require Data::Dumper;
        warn "--------------------------------------------------------\n";
        warn Data::Dumper->Dump([[$lhs, $rhs]], ["IS"]);
        warn "--------------------------------------------------------\n";
    }
    capture_io(\$output);
    my $ok = is_deeply($lhs, $rhs, $msg);
    reset_io();
    warn_line_failure() unless $ok;
    print $output;
    $ok || ($FATAL && !$TODO && die "All errors Fatal\n");
}

# Test::More does not have an isnt_deeply
# so hacking one in here.
sub isnt_deeply {
    my $tb = Test::More->builder;
    my($got, $expected, $name) = @_;

    $tb->_unoverload_str(\$expected, \$got);

    my $ok;
    if ( !ref $got and !ref $expected ) {
        # no references, simple comparison
        $ok = $tb->isnt_eq($got, $expected, $name);
    } elsif ( !ref $got xor !ref $expected ) {
        # not same type, so they are definately different
        $ok = $tb->ok(1, $name);
    } else {                    # both references
        local @Test::More::Data_Stack = ();
        if ( Test::More::_deep_check($got, $expected) ) {
            # deep check passed, so they are the same
            $ok = $tb->ok(0, $name);
        } else {
            $ok = $tb->ok(1, $name);
        }
    }

    return $ok;
}

sub ISNT ($$;$) {
    my ($lhs, $rhs, $msg) = @_;
    $msg ||= line_to_text();
    if( $VERBOSE ) {
        require Data::Dumper;
        warn "--------------------------------------------------------\n";
        warn Data::Dumper->Dump([[$lhs, $rhs]], ["ISNT"]);
        warn "--------------------------------------------------------\n";
    }
    check_is($lhs,$rhs) && warn_line_failure(1);
    isnt_deeply($lhs, $rhs, $msg) || ($FATAL && !$TODO && die "All errors Fatal\n");
}

sub LIKE ($$;$) {
    my ($lhs, $rhs, $msg) = @_;
    $msg ||= line_to_text();
    if( $VERBOSE ) {
        require Data::Dumper;
        warn "--------------------------------------------------------\n";
        warn Data::Dumper->Dump([[$lhs, $rhs]], ["LIKE"]);
        warn "--------------------------------------------------------\n";
    }
    check_like($lhs,$rhs) || warn_line_failure(1);
    like($lhs, $rhs, $msg) || ($FATAL && !$TODO && die "All errors Fatal\n");
}

sub UNLIKE ($$;$) {
    my ($lhs, $rhs, $msg) = @_;
    $msg ||= line_to_text();
    if( $VERBOSE ) {
        require Data::Dumper;
        warn "--------------------------------------------------------\n";
        warn Data::Dumper->Dump([[$lhs, $rhs]], ["UNLIKE"]);
        warn "--------------------------------------------------------\n";
    }
    check_like($lhs,$rhs) && warn_line_failure(1);
    unlike($lhs, $rhs, $msg) || ($FATAL && !$TODO && die "All errors Fatal\n");
}

sub check {
    if( !$_[0] ) {
        return 0;
    }
    return 1;
}

sub check_is {
    my $data = shift;
    my $expected = shift;
    return 1 if (not defined $data) && (not defined $expected);
    return 0 if (not defined $data) && (defined $expected);
    return 0 if (defined $data) && (not defined $expected);
    return $data eq $expected;
}

sub check_like {
    my $data = shift;
    my $match = shift;
    return 0 unless defined $match;
    
    if ( ((not defined $data) && (defined $match))
             || ($data !~ $match) ) {
        return 0;
    }
    return 1;
}

my %file_cache = ();

sub warn_line_failure {
    my $count_offset = shift || 0;
    my ($pkg, $file, $line, $sub) = caller($LEVEL + 1);
    print STDERR POSIX::strftime("# Time: %Y-%m-%d %X\n", localtime())
        unless $ENV{HARNESS_ACTIVE};
    $sub =~ s/^.*?::(\w+)$/$1/;
    my $source = $file_cache{$file}->[$line-1];
    my $col = index($source,$sub);
    # index -1 on error, else add 1 (editors start at 1, not 0)
    $col = $col == -1 ? 0 : $col + 1;
    my $tb = Test::Builder->new();
    print "$file:$line:$col: Test ", $tb->current_test()+$count_offset, " Failed\n"
        unless $ENV{HARNESS_ACTIVE};
}


my %OPS = (
    'OK'     => "",
    'NOK'    => "",
    'EQ'     => "==",
    'ID'     => "==",
    'IS'     => "==",
    'ISA'    => "ISA",
    'ISNT'   => "!=",
    'LIKE'   => "=~",
    'UNLIKE' => "!~",
);

sub line_to_text {
    my ($pkg, $file, $line, $sub) = caller($LEVEL + 1);

    $sub =~ s/^.*::(\w+)$/$1/;

    my $source;
    unless( $file_cache{$file} && @{$file_cache{$file}}) {
        # reset input line seperator in case some
        # is trying to screw with us
        local $/ = IFS;
        my $io = IO::Handle->new();
        my $fn = $file eq '-e' ? "/proc/$$/cmdline" : $file;
        $fn = $0 unless -e $fn;
        $fn = "$ENV{PWD}/$0" unless -e $fn;
        $fn = "$ENV{PWD}/$ENV{_}" unless -e $fn;
        open($io, "$fn") or die "Could not open $file: $!";
        my @source = <$io>;
        $file_cache{$file} = \@source;
    }

    # sometimes caller returns the line number of the end
    # of the statement insted of the beginning, so backtrack
    # to find the calling sub if the current line does not 
    # have sub in it.
    $line-- while defined $file_cache{$file}->[$line-1] && $file_cache{$file}->[$line-1] !~ /$sub/;
    my $offset = $line-1;
    $source = $file_cache{$file}->[$offset];
    while ($source !~ /;/ && $offset+1 != @{$file_cache{$file}} ){ 
        $offset++;
        $source .= $file_cache{$file}->[$offset];
    }

    my $msg = "Unknown";
    if( $source =~ /$sub$RE{balanced}{-parens=>'()'}{-keep}/s ) {
        $msg = substr($1,1,-1);
    }
    elsif( $source =~ /$sub(.*?)\s(or|and)\b/s ) {
        $msg = $1;
    }
    elsif( $source =~ /$sub(.*?)(;|$)/s ) {
        $msg = $1;
    }

    $msg =~ s/^\s+//;
    $msg =~ s/\s+$//;

    if( my $op = $OPS{$sub} ) {
        # multiple args
        my @parens;
        while( $msg =~ s/$RE{balanced}{-parens=>'(){}[]'}{-keep}/#####GRP#####/s ) {
            push @parens, $1;
        }
        my @parts = split /\s*(?:,|=>)\s*/s, $msg;
        s/^\s+// || s/\s+$// for @parts;
        $msg = "$parts[0] $op $parts[1]";

        while( my $paren = shift @parens ) {
            $msg =~ s/#####GRP#####/$paren/;
        }
        
    }
    return $msg;
}

#
# this routing is basically copied from 
#
# Test::More::_format_stack.
# Original Author: Michael G Schwern <schwern@pobox.com>
# Copyright: Copyright 2001-2008 by Michael G Schwern <schwern@pobox.com>
#
# It has been modified to wedge in the Text::Diff call
#

sub format_stack {
    my(@Stack) = @_;
        
    my $var = '$FOO';
    my $did_arrow = 0;
    foreach my $entry (@Stack) {
        my $type = $entry->{type} || '';
        my $idx  = $entry->{'idx'};
        if ( $type eq 'HASH' ) {
            $var .= "->" unless $did_arrow++;
            $var .= "{$idx}";
        } elsif ( $type eq 'ARRAY' ) {
            $var .= "->" unless $did_arrow++;
            $var .= "[$idx]";
        } elsif ( $type eq 'REF' ) {
            $var = "\${$var}";
        }
    }

    my @vals = @{$Stack[-1]{vals}}[0,1];
    my @vars = ();

    my $out = "Structures begin differing at:\n";
    if ( $vals[0] =~ /\n/ || $vals[1] =~ /\n/ ) {
        ($vars[0] = $var) =~ s/\$FOO/\$got/;
        ($vars[1] = $var) =~ s/\$FOO/\$expected/;
        $out .= Text::Diff::diff(\$vals[0], \$vals[1], { 
            STYLE => $DIFF,
            FILENAME_A => $vars[0],
            FILENAME_B => $vars[1],
        })
    } else {
        foreach my $idx (0..$#vals) {
            my $val = $vals[$idx];
            $vals[$idx] = !defined $val ? 'undef'          :
                Test::More::_dne($val)    ? "Does not exist" :
                      ref $val      ? "$val"           :
                          "'$val'";
        }
        ($vars[0] = $var) =~ s/\$FOO/     \$got/;
        ($vars[1] = $var) =~ s/\$FOO/\$expected/;
        $out .= "$vars[0] = $vals[0]\n";
        $out .= "$vars[1] = $vals[1]\n";
        $out =~ s/^/    /msg;
    }
    return $out;
}

package Test::Trivial::Builder;
use base qw(Test::Builder);

#
# Overload the base Test::Builder _is_diag function
# so we can call Text::Diff on multiline statements.
#
sub _is_diag {
    my($self, $got, $type, $expect) = @_;
    return $self->SUPER::_is_diag($got,$type,$expect)
        unless defined $got && defined $expect;

    if( $got =~ /\n/ || $expect =~ /\n/ ) {
        return $self->diag(
            Text::Diff::diff(\$got, \$expect, { 
                STYLE => $DIFF,
                FILENAME_A => "got",
                FILENAME_B => "expected",
            })
          );
    }
    return $self->SUPER::_is_diag($got,$type,$expect);
}

#
# chop out the "at tests.t line 32" stuff since
# we add that above with warn_line_failure().
# I prefer ours since it prints out before
# the test header so emacs next-error will
# let me see what just ran
#
sub diag{ 
    my ($self, @msgs) = @_;
    $self->SUPER::diag(
        grep { !/\s+at\s+\S+\s+line\s+\d+[.]\n/ } @msgs
    );
}

package Test::Trivial::IO::Tee;
use base qw(IO::Tee);

sub TIEHANDLE {
    my $class = shift;
    my @handles = ();
    for my $handle ( @_ ) {
        unless( UNIVERSAL::isa($handle, "IO::Handle") ) {
            my $io = IO::Handle->new();
            $io->fdopen($handle->fileno(), "w");
            $io->autoflush(1);
            push @handles, $io;
        }
        else {
            $handle->autoflush(1);
            push @handles, $handle;
        }
    }
    return bless [@handles], $class;
}

sub log {
    shift->[0]->print(@_);
}

1;

__END__

=head1 NAME

Test::Trivial - Declutter and simplify tests

=head1 SYNOPSIS

    use Test::Trivial tests => 11;
    
    OK $expression;
    NOK $expression;
    IS $got => $expected;
    ISNT $got => $expected;
    ISA $obj => $class;
    ID $refA => $refB;
    EQ $numA => $numB;
    LIKE $got => qr/regex/;
    UNLIKE $got => qr/regex/;
    IS ERR { die "OMG No!\n" } => "OMG No!\n";
    TODO IS $got, $expected;

=head1 DESCRIPTION

C<Test::Trivial> was written to allow test writters to trivially write tests
while still allowing the test code to be readable.  The output upon failure
has been modified to provide better diagnostics when things go wrong, including
the source line number for the failed test.  Global getopt options are automatically
added to all tests files to allow for easier debugging when things go wrong.

=head2 OPTIONS

=head3 --verbose

B<--verbose> passed on the command line to any B<Test::Trivial> test file will automatically
print out verbose data for each test.  Primarily this will use Data::Dumper to print out the
arguments to the various operators.

=head3 --fatal

B<--fatal> passed will automatically cause the test run to abort on the first (non TODO) "not ok" check.

=head3 --log[=<file>]

B<--log> can be used to force verbose log to the the given log file name (default $0.log) while 
allowing non-verbose output to go to the terminal.  This can be useful to diagnose bugs that happen during the
night when run under some automated testing.

=head2 OK

Takes one argument which will be evaluated for boolean truth.  The expression will be evaluated in scalar context.

Examples:

    OK 1 + 1 == 2;
    # output:
    # ok 1 - 1 + 1 == 2
    
    OK 1 + 1 == 3;
    # output:
    # # Time: 2012-02-28 12:20:19 PM
    # ./example.t:5:1: Test 2 Failed
    # not ok 2 - 1 + 1 == 3
    # #   Failed test '1 + 1 == 3'
    
    @array = (1,2,3);
    OK @array;
    # output:
    # ok 3 - @array
    
    @array = ();
    OK @array;
    # output:
    # # Time: 2012-02-28 12:20:19 PM
    # ./example.t:18:1: Test 4 Failed
    # not ok 4 - @array
    # #   Failed test '@array'

=head2 NOK

Takes one argument which is evaluated for boolean false.  The expression will be evaluated in scalar context.

Examples:

    NOK 1 + 1 == 2;
    # output:
    # # Time: 2012-02-28 12:25:45 PM
    # ./example.t:1:1: Test 1 Failed
    # not ok 1 - not [1 + 1 == 2]
    # #   Failed test 'not [1 + 1 == 2]'
    
    NOK 1 + 1 == 3;
    # output:
    # ok 2 - not [1 + 1 == 3]
    
    @array = (1,2,3);
    NOK @array;
    # output:
    # # Time: 2012-02-28 12:25:45 PM
    # ./example.t:13:1: Test 3 Failed
    # not ok 3 - not [@array]
    # #   Failed test 'not [@array]'
    
    @array = ();
    NOK @array;
    # output:
    # ok 4 - not [@array]

=head2 IS

Takes two arguments and compares the values (or structures if references).  The arguments will be evaluated in scalar context.
If the inputs are strings with embedded newlines then L<Text::Diff> will be used to print out the differences when the 
strings dont match.  If the inputs are references then the structures will be compared recusively for equivalence.
       
Examples:

    my $string = "abc";
    IS $string => "abc";
    # output:
    # ok 1 - $string == "abc"
    
    my @array = (1,2,3);
    IS @array => 3;
    # output: 
    # ok 2 - @array == 3
    
    IS "a\nb\n" => "a\nc\n";
    # output:
    # # Time: 2012-02-28 01:27:33 PM
    # ./example.t:10:1: Test 3 Failed
    # not ok 3 - "a\nb\n" == "a\nc\n"
    # #   Failed test '"a\nb\n" == "a\nc\n"'
    # # --- got
    # # +++ expected
    # # @@ -1,2 +1,2 @@
    # #  a
    # # -b
    # # +c
    
    IS [1,2,3,5,8], [1,2,3,5,8];
    # output: 
    # ok 4 - [1,2,3,5,8] == [1,2,3,5,8]
    
    IS [{a=>1}], [{b=>1}];
    # output: 
    # # Time: 2012-02-28 01:27:33 PM
    # ./example.t:26:1: Test 5 Failed
    # not ok 5 - [{a=>1}] == [{b=>1}]
    # #   Failed test '[{a=>1}] == [{b=>1}]'
    # #     Structures begin differing at:
    # #          $got->[0]{b} = Does not exist
    # #     $expected->[0]{b} = '1'
    
    IS substr("abcdef",0,3), "abc";
    # output:
    # ok 6 - substr("abcdef",0,3) == "abc"

=head2 ISNT

Takes two arguments and compares the values (or structures if references) for non equivalence.  The arguments will be evaluated in scalar context.
If the inputs are references then the structures will be compared recusively for non equivalence.
       
Examples:

    my $string = "abc";
    ISNT $string => "abc";
    # output:
    # # Time: 2012-02-28 01:45:18 PM
    # ./example.t:2:1: Test 1 Failed
    # not ok 1 - $string != "abc"
    # #   Failed test '$string != "abc"'
    # #          got: 'abc'
    # #     expected: anything else
    
    my @array = (1,2,3);
    ISNT @array => 3;
    # output: 
    # # Time: 2012-02-28 01:45:18 PM
    # ./example.t:12:1: Test 2 Failed
    # not ok 2 - @array != 3
    # #   Failed test '@array != 3'
    # #          got: '3'
    # #     expected: anything else
    
    ISNT "a\nb" => "a\nc";
    # output:
    # ok 3 - "a\nb" != "a\nc"
    
    ISNT [1,2,3,5,8], [1,2,3,5,8];
    # output: 
    # not ok 4 - [1,2,3,5,8] != [1,2,3,5,8]
    # #   Failed test '[1,2,3,5,8] != [1,2,3,5,8]'
    
    ISNT [{a=>1}], [{b=>1}];
    # output: 
    # ok 5 - [{a=>1}] != [{b=>1}]
    
    ISNT substr("abcdef",0,3), "abc";
    # output:
    # # Time: 2012-02-28 01:45:18 PM
    # ./example.t:34:1: Test 6 Failed
    # not ok 6 - substr("abcdef",0,3) != "abc"
    # #   Failed test 'substr("abcdef",0,3) != "abc"'
    # #          got: 'abc'
    # #     expected: anything else

=head2 ISA

Takes two arguments and checks to see if the first argument is a reference that inherits from the class/type of the second argument. 

Examples:

    ISA [] => "ARRAY";
    # output:
    # ok 1 - [] ISA "ARRAY"
    
    ISA {} => "HASH";
    # output:
    # ok 2 - {} ISA "HASH"
    
    ISA qr/ABC/ => "REGEXP";
    # output:
    # ok 3 - qr/ABC/ ISA "REGEXP"

    ISA \*STDIO => "GLOB";
    # output:
    # ok 4 - \*STDIO ISA "GLOB"
    
    my $io = IO::File->new();
    ISA $io => "IO::File";
    # output:
    # ok 5 - $io ISA "IO::File"
    
    ISA $io => "IO::Handle";
    # output:
    # ok 6 - $io ISA "IO::Handle"
    
    ISA $io => "Exporter";
    # output:
    # ok 7 - $io ISA "Exporter"
    
    ISA $io => "GLOB";
    # output:
    # ok 8 - $io ISA "GLOB"
    
    ISA $io => "ARRAY";
    # output:
    # # Time: 2012-02-28 02:03:20 PM
    # ./example.t:34:1: Test 9 Failed
    # not ok 9 - $io ISA "ARRAY"
    # #   Failed test '$io ISA "ARRAY"'
    
    ISA $io => "IO::Socket";
    # output:
    # # Time: 2012-02-28 02:03:20 PM
    # ./example.t:41:1: Test 10 Failed
    # not ok 10 - $io ISA "IO::Socket"
    # #   Failed test '$io ISA "IO::Socket"'

=head2 ID

Takes two arguments and compares them for exact values.  B<ID> is similar to B<IS> except that references are compared
literally (ie the reference address is compared) instead of recusively comparing the data structures.

Examples:

    my $arr1 = my $arr2 = [];
    ID $arr1 => $arr2;
    # output:
    # ok 1 - $arr1 == $arr2
    
    ID $arr1 => [];
    # output:
    # # Time: 2012-02-28 02:35:38 PM
    # ./example.t:6:1: Test 2 Failed
    # not ok 2 - $arr1 == []
    # #   Failed test '$arr1 == []'
    # #          got: 'ARRAY(0x186fd80)'
    # #     expected: 'ARRAY(0x188c588)'
    
    my $hash1 = $hash2 = {};
    ID $hash1 => $hash2;
    # output:
    # ok 3 - $hash1 == $hash2
    
    ID $hash1 => {};
    # output:
    # # Time: 2012-02-28 02:35:38 PM
    # ./example.t:20:1: Test 4 Failed
    # not ok 4 - $hash1 == {}
    # #   Failed test '$hash1 == {}'
    # #          got: 'HASH(0x189bcc8)'
    # #     expected: 'HASH(0x1ee95b8)'
    
    my %hash = ();
    my $hash3 = \%hash;
    
    ID $hash3 => \%hash;
    # output:
    # ok 5 - $hash3 == \%hash

=head2 EQ

Takes two arguments and compares them for numeric equivalence.

Examples:

    EQ 12 => 12;
    # output:
    # ok 1 - 12 == 12
    
    EQ 12.00001 => 12;
    # output:
    # # Time: 2012-02-28 03:16:49 PM
    # ./example.t:4:1: Test 2 Failed
    # not ok 2 - 12.00001 == 12
    # #   Failed test '12.00001 == 12'
    # #          got: '12.00001'
    # #     expected: '12'
    
    EQ 12.0 => 12;
    # output:
    # ok 3 - 12.0 == 12
    
    EQ 12.0 / 1.0 => 12;
    # output:
    # ok 4 - 12.0 / 1.0 == 12
    
    EQ 0.12E2 => 12;
    # output:
    # ok 5 - 0.12E2 == 12
    
    EQ 1200E-2 => 12;
    # output:
    # ok 6 - 1200E-2 == 12
    
    EQ 0x0C => 12;
    # output:
    # ok 7 - 0x0C == 12
    
    EQ 014 => 12;
    # output:
    # ok 8 - 014 == 12
    
    EQ 0b001100 => 12;
    # output:
    # ok 9 - 0b001100 == 12
    
    EQ "12" => 12;
    # output:
    # ok 10 - "12" == 12
    
    EQ "12.0" => 12;
    # output:
    # ok 11 - "12.0" == 12
    
    EQ "0.12E2" => 12;
    # output:
    # ok 12 - "0.12E2" == 12
    
    EQ "1200E-2" => 12;
    # output:
    # ok 13 - "1200E-2" == 12

    EQ "12 Monkeys" => 12;
    # output:
    # ok 14 - "12 Monkeys" == 12

=head2 LIKE

Takes two arguments, the first argument should be a string, and the second argument should be a REGEXP.  The regex will
be run against the string to verify that there is a successful match.

Examples:

    LIKE "abc" => qr{^a};
    # output:
    # ok 1 - "abc" =~ qr{^a}
    
    LIKE "ABC" => qr{^a}i;
    # output:
    # ok 2 - "ABC" =~ qr{^a}i
    
    LIKE "ABC" => qr/^(?i:a)/;
    # output:
    # ok 3 - "ABC" =~ qr/^(?i:a)/
    
    use Regexp::Common;
    LIKE "123.456E3" => qr[$RE{num}{real}];
    # output:
    # ok 4 - "123.456E3" =~ qr[$RE{num}{real}]
    
    LIKE "foo" => qr{bar};
    # output:
    # # Time: 2012-02-28 03:44:35 PM
    # ./example.t:18:1: Test 5 Failed
    # not ok 5 - "foo" =~ qr{bar}
    # #   Failed test '"foo" =~ qr{bar}'
    # #                   'foo'
    # #     doesn't match '(?-xism:bar)'
    

=head2 UNLIKE

Takes two arguments, the first argument should be a string, and the second argument should be a REGEXP.  The regex will
be run against the string to verify that there is a negative match.

Examples:

    UNLIKE "abc" => qr{^A};
    # output:
    # ok 1 - "abc" !~ qr{^A}
    
    UNLIKE "ABC" => qr{^a}i;
    # output:
    # # Time: 2012-02-28 03:54:31 PM
    # ./example.t:5:1: Test 2 Failed
    # not ok 2 - "ABC" !~ qr{^a}i
    # #   Failed test '"ABC" !~ qr{^a}i'
    # #                   'ABC'
    # #           matches '(?i-xsm:^a)'
    
    UNLIKE "ABC" => qr/^(?i:a)/;
    # output:
    # # Time: 2012-02-28 03:54:31 PM
    # ./example.t:14:1: Test 3 Failed
    # not ok 3 - "ABC" !~ qr/^(?i:a)/
    # #   Failed test '"ABC" !~ qr/^(?i:a)/'
    # #                   'ABC'
    # #           matches '(?-xism:^(?i:a))'
    
    use Regexp::Common;
    UNLIKE "123.456E3" => qr[$RE{num}{int}];
    # output:
    # # Time: 2012-02-28 03:54:31 PM
    # ./example.t:24:1: Test 4 Failed
    # not ok 4 - "123.456E3" !~ qr[$RE{num}{int}]
    # #   Failed test '"123.456E3" !~ qr[$RE{num}{int}]'
    # #                   '123.456E3'
    # #           matches '(?-xism:(?:(?:[+-]?)(?:[0123456789]+)))'
    
    UNLIKE "foo" => qr{bar};
    # output:
    # ok 5 - "foo" !~ qr{bar}

=head2 ERR

B<ERR> is a wrapper to help capture exceptions to make analyzing error cases easier.  The argument to B<ERR> is 
a subroutine or code block.

Examples:

    package PosixErr;
    use POSIX qw(strerror);
    use overload '""' => \&stringify;
    sub new { bless { code => $_[1] }, $_[0] }
    sub stringify { strerror($_[0]->{code}) }
    
    package main;
    IS ERR { die "OMG No!\n" } => "OMG No!\n";
    # output:
    # ok 1 - ERR { die "OMG No!\n" } == "OMG No!\n"
    
    IS ERR { die PosixErr->new(12) }  => PosixErr->new(12);
    # output:
    # ok 2 - ERR { die PosixErr->new(12) } == PosixErr->new(12)
    
    IS ERR { die PosixErr->new(12) }  => "Cannot allocate memory";
    # output:
    # ok 3 - ERR { die PosixErr->new(12) } == "Cannot allocate memory"
    
    IS ERR { die PosixErr->new(13) }  => "Knock it out, wiseguy";
    # output:
    # # Time: 2012-02-28 04:27:35 PM
    # ./example.t:20:1: Test 4 Failed
    # not ok 4 - ERR { die PosixErr->new(13) } == "Knock it out
    # #   Failed test 'ERR { die PosixErr->new(13) } == "Knock it out'
    # #          got: 'Permission denied'
    # #     expected: 'Knock it out, wiseguy'
    
    IS ERR { die PosixErr->new(13) }  => "Permission denied";
    # output:
    # ok 5 - ERR { die PosixErr->new(13) } == "Permission denied"
    
    IS ERR { "ok" } => "ok";
    # output:
    # ok 6 - ERR { "ok" } == "ok"

=head2 TODO

B<TODO> can be used a prefix to any test to indicate that it is a known failure.  For futher reading on TODO
please read L<Test::More>.

Examples:

    TODO OK 1 == 2;
    # output:
    # # Time: 2012-02-28 04:39:55 PM
    # ./example.t:1:6: Test 1 Failed
    # not ok 1 - 1 == 2 # TODO Test Know to fail
    # #   Failed (TODO) test '1 == 2'
    
    TODO NOK 1 == 1;
    # output:
    # # Time: 2012-02-28 04:39:55 PM
    # ./example.t:8:6: Test 2 Failed
    # not ok 2 - not [1 == 1] # TODO Test Know to fail
    # #   Failed (TODO) test 'not [1 == 1]'
    
    TODO IS "abc" => "ABC";
    # output:
    # # Time: 2012-02-28 04:39:55 PM
    # ./example.t:15:6: Test 3 Failed
    # not ok 3 - "abc" == "ABC" # TODO Test Know to fail
    # #   Failed (TODO) test '"abc" == "ABC"'
    # #          got: 'abc'
    # #     expected: 'ABC'
    
    TODO ISNT "abc" => "abc";
    # output:
    # # Time: 2012-02-28 04:39:55 PM
    # ./example.t:24:6: Test 4 Failed
    # not ok 4 - "abc" != "abc" # TODO Test Know to fail
    # #   Failed (TODO) test '"abc" != "abc"'
    # #          got: 'abc'
    # #     expected: anything else
    
    TODO ISA [] => "HASH";
    # output:
    # # Time: 2012-02-28 04:39:55 PM
    # ./example.t:33:6: Test 5 Failed
    # not ok 5 - [] ISA "HASH" # TODO Test Know to fail
    # #   Failed (TODO) test '[] ISA "HASH"'
    
    TODO ID [] => [];
    # output:
    # # Time: 2012-02-28 04:39:55 PM
    # ./example.t:40:6: Test 6 Failed
    # not ok 6 - [] == [] # TODO Test Know to fail
    # #   Failed (TODO) test '[] == []'
    # #          got: 'ARRAY(0x1c62a28)'
    # #     expected: 'ARRAY(0x1c62a10)'
    
    TODO EQ 123 => 124;
    # output:
    # # Time: 2012-02-28 04:39:55 PM
    # ./example.t:49:6: Test 7 Failed
    # not ok 7 - 123 == 124 # TODO Test Know to fail
    # #   Failed (TODO) test '123 == 124'
    # #          got: '123'
    # #     expected: '124'
    
    TODO LIKE "abc" => qr/^ABC$/;
    # output:
    # # Time: 2012-02-28 04:39:55 PM
    # ./example.t:58:6: Test 8 Failed
    # not ok 8 - "abc" =~ qr/^ABC$/ # TODO Test Know to fail
    # #   Failed (TODO) test '"abc" =~ qr/^ABC$/'
    # #                   'abc'
    # #     doesn't match '(?-xism:^ABC$)'
    
    TODO UNLIKE "abc" => qr/^abc$/;
    # output:
    # # Time: 2012-02-28 04:39:55 PM
    # ./example.t:67:6: Test 9 Failed
    # not ok 9 - "abc" !~ qr/^abc$/ # TODO Test Know to fail
    # #   Failed (TODO) test '"abc" !~ qr/^abc$/'
    # #                   'abc'
    # #           matches '(?-xism:^abc$)'

=head2 ENVIRONMENT

=head3 TEST_TRIVIAL_LOG

This environment variable will act as if B<--log=$ENV{TEST_TRIVIAL_LOG}> had been set.

=head1 AUTHOR

2007-2012, Cory Bennett <cpan@corybennett.org>

=head1 SOURCE

The Source is available at github: https://github.com/coryb/perl-test-trivial

=head1 SEE ALSO

L<Test::More>, L<Test::Harness>, L<Text::Diff>

=head1 COPYRIGHT and LICENSE

Copyright (c) 2008 Yahoo! Inc. All rights reserved. The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997).
