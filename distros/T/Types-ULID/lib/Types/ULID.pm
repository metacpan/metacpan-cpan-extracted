package Types::ULID;
$Types::ULID::VERSION = '0.001';
use v5.10;
use strict;
use warnings;

use Type::Library -base;
use Types::Standard qw(Undef);
use Types::Common::String qw(StrLength);
use Data::ULID;

my $tr_alphabet = '0-9a-hjkmnp-tv-zA-HJKMNP-TV-Z';
my $ULID = Type::Tiny->new(
	name => 'ULID',
	parent => StrLength[26, 26],
	constraint => qq{ tr/$tr_alphabet// == 26 },
	inlined => sub {
		my $varname = pop;
		return (undef, qq{ ($varname =~ tr/$tr_alphabet//) == 26 });
	},

	coercion => [
		Undef, q{ Data::ULID::ulid() },
	],
);

my $BinaryULID = Type::Tiny->new(
	name => 'BinaryULID',
	parent => StrLength[16, 16],

	coercion => [
		Undef, q{ Data::ULID::binary_ulid() },
	],
);

__PACKAGE__->add_type($ULID);
__PACKAGE__->add_type($BinaryULID);

__PACKAGE__->make_immutable;

__END__

=head1 NAME

Types::ULID - ULID type constraints

=head1 SYNOPSIS

	use Types::ULID qw(ULID BinaryULID);

	# coercion from undef will generate new ulid
	has 'id' => (
		is => 'ro',
		isa => ULID,
		coerce => 1,
		default => sub { undef },
	);

=head1 DESCRIPTION

Types::ULID is L<Type::Tiny> type for L<Data::ULID>. See
L<https://github.com/ulid/spec> for ulid specification.

=head2 Types

=head3 ULID

Type for text (base32-encoded) ulid. Can be coerced from C<undef> - generates a new ulid.

=head3 BinaryULID

Type for binary ulid. Can be coerced from C<undef> - generates a new ulid.

TODO: this does not currently check whether string contains multibyte characters.

=head1 SEE ALSO

L<Data::ULID>

L<Type::Tiny>

=head1 AUTHOR

Bartosz Jarzyna E<lt>bbrtj.pro@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2022 by Bartosz Jarzyna

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

