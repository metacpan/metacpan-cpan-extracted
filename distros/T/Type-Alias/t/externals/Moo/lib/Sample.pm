package Sample;
use Moo;

use Exporter 'import';
our @EXPORT_OK = qw( UserName );

use Type::Alias -alias => [qw( UserName )];
use Types::Standard qw( Str );

type UserName => Str & sub { length $_ > 1 };

has 'name' => (is => 'rw', isa => UserName, default => 'John Doe');

1;
