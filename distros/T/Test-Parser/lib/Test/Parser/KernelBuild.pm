package Test::Parser::KernelBuild;

=head1 NAME

Test::Parser::KernelBuild - Perl module to parse output from Linux kernel builds.

=head1 SYNOPSIS

    use Test::Parser::KernelBuild;

    my $parser = new Test::Parser::KernelBuild;
    $parser->parse($text);
    printf("Num Errors:    %8d\n", $parser->num_errors());
    printf("Num Warnings:  %8d\n", $parser->num_warnings());

Additional information is available from the subroutines listed below
and from the L<Test::Parser> baseclass.

=head1 DESCRIPTION

This module provides a way to extract information out of kernel builds,
suitable for use in kernel test harnesses, similar to if you did `cat
build.log | grep 'errors:' | wc -l`, except that this module also checks
if the system is in the 'make config' or 'make bzImage' stages and skips
any false positives that might be encountered there.

=head1 FUNCTIONS

Also see L<Test::Parser> for functions available from the base class.

=cut

use strict;
use warnings;
use Test::Parser;

@Test::Parser::KernelBuild::ISA = qw(Test::Parser);
use base 'Test::Parser';

use fields qw(
              _state

              states
              make_targets
              config_file
              );

use vars qw( %FIELDS $AUTOLOAD $VERSION );
our $VERSION = '1.7';

=head2 new()

Creates a new Test::Parser::KernelBuild instance.
Also calls the Test::Parser base class' new() routine.
Takes no arguments.

=cut

sub new {
    my $class = shift;
    my Test::Parser::KernelBuild $self = fields::new($class);
    $self->SUPER::new();

    return $self;
}

=head3 make_targets()

Returns a list of the different targets that were built by make.

=cut
sub make_targets {
    my $self = shift;
    return $self->{make_targets};
}

=head3 config_file()

Returns the name of the kernel .config file used, if any

=cut
sub config_file {
    my $self = shift;
    return $self->{config_file};
}

=head3 states()

Returns a list of the various steps in the build process (e.g. config,
make, modules_install, etc.)

=cut
sub states {
    my $self = shift;
    return $self->{states};
}

=head3

Override of Test::Parser's default parse_line() routine to make it able
to parse kernel build logs.

=cut
sub parse_line {
    my $self = shift;
    my $line = shift;

    # Determine if we're changing states...
    if ($line =~ /^make .*?config/) {
        $self->{_state} = 'config';
        push @{$self->{states}}, $self->{_state};
    }

    elsif ($line =~ /^make bzImage/) {
        $self->{_state} = 'image';
        push @{$self->{states}}, $self->{_state};
    }

    elsif ($line =~ /^make /) {
        $self->{_state} = 'build';
        push @{$self->{states}}, $self->{_state};
    }

    # Get the config file name, if one is used
    if ($line =~ /^Using default config file '(.+)'$/ && ! defined($self->{config_file})) {
        $self->{config_file} = $1;
    }

    # Conduct the output parsing
    elsif ($self->{_state} eq 'build') {
        # Gets CC, LD, CHK, etc.
        if ($line =~ /^\s\s([A-Z]+) /) {  
            $self->{make_targets}->{$1}++;
        }
        
        elsif ($line =~ /error\:/) {
            push @{$self->{errors}}, $_;
        } 
        
        elsif ($line =~ /warning\:/) {
            push @{$self->{warnings}}, $_;
        }
    }

    return 1;
}

1;
__END__

=head2 config_file()

Returns the config file name, if one is indicated in the build log output.
The parser expects this appears in a line of the form:
"^Using default config file '(.+)'$"

=head2 num_states()

The number of states the parser noticed

=head2 states()

Returns a reference to an array of the different build states (make
config, make, make modules_install, etc.) found in the build.

=head2 num_make_targets()

The number of make targets seen during the build stage.

=head2 make_targets()

Returns a hash reference

              warnings
              errors
              states
              make_targets

=head1 AUTHOR

Bryce Harrington <bryce@osdl.org>

=head1 COPYRIGHT

Copyright (C) 2005 Bryce Harrington.
All Rights Reserved.

This script is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 SEE ALSO

L<Test::Parser>

=end

