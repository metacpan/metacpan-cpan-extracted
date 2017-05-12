use strict;
use warnings;

package Tiny::OpenSSL::Config;

# ABSTRACT: Load default Tiny::OpenSSL configuration
our $VERSION = '0.1.3'; # VERSION

use YAML::Tiny;
use File::ShareDir qw(dist_file);

local $YAML::UseCode  = 0 if !defined $YAML::UseCode;
local $YAML::LoadCode = 0 if !defined $YAML::LoadCode;

use base qw(Exporter);

our @EXPORT = qw( $CONFIG );

my $yaml = YAML::Tiny->read(dist_file 'Tiny-OpenSSL', 'config.yml');

our $CONFIG = $yaml->[0];

$CONFIG->{openssl} = 'openssl';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Tiny::OpenSSL::Config - Load default Tiny::OpenSSL configuration

=head1 VERSION

version 0.1.3

=head1 AUTHOR

James F Wilkus <jfwilkus@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by James F Wilkus.

This is free software, licensed under:

  The (three-clause) BSD License

=cut
