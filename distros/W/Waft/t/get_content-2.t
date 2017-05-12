
use Test;
BEGIN { plan tests => 1 };

use strict;
BEGIN { eval { require warnings } ? 'warnings'->import : ( $^W = 1 ) }

require Waft;

{
    package Waft::Test::D;

    sub html_escape {
        my ($self, $value) = @_;

        $self->output('d');

        return $self->next( $value . 'D' );
    }
}

{
    package Waft::Test::C;

    sub html_escape {
        my ($self, $value) = @_;

        $self->output('c');

        return $self->next( $value . 'C' );
    }
}

{
    package Waft::Test::B::Base;

    sub html_escape {
        my ($self, $value) = @_;

        return $self->next( $value . 'B' );
    }
}

{
    package Waft::Test::B;

    use base qw( Waft::Test::B::Base );

    sub html_escape {
        my ($self, $value) = @_;

        my ($content, $return_value) = $self->get_content( sub {

            return $self->SUPER::html_escape($value);
        } );

        return $return_value . $content;
    }
}

{
    package Waft::Test::A;

    use base qw( Waft::Test::B Waft::Test::C Waft::Test::D Waft );

    sub html_escape {
        my ($self, $value) = @_;

        return $self->next( $value . 'A' );
    }
}

ok( Waft::Test::A->new->html_escape(q{}) eq 'ABCDcd' );
