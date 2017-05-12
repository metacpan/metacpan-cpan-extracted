package Test::Skip::UnlessExistsExecutable;
use strict;
use warnings;
our $VERSION = '0.041';
use base 'Test::Builder::Module';
use 5.008000;
use File::Spec;
use File::Which qw(which);

use constant WIN32 => $^O eq 'MSWin32';
my $quote = WIN32 ? q/"/ : q/'/;

sub import {
    my $class  = shift;
    my $caller = caller(0);

    # export methods
    {
        no strict 'refs';
        *{"$caller\::skip_all_unless_exists"} = \&skip_all_unless_exists;

    }

    for my $executable (@_) {
        skip_all_unless_exists($executable);
    }
}

sub skip_all_unless_exists {
    my $executable = shift;
    my $found      = can_execute($executable);

    unless ($found) {
        my $skip_all = sub {
            my $builder = __PACKAGE__->builder;

            if ( not defined $builder->has_plan ) {
                $builder->skip_all(@_);
            }
            elsif ( $builder->has_plan eq 'no_plan' ) {
                $builder->skip(@_);
                if ( $builder->can('parent') && $builder->parent ) {
                    die bless {} => 'Test::Builder::Exception';
                }
                exit 0;
            }
            else {
                for ( 1 .. $builder->has_plan ) {
                    $builder->skip(@_);
                }
                if ( $builder->can('parent') && $builder->parent ) {
                    die bless {} => 'Test::Builder::Exception';
                }
                exit 0;
            }
        };

        $skip_all->("The test requires '$executable' in PATH");
    }
}

sub can_execute {
    my $path = shift;

    if ( is_file_path($path) ) {
        return can_execute_path($path);

    }
    else {
        return which($path);
    }
}

sub can_execute_path {
    my $path = shift;
    if ( -x $path ) {
        if ( $path =~ /\s/ && $path !~ /^$quote/ ) {
            $path = "$quote$path$quote";
        }
        return $path;
    }
    else {
        return;
    }
}

sub is_file_path {
    my $path = shift;

    # hmm
    my $dsep = "\/";
    return 1 if $path =~ /$dsep/;
}

1;

__END__

=encoding utf-8

=head1 NAME

Test::Skip::UnlessExistsExecutable - skips tests unless executable exists

=head1 SYNOPSIS

    use Test::More tests => 1;
    use Test::Skip::UnlessExistsExecutable qw(
        /usr/bin/rsync
        perl
    );
    use_ok 'Mouse';

    # or

    use Test::More tests => 1;
    use Test::Skip::UnlessExistsExecutable; 

    skip_all_unless_exists '/bin/sh';
    skip_all_unless_exists 'perl';
    ok 1;

=head1 DESCRIPTION

Test::Skip::UnlessExistsExecutable checks if an executable exist and skips the test if it
does not. The intent is to avoid needing to write this sort of boilerplate code:

    Test::More;
    BEGIN {
        do_i_have_all_my_optional_deps() ? plan skip_all : plan tests => 42
    }

=head1 INTERFACE

Both Test::Skip::UnlessExistsExecutable import method and test_exists_executable
method take the name of a program or the file path of executable.
It checks if the program exists and is executable.

=head1 SOURCE AVAILABILITY

This source is in Github:

  http://github.com/dann/p5-test-skip-unlessexistsexecutable

=head1 AUTHOR

dann E<lt>techmemo@gmail.comE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
