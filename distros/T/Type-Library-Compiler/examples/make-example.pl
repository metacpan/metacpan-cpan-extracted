#!perl

use strict;
use warnings;

use Type::Library::Compiler;

use Types::Standard -types;
use Types::Common::String -types;
use Types::Path::Tiny -types;

my $compiler = 'Type::Library::Compiler'->new(
	types => {
		Null           => Undef,
		Any            => Any,
		String         => Str,
		NonEmptyString => NonEmptyStr,
		Number         => Num,
		Integer        => Int,
		Object         => Object,
		Array          => ArrayRef,
		Hash           => HashRef,
		Path           => Path,
		File           => File,
		Directory      => Dir,
	},
	destination_module => 'TLC::Example',
);

print $compiler->compile_to_string;
