package Thorium::BuildConf::Knob::Apache::DocumentRoot;
{
  $Thorium::BuildConf::Knob::Apache::DocumentRoot::VERSION = '0.510';
}
BEGIN {
  $Thorium::BuildConf::Knob::Apache::DocumentRoot::AUTHORITY = 'cpan:AFLOTT';
}

# ABSTRACT: Apache's DocumentRoot directive

use Thorium::Protection;

use Moose;

# core
use FindBin qw();

# local
use Thorium::Types qw(UnixDirectory);

has 'conf_key_name' => (
    'isa'     => 'Str',
    'is'      => 'ro',
    'default' => 'apache.document_root'
);

has 'name' => (
    'isa'     => 'Str',
    'is'      => 'ro',
    'default' => 'Apache document root'
);

has 'question' => (
    'isa'     => 'Str',
    'is'      => 'ro',
    'default' => 'What is the Apache document root directory?'
);

has 'value' => (
    'isa' => UnixDirectory,
    'is'  => 'rw',
);

has 'data' => (
    'isa'     => UnixDirectory,
    'is'      => 'ro',
    'default' => sub { File::Spec->catdir($FindBin::Bin, '/htdocs') }
);

with qw(Thorium::BuildConf::Roles::Knob Thorium::BuildConf::Roles::UI::DirectorySelect);

__PACKAGE__->meta->make_immutable;
no Moose;

1;

__END__
=pod

=head1 NAME

Thorium::BuildConf::Knob::Apache::DocumentRoot - Apache's DocumentRoot directive

=head1 VERSION

version 0.510

=head1 AUTHOR

Adam Flott <adam@npjh.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Adam Flott <adam@npjh.com>, CIDC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

