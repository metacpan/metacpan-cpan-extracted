## no critic: ValuesAndExpressions::ProhibitCommaSeparatedStatements BuiltinFunctions::RequireBlockMap

package Test::Module::Features;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-02-26'; # DATE
our $DIST = 'Test-Module-Features'; # DIST
our $VERSION = '0.002'; # VERSION

use 5.010001;
use strict 'subs', 'vars';
use warnings;

use File::Spec;
use Module::FeaturesUtil::Get;
use Module::FeaturesUtil::Check;
use Test::Builder;
use Test::More ();

my $Test = Test::Builder->new;

sub import {
    my $self = shift;
    my $caller = caller;
    no strict 'refs';
    *{$caller.'::module_features_in_module_ok'}      = \&module_features_in_module_ok;
    *{$caller.'::module_features_in_all_modules_ok'} = \&module_features_in_all_modules_ok;

    $Test->exported_to($caller);
    $Test->plan(@_);
}

sub module_features_in_module_ok {
    my $module = shift;
    my %opts = (@_ && (ref $_[0] eq "HASH")) ? %{(shift)} : ();
    my $msg  = @_ ? shift : "Module features in module $module";
    my $res;
    my $ok = 1;

    #$opts{test_examples}  //= 1;

    $Test->subtest(
        $msg,
        sub {
            my $res;
            if ($module =~ /^Module::Features::(.+)/) {
                my $fsetname = $1;
                my $feature_set_spec = Module::FeaturesUtil::Get::get_feature_set_spec($fsetname, 'load', 'fatal');
                if ($feature_set_spec->{features}) {
                    $res = Module::FeaturesUtil::Check::check_feature_set_spec($feature_set_spec);
                } else {
                    $Test->ok(1);
                    $Test->diag("Module $module does not define feature set specfication in \%FEATURES_DEF or the spec is empty");
                    goto SKIP;
                }
            } else {
                my $features_decl = Module::FeaturesUtil::Get::get_features_decl($module, 'load', 'fatal');
                if ($features_decl->{features}) {
                    $res = Module::FeaturesUtil::Check::check_features_decl($features_decl);
                } else {
                    $Test->ok(1);
                    $Test->diag("Module $module does not declare features in \%FEATURES or the declaration is empty");
                    goto SKIP;
                }
            }

            if ($res->[0] == 200) {
                $Test->ok(1);
                $Test->diag("Check succeeded for $module");
            } else {
                $Test->diag("Check failed for $module: $res->[0] - $res->[1]");
                $ok = 0;
            }
          SKIP:
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

sub module_features_in_all_modules_ok {
    my $opts = (@_ && (ref $_[0] eq "HASH")) ? shift : {};
    my $msg  = shift;
    my $ok = 1;

    my @starters = _starting_points();
    local @INC = (@starters, @INC);

    $Test->plan(tests => 1);

    my @modules = all_modules(@starters);
    if (@modules) {
        $Test->subtest(
            "Module features in all of dist's modules",
            sub {
                for my $module (@modules) {
                    my $thismsg = defined $msg ? $msg :
                        "Module features in module $module";
                    my $thisok = module_features_in_module_ok(
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
# ABSTRACT: Test feature set specifications and features declarations

__END__

=pod

=encoding UTF-8

=head1 NAME

Test::Module::Features - Test feature set specifications and features declarations

=head1 VERSION

This document describes version 0.002 of Test::Module::Features (from Perl distribution Test-Module-Features), released on 2021-02-26.

=head1 SYNOPSIS

To check a single a module:

 use Test::Module::Features;
 module_features_in_module_ok("Foo::Bar", {opt => ...}, $msg);

Alternatively, you can check all modules in a distro:

 # save in release-module-features.t, put in distro's t/ subdirectory
 use Test::More;
 plan skip_all => "Not release testing" unless $ENV{RELEASE_TESTING};
 eval "use Test::Module::Features";
 plan skip_all => "Test::Module::Features required for testing feature set specifications and features declarations" if $@;
 module_features_in_all_modules_ok({opt => ...}, $msg);

=head1 DESCRIPTION

=for Pod::Coverage ^(all_modules)$

=head1 ACKNOWLEDGEMENTS

Some code taken from L<Test::Pod::Coverage> by Andy Lester.

=head1 FUNCTIONS

All these functions are exported by default.

=head2 module_features_in_module_ok

Usage:

 module_features_in_module_ok($module [, \%opts ] [, $msg])

Load C<$module> and perform test on module's feature set specifications and/or features declarations.

Available options:

=over

=back

=head2 module_features_in_all_modules_ok

Usage:

 module_features_in_all_modules_ok([ \%opts ] [, $msg])

Look for modules in directory C<lib> (or C<blib> instead, if it exists), and run
C<module_features_in_module_ok()> against each of them.

Options are the same as in C<module_features_in_module_ok()>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Test-Module-Features>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Test-Module-Features>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://github.com/perlancar/perl-Test-Module-Features/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<test-module-features>, a command-line interface for
C<module_features_in_all_modules_ok()>.

L<Module::Features>

L<Dist::Zilla::Plugin::Module::Features>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
