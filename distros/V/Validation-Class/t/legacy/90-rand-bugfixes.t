BEGIN {

    use FindBin;
    use lib $FindBin::Bin . "/myapp/lib";

}

use utf8;
use Test::More;

{

    package TestClass::GithubIssue16;
    use Validation::Class;

    fld name => {required => 1};

    package main;

    my $class = "TestClass::GithubIssue16";
    my $self = $class->new(ignore_unknown => 1, report_unknown => 1);

    ok $class eq ref $self, "$class instantiated";

    ok !$self->validate('+name'), 'name exists and is invalid';
    ok !$self->validate('+abcd'), 'abcd does not exist and is invalid';

    $self->ignore_unknown(0);
    $self->report_unknown(0);

    eval { $self->validate('+abcd') };

    ok $@, 'abcd does not exist and terminates';

}

done_testing;
