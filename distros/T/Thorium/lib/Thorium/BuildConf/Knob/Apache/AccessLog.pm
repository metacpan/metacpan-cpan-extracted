package Thorium::BuildConf::Knob::Apache::AccessLog;
{
  $Thorium::BuildConf::Knob::Apache::AccessLog::VERSION = '0.510';
}
BEGIN {
  $Thorium::BuildConf::Knob::Apache::AccessLog::AUTHORITY = 'cpan:AFLOTT';
}

# ABSTRACT: Apache's AccessLog directive

use Thorium::Protection;

use Moose;

# core
use FindBin qw();
use File::Spec;

# local
use Thorium::Types qw(UnixFilename);

has 'conf_key_name' => (
    'isa'     => 'Str',
    'is'      => 'ro',
    'default' => 'apache.logs.access'
);

has 'name' => (
    'isa'     => 'Str',
    'is'      => 'ro',
    'default' => 'Apache access log path'
);

has 'question' => (
    'isa'     => 'Str',
    'is'      => 'ro',
    'default' => 'Where is the Apache access log filename (relative or absolute)?'
);

has 'value' => (
    'isa' => UnixFilename,
    'is'  => 'rw',
);

has 'data' => (
    'isa'     => UnixFilename,
    'is'      => 'ro',
    'default' => sub { File::Spec->catfile($FindBin::Bin, 'logs', 'access_log') }
);

with qw(Thorium::BuildConf::Roles::Knob Thorium::BuildConf::Roles::UI::FileSelect);

__PACKAGE__->meta->make_immutable;
no Moose;

1;

__END__
=pod

=head1 NAME

Thorium::BuildConf::Knob::Apache::AccessLog - Apache's AccessLog directive

=head1 VERSION

version 0.510

=head1 AUTHOR

Adam Flott <adam@npjh.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Adam Flott <adam@npjh.com>, CIDC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

