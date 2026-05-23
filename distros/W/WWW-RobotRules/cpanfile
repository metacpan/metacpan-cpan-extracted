use strict;
use warnings;

on 'configure' => sub {
    requires 'ExtUtils::MakeMaker';
};

on 'runtime' => sub {
    requires 'perl' => '5.008001';
    requires 'strict';
    requires 'AnyDBM_File';
    requires 'Carp';
    requires 'Fcntl';
    requires 'URI' => '1.10';

    # DB_File is only needed for the optional WWW::RobotRules::DB_File
    # backend. It is a non-core XS module, so it is suggested, not required.
    suggests 'DB_File';
};

on 'test' => sub {
    requires 'Test::More' => '0.96';
    requires 'strict';
    requires 'warnings';
};

on 'develop' => sub {
    requires 'Pod::Coverage::TrustPod';
    requires 'Pod::Spell' => '1.25';
    requires 'Test::EOL' => '2.00';
    requires 'Test::MinimumVersion';
    requires 'Test::Mojibake';
    requires 'Test::Pod';
    requires 'Test::Pod::Coverage';
    requires 'Test::Portability::Files';
    requires 'Test::Version';
};
