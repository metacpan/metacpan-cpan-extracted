use Test2::Roo;
use File::pushd qw/tempd/;
use Cwd qw/getcwd/;

has tempdir => (
    is => 'lazy',
    isa => sub { shift->isa('File::pushd') },
    clearer => 1,
);

# tempd changes directory until the object is destroyed
# and the fixture caches the object until cleared
sub _build_tempdir { return tempd() }

# building attribute will change to temp directory
before each_test => sub { shift->tempdir };

# clearing attribute will change to original directory
after each_test => sub { shift->clear_tempdir };

# do stuff in a temp directory
test 'first test' => sub {
    my $self = shift;
    is( $self->tempdir, getcwd(), "cwd is " . $self->tempdir );
    # ... more tests ...
};

# do stuff in a separate, fresh temp directory
test 'second test' => sub {
    my $self = shift;
    is( $self->tempdir, getcwd(), "cwd is " . $self->tempdir );
    # ... more tests ...
};

run_me;
done_testing;
