#!/usr/bin/perl -c

package Test::Unit::Lite;

=head1 NAME

Test::Unit::Lite - Unit testing without external dependencies

=head1 SYNOPSIS

Bundling the L<Test::Unit::Lite> as a part of package distribution:

  perl -MTest::Unit::Lite -e bundle

Running all test units:

  perl -MTest::Unit::Lite -e all_tests

Using as a replacement for Test::Unit:

  package FooBarTest;
  use Test::Unit::Lite;   # unnecessary if module isn't directly used
  use base 'Test::Unit::TestCase';

  sub new {
      my $self = shift()->SUPER::new(@_);
      # your state for fixture here
      return $self;
  }

  sub set_up {
      # provide fixture
  }
  sub tear_down {
      # clean up after test
  }
  sub test_foo {
      my $self = shift;
      my $obj = ClassUnderTest->new(...);
      $self->assert_not_null($obj);
      $self->assert_equals('expected result', $obj->foo);
      $self->assert(qr/pattern/, $obj->foobar);
  }
  sub test_bar {
      # test the bar feature
  }

=head1 DESCRIPTION

This framework provides lighter version of L<Test::Unit> framework.  It
implements some of the L<Test::Unit> classes and methods needed to run test
units.  The L<Test::Unit::Lite> tries to be compatible with public API of
L<Test::Unit>. It doesn't implement all classes and methods at 100% and only
those necessary to run tests are available.

The L<Test::Unit::Lite> can be distributed as a part of package distribution,
so the package can be distributed without dependency on modules outside
standard Perl distribution.  The L<Test::Unit::Lite> is provided as a single
file.

=head2 Bundling the L<Test::Unit::Lite> as a part of package distribution

The L<Test::Unit::Lite> framework can be bundled to the package distribution.
Then the L<Test::Unit::Lite> module is copied to the F<inc> directory of the
source directory for the package distribution.

=cut


use 5.006;

use strict;
use warnings;

our $VERSION = '0.1202';

use Carp ();
use File::Spec ();
use File::Basename ();
use File::Copy ();
use File::Path ();
use Symbol ();


# Can't use Exporter 'import'. Compatibility with Perl 5.6
use Exporter ();
BEGIN { *import = \&Exporter::import };
our @EXPORT = qw{ bundle all_tests };


# Copy this module to inc subdirectory of the source distribution
sub bundle {
    -f 'Makefile.PL' or -f 'Build.PL'
        or die "Cannot find Makefile.PL or Build.PL in current directory\n";

    my $src = __FILE__;
    my $dst = "inc/Test/Unit/Lite.pm";


    my @src = split m{/}, $src;
    my @dst = split m{/}, $dst;
    my $srcfile = File::Spec->catfile(@src);
    my $dstfile = File::Spec->catfile(@dst);

    die "Cannot bundle to itself: $srcfile\n" if $srcfile eq $dstfile;
    print "Copying $srcfile -> $dstfile\n";

    my $dstdir = File::Basename::dirname($dstfile);

    -d $dstdir or File::Path::mkpath([$dstdir], 0, oct(777) & ~umask);

    File::Copy::cp($srcfile, $dstfile) or die "Cannot copy $srcfile to $dstfile: $!\n";
}

sub all_tests {
    Test::Unit::TestRunner->new->start('Test::Unit::Lite::AllTests');
}


{
    package Test::Unit::TestCase;
    use Carp ();
    our $VERSION = $Test::Unit::Lite::VERSION;

    our %Seen_Refs = ();
    our @Data_Stack;
    my $DNE = bless [], 'Does::Not::Exist';

    sub new {
        my ($class) = @_;
        $class = ref $class if ref $class;
        my $self = {};
        return bless $self => $class;
    }

    sub set_up { }

    sub tear_down { }

    sub list_tests {
        my ($self) = @_;

        my $class = ref $self || $self;

        my @tests;

        my %seen_isa;
        my $list_base_tests;
        $list_base_tests = sub {
            my ($class) = @_;
            foreach my $isa (@{ *{ Symbol::qualify_to_ref("${class}::ISA") } }) {
                next unless $isa->isa(__PACKAGE__);
                $list_base_tests->($isa) unless $seen_isa{$isa};
                $seen_isa{$isa} = 1;
                push @tests, grep { /^test_/ } keys %{ *{ Symbol::qualify_to_ref("${class}::") } };
            };
        };
        $list_base_tests->($class);

        my %uniq_tests = map { $_ => 1 } @tests;
        @tests = sort keys %uniq_tests;

        return wantarray ? @tests : [ @tests ];
    }

    sub __croak {
        my ($default_message, $custom_message) = @_;
        $default_message = '' unless defined $default_message;
        $custom_message = '' unless defined $custom_message;
        my $n = 1;

        my ($file, $line) = (caller($n++))[1,2];
        my $caller;
        $n++ while (defined( $caller = caller($n) ) and not eval { $caller->isa('Test::Unit::TestSuite') });

        my $sub = (caller($n))[3] || '::';
        $sub =~ /^(.*)::([^:]*)$/;
        my ($test, $unit) = ($1, $2);

        my $message = "$file:$line - $test($unit)\n$default_message\n$custom_message";
        chomp $message;

        no warnings 'once';
        local $Carp::Internal{'Test::Unit::TestCase'} = 1;
        Carp::confess("$message\n");
    }

    sub fail {
        my ($self, $msg) = @_;
        $msg = '' unless defined $msg;
        __croak $msg;
    }

    sub assert {
        my $self = shift;
        my $arg1 = shift;
        if (ref $arg1 eq 'Regexp') {
            my $arg2 = shift;
            my $msg = shift;
            __croak "'$arg2' did not match /$arg1/", $msg unless $arg2 =~ $arg1;
        }
        else {
            my $msg = shift;
            __croak "Boolean assertion failed", $msg unless $arg1;
        }
    }

    sub assert_null {
        my ($self, $arg, $msg) = @_;
        __croak "$arg is defined", $msg unless not defined $arg;
    }

    sub assert_not_null {
        my ($self, $arg, $msg) = @_;
        __croak "<undef> unexpected", $msg unless defined $arg;
    }

    sub assert_equals {
        my ($self, $arg1, $arg2, $msg) = @_;
        if (not defined $arg1 and not defined $arg2) {
            return;
        }
        __croak "expected value was undef; should be using assert_null?", $msg unless defined $arg1;
        __croak "expected '$arg1', got undef", $msg unless defined $arg2;
        if ($arg1 =~ /^[+-]?(\d+\.\d+|\d+\.|\.\d+|\d+)([eE][+-]?\d+)?$/ and
            $arg2 =~ /^[+-]?(\d+\.\d+|\d+\.|\.\d+|\d+)([eE][+-]?\d+)?$/)
        {
            __croak "expected $arg1, got $arg2", $msg unless $arg1 == $arg2;
        }
        else {
            __croak "expected '$arg1', got '$arg2'", $msg unless $arg1 eq $arg2;
        }
    }

    sub assert_not_equals {
        my ($self, $arg1, $arg2, $msg) = @_;
        if (not defined $arg1 and not defined $arg2) {
            __croak "both args were undefined", $msg;
        }
        if (not defined $arg1 xor not defined $arg2) {
            # pass
        }
        elsif ($arg1 =~ /^[+-]?(\d+\.\d+|\d+\.|\.\d+|\d+)([eE][+-]?\d+)?$/ and
               $arg2 =~ /^[+-]?(\d+\.\d+|\d+\.|\.\d+|\d+)([eE][+-]?\d+)?$/)
        {
            __croak "$arg1 and $arg2 should differ", $msg unless $arg1 != $arg2;
        }
        else {
            __croak "'$arg1' and '$arg2' should differ", $msg unless $arg1 ne $arg2;
        }
    }

    sub assert_num_equals {
        my ($self, $arg1, $arg2, $msg) = @_;
        __croak "expected value was undef; should be using assert_null?", $msg unless defined $arg1;
        __croak "expected '$arg1', got undef", $msg unless defined $arg2;
        no warnings 'numeric';
        __croak "expected $arg1, got $arg2", $msg unless $arg1 == $arg2;
    }

    sub assert_num_not_equals {
        my ($self, $arg1, $arg2, $msg) = @_;
        __croak "expected value was undef; should be using assert_null?", $msg unless defined $arg1;
        __croak "expected '$arg1', got undef", $msg unless defined $arg2;
        no warnings 'numeric';
        __croak "$arg1 and $arg2 should differ", $msg unless $arg1 != $arg2;
    }

    sub assert_str_equals {
        my ($self, $arg1, $arg2, $msg) = @_;
        __croak "expected value was undef; should be using assert_null?", $msg unless defined $arg1;
        __croak "expected '$arg1', got undef", $msg unless defined $arg2;
        __croak "expected '$arg1', got '$arg2'", $msg unless "$arg1" eq "$arg2";
    }

    sub assert_str_not_equals {
        my ($self, $arg1, $arg2, $msg) = @_;
        __croak "expected value was undef; should be using assert_null?", $msg unless defined $arg1;
        __croak "expected '$arg1', got undef", $msg unless defined $arg2;
        __croak "'$arg1' and '$arg2' should differ", $msg unless "$arg1" ne "$arg2";
    }

    sub assert_matches {
        my ($self, $arg1, $arg2, $msg) = @_;
        __croak "arg 1 to assert_matches() must be a regexp", $msg unless ref $arg1 eq 'Regexp';
        __croak "expected '$arg1', got undef", $msg unless defined $arg2;
        __croak "$arg2 didn't match /$arg1/", $msg unless $arg2 =~ $arg1;
    }

    sub assert_does_not_match {
        my ($self, $arg1, $arg2, $msg) = @_;
        __croak "arg 1 to assert_does_not_match() must be a regexp", $msg unless ref $arg1 eq 'Regexp';
        __croak "expected '$arg1', got undef", $msg unless defined $arg2;
        __croak "$arg2 matched /$arg1/", $msg unless $arg2 !~ $arg1;
    }

    sub assert_deep_equals {
        my ($self, $arg1, $arg2, $msg) = @_;
        __croak 'Both arguments were not references', $msg unless ref $arg1 and ref $arg2;
        local @Data_Stack = ();
        local %Seen_Refs = ();
        __croak $self->_format_stack(@Data_Stack), $msg unless $self->_deep_check($arg1, $arg2);
    }

    sub assert_deep_not_equals {
        my ($self, $arg1, $arg2, $msg) = @_;

        __croak 'Both arguments were not references', $msg unless ref $arg1 and ref $arg2;

        local @Data_Stack = ();
        local %Seen_Refs = ();
        __croak $self->_format_stack(@Data_Stack), $msg if $self->_deep_check($arg1, $arg2);
    }

    sub _deep_check {
        my ($self, $e1, $e2) = @_;

        if ( ! defined $e1 || ! defined $e2 ) {
            return 1 if !defined $e1 && !defined $e2;
            push @Data_Stack, { vals => [$e1, $e2] };
            return 0;
        }

        return 1 if $e1 eq $e2;
        if ( ref $e1 && ref $e2 ) {
            my $e2_ref = "$e2";
            return 1 if defined $Seen_Refs{$e1} && $Seen_Refs{$e1} eq $e2_ref;
            $Seen_Refs{$e1} = $e2_ref;
        }

        if (ref $e1 eq 'ARRAY' and ref $e2 eq 'ARRAY') {
            return $self->_eq_array($e1, $e2);
        }
        elsif (ref $e1 eq 'HASH' and ref $e2 eq 'HASH') {
            return $self->_eq_hash($e1, $e2);
        }
        elsif (ref $e1 eq 'REF' and ref $e2 eq 'REF') {
            push @Data_Stack, { type => 'REF', vals => [$e1, $e2] };
            my $ok = $self->_deep_check($$e1, $$e2);
            pop @Data_Stack if $ok;
            return $ok;
        }
        elsif (ref $e1 eq 'SCALAR' and ref $e2 eq 'SCALAR') {
            push @Data_Stack, { type => 'REF', vals => [$e1, $e2] };
            return $self->_deep_check($$e1, $$e2);
        }
        else {
            push @Data_Stack, { vals => [$e1, $e2] };
            return 0;
        }
    }

    sub _eq_array  {
        my ($self, $a1, $a2) = @_;
        return 1 if $a1 eq $a2;

        my $ok = 1;
        my $max = $#$a1 > $#$a2 ? $#$a1 : $#$a2;
        for (0..$max) {
            my $e1 = $_ > $#$a1 ? $DNE : $a1->[$_];
            my $e2 = $_ > $#$a2 ? $DNE : $a2->[$_];

            push @Data_Stack, { type => 'ARRAY', idx => $_, vals => [$e1, $e2] };
            $ok = $self->_deep_check($e1,$e2);
            pop @Data_Stack if $ok;

            last unless $ok;
        }
        return $ok;
    }

    sub _eq_hash {
        my ($self, $a1, $a2) = @_;
        return 1 if $a1 eq $a2;

        my $ok = 1;
        my $bigger = keys %$a1 > keys %$a2 ? $a1 : $a2;
        foreach my $k (sort keys %$bigger) {
            my $e1 = exists $a1->{$k} ? $a1->{$k} : $DNE;
            my $e2 = exists $a2->{$k} ? $a2->{$k} : $DNE;

            push @Data_Stack, { type => 'HASH', idx => $k, vals => [$e1, $e2] };
            $ok = $self->_deep_check($e1, $e2);
            pop @Data_Stack if $ok;

            last unless $ok;
        }

        return $ok;
    }

    sub _format_stack {
        my ($self, @Stack) = @_;

        my $var = '$FOO';
        my $did_arrow = 0;
        foreach my $entry (@Stack) {
            my $type = $entry->{type} || '';
            my $idx  = $entry->{'idx'};
            if( $type eq 'HASH' ) {
                $var .= "->" unless $did_arrow++;
                $var .= "{$idx}";
            }
            elsif( $type eq 'ARRAY' ) {
                $var .= "->" unless $did_arrow++;
                $var .= "[$idx]";
            }
            elsif( $type eq 'REF' ) {
                $var = "\${$var}";
            }
        }

        my @vals = @{$Stack[-1]{vals}}[0,1];

        my @vars = ();
        ($vars[0] = $var) =~ s/\$FOO/  \$a/;
        ($vars[1] = $var) =~ s/\$FOO/  \$b/;

        my $out = "Structures begin differing at:\n";
        foreach my $idx (0..$#vals) {
            my $val = $vals[$idx];
            $vals[$idx] = !defined $val ? 'undef' :
                          $val eq $DNE  ? 'Does not exist'
                                        : "'$val'";
        }

        $out .= "$vars[0] = $vals[0]\n";
        $out .= "$vars[1] = $vals[1]";

        return $out;
    }

    BEGIN { $INC{'Test/Unit/TestCase.pm'} = __FILE__; }
}

{
    package Test::Unit::Result;
    our $VERSION = $Test::Unit::Lite::VERSION;

    sub new {
        my ($class) = @_;
        my $self = {
            'messages' => [],
            'errors'   => 0,
            'failures' => 0,
            'passes'   => 0,
        };

        return bless $self => $class;
    }

    sub messages {
        my ($self) = @_;
        return $self->{messages};
    }

    sub errors {
        my ($self) = @_;
        return $self->{errors};
    }

    sub failures {
        my ($self) = @_;
        return $self->{failures};
    }

    sub passes {
        my ($self) = @_;
        return $self->{passes};
    }

    sub add_error {
        my ($self, $test, $message, $runner) = @_;
        $self->{errors}++;
        my $result = {test => $test, type => 'ERROR', message => $message};
        push @{$self->messages}, $result;
        $runner->print_error($result) if defined $runner;
    }

    sub add_failure {
        my ($self, $test, $message, $runner) = @_;
        $self->{failures}++;
        my $result = {test => $test, type => 'FAILURE', message => $message};
        push @{$self->messages}, $result;
        $runner->print_failure($result) if defined $runner;
    }

    sub add_pass {
        my ($self, $test, $message, $runner) = @_;
        $self->{passes}++;
        my $result = {test => $test, type => 'PASS', message => $message};
        push @{$self->messages}, $result;
        $runner->print_pass($result) if defined $runner;
    }

    BEGIN { $INC{'Test/Unit/Result.pm'} = __FILE__; }
}

{
    package Test::Unit::TestSuite;
    our $VERSION = $Test::Unit::Lite::VERSION;

    sub empty_new {
        my ($class, $name) = @_;
        my $self = {
            'name' => defined $name ? $name : 'Test suite',
            'units' => [],
        };

        return bless $self => $class;
    }

    sub new {
        my ($class, $test) = @_;

        my $self = {
            'name' => 'Test suite',
            'units' => [],
        };

        if (defined $test and not ref $test) {
            # untaint $test
            $test =~ /([A-Za-z0-9:-]*)/;
            $test = $1;
            eval "use $test;";
            die if $@;
        }
        elsif (not defined $test) {
            $test = $class;
        }

        if (defined $test and $test->isa('Test::Unit::TestSuite')) {
            $class = ref $test ? ref $test : $test;
            $self->{name} = $test->name if ref $test;
            $self->{units} = $test->units if ref $test;
        }
        elsif (defined $test and $test->isa('Test::Unit::TestCase')) {
            $class = ref $test ? ref $test : $test;
            $self->{units} = [ $test ];
        }
        else {
            require Carp;
            Carp::croak(sprintf("usage: %s->new([CLASSNAME | TEST])\n", __PACKAGE__));
        }

        return bless $self => $class;
    }

    sub name {
        return $_[0]->{name};
    }

    sub units {
        return $_[0]->{units};
    }

    sub add_test {
        my ($self, $unit) = @_;

        if (not ref $unit) {
            # untaint $unit
            $unit =~ /([A-Za-z0-9:-]*)/;
            $unit = $1;
            eval "use $unit;";
            die if $@;
            return unless $unit->isa('Test::Unit::TestCase');
        }

        return push @{ $self->{units} }, ref $unit ? $unit : $unit->new;
    }

    sub count_test_cases {
        my ($self) = @_;

        my $plan = 0;

        foreach my $unit (@{ $self->units }) {
            $plan += scalar @{ $unit->list_tests };
        }
        return $plan;
    }

    sub run {
        my ($self, $result, $runner) = @_;

        die "Undefined result object" unless defined $result;

        foreach my $unit (@{ $self->units }) {
            foreach my $test (@{ $unit->list_tests }) {
                my $unit_test = (ref $unit ? ref $unit : $unit) . '::' . $test;
                my $add_what;
                my $e = '';
                eval {
                    $unit->set_up;
                };
                if ($@) {
                    $e = "$@";
                    $add_what = 'add_error';
                }
                else {
                    eval {
                        $unit->$test;
                    };
                    if ($@) {
                        $e = "$@";
                        $add_what = 'add_failure';
                    }
                    else {
                        $add_what = 'add_pass';
                    };
                };
                eval {
                    $unit->tear_down;
                };
                if ($@) {
                    $e .= "$@";
                    $add_what = 'add_error';
                };
                $result->$add_what($unit_test, $e, $runner);
            }
        }
        return;
    }

    BEGIN { $INC{'Test/Unit/TestSuite.pm'} = __FILE__; }
}

{
    package Test::Unit::TestRunner;
    our $VERSION = $Test::Unit::Lite::VERSION;

    sub new {
        my ($class, $fh_out, $fh_err) = @_;
        $fh_out = \*STDOUT unless defined $fh_out;
        $fh_err = \*STDERR unless defined $fh_err;
        _autoflush($fh_out);
        _autoflush($fh_err);
        my $self = {
            'suite'  => undef,
            'fh_out' => $fh_out,
            'fh_err' => $fh_err,
        };
        return bless $self => $class;
    }

    sub fh_out {
        my ($self) = @_;
        return $self->{fh_out};
    }

    sub fh_err {
        my ($self) = @_;
        return $self->{fh_err};
    }

    sub result {
        my ($self) = @_;
        return $self->{result};
    }

    sub _autoflush {
        my ($fh) = @_;
        my $old_fh = select $fh;
        $| = 1;
        select $old_fh;
    }

    sub suite {
        my ($self) = @_;
        return $self->{suite};
    }

    sub print_header {
    }

    sub print_error {
        my ($self, $result) = @_;
        print { $self->fh_out } "E";
    }

    sub print_failure {
        my ($self, $result) = @_;
        print { $self->fh_out } "F";
    }

    sub print_pass {
        my ($self, $result) = @_;
        print { $self->fh_out } ".";
    }

    sub print_footer {
        my ($self, $result) = @_;
        printf { $self->fh_out } "\nTests run: %d", $self->suite->count_test_cases;
        if ($result->errors) {
            printf { $self->fh_out } ", Errors: %d", $result->errors;
        }
        if ($result->failures) {
            printf { $self->fh_out } ", Failures: %d", $result->failures;
        }
        print { $self->fh_out } "\n";
        if ($result->errors) {
            print { $self->fh_out } "\nERRORS!!!\n\n";
            foreach my $message (@{ $result->messages }) {
                if ($message->{type} eq 'ERROR') {
                    printf { $self->fh_out } "%s\n%s:\n\n%s\n",
                                             '-' x 78,
                                             $message->{test},
                                             $message->{message};
                }
            }
            printf { $self->fh_out } "%s\n", '-' x 78;
        }
        if ($result->failures) {
            print { $self->fh_out } "\nFAILURES!!!\n\n";
            foreach my $message (@{ $result->messages }) {
                if ($message->{type} eq 'FAILURE') {
                    printf { $self->fh_out } "%s\n%s:\n\n%s\n",
                                             '-' x 78,
                                             $message->{test},
                                             $message->{message};
                }
            }
            printf { $self->fh_out } "%s\n", '-' x 78;
        }
    }

    sub start {
        my ($self, $test) = @_;

        my $result = Test::Unit::Result->new;

        # untaint $test
        $test =~ /([A-Za-z0-9:-]*)/;
        $test = $1;
        eval "use $test;";
        die if $@;

        if ($test->isa('Test::Unit::TestSuite')) {
            $self->{suite} = $test->suite;
        }
        elsif ($test->isa('Test::Unit::TestCase')) {
            $self->{suite} = Test::Unit::TestSuite->empty_new;
            $self->suite->add_test($test);
        }
        else {
            die "Unknown test $test\n";
        }

        $self->print_header;
        $self->suite->run($result, $self);
        $self->print_footer($result);
    }

    BEGIN { $INC{'Test/Unit/TestRunner.pm'} = __FILE__; }
}

{
    package Test::Unit::HarnessUnit;
    our $VERSION = $Test::Unit::Lite::VERSION;

    use base 'Test::Unit::TestRunner';

    sub print_header {
        my ($self) = @_;
        print { $self->fh_out } "STARTING TEST RUN\n";
        printf { $self->fh_out } "1..%d\n", $self->suite->count_test_cases;
    }

    sub print_error {
        my ($self, $result) = @_;
        printf { $self->fh_out } "not ok %s %s\n", $result->{type}, $result->{test};
        print { $self->fh_err } join("\n# ", split /\n/, "# " . $result->{message}), "\n";
    }

    sub print_failure {
        my ($self, $result) = @_;
        printf { $self->fh_out } "not ok %s %s\n", $result->{type}, $result->{test};
        print { $self->fh_err } join("\n# ", split /\n/, "# " . $result->{message}), "\n";
    }

    sub print_pass {
        my ($self, $result) = @_;
        printf { $self->fh_out } "ok %s %s\n", $result->{type}, $result->{test};
    }

    sub print_footer {
    }

    BEGIN { $INC{'Test/Unit/HarnessUnit.pm'} = __FILE__; }
}

{
    package Test::Unit::Debug;
    our $VERSION = $Test::Unit::Lite::VERSION;

    BEGIN { $INC{'Test/Unit/Debug.pm'} = __FILE__; }
}

{
    package Test::Unit::Lite::AllTests;
    our $VERSION = $Test::Unit::Lite::VERSION;

    use base 'Test::Unit::TestSuite';

    use Cwd ();
    use File::Find ();
    use File::Basename ();
    use File::Spec ();

    sub suite {
        my $class = shift;
        my $suite = Test::Unit::TestSuite->empty_new('All Tests');

        my $cwd = ${^TAINT} ? do { local $_=Cwd::getcwd; /(.*)/; $1 } : '.';
        my $dir = File::Spec->catdir($cwd, 't', 'tlib');
        my $depth = scalar File::Spec->splitdir($dir);

        push @INC, $dir;

        File::Find::find({
            wanted => sub {
                my $path = File::Spec->canonpath($File::Find::name);
                return unless $path =~ s/(Test)\.pm$/$1/;
                my @path = File::Spec->splitdir($path);
                splice @path, 0, $depth;
                return unless scalar @path > 0;
                my $class = join '::', @path;
                return unless $class;
                return if $class =~ /^Test::Unit::/;
                return if @ARGV and $class !~ $ARGV[0];
                $suite->add_test($class);
            },
            no_chdir => 1,
        }, $dir || '.');

        return $suite;
    }

    BEGIN { $INC{'Test/Unit/Lite/AllTests.pm'} = __FILE__; }
}


1;


__END__

=for readme stop

=head1 FUNCTIONS

=over

=item bundle

Copies L<Test::Unit::Lite> modules into F<inc> directory.  Creates missing
subdirectories if needed.  Silently overwrites previous module if was
existing.

=item all_tests

Creates new test runner for L<Test::Unit::Lite::AllTests> suite which searches
for test units in F<t/tlib> directory.

=back

=head1 CLASSES

=head2 L<Test::Unit::TestCase>

This is a base class for single unit test module.  The user's unit test
module can override the default methods that are simple stubs.

The MESSAGE argument is optional and is included to the default error message
when the assertion is false.

=over

=item new

The default constructor which just bless an empty anonymous hash reference.

=item set_up

This method is called at the start of each test unit processing.  It is empty
method and can be overridden in derived class.

=item tear_down

This method is called at the end of each test unit processing.  It is empty
method and can be overridden in derived class.

=item list_tests

Returns the list of test methods in this class and base classes.

=item fail([MESSAGE])

Immediate fail the test.

=item assert(ARG [, MESSAGE])

Checks if ARG expression returns true value.

=item assert_null(ARG [, MESSAGE])

=item assert_not_null(ARG [, MESSAGE])

Checks if ARG is defined or not defined.

=item assert_equals(ARG1, ARG2 [, MESSAGE])

=item assert_not_equals(ARG1, ARG2 [, MESSAGE])

Checks if ARG1 and ARG2 are equals or not equals.  If ARG1 and ARG2 look like
numbers then they are compared with '==' operator, otherwise the string 'eq'
operator is used.

=item assert_num_equals(ARG1, ARG2 [, MESSAGE])

=item assert_num_not_equals(ARG1, ARG2 [, MESSAGE])

Force numeric comparison.

=item assert_str_equals(ARG1, ARG2 [, MESSAGE])

=item assert_str_not_equals(ARG1, ARG2 [, MESSAGE])

Force string comparison.

=item assert(qr/PATTERN/, ARG [, MESSAGE])

=item assert_matches(qr/PATTERN/, ARG [, MESSAGE])

=item assert_does_not_match(qr/PATTERN/, ARG [, MESSAGE])

Checks if ARG matches PATTER regexp.

=item assert_deep_equals(ARG1, ARG2 [, MESSAGE])

=item assert_deep_not_equals(ARG1, ARG2 [, MESSAGE])

Check if reference ARG1 is a deep copy of reference ARG2 or not.  The
references can be deep structure.  If they are different, the message will
display the place where they start differing.

=back

=head2 L<Test::Unit::TestSuite>

This is a base class for test suite, which groups several test units.

=over

=item empty_new([NAME])

Creates a fresh suite with no tests.

=item new([CLASS | TEST])

Creates a test suite from unit test name or class.  If a test suite is
provided as the argument, it merely returns that suite.  If a test case is
provided, it extracts all test case methods (see
L<Test::Unit::TestCase>->list_test) from the test case into a new test suite.

=item name

Contains the name of the current test suite.

=item units

Contains the list of test units.

=item add_test([TEST_CLASSNAME | TEST_OBJECT])

Adds the test object to a suite.

=item count_test_cases

Returns the number of test cases in this suite.

=item run

Runs the test suite and output the results as TAP report.

=back

=head2 L<Test::Unit::TestRunner>

This is the test runner which outputs text report about finished test suite.

=over

=item new([$fh_out [, $fh_err]])

The constructor for whole test framework.  Its optional parameters are
filehandles for standard output and error messages.

=item fh_out

Contains the filehandle for standard output.

=item fh_err

Contains the filehandle for error messages.

=item suite

Contains the test suite object.

=item print_header

Called before running test suite.

=item print_error

Called after error was occurred on C<set_up> or C<tear_down> method.

=item print_failure

Called after test unit is failed.

=item print_pass

Called after test unit is passed.

=item print_footer

Called after running test suite.

=item start(TEST_SUITE)

Starts the test suite.

=back

=head2 L<Test::Unit::Result>

This object contains the results of test suite.

=over

=item new

Creates a new object.

=item messages

Contains the array of result messages.  The single message is a hash which
contains:

=over

=item test

the test unit name,

=item type

the type of message (PASS, ERROR, FAILURE),

=item message

the text of message.

=back

=item errors

Contains the number of collected errors.

=item failures

Contains the number of collected failures.

=item passes

Contains the number of collected passes.

=item add_error(TEST, MESSAGE)

Adds an error to the report.

=item add_failure(TEST, MESSAGE)

Adds an failure to the report.

=item add_pass(TEST, MESSAGE)

Adds a pass to the report.

=back

=head2 L<Test::Unit::HarnessUnit>

This is the test runner which outputs in the same format that
L<Test::Harness> expects (Test Anything Protocol).  It is derived
from L<Test::Unit::TestRunner>.

=head2 L<Test::Unit::Debug>

The empty class which is provided for compatibility with original
L<Test::Unit> framework.

=head2 L<Test::Unit::Lite::AllTests>

The test suite which searches for test units in F<t/tlib> directory.

=head1 COMPATIBILITY

L<Test::Unit::Lite> should be compatible with public API of L<Test::Unit>.
The L<Test::Unit::Lite> also has some known incompatibilities:

=over 2

=item *

The test methods are sorted alphabetically.

=item *

It implements new assertion method: B<assert_deep_not_equals>.

=item *

Does not support B<ok>, B<assert>(CODEREF, @ARGS) and B<multi_assert>.

=back

C<Test::Unit::Lite> is compatible with L<Test::Assert> assertion functions.

=head1 EXAMPLES

=head2 t/tlib/SuccessTest.pm

This is the simple unit test module.

  package SuccessTest;

  use strict;
  use warnings;

  use base 'Test::Unit::TestCase';

  sub test_success {
    my $self = shift;
    $self->assert(1);
  }

  1;

=head2 t/all_tests.t

This is the test script for L<Test::Harness> called with "make test".

  #!/usr/bin/perl

  use strict;
  use warnings;

  use File::Spec;
  use Cwd;

  BEGIN {
      unshift @INC, map { /(.*)/; $1 } split(/:/, $ENV{PERL5LIB}) if defined $ENV{PERL5LIB} and ${^TAINT};

      my $cwd = ${^TAINT} ? do { local $_=getcwd; /(.*)/; $1 } : '.';
      unshift @INC, File::Spec->catdir($cwd, 'inc');
      unshift @INC, File::Spec->catdir($cwd, 'lib');
  }

  use Test::Unit::Lite;

  local $SIG{__WARN__} = sub { require Carp; Carp::confess("Warning: $_[0]") };

  Test::Unit::HarnessUnit->new->start('Test::Unit::Lite::AllTests');

=head2 t/test.pl

This is the optional script for calling test suite directly.

  #!/usr/bin/perl

  use strict;
  use warnings;

  use File::Basename;
  use File::Spec;
  use Cwd;

  BEGIN {
      chdir dirname(__FILE__) or die "$!";
      chdir '..' or die "$!";

      unshift @INC, map { /(.*)/; $1 } split(/:/, $ENV{PERL5LIB}) if defined $ENV{PERL5LIB} and ${^TAINT};

      my $cwd = ${^TAINT} ? do { local $_=getcwd; /(.*)/; $1 } : '.';
      unshift @INC, File::Spec->catdir($cwd, 'inc');
      unshift @INC, File::Spec->catdir($cwd, 'lib');
  }

  use Test::Unit::Lite;

  local $SIG{__WARN__} = sub { require Carp; Carp::confess("Warning: $_[0]") };

  all_tests;

This is perl equivalent of shell command line:

  perl -Iinc -Ilib -MTest::Unit::Lite -w -e all_tests

=head1 SEE ALSO

L<Test::Unit>, L<Test::Assert>.

=head1 TESTS

The L<Test::Unit::Lite> was tested as a L<Test::Unit> replacement for following
distributions: L<Test::C2FIT>, L<XAO::Base>, L<Exception::Base>.

=for readme continue

=head1 BUGS

If you find the bug or want to implement new features, please report it at
L<https://github.com/dex4er/perl-Test-Unit-Lite/issues>

The code repository is available at
L<http://github.com/dex4er/perl-Test-Unit-Lite>

=head1 AUTHOR

Piotr Roszatycki <dexter@cpan.org>

=head1 LICENSE

Copyright (c) 2007-2009, 2012 by Piotr Roszatycki <dexter@cpan.org>.

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>
