package XBRL::JPFR::Element;

use strict;
use warnings;
use Carp;

our $VERSION = '0.01';

use base qw(XBRL::Element);

my @fields = qw(substitutionGroup);
XBRL::JPFR::Element->mk_accessors(@fields);

my %default = ();

sub new() {
	my ($class, $xml, $args) = @_;
	my $self = $class->SUPER::new($xml);
	$$self{'abstract'} = 'false' if !defined $$self{'abstract'};
	bless $self, $class;
	foreach (@fields) {
		if (exists $$args{$_}) {
		 	$$self{$_} = $$args{$_};
		}
		elsif (exists $default{$_}) {
		 	$$self{$_} = $default{$_};
		}
	}

	return $self;
}

=head1 XBRL::JPFR::Element

XBRL::JPFR::Element - OO Module for Encapsulating XBRL::JPFR Elements

=head1 SYNOPSIS

  use XBRL::JPFR::Element;

	my $ele = XBRL::JPFR::Element->new();

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
