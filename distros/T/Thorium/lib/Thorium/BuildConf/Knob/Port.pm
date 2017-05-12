package Thorium::BuildConf::Knob::Port;
{
  $Thorium::BuildConf::Knob::Port::VERSION = '0.510';
}
BEGIN {
  $Thorium::BuildConf::Knob::Port::AUTHORITY = 'cpan:AFLOTT';
}

# ABSTRACT: Network IP port

use Thorium::Protection;

use Moose;

# core
use Cwd;

# local
use Thorium::Types qw(Port);

has 'conf_key_name' => (
    'isa'     => 'Str',
    'is'      => 'ro',
    'default' => 'port'
);

has 'name' => (
    'isa'     => 'Str',
    'is'      => 'ro',
    'default' => 'Listening Port'
);

has 'question' => (
    'isa'     => 'Str',
    'is'      => 'ro',
    'default' => 'What port will this server listen on?'
);

has 'value' => (
    'isa' => Port,
    'is'  => 'rw',
);

has 'data' => (
    'isa'     => Port,
    'is'      => 'ro',
    'default' => sub { 8080 }
);

with qw(Thorium::BuildConf::Roles::Knob Thorium::BuildConf::Roles::UI::InputBox);

__PACKAGE__->meta->make_immutable;
no Moose;

1;

__END__
=pod

=head1 NAME

Thorium::BuildConf::Knob::Port - Network IP port

=head1 VERSION

version 0.510

=head1 AUTHOR

Adam Flott <adam@npjh.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Adam Flott <adam@npjh.com>, CIDC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

