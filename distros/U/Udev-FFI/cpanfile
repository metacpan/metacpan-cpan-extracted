requires 'perl', '5.008001';

requires 'File::Which';
requires 'FFI::CheckLib';
requires 'FFI::Platypus';

on 'configure' => sub {
    requires 'FFI::CheckLib';
};

on 'test' => sub {
    requires 'Test2', '>= 1.302207';
};
