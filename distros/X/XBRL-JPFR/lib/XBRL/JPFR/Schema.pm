package XBRL::JPFR::Schema;

our $VERSION = '0.01';

use strict;
use warnings;
use Carp;

use base qw(XBRL::Schema);

my @fields = qw(elements);
XBRL::JPFR::Schema->mk_accessors(@fields);

sub new() {
	my ($class, $args) = @_;
	my $self = $class->SUPER::new($args);
	bless $self, $class;

	return $self;
}

=head1 XBRL::JPFR::Schema

XBRL::JPFR::Schema - OO Module for Encapsulating XBRL::JPFR Schemas

=head1 SYNOPSIS

  use XBRL::JPFR::Schema;

	my $schema = XBRL::JPFR::Schema->new();

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
