package SetTear;
use Test2::Roo::Role;
use File::Temp;

has tempdir => ( is => 'rw', );

has tempname => ( is => 'rw', );

before setup => sub {
    my $self = shift;
    $self->tempdir( File::Temp->newdir );
    $self->tempname( '' . $self->tempdir );
};

after teardown => sub {
    my $self = shift;
    $self->tempdir(undef);
};

1;
