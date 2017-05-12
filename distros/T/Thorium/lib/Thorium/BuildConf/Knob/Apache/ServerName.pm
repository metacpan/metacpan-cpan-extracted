package Thorium::BuildConf::Knob::Apache::ServerName;
{
  $Thorium::BuildConf::Knob::Apache::ServerName::VERSION = '0.510';
}
BEGIN {
  $Thorium::BuildConf::Knob::Apache::ServerName::AUTHORITY = 'cpan:AFLOTT';
}

# ABSTRACT: Apache's ServerName directive

use Thorium::Protection;

use Moose;

# core
use Sys::Hostname;

# CPAN
use Sys::HostAddr;

# local
use Thorium::Types qw(Hostname);

has 'conf_key_name' => (
    'isa'     => 'Str',
    'is'      => 'ro',
    'default' => 'apache.server.name'
);

has 'name' => (
    'isa'     => 'Str',
    'is'      => 'ro',
    'default' => 'Apache server name'
);

has 'question' => (
    'isa'     => 'Str',
    'is'      => 'ro',
    'default' => 'What is the Apache server name (normally the fully qualified domain name?'
);

has 'value' => (
    'isa' => Hostname,
    'is'  => 'rw',
);

has 'data' => (
    'isa'     => Hostname,
    'is'      => 'ro',
    'default' => sub { Sys::Hostname::hostname }
);

with qw(Thorium::BuildConf::Roles::Knob Thorium::BuildConf::Roles::UI::InputBox);

__PACKAGE__->meta->make_immutable;
no Moose;

1;

__END__
=pod

=head1 NAME

Thorium::BuildConf::Knob::Apache::ServerName - Apache's ServerName directive

=head1 VERSION

version 0.510

=head1 AUTHOR

Adam Flott <adam@npjh.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Adam Flott <adam@npjh.com>, CIDC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

