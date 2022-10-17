## no critic: ValuesAndExpressions::ProhibitCommaSeparatedStatements BuiltinFunctions::RequireBlockMap

package Test::Sah::Filter;

use 5.010001;
use strict 'subs', 'vars';
use warnings;
use Log::ger;
use Log::ger::App;

use File::Spec;
use Test::Builder;
use Test::More ();

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-10-17'; # DATE
our $DIST = 'Test-Sah-Filter'; # DIST
our $VERSION = '0.005'; # VERSION

my $Test = Test::Builder->new;

sub import {
    my $self = shift;
    my $caller = caller;
    no strict 'refs';
    *{$caller.'::sah_filter_modules_ok'}      = \&sah_filter_modules_ok;

    $Test->exported_to($caller);
    $Test->plan(@_);
}

sub _set_option_defaults {
    my $opts = shift;
    $opts->{test_examples} //= 1;
    $opts->{test_perl_filters} //= 1;
    $opts->{test_js_filters} //= 1;
}

sub sah_filter_module_ok {
    my $module = shift;
    my %opts   = (@_ && (ref $_[0] eq "HASH")) ? %{(shift)} : ();
    my $msg    = @_ ? shift : "Sah filter module $module";
    my $res;
    my $ok = 1;

    _set_option_defaults(\%opts);

    my $modulep = $module; $modulep =~ s!::!/!g; $modulep .= ".pm";
    require $modulep;
    my $meta = $module->meta;

    (my $filter_name0 = $module) =~ s/\AData::Sah::Filter::// or die "Module is not named Data::Sah::Filter::*";
    (my $filter_name1 = $filter_name0) =~ s/\A(\w+)::// or die "Module is not named Data::Sah::Filter::LANG::*";
    my $lang = $1; $lang =~ /\A(js|perl)\z/ or die "Language '$lang' is not supported, only js & perl are currently supported";

    if ($lang eq 'perl' && !$opts{test_perl_filters}) {
        $Test->diag("Perl filter module '$module' is skipped due to test_perl_filters option set to 0");
        return;
    }
    if ($lang eq 'js' && !$opts{test_js_filters}) {
        $Test->diag("JS filter module '$module' is skipped due to test_js_filters option set to 0");
        return;
    }

    $Test->subtest(
        $msg,
        sub {
          TEST_META: {

                if (ref $meta eq 'HASH') {
                    $Test->ok(1, "Metadata is hash");
                } else {
                    $Test->ok(0, "Metadata is NOT a hash");
                }

                require Hash::DefHash;
                my $meta_dh;
                eval { $meta_dh = Hash::DefHash->new($meta) };
                if (!$@) {
                    $Test->ok(1, "Metadata is a valid defhash");
                } else {
                    $Test->ok(0, "Metadata is NOT a valid defhash: $@");
                }

                my $meta_v = $meta->{v} // 1;
                if ($meta_v == 1) {
                    $Test->ok(1, "Metadata version is 1");
                } else {
                    $Test->ok(0, "Metadata version ($meta_v) is not supported, currently only v=1 is supported");
                }

              TEST_META_ARGS: {
                    last unless $meta->{args};

                    if (ref $meta->{args} eq 'HASH') {
                        $Test->ok(1, "Args is a hash");
                    } else {
                        $Test->ok(0, "Args is NOT a hash");
                    }

                    my $args_dh;
                    eval { $args_dh = Hash::DefHash->new($meta->{args}) };
                    if (!$@) {
                        $Test->ok(1, "Args is a valid defhash");
                    } else {
                        $Test->ok(0, "Args is NOT a valid defhash: $@");
                    }

                    for my $argname (sort keys %{ $meta->{args} // {} }) {
                        my $argspec = $meta->{args}{$argname};

                        if (ref $argspec eq 'HASH') {
                            $Test->ok(1, "Spec for arg '$argname' is a hash");
                        } else {
                            $Test->ok(0, "Spec for arg '$argname' is NOT a hash");
                        }

                        my $argspec_dh;
                        eval { $argspec_dh = Hash::DefHash->new($argspec) };
                        if (!$@) {
                            $Test->ok(1, "Spec for arg '$argname' is a valid defhash");
                        } else {
                            $Test->ok(0, "Spec for arg '$argname' is NOT a valid defhash: $@");
                        }

                    } # for arg
                } # TEST_META_ARGS
            } # TEST_META

          TEST_EXAMPLES: {
                last unless $opts{test_examples};

                if ($meta->{before_test_examples}) {
                    log_trace "Executing before_test_examples hook ...";
                    $meta->{before_test_examples}->();
                }

                unless ($meta->{examples} && @{ $meta->{examples} }) {
                    $Test->ok(1);
                    $Test->diag("There are no examples");
                    last;
                }

                require Data::Cmp;

                my $gen_filter;
                if ($lang eq 'js') {
                    require Data::Sah::FilterJS;
                    $gen_filter = \&Data::Sah::FilterJS::gen_filter;
                } else {
                    require Data::Sah::Filter;
                    $gen_filter = \&Data::Sah::Filter::gen_filter;
                }

                my $i = 0;
                for my $eg (@{ $meta->{examples} }) {
                    $i++;
                    $Test->subtest(
                        "example #$i",
                        sub {

                            if ($eg->{before_test}) {
                                log_trace "Executing before_test example hook ...";
                                $eg->{before_test}->();
                            }

                            my $filter_rule = [$filter_name1, $eg->{filter_args} // {}];
                            my $filter_code = $gen_filter->(
                                filter_names=>[$filter_rule],
                                return_type => 'str_errmsg+val',
                            );

                            my ($actual_errmsg, $actual_filtered_value);
                            ($actual_errmsg, $actual_filtered_value) = @{ $filter_code->($eg->{value}) };
                            my $correct_filtered_value = exists($eg->{filtered_value}) ?
                                $eg->{filtered_value} : $eg->{value};

                            if ($eg->{valid} // 1) {
                                if ($actual_errmsg) {
                                    $Test->ok(0, "filtering should succeed but it fails: $actual_errmsg");
                                } elsif (Data::Cmp::cmp_data($actual_filtered_value, $correct_filtered_value) != 0) {
                                    require Data::Dump;
                                    require Text::Diff;
                                    my $actual_filtered_value_dmp  = Data::Dump::dump($actual_filtered_value);
                                    my $correct_filtered_value_dmp = Data::Dump::dump($correct_filtered_value);
                                    my $diff = Text::Diff::diff(\$actual_filtered_value_dmp, \$correct_filtered_value_dmp);
                                    $Test->diag("Result difference (actual vs expected): $diff");
                                    $Test->ok(0, "filtering succeeds but result is not as expected");
                                } else {
                                    $Test->ok(1, "filtering succeeds and result is ok");
                                }
                            } else {
                                if ($actual_errmsg) {
                                    $Test->ok(1, "filtering fails as expected");
                                } else {
                                    $Test->ok(0, "filtering should fail but succeeds");
                                }
                            }

                            if ($eg->{after_test}) {
                                log_trace "Executing after_test example hook ...";
                                $eg->{after_test}->();
                            }

                        },
                    ); # subtest example #$i
                } # for $eg

                if ($meta->{after_test_examples}) {
                    log_trace "Executing after_test_examples hook ...";
                    $meta->{after_test_examples}->();
                }

            } # TEST_EXAMPLES
            $ok;
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
            my @newfiles = sort readdir DH;
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

sub sah_filter_modules_ok {
    my $opts = (@_ && (ref $_[0] eq "HASH")) ? shift : {};
    my $msg  = shift;
    my $ok = 1;

    _set_option_defaults($opts);

    my @starters = _starting_points();
    local @INC = (@starters, @INC);

    $Test->plan(tests => 1);

    my @include_modules;
    {
        my $val = delete $opts->{include_modules};
        last unless $val;
        for my $mod (@$val) {
            $mod = "Data::Sah::Filter::$mod" unless $mod =~ /^Data::Sah::Filter::/;
            push @include_modules, $mod;
        }
    }
    my @exclude_modules;
    {
        my $val = delete $opts->{exclude_modules};
        last unless $val;
        for my $mod (@$val) {
            $mod = "Data::Sah::Filter::$mod" unless $mod =~ /^Data::Sah::Filter::/;
            push @exclude_modules, $mod;
        }
    }

    my @all_modules = all_modules(@starters);
    if (@all_modules) {
        $Test->subtest(
            "Sah filter modules in dist",
            sub {
                for my $module (@all_modules) {
                    next unless $module =~ /\AData::Sah::Filter::/;
                    if (@include_modules) {
                        next unless grep { $module eq $_ } @include_modules;
                    }
                    if (@exclude_modules) {
                        next if grep { $module eq $_ } @exclude_modules;
                    }

                    log_info "Processing module %s ...", $module;
                    my $thismsg = defined $msg ? $msg :
                        "Sah filter module $module";
                    my $thisok = sah_filter_module_ok(
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
# ABSTRACT: Test Data::Sah::Filter::* modules in distribution

__END__

=pod

=encoding UTF-8

=head1 NAME

Test::Sah::Filter - Test Data::Sah::Filter::* modules in distribution

=head1 VERSION

This document describes version 0.005 of Test::Sah::Filter (from Perl distribution Test-Sah-Filter), released on 2022-10-17.

=head1 SYNOPSIS

To check a single Data::Sah::Filter::* module:

 use Test::Sah::Filter tests=>1;
 sah_filter_module_ok("Data::Sah::Filter::perl::Str::check", {opt => ...}, $msg);

To check all Data::Sah::Filter::* modules in a distro:

 # save in release-sah-filter.t, put in distro's t/ subdirectory
 use Test::More;
 plan skip_all => "Not release testing" unless $ENV{RELEASE_TESTING};
 eval "use Test::Sah::Filter";
 plan skip_all => "Test::Sah::Filter required for testing Data::Sah::Filter::* modules" if $@;
 sah_filter_modules_ok({opt => ...}, $msg);

=head1 DESCRIPTION

This module performs various checks on Data::Sah::Filter::* modules. It is
recommended that you include something like C<release-sah-filter.t> in your
distribution if you add metadata to your code. If you use L<Dist::Zilla> to
build your distribution, there is L<Dist::Zilla::Plugin::Sah::Filter> to make it
easy to do so.

=for Pod::Coverage ^(all_modules)$

=head1 ACKNOWLEDGEMENTS

Some code taken from L<Test::Pod::Coverage> by Andy Lester.

=head1 FUNCTIONS

All these functions are exported by default.

=head2 sah_filter_module_ok($module [, \%opts ] [, $msg])

Load C<$module> and perform tests on it.

Available options:

=over

=item * test_examples => BOOL (default: 1)

Whether to test examples in filter.

=back

=head2 sah_filter_modules_ok([ \%opts ] [, $msg])

Look for modules in directory F<lib> (or F<blib> instead, if it exists), and run
C<sah_filter_module_ok> on each of them.

Options are the same as in C<sah_filter_module_ok>, plus:

=over

=item * include_modules

=item * exclude_modules

=item * test_js_filters

=item * test_perl_filters

=back

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Test-Sah-Filter>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Test-Sah-Filter>.

=head1 SEE ALSO

L<test-sah-filter-modules>, a command-line interface for
C<sah_filter_modules_ok()>.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 CONTRIBUTING


To contribute, you can send patches by email/via RT, or send pull requests on
GitHub.

Most of the time, you don't need to build the distribution yourself. You can
simply modify the code, then test via:

 % prove -l

If you want to build the distribution (e.g. to try to install it locally on your
system), you can install L<Dist::Zilla>,
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>,
L<Pod::Weaver::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla- and/or Pod::Weaver plugins. Any additional steps required beyond
that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Test-Sah-Filter>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
