package Module::Install::TestBase;
use strict;

use Module::Install::Base;

use vars qw($VERSION @ISA);
BEGIN {
    $VERSION = '0.10';
    @ISA     = 'Module::Install::Base';
}

sub use_yaml_tests {
    my $self = shift; 
    my $base_env_name = 'PERL_YAML_TESTS_BASE';
    my $base = $ENV{$base_env_name}
      or die "$base_env_name environment variable is not set";
    die "'$base' is an invalid value for $base_env_name"
      unless
        -d "$base/yaml-tests" and
        -d "$base/t";
    my $config_file = 't/yaml_tests.yaml';
    die "You must define the file $config_file to 'use_yaml_tests'"
      unless -f $config_file;
    eval "use YAML::Tiny 1.08; 1" or die $@;

    my ($config) = YAML::Tiny::LoadFile($config_file);

    die "'yaml_module' not defined in $config_file"
      unless defined $config->{yaml_module};
    $config->{use_blib} ||= 0;
    $config->{exclude} ||= [];

    print "TODO - Copy YAML::Tests test files to here\n";

    for (
        "$base/t/TestYAMLTests.pm",
        "$base/t/data",
        glob("$base/yaml-tests/*"),
    ) {
        $self->_copy_file($_, $config);
    }
}

sub _copy_file {
    my ($self, $source, $config) = @_;
    my $file = $source;
    $file =~ s/.*[\/\\]//;
    if (grep {$_ eq $file} @{$config->{exclude}}) {
        print ">> Excluding t/$file\n";
        return;
    }
    if (-d $source && -e "t/$file") {
        my $command = "rm -fr t/$file";
        print ">> $command\n";
        system($command) == 0 or die "Failed";
    }
    if (-e "t/$file" and -M $source >= -M "t/$file") {
        print ">> Skipping t/$file\n";
        return;
    }
    my $command = "cp -r $source t/$file";
    print ">> $command\n";
    system($command) == 0 or die "Failed";
}

1;

=head1 NAME

Module::Install::TestBase - Module::Install Support for YAML::Tests

=head1 SYNOPSIS

    # Example Makefile.PL
    use inc::Module::Install;

    name            'YAML::Foo';
    all_from        'lib/YAML/Foo.pm';

    use_yaml_tests;

    WriteAll;

=head1 DESCRIPTION

By adding the single line:

    use_yaml_tests;

to your C<Module::Install> based C<Makefile.PL>, when you then run
the command:

    perl Makefile.PL

the YAML::Tests test files will be copied into your module's C<t/>
directory.

=head1 CONFIGURATION

If you are using C<YAML::Tests> in your own YAML module, create a
file called C<t/yaml_tests.yaml>. Here is an example:

    # YAML::Tests Config File
    
    # The name of your module
    yaml_module: YAML::Syck
    
    # Set this to '1' if your module uses XS
    use_blib: 1
    
    # List of test components to *not* copy to your module area
    exclude:
      - alias.t
      - null.t

=head1 AUTHOR

Ingy döt Net <ingy@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2007. Ingy döt Net. All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>

=cut
