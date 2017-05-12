package Thorium::Roles::Conf;
{
  $Thorium::Roles::Conf::VERSION = '0.510';
}
BEGIN {
  $Thorium::Roles::Conf::AUTHORITY = 'cpan:AFLOTT';
}

# ABSTRACT: Adds configuration to your class

use Thorium::Protection;

use Moose::Role;

# local
use Thorium::Conf;

# Attributes
has 'conf' => (
    'is'         => 'ro',
    'isa'        => 'Thorium::Conf',
    'lazy_build' => 1
);

# Builders
sub _build_conf {
    return Thorium::Conf->new;
}

no Moose::Role;

1;



=pod

=head1 NAME

Thorium::Roles::Conf - Adds configuration to your class

=head1 VERSION

version 0.510

=head1 SYNOPSIS

    with 'Thorium::Roles::Conf';

    ...

    print $self->conf->data('some.stuff');

=head1 DESCRIPTION

Adds one attribute, 'conf', to the consuming class which will instantiate a
Thorium::Conf object.

=head1 AUTHOR

Adam Flott <adam@npjh.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Adam Flott <adam@npjh.com>, CIDC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

