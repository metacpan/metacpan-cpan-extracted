package YAML::Tests;
use 5.005003;
use strict;
$YAML::Tests::VERSION = '0.06';

sub yt_process {
    my $class = shift;
    my @ARGS = @_;
    my $base_env_name = 'PERL_YAML_TESTS_BASE';
    my $base = $ENV{$base_env_name} || '.';

    die YAML::Tests->env_error_msg($base, $base_env_name)
      unless
        -d "$base/yaml-tests" and
        -d "$base/t" and
        -f "$base/lib/YAML/Tests.pm" and
        -f "$base/Makefile.PL";

    chdir($base) or die "Can't chdir to '$base'";

    my ($commands, $modules, $options, $tests) = ([], [], [], []);
    for (@ARGS) {
        push @{(
            /^--/ ? $commands :
            /^-M/ ? $modules :
            /^-/ ? $options : $tests
        )}, $_;
    }

    my $command;
    if (@$commands) {
        $command = $commands->[0];
        if ($command =~ /^--(list|benchmark|version)$/) {
            my $method = "handle_$1";
            $class->$method($options, $tests);
            return;
        }
        die "Unknown command: '$command'";
    }
    
    my $module;
    if (@$modules and $modules->[0] =~ /^-M([\w\:]+)$/) {
        $module = $1;
    }
    $module ||= $ENV{PERL_YAML_TESTS_MODULE};
    die YAML::Tests->usage_msg($base, $base_env_name)
      unless $module;
    eval "require $module; 1"
      or die $@;
    die "Error: $module does not support the YAML Dump/Load API\n"
      unless 
        $module->can('Load') and
        $module->can('Dump');
    $ENV{PERL_YAML_TESTS_MODULE} = $module;

    my $file_list = join ' ',
        (@$tests) ? do {
            map {
                s/.*yaml-tests[\/\\]//;
                "yaml-tests/$_";
            } @$tests;
        } : "yaml-tests";
    
    my $option_list = join ' ',
        (@$options) ? (@$options, '') : ();
    
    my $command = "prove $option_list$file_list";
    system($command) == 0
      or die("Command failed:\n    $command\n");
}

sub handle_list {
    opendir DIR, "yaml-tests"
      or die "Can't open yaml-tests directory";
    while (my $file = readdir(DIR)) {
        next unless $file =~ /\.t$/;
        print "$file\n";
    }
    closedir DIR;
}

sub handle_benchmark {
    my $class = shift;
    require YAML::Tests::Benchmark;
    YAML::Tests::Benchmark->run(@_);
}

sub handle_version {
    my @modules;
    for my $module (qw(YAML YAML::LibYAML YAML::Syck YAML::Tiny)) {
        eval "require $module; 1" or next;
        no strict 'refs';
        push @modules, {
            name => $module,
            version => ${$module . "::VERSION"},
        };
    }
    print <<"...";
This is the "yt" program, version $main::VERSION.

It uses the Perl module YAML::Tests, version $YAML::Tests::VERSION.

The following known YAML Perl modules are installed on your system:

...

    for my $module (@modules) {
        print "  - $module->{name}, version $module->{version}\n";
    }

    print "\n";
}

sub env_error_msg {
    my ($class, $base, $base_env_name) = @_;
    return <<"...";
'$base' is not a YAML-Tests directory.

You need to get YAML-Tests from CPAN or its SVN repository. If you get a 
tarball you need to untar it into a directory.

Next you should cd to that directory or set the $base_env_name
environment variable to point to the directory.

The SVN location is: http://svn.kwiki.org/ingy/YAML-Tests/

...
}

sub usage_msg {
    return <<"...";
Usage:
    yt [prove-options] [-MYAML::Module] [list-of-tests]
    yt --list
    yt --benchmark
    yt --version

Examples:
    yt
    yt -MYAML::LibYAML
    yt -v -MYAML::Tiny dump.t load.t
    PERL_YAML_TESTS_MODULE=YAML::Syck yt

See Also:
    perldoc yt

...
}

1;

=head1 NAME

YAML::Tests - Common Test Suite for Perl YAML Implementations

=head1 SYNOPSIS

    > yt -MYAML::Foo   # Run all YAML Tests against YAML::Foo implementation

or:

    > export PERL_YAML_TESTS_MODULE=YAML::Foo
    > yt

=head1 DESCRIPTION

YAML-Tests defines a number of implementation independent tests that can
be used to test various YAML modules.

There are two ways to use YAML-Tests. If you are the author of a Perl
YAML module, you can add the line:

    use_yaml_tests;

to your C<Makefile.PL>. This will copy the tests from YAML::Tests into
your module's test area.

If you are Just Another Perl Hacker, YAML-Tests installs a command line tool
called C<yt> to run the YAML tests against a specific module. Like this:

    > yt -MYAML::Syck

YAML::Tests provides a common test suite against which to test Perl YAML
modules. It also provides a Module::Install component
(C<use_yaml_tests>) to make it simple for YAML module authors to include
the tests in their distributions. See L<Module::Install::YAML::Tests>
for more information about this feature.

This module installs a command line tool called C<yt> which can be used
to run the YAML tests against various implementations. See L<yt> for more
information.

=head1 TYPES OF TESTS

YAML::Tests provides tests that should pass on any YAML implementation
that provides a C<Dump> and C<Load> function interface. These are likely
not the only tests that an implementation should have. They are intended
to be a common subset.

This section describes the types of tests that are provided.

=head2 NYN Roundtripping

"NYN Roundtripping" is a YAML term that means Native->YAML->Native. In
our case "Native" means "Perl". These tests take various Perl objects,
Dump them to YAML and then Load them back into Perl. The original and
the clone Perl objects are compared for equivalence.

This is a very common type of test.

=head2 YNY Roundtripping

"YNY" means YAML->Native->YAML. Load a YAML stream to Perl and Dump it
back to YAML. Test if the YAML streams match.

There are fewer of these tests because there are usually variations in
how a Dumper implementation will actually Dump a given object. Still we
can cover the simple basics.

=head2 Y2N Testing

Load a given YAML stream and see if it produces the expected Perl
objects.

This is different from NYN because we are testing YAML streams that are
not produced by a YAML Dumper. This is where we can test the edge cases
that might be produced by a human editing YAML.

=head2 YAML Loader Errors

Invalid YAML should cause a Loader to throw an error. These tests Load
various invalid YAML streams and make sure that an error is thrown.

=head2 API Testing

Some tests make sure that all the C<Dump> and C<Load> functions follow
the same API.

=head1 YAML IMPLEMENTATIONS

Currently there are 4 YAML Implementations on CPAN:

=head2 YAML.pm

This is the original YAML module written in 2001 by Ingy döt Net. It is
pure Perl.

=head2 YAML::Syck

This wrapper of Why The Lucky Stiff's libsyck, was written by Audrey
Tang in 2005. YAML::Syck is almost entirely written in C, so it is
fast. The libsyck library was written in 2003 and targeted at the
YAML 1.0 spec.

=head2 YAML::Tiny

YAML::Tiny is a pure Perl module written by Adam Kennedy in 2006. It is
an attempt to write a YAML implementation that is as small as possible.
It does this by choosing to only deal with a subset of the YAML
language. It attempts to support the subset of YAML that is used by
popular Perl projects like CPAN and SVK.

=head2 YAML::LibYAML

This wrapper of Kirill Siminov's libyaml (2005) is a pure C module
written by Ingy döt Net in 2007. The libyaml library was targeted at
the current YAML 1.1 spec. It was written to match the spec exactly. At
this point it has no known bugs. It is meant to eventually become the
new YAML.pm codebase.

=head1 AUTHOR

Ingy döt Net <ingy@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2007. Ingy döt Net. All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut
