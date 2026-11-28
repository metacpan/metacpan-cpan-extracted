use strict;
use Test::More;

# MySQLJSON warns about Index: the store would write indexed fields into
# columns that don't exist in a JSON table
SKIP: {
    my $class = 'Web::Session::MySQLJSON';
    skip "$class can't be loaded", 5 unless ( eval "require $class" );
    foreach my $index ( undef, '', '  ' ) {
        my $self = bless { args => {} }, $class;
        $self->{args}->{Index} = $index if defined $index;
        my $ok = eval { $self->populate; 1 };
        ok( $ok, 'MySQLJSON accepts a missing or empty Index' ) or diag $@;
    }
    foreach my $index ( 'uid', [ 'uid', 'mail' ] ) {
        my $self = bless { args => {} }, $class;
        $self->{args}->{Index} = $index;
        my @warn;
        local $SIG{__WARN__} = sub { push @warn, @_ };
        eval { $self->populate };
        like( join( '', @warn ), qr/Index should not be set/,
            'MySQLJSON warns about Index' );
    }
}

done_testing();
