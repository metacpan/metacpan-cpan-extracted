use Test;
BEGIN { plan tests => 9 };

ok(eval q{{
    use enum::fields 'ONE0', 'ONE1';
    
    (ONE == 0 && ONE1 == 1);
}});

# Make sure we can't redefine

eval "use enum::fields 'ONE0';";

ok($@ =~ /Redefined constant/);

# Add fields

ok(eval q{{
    use enum::fields 'ONE2';
    ONE2 == 2;
}});

# Reset to zero for new class

ok(eval q{{
    package Foo;
    
    use enum::fields 'TWO0', 'TWO1', 'TWO2', 'TWO3';
    
    TWO0 == 0 && TWO1 == 1 && TWO2 == 2 && TWO3 == 3;
}});

# Add another field to main

ok(eval q{{
    use enum::fields 'ONE3';
    
    ONE3 == 3;
}});

# Inherit from Foo

ok(eval q{{
    package Bar;
    
    use enum::fields::extending Foo => 'LOCAL0', 'LOCAL1';
    
    TWO3 == 3 && LOCAL0 == 4 && LOCAL1 == 5;
}});

# Try to extend Foo

eval q{{
    package Foo;
    
    use enum::fields 'NEVER';
}};

ok($@ =~ /Cannot add fields to class that has been inherited/);

# Try to extend Bar

ok(eval q{{
    package Bar;
    
    use enum::fields 'LOCAL2', 'LOCAL3';
    
    LOCAL3 == 7;
}});

# Try to extend Bar with Foo again

eval q{{
    package Bar;
    
    use enum::fields::extending Foo => 'NEVEREVER';
}};

ok($@ =~ /class already has fields/);
