use v5.10;
use strict;
use warnings;

use Test::More;
use Types::ULID qw(is_ULID to_ULID is_BinaryULID to_BinaryULID);
use Data::ULID qw(ulid binary_ulid);

subtest 'testing ULID' => sub {
	ok is_ULID('00000000010000000000000001'), 'small ulid ok';
	ok is_ULID('01B3Z3A7GQ6627FZPDQHQP87PM'), 'old ulid ok';
	ok is_ULID('01b3z3a7gq6627fzpdqhqp87pm'), 'lowercase ulid ok';
	ok is_ULID(ulid), 'current random ulid ok';

	ok !is_ULID('01B3Z3A7GQ6627FZPDQHQP87PMA'), 'incorrect ulid 1 ok';
	ok !is_ULID('01B3Z3A7GQ6627FZPDQHQP87P'), 'incorrect ulid 2 ok';
	ok !is_ULID('01B3Z3A7GQ6627FZPDQHQP87PI'), 'incorrect ulid 3 ok';
	ok !is_ULID('01B3Z3A7GQ6627FZPDQHQP87PO'), 'incorrect ulid 4 ok';
	ok !is_ULID('01B3Z3A7GQ6627FZPDQHQP87PL'), 'incorrect ulid 5 ok';
	ok !is_ULID('01B3Z3A7GQ6627FZPDQHQP87PU'), 'incorrect ulid 6 ok';
	ok !is_ULID('01B3Z3A7GQ6627FZPDQHQP87PUA'), 'incorrect ulid 7 ok';
	ok !is_ULID({}), 'incorrect ulid 8 ok';

	ok is_ULID(to_ULID(undef)), 'coercion ok';
	is to_ULID('aaa'), 'aaa', 'invalid coercion ok';
};

subtest 'testing BinaryULID' => sub {
	ok is_BinaryULID("\x01" x 16), 'small ulid ok';
	ok is_BinaryULID("\xff" x 16), 'big ulid ok';
	ok is_BinaryULID(binary_ulid), 'current random ulid ok';

	ok !is_BinaryULID("\x31" x 17), 'incorrect ulid 1 ok';
	ok !is_BinaryULID("\xff" x 15), 'incorrect ulid 2 ok';
	ok !is_BinaryULID({}), 'incorrect ulid 3 ok';

	ok is_BinaryULID(to_BinaryULID(undef)), 'coercion ok';
	is to_BinaryULID('aaa'), 'aaa', 'invalid coercion ok';
};

done_testing;

