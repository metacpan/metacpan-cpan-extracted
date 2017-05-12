use FindBin;
use Test::More;
use utf8;
use strict;
use warnings;

{

    use_ok 'Validation::Class';
    use_ok 'Validation::Class::Prototype';
    use_ok 'Validation::Class::Mapping';

}


{

    {
        package TestClass::A;
        use Validation::Class;

        field 'test_a';

        my  $set = Validation::Class->prototype(__PACKAGE__)->configuration->settings;
            $set->{unit} ||= {};
            $set->{unit}->{'test_a'} = { test => 'ok' };
    }
    {
        package TestClass::B;
        use Validation::Class;

        field 'test_b';

        my  $set = Validation::Class->prototype(__PACKAGE__)->configuration->settings;
            $set->{unit} ||= {};
            $set->{unit}->{'test_b'} = { test => 'ok' };
    }
    {
        package TestClass;
        use Validation::Class 'set';

        set roles => ['TestClass::A', 'TestClass::B'];

        my  $set = Validation::Class->prototype(__PACKAGE__)->configuration->settings;
            $set->{unit} ||= {};
            $set->{unit}->{'test'} = { test => 'ok' };
    }
    package main;

    my $t = TestClass->new;

    ok "TestClass" eq ref $t, "TestClass instantiated";

    my $settings = $t->proto->settings;

    ok "Validation::Class::Mapping" eq ref $settings, "TestClass settings initialized";

    my $unit = $settings->{unit};

    ok "HASH" eq ref $unit, "TestClass settings/unit initialized";

    my $data = {
        test   => { test => 'ok' },
        test_a => { test => 'ok' },
        test_b => { test => 'ok' },
    };

    is_deeply $unit, $data, "TestClass settings/unit deeply okay";

}

done_testing();
