use strict;
use warnings;

use constant STANDARD_PARAMETERS => (
    [ [1 .. 10]                                => [1 .. 9] ],
    [ [[1 .. 10]]                              => [1 .. 9] ],
    [ [[1 .. 9], [1 .. 9]]                     => [grep !/0/, (11 .. 99)] ], 
    [ [[1,2], [1,2], [1,2], [1,2]]             => [grep !/[03-9]/, (1111 .. 9999)] ]
);

sub _dump_params {
    local $_ = Dumper($_[0]);
    s/\s+//gs;   # remove all indents, but I didn't want to set 
                 # $Data::Dumper::Indent as it could have global effects
    s/^.*? = //; # remove the variable name of the dumped output
    $_[1] or s/'//g;      # numbers could be quoted, but they shouldn't
    return $_;
}

1;
