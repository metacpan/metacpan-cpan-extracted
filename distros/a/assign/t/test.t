use assign::Test;

test <<'...', "111-222",
my [$foo, $bar] = [111, 222, 333];
print "$foo-$bar";
...
    "Simple array destructure";
