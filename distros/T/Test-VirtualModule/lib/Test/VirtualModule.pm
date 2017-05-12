=head1 NAME

Test::VirtualModule

=head1 DESCRIPTION

This package allows you to generate perl modules on flight for unit-testing. This package is usable
when you have complex environment with some tricky perl modules inside of it, which can't be installed without full environment.
And you unable to write unit tests.

This module allows you to cheat and tell to perl that these modules already loaded.

=head1 SYNOPSIS

    # load virtual module
    use Test::VirtualModule qw/BlahBlahBlah::FooBar/;
    # import mocked module, it's ok
    use BlahBlahBlah::FooBar;
    # Mock constructor
    Test::VirtualModule->mock_sub('BlahBlahBlah::FooBar',
        new => sub {
            my $self = {};
            bless $self, 'BlahBlahBlah::FooBar';
            return $self;
        }
    );
    # create object
    my $object = BlahBlahBlah::FooBar->new();

That's all.

=over

=cut

package Test::VirtualModule;
use strict;
use warnings;
use Carp;

our $VERSION = 0.01;

sub import {
    my ($caller, @module_list) = @_;

    my %hash = map{s/\s+//gs;($_=>1)}@module_list;
    return unless %hash;
    unshift @INC, sub {
        my ($self, $package) = @_;
        $package =~ s|/|::|gs;
        $package =~ s|\.pm||s;
        return unless $hash{$package};
        my $text = qq|package $package;1;|;
        open my $fh, '<', \$text;
        return $fh;
    };
}


=item B<mock_sub>

Alows you to mock subroutines of specified module.

    Test::VirtualModule->mock_sub(
        'SomeModule',
        get_property    =>  sub {
            return 1;
        },
    );
    SomeModule->get_property(1);

=cut

sub mock_sub {
    my ($caller, $module, %subs) = @_;

    no warnings qw/redefine/;
    no strict qw/refs/;

    for my $name (keys %subs) {
        if (!$subs{$name} || ref $subs{$name} ne 'CODE') {
            croak "Wrong args";
        }

        *{$module . "::$name"} = $subs{$name};
    }

    return 1;
}

=back

=cut

1;
