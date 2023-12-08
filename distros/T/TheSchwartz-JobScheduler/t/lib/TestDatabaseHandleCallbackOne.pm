package TestDatabaseHandleCallbackOne;
use strict;
use warnings;

use Moo;
use Carp;
has dbs => (
    is      => 'ro',
    default => sub {
        return {
            'db_1_id'  => ( bless {}, 'DBI::db' ),
            'db_2_id'  => ( bless {}, 'DBI::db' ),
            'db_undef' => undef,
        };
    },
);

sub dbh {
    my ( $self, $db_id ) = @_;
    croak 'Just die' if ( $db_id eq 'sub_die' );
    return $self->dbs->{$db_id};
}
1;
