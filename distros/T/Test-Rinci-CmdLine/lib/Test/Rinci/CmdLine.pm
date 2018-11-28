## no critic: ValuesAndExpressions::ProhibitCommaSeparatedStatements BuiltinFunctions::RequireBlockMap

package Test::Rinci::CmdLine;

our $DATE = '2018-11-22'; # DATE
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict;
use warnings;
use Log::ger;

use Perinci::Access::Perl;
use Test::Builder ();

my $Test = Test::Builder->new;
# XXX is cache_size=0 really necessary?
my $Pa = Perinci::Access::Perl->new(load=>0, cache_size=>0);

sub import {
    my $self = shift;
    my $caller = caller;
    no strict 'refs';
    *{$caller.'::metadata_in_script_ok'}      = \&metadata_in_script_ok;
    *{$caller.'::metadata_in_scripts_ok'}     = \&metadata_in_scripts_ok;
    *{$caller.'::metadata_in_all_scripts_ok'} = \&metadata_in_all_scripts_ok;

    $Test->exported_to($caller);
    $Test->plan(@_);
}

sub metadata_in_script_ok {
    require Perinci::CmdLine::Dump;
    require Test::Rinci;

    my $script = shift;
    my %opts   = (@_ && (ref $_[0] eq "HASH")) ? %{(shift)} : ();
    my $msg    = @_ ? shift : "Rinci metadata in script $script";
    my $ok = 1;

    my $libs = delete($opts{libs}) // [];
    my $res = Perinci::CmdLine::Dump::dump_pericmd_script(
        filename => $script, libs=>$libs);

    if ($res->[0] == 412) {
        $Test->ok(1);
        $Test->diag("Script $script is not a Perinci::CmdLine script");
    } elsif ($res->[0] == 200) {
        local %main::SPEC = %{ $res->[2]{'x.main.spec'} // {} };
        Test::Rinci::metadata_in_module_ok('main', {load=>0}, $msg);
    } else {
        $ok = 0;
        $Test->ok(0);
        $Test->diag("Cannot dump script $script: $res->[0] - $res->[1]");
    }

    $ok;
}

sub metadata_in_scripts_ok {
    my $opts = (@_ && (ref $_[0] eq "HASH")) ? shift : {};
    my $scripts = shift;
    my $msg  = shift;
    my $ok = 1;

    $Test->plan(tests => 1);
    if (@$scripts) {
        $Test->subtest(
            $msg || "Rinci metadata in scripts",
            sub {
                for my $script (@$scripts) {
                    #log_info "Processing script %s ...", $script;
                    my $thisok = metadata_in_script_ok($script, $opts)
                        or $ok = 0;
                }
            }
        ) or $ok = 0;
    } else {
        $Test->ok(1, "No scripts.");
    }
    $ok;
}

# BEGIN modified from Test::Pod::Coverage's all_modules

sub all_scripts {
    my @starters = @_ ? @_ : _starting_points();
    my %starters = map {$_,1} @starters;

    my @queue = @starters;

    my @scripts;
    while ( @queue ) {
        my $file = shift @queue;
        if ( -d $file ) {
            local *DH;
            opendir DH, $file or next;
            my @newfiles = readdir DH;
            closedir DH;

            @newfiles = File::Spec->no_upwards( @newfiles );
            @newfiles = grep { $_ ne "CVS" && $_ ne ".svn" && $_ ne ".git"}
                @newfiles;

            push @queue, map "$file/$_", @newfiles;
        }
        if ( -f $file ) {
            next if $file =~ /(~|\.bak)\z/; # common backup extensions
            push( @scripts, $file );
        }
    } # while

    return @scripts;
}

sub _starting_points {
    return grep { -d $_ } ('script', 'scripts', 'bin');
}

# END modified from Test::Pod::Coverage's all_modules

sub metadata_in_all_scripts_ok {
    my $opts = (@_ && (ref $_[0] eq "HASH")) ? shift : {};
    my $msg  = shift || "Rinci metadata in all scripts of dist";

    my @starters = _starting_points();
    local @INC = (@starters, @INC);
    my @scripts = all_scripts(@starters);

    metadata_in_scripts_ok($opts, \@scripts, $msg);
}

1;
# ABSTRACT: Test Rinci metadata of Perinci::CmdLine scripts

__END__

=pod

=encoding UTF-8

=head1 NAME

Test::Rinci::CmdLine - Test Rinci metadata of Perinci::CmdLine scripts

=head1 VERSION

This document describes version 0.001 of Test::Rinci::CmdLine (from Perl distribution Test-Rinci-CmdLine), released on 2018-11-22.

=head1 SYNOPSIS

To check all metadata in a script:

 use Test::Rinci::CmdLine tests => 1;
 metadata_in_script_ok("script.pl", {opt => ...}, $msg);

Alternatively, you can check all metadata in all scripts in a distro:

 # save in release-rinci-cmdline.t, put in distro's t/ subdirectory
 use Test::More;
 plan skip_all => "Not release testing" unless $ENV{RELEASE_TESTING};
 eval "use Test::Rinci::CmdLine";
 plan skip_all => "Test::Rinci::CmdLine required for testing Rinci metadata" if $@;
 metadata_in_all_scripts_ok({opt => ...}, $msg);

=head1 DESCRIPTION

This module is like L<Test::Rinci> except that it looks for metadata in the
C<main> package of scripts, instead of modules.

=for Pod::Coverage ^(all_scripts)$

=head1 ACKNOWLEDGEMENTS

Some code taken from L<Test::Pod::Coverage> by Andy Lester.

=head1 FUNCTIONS

All these functions are exported by default.

=head2 metadata_in_script_ok($module [, \%opts ] [, $msg])

Load C<$script>, get its metadata in the C<main> package, and perform test on
the metadata on the C<main> package using L<Test::Rinci>'s
C<metadata_in_module_ok()>. See Test::Rinci for available options.

=head2 metadata_in_scripts_ok([ \%opts, ] \@scripts [, $msg])

Run C<metadata_in_script_ok()> for each script specified in C<@scripts>.

Options are the same as in C<metadata_in_script_ok()>.

=head2 metadata_in_all_scripts_ok([ \%opts ] [, $msg])

Look for scripts in directory C<script> (and C<scripts> and C<bin>) and run
C<metadata_in_script_ok()> on each of them.

Options are the same as in C<metadata_in_script_ok()>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Test-Rinci-CmdLine>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Test-Rinci-CmdLine>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Test-Rinci-CmdLine>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<test-rinci-cmdline>, a command-line interface for C<metadata_in_all_scripts_ok()>.

L<Test::Rinci> and L<test-rinci>.

L<Rinci>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
