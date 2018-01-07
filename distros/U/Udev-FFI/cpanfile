requires 'perl', '5.008001';

requires 'IPC::Cmd';

requires 'FFI::Platypus';
requires 'FFI::CheckLib';


on 'configure' => sub {
    requires 'FFI::CheckLib';
};


on 'test' => sub {
    requires 'Test::More', '0.98';
};
