package Thorium::BuildConf::Knob::UnixDirectory;
{
  $Thorium::BuildConf::Knob::UnixDirectory::VERSION = '0.510';
}
BEGIN {
  $Thorium::BuildConf::Knob::UnixDirectory::AUTHORITY = 'cpan:AFLOTT';
}

# ABSTRACT: Unix directory

use Thorium::Protection;

use Moose;

# local
use Thorium::Types qw(UnixDirectory);

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
    'isa' => UnixDirectory,
    'is'  => 'rw'
);

has 'data' => (
    'isa'     => UnixDirectory,
    'is'      => 'ro',
    'default' => '/tmp'
);

with qw(Thorium::BuildConf::Roles::Knob Thorium::BuildConf::Roles::UI::DirectorySelect);

__PACKAGE__->meta->make_immutable;
no Moose;

1;

__END__
=pod

=head1 NAME

Thorium::BuildConf::Knob::UnixDirectory - Unix directory

=head1 VERSION

version 0.510

=head1 AUTHOR

Adam Flott <adam@npjh.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Adam Flott <adam@npjh.com>, CIDC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

