package XBRL::JPFR::Arc;

our $VERSION = '0.01';

use strict;
use warnings;
use Carp;
use Hash::Merge qw(merge);
use Data::Dumper;

use base qw(XBRL::Arc);

my @fields = qw(role weight use priority from_name to_name from_prefix to_prefix text lang id);
XBRL::JPFR::Arc->mk_accessors(@fields);

my %default = (
);

sub new() {
	my ($class, $args) = @_;
	$args = {} if !$args;
	my $self = merge($args, \%default);
	bless $self, $class;

	return $self;
}


=head1 XBRL::JPFR::Arc

XBRL::JPFR::Arc - OO Module for Encapsulating XBRL::JPFR Arcs

=head1 SYNOPSIS

  use XBRL::JPFR::Arc;

	my $arc = XBRL::JPFR::Arc->new();

=head1 DESCRIPTION

This module is part of the XBRL::JPFR modules group and is intended for use with XBRL::JPFR.

=head1 AUTHOR

Tetsuya Yamamoto <yonjouhan@gmail.com>

=head1 SEE ALSO

Modules: XBRL XBRL::JPFR

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2015 by Tetsuya Yamamoto

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10 or,
at your option, any later version of Perl 5 you may have available.


=cut


1;
