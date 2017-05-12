package Test::Pod::Coverage::Permissive;

use warnings;
use strict;
use 5.008009;
use Test::More 0.88;
use File::Spec;
use Pod::Coverage;
use YAML::Syck qw(LoadFile DumpFile);

my $Test = Test::Builder->new;

sub import {
    my $self = shift;
    my $caller = caller;
    no strict 'refs';
    *{$caller.'::pod_coverage_ok'}       = \&pod_coverage_ok;
    *{$caller.'::all_pod_coverage_ok'}   = \&all_pod_coverage_ok;
    *{$caller.'::all_modules'}           = \&all_modules;

    $Test->exported_to($caller);
    $Test->plan(@_);
}

=head1 NAME

Test::Pod::Coverage::Permissive - Checks for pod coverage regression.

=head1 VERSION

Version 0.05

=cut

our $VERSION = '0.05';

=head1 SYNOPSIS

Checks for POD coverage regressions in your code. This module is for large projects, which can't be covered by POD for a
5 minutes. If you have small module or your project is fully covered - use L<Test::Pod::Coverage> instead.

After first run, this module creates data file, where saves all uncovered subroutines. If you create new uncovered
subroutine, it will fail. If you create new package with uncovered subroutines, it will fail. Otherwise it will show
diagnostic messages like these:

    t/03podcoverage.t .. 2/? # YourProject::Controller::Root: naked 4 subroutine(s)
    # YourProject::Controller::NotRoot: naked 8 subroutine(s)
    # YorProject::Controller::AlsoNotRoot: naked 3 subroutine(s)
    ...

This module will help you to cover your project step-by-step. And your new code will be covered by POD.

Interface is like L<Test::Pod::Coverage>:

    use Test::Pod::Coverage::Permissive;

    use Test::More;
    eval "use Test::Pod::Coverage::Permissive";
    plan skip_all => "Test::Pod::Coverage::Permissive required for testing POD coverage" if $@;
    all_pod_coverage_ok();

=head1 FUNCTIONS

=head2 all_pod_coverage_ok( [$parms] )

Checks that the POD code in all modules in the distro have proper POD
coverage.

If the I<$parms> hashref if passed in, they're passed into the
C<Pod::Coverage> object that the function uses.  Check the
L<Pod::Coverage> manual for what those can be.

The exception is the C<coverage_class> parameter, which specifies a class to
use for coverage testing.  It defaults to C<Pod::Coverage>.

=cut

sub all_pod_coverage_ok {
    my $parms = ( @_ && ( ref $_[0] eq "HASH" ) ) ? shift : {};
    my $msg = shift;

    my $ok         = 1;
    my @modules    = all_modules();
    if (@modules) {
        for my $module (@modules) {
            pod_coverage_ok($module, $parms, $msg);
        }
    }
    else {
        ok( 1, "No modules found." );
    }

    return $ok;
}

=head2 pod_coverage_ok( $module, [$parms,] $msg )

Checks that the POD code in I<$module> has proper POD coverage.

If the I<$parms> hashref if passed in, they're passed into the
C<Pod::Coverage> object that the function uses.  Check the
L<Pod::Coverage> manual for what those can be.

The exception is the C<coverage_class> parameter, which specifies a class to
use for coverage testing.  It defaults to C<Pod::Coverage>.

=cut

sub pod_coverage_ok {
    my $module = shift;
    my %parms = (@_ && (ref $_[0] eq "HASH")) ? %{(shift)} : ();
    my $msg = @_ ? shift : "Pod coverage on $module";
    my $first_time = !-e 't/pod_correct.yaml';
    my $correct = eval { LoadFile('t/pod_correct.yaml') } || {};
    my $coverage = Pod::Coverage->new( package => $module, %parms );
    my $v = $coverage->naked || 0;
    my $ok = 1;
    if ( defined $coverage->coverage ) {
        $correct->{$module} = $v if $first_time;
        if ( $ok = $Test->ok($v <= ($correct->{$module}||0), $msg) ) {
            $correct->{$module} = $v;
        }
        if ( my $count = $coverage->naked ) {
            $Test->diag("${module}: naked $count subroutine(s)");
        }
    }
    else { # No symbols
        my $why = $coverage->why_unrated;
        my $nopublics = ( $why =~ "no public symbols defined" );
        my $verbose = $ENV{HARNESS_VERBOSE} || 0;
        $correct->{$module} = undef if $first_time;
        $ok = $nopublics || exists $coverage->{$module};
        $Test->ok( $ok, $msg );
        $Test->diag( "$module: $why" ) unless ( $nopublics && !$verbose );
    }

    DumpFile( 't/pod_correct.yaml', $correct );
}

=head2 all_modules( [@dirs] )

Returns a list of all modules in I<$dir> and in directories below. If
no directories are passed, it defaults to F<blib> if F<blib> exists,
or F<lib> if not.

Note that the modules are as "Foo::Bar", not "Foo/Bar.pm".

The order of the files returned is machine-dependent.  If you want them
sorted, you'll have to sort them yourself.

=cut

sub all_modules {
    my @starters = @_ ? @_ : _starting_points();
    my %starters = map { $_, 1 } @starters;

    my @queue = @starters;

    my @modules;
    while (@queue) {
        my $file = shift @queue;
        if ( -d $file ) {
            local *DH;
            opendir DH, $file or next;
            my @newfiles = readdir DH;
            closedir DH;

            @newfiles = File::Spec->no_upwards(@newfiles);
            @newfiles = grep { $_ ne "CVS" && $_ ne ".svn" } @newfiles;

            push @queue, map "$file/$_", @newfiles;
        }
        if ( -f $file ) {
            next unless $file =~ /\.pm$/;

            my @parts = File::Spec->splitdir($file);
            shift @parts if @parts && exists $starters{ $parts[0] };
            shift @parts if @parts && $parts[0] eq "lib";
            $parts[-1] =~ s/\.pm$// if @parts;

            # Untaint the parts
            for (@parts) {
                if ( /^([a-zA-Z0-9_\.\-]+)$/ && ( $_ eq $1 ) ) {
                    $_ = $1;    # Untaint the original
                }
                else {
                    die qq{Invalid and untaintable filename "$file"!};
                }
            }
            my $module = join( "::", @parts );
            push( @modules, $module );
        }
    }    # while

    return @modules;
}

sub _starting_points {
    return 'blib' if -e 'blib';
    return 'lib';
}

=head1 AUTHOR

Andrey Kostenko, C<< <andrey at kostenko.name> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-test-pod-coverage-permissive at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Test-Pod-Coverage-Permissive>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Test::Pod::Coverage::Permissive


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Test-Pod-Coverage-Permissive>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Test-Pod-Coverage-Permissive>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Test-Pod-Coverage-Permissive>

=item * Search CPAN

L<http://search.cpan.org/dist/Test-Pod-Coverage-Permissive/>

=back


=head1 ACKNOWLEDGEMENTS

Thanks to author of L<Test::Pod::Coverage>. 90% of this module is a copy-paste from L<Test::Pod::Coverage>.

=head1 LICENSE AND COPYRIGHT

Copyright 2010 Andrey Kostenko, based on Andy Lester's L<Test::Pod::Coverage>

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1;    # End of Test::Pod::Coverage::Permissive
