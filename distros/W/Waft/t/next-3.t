
use Test;
BEGIN { plan tests => 1 };

use strict;
BEGIN { eval { require warnings } ? 'warnings'->import : ( $^W = 1 ) }

require Waft;

{
    package Waft::Test::A;

    use vars qw( @ISA );

    @ISA = qw( Waft::Test::B Waft );

    sub html_escape {
        eval {
            $_[1] . $_[0]->next('A');
        };
    }
}

{
    package Waft::Test::B;

    sub html_escape {
        eval {
            eval {
                $_[1] . $_[0]->next('B');
            };
        };
    }
}

ok( Waft::Test::A->html_escape('') eq 'AB' );
