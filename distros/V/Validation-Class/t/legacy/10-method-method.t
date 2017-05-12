BEGIN {

    use FindBin;
    use lib $FindBin::Bin . "/myapp/lib";

}

use utf8;
use Test::More;

{

    package MyApp;

    use Validation::Class;

    fld name => {
        required => 1
    };

    mth print_name => {
        input => ['name'],
        using => sub {
            my ($self) = @_;
            return "my name is " . $self->name;
        }
    };

    package main;

    my $class = "MyApp";
    my $self  = $class->new();

    ok $class eq ref $self, "$class instantiated";
    ok !$self->print_name, "no name printed because the name field is null";

    $self->name("echo");

    ok "my name is echo" eq $self->print_name, "name printed as intended";

}

{

    package MyApp2;

    use Validation::Class;

    fld name => {
        required => 1
    };

    pro has_name => sub {
        shift->validate('name')
    };

    mth print_name => {
        input => 'has_name',
        using => sub {
            my ($self) = @_;
            return "my name is " . $self->name;
        }
    };

    package main;

    my $class = "MyApp2";
    my $self  = $class->new();

    ok $class eq ref $self, "$class instantiated";
    ok !$self->print_name, "no name printed because the name field is null";

    $self->name("echo");

    ok "my name is echo" eq $self->print_name, "name printed as intended";

}

{

    package MyApp3;

    use Validation::Class;

    fld name => {
        required => 1
    };

    pro has_name => sub {
        shift->validate('name')
    };

    mth print_name => {
        input  => 'has_name',
        output => 'has_name',
        using  => sub {
            my ($self) = @_;
            return "my name is " . $self->name;
        }
    };

    mth die_name => {
        input  => 'has_name',
        output => 'has_name',
        using  => sub {
            shift->name(undef)
        }
    };

    package main;

    my $class = "MyApp3";
    my $self  = $class->new();

    ok $class eq ref $self, "$class instantiated";
    ok !$self->print_name, "no name printed because the name field is null";

    $self->name("echo");

    ok "my name is echo" eq $self->print_name, "name printed as intended";

    eval { $self->die_name };

    ok $@, "die_name method died as expected because name could not be validated on output";

}

{

    package MyApp4;

    use Validation::Class;

    fld name => {
        required => 1
    };

    mth print_name => {
        input  => ['name'],
        output => ['name'],
        using  => sub {
            my ($self) = @_;
            return "my name is " . $self->name;
        }
    };

    mth build_name => {
        input  => 'print_name',
        using  => sub {
            shift->print_name . ", the 2nd"
        }
    };

    package main;

    my $class = "MyApp4";
    my $self  = $class->new();

    ok $class eq ref $self, "$class instantiated";
    ok !$self->build_name, "no name printed because the name field is null";

    $self->name("echo");

    ok "my name is echo, the 2nd" eq $self->build_name, "name printed as intended";

}

{

    package MyApp5;

    use Validation::Class;

    fld name => {
        required => 1
    };

    mth print_name => {
        input  => ['name'],
        output => ['name']
    };

    sub _print_name {
        my ($self) = @_;
        return "my name is " . $self->name;
    }

    package main;

    my $class = "MyApp5";
    my $self  = $class->new();

    ok $class eq ref $self, "$class instantiated";
    ok !$self->print_name, "no name printed because the name field is null";

    $self->name("echo");

    ok "my name is echo" eq $self->print_name, "name printed as intended";

}

done_testing;
