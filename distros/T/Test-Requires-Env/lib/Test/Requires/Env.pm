package Test::Requires::Env;

use strict;
use warnings;
use parent qw(Test::Builder::Module);

our $VERSION = '0.02';

sub import {
    my $class = shift;
    my $caller = caller(0);

    # export methods
    {
        no strict 'refs';
        *{"$caller\::test_environments"} = \&test_environments;
    }

    if ( @_ > 0 ) {
        test_environments(@_);
    }
}

sub test_environments {
    my @entries = @_;

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

    for my $entry ( @entries ) {
        if ( ref $entry eq 'HASH' ) {
            for my $env_name ( keys %$entry ) {
                unless ( exists $ENV{$env_name} ) {
                    $skip_all->( sprintf('%s environment is not existed', $env_name) );
                }

                if ( ref $entry->{$env_name} eq 'Regexp' ) {
                    my $regex = $entry->{$env_name};
                    $ENV{$env_name} =~ m#$regex#
                        or $skip_all->( sprintf('%s environment is not match by the pattern (pattern: %s)', $env_name, "$regex") );
                }
                else {
                    ( $ENV{$env_name} eq $entry->{$env_name} )
                        or $skip_all->( sprintf("%s environment is not equals %s", $env_name, $entry->{$env_name}) );
                }
            }
        }
        else {
            unless ( exists $ENV{$entry} ) {
                $skip_all->( sprintf('%s environment is not existed', $entry) );
            }
        }
    }
}

1;
__END__

=head1 NAME

Test::Requires::Env - Testing environments and skipping by result of the testing

=head1 SYNOPSIS

  use Test::More;
  use Test::Requires::Env;

  $ENV{SHELL} = '/bin/zsh';

  test_environments(
    'HOME',
    'PATH',
    +{
      'SHELL'   => '/bin/bash',
      'INCLUDE' => qr{/usr/local/include},
      'LIB'     => qr{/usr/local/lib},
    },
  );

  fail 'Do not reach here';

=head1 DESCRIPTION

Test::Requires::Env is testing environments and skipping by result of the testing.
This module exports 'test_environments()' sub routine.

The sub routine accepts two type arguments. One of them is array of environment names, it is used to check existing such a environment.
Other one is hash reference of environment conditions, it is used to check environment value by equals or regexp.

And this module provides short cut of test_environments() sub routine by import method looks like synopsis.

=head1 FUNCTIONS

=head2 test_environments( @entries )

@entries items should be scalar or hash reference. The scalar is treated as environment name,
and check which the specified environment is existing or not in environments.

The hash reference is consisted of environment name is key, environment value condition is value.
The environment value condition accepts scalar and regexp.

The condition scalar is used by which the scalar equals actual environment value or not.
The condition regexp is used by matching to actual environment value.

=head1 AUTHOR

Toru Yamaguchi E<lt>zigorou@cpan.orgE<gt>

=head1 SEE ALSO

=over

=item L<Test::Requires>

This module is expired L<Test::Requires>.

=item L<Test::Skip::UnlessExistsExecutable>

=back

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
