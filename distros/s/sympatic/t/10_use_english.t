use Test::More;
use Sympatic;
# use warnings qw< FATAL all >;

eval { $_ = defined $ARG };
ok !$@, 'no error using $ARG so Enlish module is imported';

# ok eval { defined $ARG } => '$ARG is defined';
# ok eval { defined $ARG } => '$ARG is defined';

done_testing;


