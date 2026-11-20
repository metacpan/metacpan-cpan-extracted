package Web::VWF::Data::vwf_log;

# Open /tmp/vwf.log as a database
# Standard CSV file, with no header line

use strict;
use warnings;

use version; our $VERSION = version->declare('0.003.1');

use Database::Abstraction;
use DBD::CSV;

our @ISA = ('Database::Abstraction');

# Doesn't ignore lines starting with '#' as it's not treated like a CSV file
sub _open {
	my $self = shift;
	my %args = (ref($_[0]) eq 'HASH') ? %{$_[0]} : @_;

	return $self->SUPER::_open(sep_char => ',', column_names => ['domain_name', 'time', 'IP', 'country', 'type', 'language', 'http_code', 'template', 'args', 'warnings', 'error', 'duration_ms'], %args);
}

1;

=encoding utf8

=head1 NAME

Web::VWF::Data::vwf_log - The access log, as a database

=head1 VERSION

Version 0.003.1

=head1 DESCRIPTION

A L<Database::Abstraction> over the CSV file that the framework appends a line
to for every request (the C<vwflog> setting).  The file has no header line, so
the columns are fixed: C<domain_name>, C<time>, C<IP>, C<country>, C<type>,
C<language>, C<http_code>, C<template>, C<args>, C<warnings>, C<error> and
C<duration_ms>.  Lines starting with C<#> are not skipped.

The framework builds this handle itself and gives it to every page as
C<vwf_log>, which is what L<Web::VWF::Display::meta_data> reads.  It is not one
of the C<databases> a site declares.

=head1 AUTHOR

Nigel Horne, C<< <njh at nigelhorne.com> >>

=head1 LICENCE AND COPYRIGHT

Copyright 2010-2026 Nigel Horne.

Usage is subject to the GPL2 licence terms.
If you use it,
please let me know.

=cut
