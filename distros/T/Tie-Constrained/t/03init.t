use Test::More tests=>13;

use Tie::Constrained;


{
    my $subr = sub { $_[0]->isa('Bird')};
    my $foo;
    my $foo_obj = eval {
        tie $foo, 'Tie::Constrained', $subr
    };
    ok ( !$@, 'No complaints from tie');

    ok ( exists $foo_obj->{'test'},  'Test elemet exists');
    ok ( defined $foo_obj->{'test'}, 'Test element defined');
    is ( $foo_obj->{'test'}, $subr,  'Test element correct');

    ok ( exists $foo_obj->{'fail'},  'Fail elemet exists');
    ok ( defined $foo_obj->{'fail'}, 'Fail element defined');
    is ( $foo_obj->{'fail'}, \&Tie::Constrained::failure,
          'Fail element correct');

    ok ( exists $foo_obj->{'value'}, 'Value element exists');
    ok ( !defined $foo_obj->{'value'},
         'Value element not defined');

    
    my $not = bless [], 'Beast';
    my $is  = bless [], 'Bird';

    ok ( !eval {$foo = $not}, 'Bad assignment');
    ok ( !defined $foo,       'Bad assignment not accepted');
    ok ( eval  {$foo = $is }, 'Good assignment');
    is ( $foo, $is,           'Good assignment accepted');
}

