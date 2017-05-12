package Thorium::Roles::Logging;
{
  $Thorium::Roles::Logging::VERSION = '0.510';
}
BEGIN {
  $Thorium::Roles::Logging::AUTHORITY = 'cpan:AFLOTT';
}

# ABSTRACT: Adds standard logging to your class

use Thorium::Protection;

use MooseX::Role::Strict;

# core
use Scalar::Util qw(blessed);

# local
use Thorium::Log;

# Attributes
has 'log' => (
    'is'         => 'ro',
    'isa'        => 'Thorium::Log',
    'lazy_build' => 1,
);

# Builders
sub _build_log {
    my $self = shift;

    # If we'd like to add configuring logging through Thorium::Roles::Conf,
    # then this is where we'd do it
    my $log = Thorium::Log->new(
        'set_category' => blessed $self,
        'caller_depth' => 3
    );

    return $log;
}

no Moose::Role;

1;



=pod

=head1 NAME

Thorium::Roles::Logging - Adds standard logging to your class

=head1 VERSION

version 0.510

=head1 SYNOPSIS

    with 'Thorium::Roles::Logging';

    ...

    $self->log->warn('look out! impending destruction awaits ahead!');

=head1 DESCRIPTION

Adds one attribute, 'log' to the consuming class, which will instantiate to a
Thorium::Log object at first use. Category is automatically set to the class
name instantiated under.

=head1 AUTHOR

Adam Flott <adam@npjh.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Adam Flott <adam@npjh.com>, CIDC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

