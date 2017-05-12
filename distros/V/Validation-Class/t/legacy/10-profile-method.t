BEGIN {

    use FindBin;
    use lib $FindBin::Bin . "/myapp/lib";

}

use utf8;
use Test::More;
use Data::Dumper;

{

    package MyApp;

    use Validation::Class;

    fld name => {
        required => 1
    };

    pro is_name_ok => sub {
        return shift->validate('name')
    };

    package main;

    my $class = "MyApp";
    my $self = $class->new(name => 'Rob Blahblah');

    ok $class eq ref $self, "$class instantiated";
    ok $self->validate_profile('is_name_ok'), 'is_name_ok profile returned true';

    $self->name(undef);

    #die Data::Dumper::Dumper($self->params);

    ok !$self->validate_profile('is_name_ok'), 'is_name_ok profile returned false';

}

done_testing;
