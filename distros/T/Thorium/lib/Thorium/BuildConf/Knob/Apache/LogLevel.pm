package Thorium::BuildConf::Knob::Apache::LogLevel;
{
  $Thorium::BuildConf::Knob::Apache::LogLevel::VERSION = '0.510';
}
BEGIN {
  $Thorium::BuildConf::Knob::Apache::LogLevel::AUTHORITY = 'cpan:AFLOTT';
}

# ABSTRACT: Apache's LogLevel directive

use Thorium::Protection;

use Moose;

# local
use Thorium::Types qw(ApacheLogLevel);

has 'conf_key_name' => (
    'isa'     => 'Str',
    'is'      => 'ro',
    'default' => 'apache.logs.level'
);

has 'name' => (
    'isa'     => 'Str',
    'is'      => 'ro',
    'default' => 'Apache log level'
);

has 'question' => (
    'isa'     => 'Str',
    'is'      => 'ro',
    'default' => 'Apache log level?'
);

has 'value' => (
    'isa' => ApacheLogLevel,
    'is'  => 'rw',
);

has 'selected' => (
    'isa'     => 'Int',
    'is'      => 'rw',
    'default' => 0
);

has 'data' => (
    'isa'     => 'ArrayRef[HashRef]',
    'is'      => 'ro',
    'default' => sub {
        my @levels;
        foreach my $level (@Thorium::Types::apache_log_levels) {
            push(@levels, {'name' => $level, 'text' => $level});
        }
        return \@levels;
    }
);

with qw(Thorium::BuildConf::Roles::Knob Thorium::BuildConf::Roles::UI::RadioList);

__PACKAGE__->meta->make_immutable;
no Moose;

1;

__END__
=pod

=head1 NAME

Thorium::BuildConf::Knob::Apache::LogLevel - Apache's LogLevel directive

=head1 VERSION

version 0.510

=head1 AUTHOR

Adam Flott <adam@npjh.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Adam Flott <adam@npjh.com>, CIDC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

