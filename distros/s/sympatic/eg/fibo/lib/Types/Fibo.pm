
package Types::Fibo;
use Type::Library -base;
use Type::Utils -all;
BEGIN { extends 'Types::Standard' }

declare Seed
    => as ArrayRef
    => where { @$_ == 2 };

