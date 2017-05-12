package MyVal::Ticket;

use Validation::Class;

field description => {
    mixin => 'TMP',
    label => 'Ticket description'
};

field priority => {
    mixin => 'TMP',
    label => 'Ticket priority',
    options => [qw/Low Normal High Other/]
};

1;