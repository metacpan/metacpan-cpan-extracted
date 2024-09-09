requires 'Kelp' => '2.16';
requires 'Kelp::Module::YAML' => '2.00';
requires 'Role::Tiny' => 0;

# needed for multiple boolean types and 'perl' booleans
# (fails on older perls before v0.38.0)
requires 'YAML::PP' => '0.038';

# needed for deep cloning without errors on sub references
requires 'Clone' => 0;

# needed for uniq on old perls
requires 'List::Util' => '1.44';

# needed for typo suggestions
requires 'Text::Levenshtein' => 0;

on 'test' => sub {
	requires 'Test::Exception' => 0;
};

