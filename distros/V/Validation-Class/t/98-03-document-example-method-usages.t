use utf8;
use strict;
use warnings;
use Test::More;

{

    package T;

    use Validation::Class;

    field name => {
        min_length => 2,
        max_length => 100
    };

    document user => {
        'name.first' => 'name',
        'name.last'  => 'name'
    };

    method set_user => {
        input_document => 'user',
        using          => sub { $_[1] }
    };

    package main;

    my $data = { name => { first => undef } };

    my $class = eval { T->new };

    ok "T" eq ref $class, "T instantiated";

    ok $class->set_user($data),
      "T document (user) is valid; nothing required";

    my $user = $class->proto->documents->get('user');

    $user->{'name.first'} = '+name';

    ok !$class->set_user($data) && $class->errors_to_string =~ /name\.first/,
      "T document (user) is NOT valid; name.first required";

    $user->{'name.first'}   = 'name';

    $data->{name}->{first}  = 'friendly';
    $data->{name}->{middle} = 'guy';

    is_deeply
        { name => { first => 'friendly', middle => 'guy', last => undef } },
        $class->set_user($data),
        'T document (user) is valid; return value expected'
    ;

    is_deeply
        { name => { first => 'friendly', last => undef } },
        $class->set_user($data, { prune => 1 }),
        'T document (user) is valid; pruned return value expected'
    ;

}

done_testing;
