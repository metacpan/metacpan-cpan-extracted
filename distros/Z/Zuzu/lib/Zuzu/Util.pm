package Zuzu::Util;

use feature qw(state);
use strict;
use utf8;
use warnings;

our $VERSION = '0.001002';

use Unicode::Normalize qw(NFC);
use Zuzu::Value::Equality qw(equality_type);

sub nfc { NFC($_[0] // '') }

sub is_word_ident {
	my ($s) = @_;

	$s = nfc($s);

	return 0 if $s eq '';
	# Unicode "word" chars, but must not start with digit.

	return ($s =~ /\A(?!\p{Nd})[\p{XID_Start}_][\p{XID_Continue}_]*\z/u) ? 1 : 0;
}

sub is_keyword {
	my ($s) = @_;

	state $kw = { map { $_ => 1 } qw(
		let const function method static class trait extends with but
		if else unless while for in return next last switch case default continue
		true false null
		and or xor nand not
		eq ne gt ge lt le cmp eqi nei gti gei lti lei cmpi
		mod abs sqrt floor ceil round int length uc lc typeof instanceof does can
		union intersection subsetof supersetof equivalentof
		from import as
		try catch throw die do warn say print debug assert
		new self super fn
		async await spawn
	) };

	return $kw->{$s} ? 1 : 0;
}

sub boolify {
	my ($v) = @_;

	return 0 if !defined $v;

	return 0 if ref($v) && $v->can('is_truthy') && !$v->is_truthy;

	if ( !ref($v) ) {
		return 0 if equality_type($v) eq 'Number' && 0 + $v == 0;
		return 0 if equality_type($v) eq 'String' && $v eq '';
	}

	return 1;
}

=pod

=head1 NAME

Zuzu::Util - utility functions shared by parser and runtime

=head1 DESCRIPTION

Provides shared predicates and helpers for keyword checks, Unicode normalization, and truthiness/coercion.

=head1 METHODS

=head2 nfc

Executes C<nfc> for this module.

=head2 is_word_ident

Executes C<is_word_ident> for this module.

=head2 is_keyword

Executes C<is_keyword> for this module.

=head2 boolify

Executes C<boolify> for this module.

=head1 COPYRIGHT AND LICENCE

B<< Zuzu::Util >> is copyright Toby Inkster.

It is free software; you may redistribute it and/or modify it under
the terms of either the Artistic License 1.0 or the GNU General Public
License version 2.

=cut

1;
