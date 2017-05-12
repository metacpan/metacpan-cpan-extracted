package Test::Unit::ITestRunner;

use strict;
use warnings;
use base 'Test::Unit::TestRunner';
use Time::HiRes;
our $VERSION = '0.05';

my $ITESTRUNNER_TEST_WARNINGS = [];
my $ITESTRUNNER_TEST_TIMINGS = [];

BEGIN {
    $ENV{ITESTRUNNER_TEST_WARNINGS_COUNTER} = 0;
    $SIG{'__WARN__'} = sub {
        my $warning = shift;
        push(@{$ITESTRUNNER_TEST_WARNINGS}, $warning);
        $ENV{ITESTRUNNER_TEST_WARNINGS_COUNTER} ++;
    };
};

sub start
{
    my $self = shift;

    # print startup warnings
    $self->_printWarnings;
    $ITESTRUNNER_TEST_WARNINGS = [];

    return $self->SUPER::start(@_);
}

sub do_run
{
    my $self = shift;

    # print test load warnings
    $self->_printWarnings;
    $ITESTRUNNER_TEST_WARNINGS = [];

    return $self->SUPER::do_run(@_);
}

sub start_test
{
    my $self = shift;
    my ($test) = @_;

    $self->{current_test_started_at} = $self->_getHiResTime;

    $ITESTRUNNER_TEST_WARNINGS = [];
    my $testcase = ref($test);
    my $testname = $test->name;
    $self->_print("$testcase - $testname");
}


sub add_error
{
    my $self = shift;
    my ($test, $exception) = @_;

    $self->_printSpaces($test, '.');
    $self->_colorPrint('bold red', "[ERROR]\n");
    $self->_printWarnings;
}

sub add_failure
{
    my $self = shift;
    my ($test, $exception) = @_;

    $self->_printSpaces($test, '.');
    $self->_colorPrint('bold light_yellow', "[FAIL]\n");
    $self->_printWarnings;
}

sub add_pass
{
    my $self = shift;
    my ($test) = @_;

    $self->_printSpaces($test);

    $self->_colorPrint('light_green', "[OK]");

    my $started_at = $self->{current_test_started_at}; 
    my $time = $self->_getHiResTime - $started_at;
    $time = sprintf("%0.3f", $time);

    my $testcase = ref($test);
    my $testname = $test->name;

    push(@{$ITESTRUNNER_TEST_TIMINGS}, { test => "$testcase - $testname", timing => $time});
    $self->{current_test_started_at} = 0;
    my $time_warning = 0;
    $time_warning = 1 if $ENV{ITESTRUNNER_MAXTIME} && $time > $ENV{ITESTRUNNER_MAXTIME};

    if ($time_warning) {
        $self->_colorPrint('bold red', " $time sec\n");
    }else{
        $self->_print(" $time sec\n");
    }
    $self->_printWarnings;
}

sub print_result
{
    my $self = shift;

    my @results = $self->SUPER::print_result(@_);

    if ($ENV{ITESTRUNNER_TEST_WARNINGS_COUNTER}) {
        $self->_colorPrint('bold light_blue', "Warnings: ". $ENV{ITESTRUNNER_TEST_WARNINGS_COUNTER} . "\n");
    }

    return @results unless $ENV{ITESTRUNNER_SLOWTEST_TOP};


    $ITESTRUNNER_TEST_TIMINGS ||= []; 
    my @slow_tests = sort {$b->{timing} <=> $a->{timing}} @{$ITESTRUNNER_TEST_TIMINGS};
    print "\nSlow tests top:\n";
    my $count = $ENV{ITESTRUNNER_SLOWTEST_TOP};
    for my $slow_test(@slow_tests){
        $count--;
        $self->_print($slow_test->{timing} . " sec\t". $slow_test->{test} . "\n");
        last unless $count;
    }

    return @results;
}

sub _getHiResTime
{
    my $self = shift;

    return Time::HiRes::time();
}

sub _printSpaces
{
    my $self = shift;
    my ($test, $space) = @_;

    $space ||= ' ';
    my $base = $ENV{ITESTRUNNER_WIDTH} || 120;
    my $testcase = ref($test);
    my $testname = $test->name;
    my $spaces = $base - length("$testcase - $testname");
    $self->_print("$space" x $spaces);
}

sub _printWarnings
{
    my $self = shift;

    return unless $ITESTRUNNER_TEST_WARNINGS && @{$ITESTRUNNER_TEST_WARNINGS};

    for my $warning(@{$ITESTRUNNER_TEST_WARNINGS}){
        $self->_colorPrint('light_blue', "$warning\n");
    }
}

sub _colorPrint
{
    my $self = shift;
    my ($colors, $text) = @_;

    $text = $self->_colorizeText($colors, $text) if $ENV{ITESTRUNNER_COLORIZE};
    $self->_print($text);
}

sub _colorizeText
{
    my $self = shift;
    my ($colors, $text) = @_;

    return $text unless $colors;
    for my $color(split /\s+/, $colors){
        my $code = $self->_getColorCode($color);
        $text = "\e[${code}m$text";
    }

    return $text . "\e[0m";
}

sub _getColorCode
{
    my $self = shift;
    my ($color) = @_;

    return {
        bold => "1",
        red => "31",
        light_yellow => "93",
        light_green => "92",
        light_blue => "94",
        'reset' => "0",
    }->{$color};
}
1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Test::Unit::ITestRunner - Extends and colorize Test::Unit::TestRunner output 

=head1 SYNOPSIS

  use Test::Unit::ITestRunner;
  my $runner = Test::Unit::ITestRunner->new();
  $runner->start($my_testcase_class);

See L<Test::Unit::TestRunner> for more information

  # ITestRunner specific options

  # enable ANSI-colorized output
  $ENV{ITESTRUNNER_COLORIZE} = 1; # default 0 = disabled

  # enable slow test highlight
  # required ITESTRUNNER_COLORIZE = 1
  $ENV{ITESTRUNNER_MAXTIME} = 0.8 # max test time (sec.) # default 0 = disabled

  # show top slow tests
  $ENV{ITESTRUNNER_SLOWTEST_TOP} = 5 # default 0 = disabled

  # set output width
  $ENV{ITESTRUNNER_WIDTH} = 80 # default 120


=head1 DESCRIPTION

Test::Unit::ITestRunner extends Test::Unit::TestRunner output.

Test::Unit::TestRunner

    ....F....F........E.......F......E........

Test::Unit::ITestRunner

    MyTestCase - test_someTest1                        [OK] 0.031 sec
    MyTestCase - test_someTest2                        [OK] 0.018 sec
    MyTestCase - test_someTest3                        [OK] 0.012 sec
    MyTestCase - test_someTest4........................[ERROR]
    MyTestCase - test_someTest5                        [OK] 0.054 sec
    MyTestCase - test_someTest6                        [OK] 0.044 sec
    MyTestCase - test_someTest7........................[FAIL]
    MyTestCase - test_someTest8                        [OK] 0.030 sec


=head1 SEE ALSO

L<Test::Unit>, L<Test::Unit::TestRunner>, L<Time::HiRes>

=head1 AUTHOR

cmapuk[0nline], E<lt>cmapuk.0nline@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by cmapuk[0nline]

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.


=cut
