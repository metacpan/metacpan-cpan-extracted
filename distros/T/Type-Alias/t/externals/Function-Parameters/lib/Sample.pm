package Sample;
use strict;
use warnings;

use Exporter 'import';
our @EXPORT_OK = qw(User);

use Type::Alias -alias => [qw(ID User)];
use Types::Standard -types;

type User => {
    name => Str,
};

1;
