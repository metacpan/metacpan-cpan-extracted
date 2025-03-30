use Test::More tests => 10;  # Adjust the number of tests as needed
use autobox::Lookup;
    

# Test Case 1: Empty Structure
{
    my $result = {}->get('foo');
    is($result, undef, "Result is undef on an empty hash");
}

# Test Case 2: Empty Key String
{
    my $result = { foo => 'bar' }->get();
    is_deeply($result, { foo => 'bar' }, "return whole structire on empty key")
}

# Test Case 3: Non-Reference Values (scalar as base structure)
{
    my $result = 'string'->get('foo');
    is($result, undef, "Result is undef on a non-ref");
}

# Test Case 4: Numeric Keys (Array Index)
{
    my $result = [1, 2, 3]->get('0');
    is($result, 1, "Numeric index returns the correct value");
}

# Test Case 5: Mixed Data Types (Array and Hash in same structure)
{
    my $data = {
        foo => { bar => 'baz' },
        array => [ 'a', 'b', 'c' ]
    };
    my $result = $data->get('array.1');
    is($result, 'b', "Mixed structure: Array index lookup works");
}

# Test Case 6: Deeply Nested Structures
{
    my $data = { foo => { bar => { baz => 'value' } } };
    my $result = $data->get('foo.bar.baz');
    is($result, 'value', "Deeply nested structure returns the correct value");
}

# Test Case 7: Non-Numeric Array Indices
{
    my $data = { arr => [ 'a', 'b', 'c' ] };
    my $result = $data->get('arr.foo');
    is($result, undef, "Result is undef on a non-numeric key on an array");
}

# Test Case 8: Invalid Array Indexes (Out of bounds)
{
    my $data = { arr => [ 'a', 'b' ] };
    my $result = $data->get('arr.5');
    is($result, undef, "Result is undef on an out-of-bounds array index");
}

# Test Case 9: Keys with Leading or Trailing Dots
{
    my $data = { foo => { bar => 'baz' } };
    my $result = $data->get('.foo.bar.');
    is($result, undef, "Result is undef with leading or trailing dots on the lookup");
}

# Test Case 10: Circular References
{
    my $data = {};
    $data->{self} = $data;
    my $result = $data->get('self.self');
    is_deeply($result, $data)
}

done_testing();
