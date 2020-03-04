## no critic: ValuesAndExpressions::ProhibitCommaSeparatedStatements BuiltinFunctions::RequireBlockMap

package Test::Sah::Schema;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-03-04'; # DATE
our $DIST = 'Test-Sah-Schema'; # DIST
our $VERSION = '0.006'; # VERSION

use 5.010001;
use strict 'subs', 'vars';
use warnings;
use Log::ger;
use Log::ger::App;

use File::Spec;
use Test::Builder;
use Test::More ();

my $Test = Test::Builder->new;

sub import {
    my $self = shift;
    my $caller = caller;
    no strict 'refs';
    *{$caller.'::sah_schema_modules_ok'}      = \&sah_schema_modules_ok;

    $Test->exported_to($caller);
    $Test->plan(@_);
}

sub _test_module {

    my ($module, $opts) = @_;
    my $ok = 1;

    (my $module_pm = "$module.pm") =~ s!::!/!g;
    require $module_pm;
    my $sch = ${"$module\::schema"};

}

sub sah_schema_module_ok {
    require Data::Sah::Normalize;

    my $module = shift;
    my %opts   = (@_ && (ref $_[0] eq "HASH")) ? %{(shift)} : ();
    my $msg    = @_ ? shift : "Sah schema in $module";
    my $res;
    my $ok = 1;

    $opts{test_schema_examples} //= [];

    my $modulep = $module; $modulep =~ s!::!/!g; $modulep .= ".pm";
    require $modulep;
    my $sch = ${"$module\::schema"};

    $Test->subtest(
        $msg,
        sub {
          TEST_NORMALIZED: {
                require Data::Dump;
                require Text::Diff;
                my $nsch = Data::Sah::Normalize::normalize_schema($sch);

                my $sch_dmp  = Data::Dump::dump($sch);
                my $nsch_dmp = Data::Dump::dump($nsch);
                if ($sch_dmp eq $nsch_dmp) {
                    $Test->ok(1, "Schema is normalized");
                } else {
                    my $diff = Text::Diff::diff(\$sch_dmp, \$nsch_dmp);
                    $Test->diag("Schema difference with normalized version: $diff");
                    $Test->ok(0, "Schema is not normalized");
                    return 0;
                }
            }

          TEST_EXAMPLES: {
                last unless $opts{test_schema_examples};
                last unless $sch->[1]{examples};
                require Data::Sah;

                my $vdr = Data::Sah::gen_validator($sch, {return_type=>'str_errmsg+val'});

                my $i = 0;
                for my $eg (@{ $sch->[1]{examples} }) {
                    $i++;
                    next unless $eg->{test} // 1;
                    $Test->subtest(
                        "example #$i" .
                            ($eg->{name} ? " ($eg->{name})" :
                             ($eg->{summary} ? " ($eg->{summary})" : "")),
                        sub {
                            my $value =
                                exists $eg->{value} ? $eg->{value} :
                                exists $eg->{data}  ? $eg->{data} : die "BUG in example #$i: Please specify 'value' or 'data'";

                                my ($errmsg, $res)  = @{ $vdr->($value) };
                            if ($eg->{valid}) {
                                if ($errmsg) {
                                    $Test->ok(0, "Value should be valid, but isn't");
                                    $ok = 0;
                                    return;
                                } else {
                                    $Test->ok(1, "Value should be valid");
                                }
                            } else {
                                if (!$errmsg) {
                                    $Test->ok(0, "Value shouldn't be valid, but is");
                                    $ok = 0;
                                    return;
                                } else {
                                    $Test->ok(1, "Value should not be valid");
                                }
                            }

                            my $validated_value =
                                exists $eg->{validated_value} ? $eg->{validated_value} :
                                exists $eg->{res} ? $eg->{res} : $eg->{value};
                            Test::More::is_deeply($res, $validated_value, 'Validated value matches') or do {
                                $Test->diag($Test->explain($res));
                                $ok = 0;
                            };
                        }
                    );
                } # for example
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

sub sah_schema_modules_ok {
    my $opts = (@_ && (ref $_[0] eq "HASH")) ? shift : {};
    my $msg  = shift;
    my $ok = 1;

    my @starters = _starting_points();
    local @INC = (@starters, @INC);

    $Test->plan(tests => 1);

    my @include_modules;
    {
        my $val = delete $opts->{include_modules};
        last unless $val;
        for my $mod (@$val) {
            $mod = "Sah::Schema::$mod" unless $mod =~ /^Sah::Schema::/;
            push @include_modules, $mod;
        }
    }
    my @exclude_modules;
    {
        my $val = delete $opts->{exclude_modules};
        last unless $val;
        for my $mod (@$val) {
            $mod = "Sah::Schema::$mod" unless $mod =~ /^Sah::Schema::/;
            push @exclude_modules, $mod;
        }
    }

    my @all_modules = all_modules(@starters);
    if (@all_modules) {
        $Test->subtest(
            "Sah schema modules in dist",
            sub {
                for my $module (@all_modules) {
                    next unless $module =~ /\ASah::Schema::/;
                    if (@include_modules) {
                        next unless grep { $module eq $_ } @include_modules;
                    }
                    if (@exclude_modules) {
                        next if grep { $module eq $_ } @exclude_modules;
                    }

                    log_info "Processing module %s ...", $module;
                    my $thismsg = defined $msg ? $msg :
                        "Sah schema module in $module";
                    my $thisok = sah_schema_module_ok(
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
# ABSTRACT: Test Sah::Schema::* modules in distribution

__END__

=pod

=encoding UTF-8

=head1 NAME

Test::Sah::Schema - Test Sah::Schema::* modules in distribution

=head1 VERSION

This document describes version 0.006 of Test::Sah::Schema (from Perl distribution Test-Sah-Schema), released on 2020-03-04.

=head1 SYNOPSIS

To check a single Sah::Schema::* module:

 use Test::Sah::Schema tests=>1;
 sah_schema_module_ok("Sah::Schema::Foo", {opt => ...}, $msg);

To check all Sah::Schema::* modules in a distro:

 # save in release-sah-schema.t, put in distro's t/ subdirectory
 use Test::More;
 plan skip_all => "Not release testing" unless $ENV{RELEASE_TESTING};
 eval "use Test::Sah::Schema";
 plan skip_all => "Test::Sah::Schema required for testing Sah::Schema modules" if $@;
 sah_schema_modules_ok({opt => ...}, $msg);

=head1 DESCRIPTION

This module performs various checks on Sah::Schema::* modules. It is recommended
that you include something like C<release-sah-schema.t> in your distribution if
you add metadata to your code. If you use L<Dist::Zilla> to build your
distribution, there is L<Dist::Zilla::Plugin::Sah::Schemas> to make it easy to
do so.

=for Pod::Coverage ^(all_modules)$

=head1 ACKNOWLEDGEMENTS

Some code taken from L<Test::Pod::Coverage> by Andy Lester.

=head1 FUNCTIONS

All these functions are exported by default.

=head2 sah_schema_module_ok($module [, \%opts ] [, $msg])

Load C<$module>, get its C<$schema>, and perform test on it.

Available options:

=over

=item * test_schema_examples => BOOL (default: 1)

Whether to test examples in schema.

=back

=head2 sah_schema_modules_ok([ \%opts ] [, $msg])

Look for modules in directory C<lib> (or C<blib> instead, if it exists), and
C<run sah_schema_module_ok()> on each of them.

Options are the same as in C<sah_schema_module_ok()>, plus:

=over

=item * include_modules

=item * exclude_modules

=back

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Test-Sah-Schema>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Test-Sah-Schema>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Test-Sah-Schema>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<test-sah-schema>, a command-line interface for C<sah_schema_modules_ok()>.

L<Test::Sah> to use Sah schema to test data.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
