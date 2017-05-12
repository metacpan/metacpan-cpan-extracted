package Test::Doctest;

use 5.014;
use warnings;
use strict;
use Data::Dumper 'Dumper';

use parent 'Exporter';
use parent 'Pod::Parser';

our $VERSION = '0.02';
our @EXPORT  = qw(run runtests);

use Carp;
use Test::Builder;
use File::Spec::Functions 'devnull';
use Module::Metadata;

=head1 NAME

Test::Doctest - extract and evaluate tests from pod fragments

=head1 SYNOPSIS

    perl -Ilib -MTest::Doctest -e run Some/Module.pm

    - or -

    perl -Ilib -MTest::Doctest -e run Some::Module

    - or -

    use Test::Doctest;
    runtests($filepath);

    - or -

    use Test::Doctest;
    my $p = Test::Doctest->new;
    $p->parse_from_filehandle(\*STDIN);
    $p->test;

=head1 DESCRIPTION

B<run> and B<runtests> uses B<Pod::Parser> to extract pod text from the files
specified, evaluates each line begining with a prompt (>>>),
and finally compares the results with the expected output using
B<is_eq> from B<Test::Builder>.

=head1 EXAMPLES

    >>> 1 + 1
    2

    >>> my @a = qw(2 3 4)
    3

    >>> use Pod::Parser;
    >>> my $p = Pod::Parser->new;
    >>> ref $p;
    'Pod::Parser'

    >>> $a = 10
    10

    >>> $a *= 2
    20

See more examples in L<Test::Doctest::Example>.

=head1 EXPORTS

=head2 B<run()>

Extract and run tests from pod for each file in @ARGV.

=head2 B<runtests()>

Extract and run tests from pod for each file argument.

=begin runtests

    >>> use Test::Doctest
    >>> runtests
    0

=end runtests

=cut

sub runtests {
    my ($total, $success, @tests) = (0, 0);
    my $test = Test::Doctest::Builder->new;

    foreach (@_) {
        my $t = Test::Doctest->new;
        $t->parse_from_file($_);
        $total += @{$t->{tests}};
        push @tests, $t;
    }

    $test->plan(tests => $total) unless $test->has_plan;

    foreach (@tests) {
        $success += $_->test == @{$_->{tests}};
    }

    return $success;
}

sub run { runtests @ARGV }

sub parse_from_file {
    my $self   = shift;
    my $module = shift;
    $module = ($module =~ s{::}{/}gr) . '.pm' unless $module =~ /\.pm$/;
    require $module;
    my $info = Module::Metadata->new_from_module($module);
    $self->{package} = $info->{packages}->[0] if @{$info->{packages}};
    return $self->SUPER::parse_from_file($info->{filename}, devnull);
}

=head1 METHODS

=head2 B<initialize()>

Initialize this B<Test::Doctest> pod parser. This method is
not typically called directly, but rather, is called by
B<Pod::Parser::new> when creating a new parser.

=begin initialize

    >>> my $t = Test::Doctest->new
    >>> @{$t->{tests}}
    0

=end initialize

=cut

sub initialize {
    my ($self) = @_;
    $self->SUPER::initialize;
    $self->{tests} = [];
}

=head2 B<command()>

Override B<Pod::Parser::command> to save the name of the
current section which is used to name the tests.

=begin command

    >>> my $t = Test::Doctest->new
    >>> $t->command('head1', "EXAMPLES\nthese are examples", 1)
    >>> $t->{name}
    'EXAMPLES'

=end command

=cut

sub command {
    my ($self, $cmd, $par, $line) = @_;
    $self->{name} = (split /(?:\r|\n|\r\n)/, $par, 2)[0];
}

=head2 B<textblock()>

Override B<Pod::Parser::textblock> to ignore normal blocks of pod text.

=begin textblock

    >>> my $t = Test::Doctest->new
    >>> not defined $t->textblock
    1

=end textblock

=cut

sub textblock { }

=head2 B<verbatim()>

Override B<Pod::Parser::verbatim> to search verbatim paragraphs for
doctest code blocks.  Each block found, along with information about
its location in the file and its expected output is appended to the
list of tests to be executed.

=begin verbatim

    >>> my $t = Test::Doctest->new
    >>> $t->verbatim(" >>> 1+1\n  2", 1)
    1

=end verbatim

=begin verbatim no prompt

    >>> my $t = Test::Doctest->new
    >>> $t->verbatim("abc", 1)
    0

=end verbatim

=cut


package Test::Doctest::Expect {
    use Test::Deep::NoTest ':all';
}


sub verbatim {
    my ($self, $par, $line) = @_;
    my $name = $self->{name}     ? $self->{name}     : q{};
    my $file = $self->input_file ? $self->input_file : 'stdin';

    my @lines = split /(?:\r|\n|\r\n)/, $par;

    my (@tests, $code, $expect);
    foreach (@lines) {
        if (/^\s+(>{3}|\.{3}|\$)\s+(.+)/ && ($1 ne '...' || $code && @$code)) {
            if (!defined $expect || @$expect) {
                push(
                    @tests,
                    {
                        code   => $code   = [],
                        expect => $expect = []
                    }
                );
            }
            # capture code
            if ($1 eq '...') {
                # capture multiline code
                $code->[$#$code] .= $2;
            }
            else {
                push @$code, $2;
            }
        }
        elsif (/^\s*(.+)/ && $code && @$code) {
            # on first non-code line, with valid code accumlated
            push(@$expect, $1);
        }
    }

    foreach (@tests) {
        my $expect = do {
            package Test::Doctest::Expect;
            eval(join('', @{$_->{expect}}));
        };

        die "$@\t$file, line $line" if $@;
        push @{$self->{tests}}, [$name, $file, $line, $expect, @{$_->{code}}];
    }
    return @{$self->{tests}};
}

=head2 B<test()>

Evaluates each test discovered via parsing and compares the results
with the expected output using B<Test::Builder::is_eq>.

=begin test

    >>> my $t = Test::Doctest->new
    >>> $t->test
    0

    >>> $t->command('begin', 'test', 1)
    >>> $t->verbatim(" >>> 1+1\n  2", 2)
    >>> @{$t->{tests}}
    1

=end test

=cut

package Test::Doctest::Builder {
    use Test::Deep::NoTest qw(cmp_details deep_diag);

    use base 'Test::Builder';

    our $Test;
    sub new { $Test ||= shift->create }

    sub is_eq {
        my $self = shift;
        my ($got, $expected, $test_name) = @_;
        if (ref $expected) {
            my ($ok, $stack) = cmp_details($got, $expected);
            $self->diag(deep_diag($stack)) unless $self->ok($ok, $test_name);
            return;
        }
        $self->SUPER::is_eq(@_);
    }
}

our ($Result, $Check);

sub test {
    my ($self) = @_;
    my $tests = $self->{tests};

    my $test = Test::Doctest::Builder->new;
    $test->plan(tests => scalar @$tests) unless $test->has_plan;

    my (@grouped, $current_group);
    foreach (@$tests) {
        if (!defined($current_group) || $_->[0] ne $current_group->[0][0]) {
            push(@grouped, $current_group = []);
        }
        push(@$current_group, $_);
    }

    my $run = 0;
    foreach my $group (@grouped) {
        my (@group_code, @checks);
        push(@group_code, "package $self->{package}") if $self->{package};
        for (my $i = 0 ; $i <= $#$group ; $i++) {
            my ($name, $file, $line, $expect, @code) = @{$group->[$i]};
            my $outof =
              $#$group > 0 ? sprintf("%d/%d", $i + 1, $#$group + 1) : q();
            my $test_name = "$name $outof ($file, $line)";
            push(@checks, sub { $test->is_eq($Result, $expect, $test_name) });
            my $result_line = pop(@code);
            push(
                @group_code,
                @code,
                "\$Test::Doctest::Result = $result_line",
                "\$Test::Doctest::Check->()"
            );
        }
        local $Check = sub { shift(@checks)->() };
        eval join(";", @group_code);
        croak $@ if $@;
        $run += @$group;
    }

    return $run;
}

1;

__END__

=head1 SEE ALSO

L<Pod::Parser>, L<Test::Builder>, L<Test::Deep>

B<Pod::Parser> defines the parser interface used to extract the tests.

B<Test::Builder> is used to plan the tests and determine the results.

B<Test::Deep> is used to compare test result with expected value.

=head1 AUTHORS

Bryan Cardillo E<lt>dillo@cpan.orgE<gt>

Andrei Fyodorov E<lt>afyodorov@cpan.orgE<gt>

L<Git repository|https://github.com/mkllnk/PerlDoctest> is maintained by Maikel Linke E<lt>mkllnk@web.deE<gt>

Please submit bugs to L<the issue tracker|https://github.com/mkllnk/PerlDoctest/issues>.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Bryan Cardillo

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
