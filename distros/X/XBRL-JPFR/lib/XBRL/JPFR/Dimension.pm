package XBRL::JPFR::Dimension;

use strict;
use warnings;
use Carp;
use Data::Dumper;

use base qw(XBRL::Dimension);

our $VERSION = '0.01';

sub new() {
	my ($class, $xbrl_doc, $uri) = @_;
	my $self = $class->SUPER::new($xbrl_doc, $uri);
	bless $self, $class;

	return $self;
}

=head1 XBRL::JPFR::Dimension

XBRL::JPFR::Dimension - OO Module for Encapsulating XBRL::JPFR Dimensions

=head1 SYNOPSIS

  use XBRL::JPFR::Dimension;

	my $dim = XBRL::JPFR::Dimension->new();

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
