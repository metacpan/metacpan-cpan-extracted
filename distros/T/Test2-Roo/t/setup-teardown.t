use Test2::Roo;

use lib 't/lib';

with 'SetTear';

after setup => sub { # intentionally *after* to check role
    my $self = shift;
    ok( $self->tempdir,  "got tempdir" );
    ok( $self->tempname, "got tempname" );
};

after teardown => sub {
    my $self = shift;
    is( $self->tempdir, undef, "tempdir cleared" );
    ok( !-e $self->tempname, "tempdir doesn't exist" );
};

test 'stub test' => sub { ok(1) };

run_me;
done_testing;
