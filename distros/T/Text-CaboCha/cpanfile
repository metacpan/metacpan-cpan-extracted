on 'configure' => sub {
    requires 'Cwd::Guard';
    requires 'Devel::CheckLib';
    requires 'File::Which';
    requires 'parent';
};

on 'test' => sub {
    requires 'Test::More', '0.98';
};

on 'develop' => sub {
    requires 'Test::LeakTrace';
    requires 'Test::Valgrind';
};
