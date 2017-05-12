package Thorium::BuildConf::Knob::UnixBinary;
{
  $Thorium::BuildConf::Knob::UnixBinary::VERSION = '0.510';
}
BEGIN {
  $Thorium::BuildConf::Knob::UnixBinary::AUTHORITY = 'cpan:AFLOTT';
}

# ABSTRACT: Unix binary

use Thorium::Protection;

use Moose;

# core
use File::Spec;

# local
use Thorium::Types qw(UnixExecutableFile);

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
    'isa' => UnixExecutableFile,
    'is'  => 'rw',
);

has 'data' => (
    'isa'     => 'Str',
    'is'      => 'ro',
    'default' => '/tmp/a.out'
);

with qw(Thorium::BuildConf::Roles::Knob Thorium::BuildConf::Roles::UI::FileSelect);

__PACKAGE__->meta->make_immutable;
no Moose;

1;

__END__
=pod

=head1 NAME

Thorium::BuildConf::Knob::UnixBinary - Unix binary

=head1 VERSION

version 0.510

=head1 AUTHOR

Adam Flott <adam@npjh.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Adam Flott <adam@npjh.com>, CIDC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

