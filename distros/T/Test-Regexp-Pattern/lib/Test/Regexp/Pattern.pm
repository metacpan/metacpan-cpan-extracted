## no critic: ValuesAndExpressions::ProhibitCommaSeparatedStatements BuiltinFunctions::RequireBlockMap

package Test::Regexp::Pattern;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-07-21'; # DATE
our $DIST = 'Test-Regexp-Pattern'; # DIST
our $VERSION = '0.009'; # VERSION

use 5.010001;
use strict 'subs', 'vars';
use warnings;

use File::Spec;
use Hash::DefHash; # exports defhash()
use Regexp::Pattern qw(re);
use Test::Builder;
use Test::More ();

my $Test = Test::Builder->new;

sub import {
    my $self = shift;
    my $caller = caller;
    no strict 'refs';
    *{$caller.'::regexp_patterns_in_module_ok'}      = \&regexp_patterns_in_module_ok;
    *{$caller.'::regexp_patterns_in_all_modules_ok'} = \&regexp_patterns_in_all_modules_ok;

    $Test->exported_to($caller);
    $Test->plan(@_);
}

sub _test_regexp_pattern {
    my ($re, $parent, $fqname, $opts) = @_;
    my $ok = 1;

  GENERAL: {
        my $dh;
        eval { $dh = Hash::DefHash->new($re, parent=>$parent); 1 };
        my $eval_err = $@;
        $Test->ok(!$eval_err, "Must be a valid defhash") or do {
            $Test->diag("error in defhash check: $eval_err");
            $ok = 0;
        };
        $Test->ok(($re->{pat} xor $re->{gen}), "Must declare pat OR gen but not both") or $ok = 0;
    }

  EXAMPLES: {
        last unless $opts->{test_examples} && $re->{examples};
        my $i = 0;
        for my $eg (@{ $re->{examples} }) {
            $i++;
            next unless $eg->{test} // 1;
            $Test->subtest(
                "example #$i" .
                    ($eg->{name} ? " ($eg->{name})" :
                     ($eg->{summary} ? " ($eg->{summary})" :
                      (defined $eg->{str} ? " (str $eg->{str})" :
                       ""))),
                sub {
                    $Test->ok(defined($eg->{str}), 'example provides string to match') or do {
                        $ok = 0;
                        return;
                    };

                    my %args;
                    if ($eg->{gen_args}) {
                        $args{$_} = $eg->{gen_args}{$_} for keys %{$eg->{gen_args}};
                    }
                    if (defined $eg->{anchor}) {
                        $args{-anchor} = $eg->{anchor};
                    }
                    my $pat = re($fqname, %args);

                    my $actual_match = $eg->{str} =~ $pat ? 1:0;
                    if (ref $eg->{matches} eq 'ARRAY') {
                        my $len = @{ $eg->{matches} };
                        my @actual_matches;
                        for (1..$len) {
                            push @actual_matches, ${$_};
                        }
                        my $should_match = $len ? 1:0;
                        if ($should_match) {
                            $Test->ok( $actual_match, 'string should match') or do {
                                $ok = 0;
                                return;
                            };
                            Test::More::is_deeply(\@actual_matches, $eg->{matches}, 'matches') or do {
                                  $Test->diag($Test->explain(\@actual_matches));
                                  $ok = 0;
                              };
                        } else {
                            $Test->ok(!$actual_match, 'string should not match') or do {
                                $ok = 0;
                                return;
                            };
                        }
                    } elsif (ref $eg->{matches} eq 'HASH') {
                        my %actual_matches = %+;
                        my $should_match = %{ $eg->{matches} } ? 1:0;
                        if ($should_match) {
                            $Test->ok( $actual_match, 'string should match') or do {
                                $ok = 0;
                                return;
                            };
                            Test::More::is_deeply(\%actual_matches, $eg->{matches}, 'matches') or do {
                                  $Test->diag($Test->explain(\%actual_matches));
                                  $ok = 0;
                              };
                        } else {
                            $Test->ok(!$actual_match, 'string should not match') or do {
                                $ok = 0;
                                return;
                            };
                        }
                    } else {
                        if ($eg->{matches}) {
                            $Test->ok( $actual_match, 'string should match') or do {
                                $ok = 0;
                                return;
                            };
                        } else {
                            $Test->ok(!$actual_match, 'string should not match') or do {
                                $ok = 0;
                                return;
                            };
                        }
                    }
                }) or $ok = 0;
        }
    }
    $ok;
}

sub regexp_patterns_in_module_ok {
    my $module = shift;
    my %opts = (@_ && (ref $_[0] eq "HASH")) ? %{(shift)} : ();
    my $msg  = @_ ? shift : "Regexp patterns in module $module";
    my $res;
    my $ok = 1;

    $opts{test_examples}  //= 1;

    my $has_tests;

    $Test->subtest(
        $msg,
        sub {
            (my $modulepm = "$module.pm") =~ s!::!/!g;
            require $modulepm;

            my $prefix = '';
            if ($module =~ /\ARegexp::Pattern::(.+)/) {
                $prefix = "$1\::";
            } else {
                goto L1;
            }

            my $RE = \%{ "$module\::RE" };
            my $dh = defhash($RE);
            for my $name ($dh->props) {
                my $re = $RE->{$name};
                $has_tests++;
                $Test->subtest(
                    "pattern $prefix$name",
                    sub {
                        _test_regexp_pattern($re, $RE, "$prefix$name", \%opts) or $ok = 0;
                    },
                ) or $ok = 0;
            }

          L1:
            unless ($has_tests) {
                $Test->ok(1);
                $Test->diag("No regexp patterns to test");
            }
        } # subtest
    ) or $ok = 0;

    $ok;
}

# BEGIN copy-pasted from Test::Pod::Coverage, with a bit modification

sub all_modules {
    my @starters = @_ ? @_ : _starting_points();
    my %starters = map {$_,1} @starters;

    my @queue = @starters;

    my @modules;
    while ( @queue ) {
        my $file = shift @queue;
        if ( -d $file ) {
            local *DH;
            opendir DH, $file or next;
            my @newfiles = readdir DH;
            closedir DH;

            @newfiles = File::Spec->no_upwards( @newfiles );
            @newfiles = grep { $_ ne "CVS" && $_ ne ".svn" } @newfiles;

            push @queue, map "$file/$_", @newfiles;
        }
        if ( -f $file ) {
            next unless $file =~ /\.pm$/;

            my @parts = File::Spec->splitdir( $file );
            shift @parts if @parts && exists $starters{$parts[0]};
            shift @parts if @parts && $parts[0] eq "lib";
            $parts[-1] =~ s/\.pm$// if @parts;

            # Untaint the parts
            for ( @parts ) {
                if ( /^([a-zA-Z0-9_\.\-]*)$/ && ($_ eq $1) ) {
                    $_ = $1;  # Untaint the original
                }
                else {
                    die qq{Invalid and untaintable filename "$file"!};
                }
            }
            my $module = join( "::", grep {length} @parts );
            push( @modules, $module );
        }
    } # while

    return @modules;
}

sub _starting_points {
    return 'blib' if -e 'blib';
    return 'lib';
}

# END copy-pasted from Test::Pod::Coverage

sub regexp_patterns_in_all_modules_ok {
    my $opts = (@_ && (ref $_[0] eq "HASH")) ? shift : {};
    my $msg  = shift;
    my $ok = 1;

    my @starters = _starting_points();
    local @INC = (@starters, @INC);

    $Test->plan(tests => 1);

    my @modules = all_modules(@starters);
    if (@modules) {
        $Test->subtest(
            "Regexp patterns on all dist's modules",
            sub {
                for my $module (@modules) {
                    my $thismsg = defined $msg ? $msg :
                        "Regexp patterns in module $module";
                    my $thisok = regexp_patterns_in_module_ok(
                        $module, $opts, $thismsg)
                        or $ok = 0;
                }
            }
        ) or $ok = 0;
    } else {
        $Test->ok(1, "No modules found.");
    }
    $ok;
}

1;
# ABSTRACT: Test Regexp::Pattern patterns

__END__

=pod

=encoding UTF-8

=head1 NAME

Test::Regexp::Pattern - Test Regexp::Pattern patterns

=head1 VERSION

This document describes version 0.009 of Test::Regexp::Pattern (from Perl distribution Test-Regexp-Pattern), released on 2021-07-21.

=head1 SYNOPSIS

To check all regexp patterns in a module:

 use Test::Regexp::Pattern;
 regexp_patterns_in_module_ok("Foo::Bar", {opt => ...}, $msg);

Alternatively, you can check all regexp patterns in all modules in a distro:

 # save in release-regexp-pattern.t, put in distro's t/ subdirectory
 use Test::More;
 plan skip_all => "Not release testing" unless $ENV{RELEASE_TESTING};
 eval "use Test::Regexp::Pattern";
 plan skip_all => "Test::Regexp::Pattern required for testing Regexp::Pattern patterns" if $@;
 regexp_patterns_in_all_modules_ok({opt => ...}, $msg);

=head1 DESCRIPTION

This module performs various checks on a module's L<Regexp::Pattern> patterns.
It is recommended that you include something like the above
C<release-regexp-pattern.t> in your distribution if you add regexp patterns to
your code. If you use L<Dist::Zilla> to build your distribution, there is a
L<[Regexp::Pattern]|Dist::Zilla::Plugin::Regexp::Pattern> plugin which
automatically adds this release test file during build.

=for Pod::Coverage ^(all_modules)$

=head1 ACKNOWLEDGEMENTS

Some code taken from L<Test::Pod::Coverage> by Andy Lester.

=head1 FUNCTIONS

All these functions are exported by default.

=head2 regexp_patterns_in_module_ok($module [, \%opts ] [, $msg])

Load C<$module> and perform test for regexp patterns (C<%RE>) in the module.

Available options:

=over 4

=item * test_examples => bool (default: 1)

=back

=head2 regexp_patterns_in_all_modules_ok([ \%opts ] [, $msg])

Look for modules in directory C<lib> (or C<blib> instead, if it exists), and run
C<regexp_patterns_in_module_ok()> against each of them.

Options are the same as in C<regexp_patterns_in_module_ok()>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Test-Regexp-Pattern>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Test-Regexp-Pattern>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Test-Regexp-Pattern>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<test-regexp-pattern>, a command-line interface for
C<regexp_patterns_in_all_modules_ok()>.

L<Regexp::Pattern>

L<Dist::Zilla::Plugin::Regexp::Pattern>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021, 2020, 2018 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
