use 5.008001;

package RequiresFixture;
use Test2::Roo::Role;

requires 'fixture';

test try_me => sub {
    my $self    = shift;
    my $fixture = $self->fixture;
    ok( ($fixture) x 2 );
};

1;
