requires 'perl', '5.010001';

requires 'Class::Load'           , '0.22';
requires 'Class::Accessor::Lite' , '0.06';
requires 'IPC::Run3'             , '0.048';
requires 'Data::Util'            , '0.63';
requires 'URI::Split';

on 'test' => sub {
    requires 'Test::More'          , '0.98';
    requires 'Test::UseAllModules' , '0.15';
    requires 'Test::Mock::Guard'   , '0.10';
    requires 'Test::Deep'          , '0.112' ,
};

on 'develop' => sub {
    requires 'Minilla';
    requires 'Version::Next';
    requires 'Data::Printer';
};
