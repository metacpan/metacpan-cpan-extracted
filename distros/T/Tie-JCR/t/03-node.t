# vim: set ft=perl :

use strict;
use warnings;

use Test::More tests => 20;

use_ok('Tie::JCR');

sub create_mock_node {
    my ($node_name, $node_data) = @_;

    my $mock_node = Test::MockObject->new;

    $mock_node->mock(get_name => sub { $node_name });

    $mock_node->mock(has_nodes => 
        sub {
            grep { UNIVERSAL::isa($node_data->{$_}, 'Test::MockObject') } 
            keys %$node_data
        }
    );

    $mock_node->mock(has_properties =>
        sub {
            grep { !UNIVERSAL::isa($node_data->{$_}, 'Test::MockObject') }
            keys %$node_data
        }
    );

    $mock_node->mock(get_node => 
        sub {
            my ($self, $path) = @_;
            return $node_data->{$path};
        }
    );

    $mock_node->mock(get_nodes =>
        sub {
            my ($self) = @_;
            return create_mock_iterator(
                [ 
                    map { $node_data->{$_} }
                    grep { UNIVERSAL::isa($node_data->{$_}, 'Test::MockObject') } 
                    keys %$node_data
                ], 1
            );
        }
    );

    $mock_node->mock(get_properties =>
        sub {
            my ($self) = @_;
            return create_mock_iterator(
                [   
                    map { ($_ => $node_data->{$_}) }
                    grep { !UNIVERSAL::isa($node_data->{$_}, 'Test::MockObject') } 
                    keys %$node_data
                ], 0
            );
        }
    );

    $mock_node->mock(get_property =>
        sub {
            my ($self, $path) = @_;
            return create_mock_property($path => $node_data->{$path});
        },
    );

    $mock_node->mock(has_node =>
        sub {
            my ($self, $path) = @_;
            return UNIVERSAL::isa($node_data->{$path}, 'Test::MockObject');
        },
    );

    $mock_node->mock(has_property =>
        sub {
            my ($self, $path) = @_;
            return defined $node_data->{$path} && !UNIVERSAL::isa($node_data->{$path}, 'Test::MockObject');
        },
    );

    return $mock_node;
}

sub create_mock_property {
    my ($name, $value) = @_;

    my $mock_property = Test::MockObject->new;

    $mock_property->mock(get_name => sub { $name });

    $mock_property->mock(get_boolean => 
        sub {
            my ($self) = @_;
            return $value ? 1 : 0;
        }
    );

    $mock_property->mock(get_date => 
        sub {
            my ($self) = @_;
            die 'Not a Date.' unless UNIVERSAL::isa($value, 'DateTime');
            return $value;
        }
    );

    $mock_property->mock(get_long =>
        sub {
            my ($self) = @_;
            return +$value;
        }
    );

    $mock_property->mock(get_string =>
        sub {
            my ($self) = @_;
            return ''.$value;
        },
    );

    $mock_property->mock(get_definition =>
        sub {
            my ($self) = @_;
            return create_mock_definition($name);
        }
    );

    return $mock_property;
}

sub create_mock_iterator {
    my ($list, $is_node) = @_;

    my $mock_iterator = Test::MockObject->new($list);

    $mock_iterator->mock(has_next => 
        sub {
            my ($list) = @_;
            return scalar(@$list);
        }
    );

    if ($is_node) {
        $mock_iterator->mock(next_node =>
            sub {
                my ($list) = @_;
                return shift @$list;
            }
        );
    }

    else {
        $mock_iterator->mock(next_property =>
            sub {
                my ($list) = @_;
                my ($name, $value) = splice @$list, 0, 2;
                return create_mock_property($name => $value);
            }
        );
    }

    return $mock_iterator;
}

sub create_mock_definition {
    my ($name) = @_;

    my $mock_definition = Test::MockObject->new;

    $mock_definition->mock(is_multiple => sub { 0 });

    $mock_definition->mock(get_required_type => 
        sub {
            # See http://rt.cpan.org/Ticket/Display.html?id=20758
            # return Java::JCR::PropertyType::value_from_name($name);
            no warnings 'once';
            return $name eq 'Boolean' ? $Java::JCR::PropertyType::BOOLEAN
                 : $name eq 'Date'    ? $Java::JCR::PropertyType::DATE
                 : $name eq 'Long'    ? $Java::JCR::PropertyType::LONG
                 : $name eq 'String'  ? $Java::JCR::PropertyType::STRING
                 : die "Unknown type $name.";
        }
    );
}

SKIP: {
    eval "use Test::MockObject";
    if ($@) { skip "Test::MockObject is not installed.", 1 }

    my $node_data = {
        Long    => 42,
        String  => 'blah',
        Boolean => 1,
        Date    => '2006-07-29 13:42:32',
    };

    $node_data->{'Node'} = create_mock_node(Node => $node_data);

    my $node = create_mock_node('' => $node_data);

    tie my %node, 'Tie::JCR', $node;
    ok(tied %node);
    isa_ok(tied %node, 'Tie::JCR');

    ok(exists $node{'Long'});
    is($node{'Long'}, 42);

    ok(exists $node{'String'});
    is($node{'String'}, 'blah');

    ok(exists $node{'Boolean'});
    is($node{'Boolean'}, 1);

    my $nested_node = $node{'Node'};
    ok($nested_node);
    is(ref $nested_node, 'HASH');

    is($nested_node->{'Long'}, 42);
    is($nested_node->{'String'}, 'blah');
    is($nested_node->{'Boolean'}, 1);

    SKIP: {
        eval "use DateTime";
        if ($@) { skip "DateTime is not installed.", 2 }

        my $date = $node_data->{'Date'} = DateTime->now;

        ok(exists $node{'Date'});
        is($node{'Date'}, $date);

        is($nested_node->{'Date'}, $date);
    }

    ok((tied %node)->node);

    is_deeply(
        [ sort keys %node ], 
        [ 'Boolean', 'Date', 'Long', 'Node', 'String' ]
    );

    ok(scalar(%node));
}
