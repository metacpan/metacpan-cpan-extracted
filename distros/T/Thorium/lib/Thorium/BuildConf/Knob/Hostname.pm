package Thorium::BuildConf::Knob::Hostname;
{
  $Thorium::BuildConf::Knob::Hostname::VERSION = '0.510';
}
BEGIN {
  $Thorium::BuildConf::Knob::Hostname::AUTHORITY = 'cpan:AFLOTT';
}

# ABSTRACT: Network hostname

use Thorium::Protection;

use Moose;

# local
use Thorium::Types qw(Hostname);
use Thorium::SystemInfo;

has 'conf_key_name' => (
    'isa'     => 'Str',
    'is'      => 'ro',
    'default' => '...'
);

has 'name' => (
    'isa'     => 'Str',
    'is'      => 'ro',
    'default' => '...'
);

has 'question' => (
    'isa'     => 'Str',
    'is'      => 'ro',
    'default' => '...'
);

has 'value' => (
    'isa' => Hostname,
    'is'  => 'rw',
);

has 'data' => (
    'isa'     => Hostname,
    'is'      => 'ro',
    'default' => sub { Thorium::SystemInfo->new->hostname }
);

with qw(Thorium::BuildConf::Roles::Knob Thorium::BuildConf::Roles::UI::InputBox);

__PACKAGE__->meta->make_immutable;
no Moose;

1;

__END__
=pod

=head1 NAME

Thorium::BuildConf::Knob::Hostname - Network hostname

=head1 VERSION

version 0.510

=head1 AUTHOR

Adam Flott <adam@npjh.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Adam Flott <adam@npjh.com>, CIDC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

