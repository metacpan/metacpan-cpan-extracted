use Test::Mini::Unit;

our @calls;

{
    package TestPreorder;

    sub up { push @calls, 'first' }

    use Test::Mini::Unit::Sugar::Advice name => 'up', order => 'pre';

    up { push @calls, 'second' }
    up { push @calls, 'third' }
}

{
    package TestPostorder;

    sub down { push @calls, 'first' }

    use Test::Mini::Unit::Sugar::Advice name => 'down', order => 'post';

    down { push @calls, 'second' }
    down { push @calls, 'third' }
}

{
    package TestSelf;
    use Test::Mini::Unit::Sugar::Advice name => 'self', order => 'pre';
    
    self { push @calls, $self }
}

case t::Test::Mini::Unit::Sugar::Advice::Behavior {
    setup { @calls = () }

    case WithOrder {
        case Pre {
            setup { TestPreorder->up() }
            test calls_are_in_declaration_order {
                assert_equal(\@calls, [qw/ first second third /]);
            }
        }
        
        case Post {
            setup { TestPostorder->down() }
            test calls_are_in_reverse_declaration_order {
                assert_equal(\@calls, [qw/ third second first /]);
            }
        }
    }

    test advice_automatically_assigns_self_variable {
        TestSelf::self('FIRST');
        assert_equal(shift(@calls) => 'FIRST');
    }
}
