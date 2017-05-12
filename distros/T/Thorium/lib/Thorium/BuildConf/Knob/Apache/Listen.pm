package Thorium::BuildConf::Knob::Apache::Listen;
{
  $Thorium::BuildConf::Knob::Apache::Listen::VERSION = '0.510';
}
BEGIN {
  $Thorium::BuildConf::Knob::Apache::Listen::AUTHORITY = 'cpan:AFLOTT';
}

# ABSTRACT: Apache's Listen directive

use Thorium::Protection;

use Moose;

# CPAN
use Sys::HostAddr;

# local
use Thorium::Types qw(ApacheListen);

has 'conf_key_name' => (
    'isa'     => 'Str',
    'is'      => 'ro',
    'default' => 'apache.listen'
);

has 'name' => (
    'isa'     => 'Str',
    'is'      => 'ro',
    'default' => 'Apache listen'
);

has 'question' => (
    'isa'     => 'Str',
    'is'      => 'ro',
    'default' => 'What is the IP and port to listen on (use the Apache2 Listen syntax)?'
);

has 'value' => (
    'isa' => ApacheListen,
    'is'  => 'rw',
);

has 'data' => (
    'isa'     => 'Str',
    'is'      => 'ro',
    'default' => sub { Sys::HostAddr->new->main_ip . ':8080' }
);

with qw(Thorium::BuildConf::Roles::Knob Thorium::BuildConf::Roles::UI::InputBox);

__PACKAGE__->meta->make_immutable;
no Moose;

1;

__END__
=pod

=head1 NAME

Thorium::BuildConf::Knob::Apache::Listen - Apache's Listen directive

=head1 VERSION

version 0.510

=head1 AUTHOR

Adam Flott <adam@npjh.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Adam Flott <adam@npjh.com>, CIDC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

