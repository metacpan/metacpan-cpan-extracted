package TestML1::Library::Debug;

use TestML1::Base;
extends 'TestML1::Library';

no warnings 'redefine';

sub WWW {
    require XXX;
    local $XXX::DumpModule = $TestML1::DumpModule;
    XXX::WWW(shift->value);
}

sub XXX {
    require XXX;
    local $XXX::DumpModule = $TestML1::DumpModule;
    XXX::XXX(shift->value);
}

sub YYY {
    require XXX;
    local $XXX::DumpModule = $TestML1::DumpModule;
    XXX::YYY(shift->value);
}

sub ZZZ {
    require XXX;
    local $XXX::DumpModule = $TestML1::DumpModule;
    XXX::ZZZ(shift->value);
}

1;
