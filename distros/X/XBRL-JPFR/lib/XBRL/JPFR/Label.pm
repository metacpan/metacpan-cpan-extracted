package XBRL::JPFR::Label;

use strict;
use warnings;
use Carp;
use Encode;

our $VERSION = '0.01';

use base qw(XBRL::Label);

my @org_fields = qw(name id role lang value);
my @fields = qw(label);
XBRL::JPFR::Label->mk_accessors(@fields);

sub new() {
	my ($class, $in_xml) = @_;
	my $self = $class->SUPER::new($in_xml);
	bless $self, $class;
	return $self;
}

sub get_fields {
	my ($self) = @_;
	return (@org_fields, @fields);
}


=head1 NAME

XBRL::JPFR::Label - Perl OO Module for encapsulating XBRL::JPFR Label information

=head1 SYNOPSIS

  use XBRL::JPFR::Label;

	my $label = XBRL::JPFR::Label->new();

=head1 DESCRIPTION

This module is part of the XBRL::JPFR modules group and is intended for use with XBRL::JPFR.

=over 4

=item new

Object constructor

=back

=head1 AUTHOR

Tetsuya Yamamoto <yonjouhan@gmail.com>

=head1 SEE ALSO

Modules: XBRL XBRL::JPFR XBRL::Label

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2015 by Tetsuya Yamamoto

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10 or,
at your option, any later version of Perl 5 you may have available.


=cut


1;
