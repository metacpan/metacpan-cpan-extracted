package Thorium::BuildConf::Roles::Knob;
{
  $Thorium::BuildConf::Roles::Knob::VERSION = '0.510';
}
BEGIN {
  $Thorium::BuildConf::Roles::Knob::AUTHORITY = 'cpan:AFLOTT';
}

# ABSTRACT: knob role

use Thorium::Protection;

use Moose::Role;

requires 'conf_key_name', 'name', 'question', 'value', 'data';

has 'explanation' => (
    'isa'           => 'Str',
    'is'            => 'rw',
    'required'      => 0,
    'documentation' => 'XXX'
);

no Moose::Role;

1;

__END__
=pod

=head1 NAME

Thorium::BuildConf::Roles::Knob - knob role

=head1 VERSION

version 0.510

=head1 AUTHOR

Adam Flott <adam@npjh.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Adam Flott <adam@npjh.com>, CIDC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

