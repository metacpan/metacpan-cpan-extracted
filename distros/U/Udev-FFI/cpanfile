requires 'perl', '5.008001';

requires 'FFI::Platypus';
requires 'FFI::CheckLib';
requires 'IPC::Cmd';

recommends 'PkgConfig', '0.17026';

on 'configure' => sub {
    requires 'FFI::CheckLib';
};

on 'test' => sub {
    requires 'Test::More', '0.98';
};
