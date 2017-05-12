use strict;
use warnings;
#use lib './lib';

use Test::More qw/tests 40/;

my $mw;
BEGIN{use_ok('Tk');
      require_ok ('Tk::EntrySet');
      require_ok ('Tk::ChoicesSet');
  }
eval{$mw = MainWindow->new};

SKIP: {
    diag "Could not create MainWindow. Please check, if your X-server is running: $@\n" if ($@);
    skip "MainWindow instantiation failed: $@", 37 if ($@);
    my $mbe;
    $mw->geometry($mw->screenwidth
                  ."x"
                  .$mw->screenheight
                  ."+0+0");
    $mw->update;

    my $lv_set = [{value => 1, label => 'first'},
                  {value => 2, label => 'second'},
                  {value => 3, label => 'third'},
              ];

    my ($val, $first_entry);


    eval{
        $mbe = $mw->MatchingBE()->pack;
    };
    isa_ok($mbe, 'Tk::MatchingBE', 'MatchingBE creation');
    $mbe->destroy;
    ## mbe with choices
    eval{
        $mbe = $mw->MatchingBE(-choices => [qw/foo bar baz/])->pack;
    };
    is_deeply([$mbe->cget('-choices')],[qw/foo bar baz/],
              'getting/setting -choices');
    ## check getting/setting values
    is($mbe->get_selected_value, undef, 'initial value undef');
    is ($mbe->Subwidget('entry')->get, '', 'empty entry if value not set');
    $mbe->set_selected_index( 0 );
    is( $mbe->get_selected_index, 0, 'get_selected_index with -choices');
    is( $mbe->get_selected_value, 'foo',
        'get_selected_value with -choices ');
    is( $mbe->Subwidget( 'entry')->get, 'foo',
        'entry reflects selected value with -choices');
    $mbe->choices([qw/one two three/]);
    is( $mbe->Subwidget('entry')->get, '',
        'reconfiguring -choices clears entry');
    is( $mbe->get_selected_value, undef,
        'reconfiguring -choices clears selected_value');
    is( $mbe->get_selected_index, undef,
        'reconfiguring -choices clears selected_index');
    my $ouch;
    eval{ $mbe->configure(-value_variable => \$ouch);};
    ok( $@,
        "can not configure -value_variable unless using labels_and_values");
    $mbe->destroy;

    ## tests in -labels_and_values mode
    eval{
        $mbe = $mw->MatchingBE(-labels_and_values => $lv_set)->pack;
    };
    ok(! $@, "instance creation with -labels_and_values given:$@");
    is_deeply($mbe->labels_and_values, $lv_set,
              'get/set labels_and_values' );


    ### wrap these in TODO because of problems with eventGenerate
    ### and some wm...
  TODO: {
        local $TODO = 'tests that depend on eventGenerate might fail';
        $mbe->focus;
        $mbe->icursor('end');
        $mw->update;
        $mbe->focus;
        $mbe->eventGenerate('<Key-BackSpace>');
        $mw->update;
        $mbe->focus;
        $mbe->eventGenerate('<Key-Return>');
        $mbe->update;
        $val = $mbe->get_selected_value;
        is($val ,1 , 'selected first item per EventGen. get_selected_value');
        $val = $mbe->get_selected_label;
        is($val, 'first', 'selected first item get_selected_label');
        $mbe->focus;
        $mbe->icursor('end');
        $mbe->eventGenerate('<Key-m>');
        $mbe->eventGenerate('<Key-Return>');
        $mbe->update;
        is($val ,1 , 'pressing non matching key does not change selection');
    }

        $mbe->set_selected_value(2);
        $val = $mbe->get_selected_value;
        is( $val, 2, 'set_selected_value');
        is( $mbe->Subwidget('entry')->get, 'second',
            'entry content reflects selected_value');

        eval{$mbe->set_selected_value(42)};
        ok($@ , "can't set_selected_value to non existing value");
        is( $val, 2,
            'failed attempt to set_selected_value does not change MBE state');
        is( $mbe->Subwidget('entry')->get, 'second',
            'failed attempt to set_selected_val does not change entry content');
        eval{$mbe->set_selected_value(undef)};
        $val = $mbe->get_selected_value;
        is($val, undef, 'can set_selected_value to undef');
        is( $mbe->Subwidget('entry')->get, '',
            'empty entry in case of selected_value->undef');
    my $val_var;
    $mbe->configure(-value_variable => \$val_var);
    is( $mbe->cget('-value_variable'), \$val_var,
        '-value_variablereference correct');
    $mbe->set_selected_value(1);
    is($val_var, 1, 'reading value_variable');

    $val_var = 2;
    is($mbe->get_selected_value, 2, 'writing value_variable');
    $mbe->configure(-labels_and_values =>
                    [{label => 'foo', value => 10},
                     {label => 'bar', value => 11},
                     {label => 'baz', value => 12}]);
    is( $mbe->get_selected_value, undef,
        'reconfiguring -labels_and_values clears selected_value');
    is( $mbe->get_selected_label, undef,
        'reconfiguring -labels_and_values clears selected_label');
    is( $mbe->Subwidget('entry')->get, '',
        'reconfiguring -labels_and_values clears entry');
    $mbe->destroy;
    
    eval{$val_var = 2};
    ok(! $@, 'value_variable has been untied during destroy');
    eval{
        $mbe = $mw->MatchingBE(
                              -value_variable => \$val_var,
                              -labels_and_values => $lv_set,
                               )->pack;
    };

    ok(! $@, 'instantiation with -labels_and_values and '
             .' value_variable set');
    is( $mbe->get_selected_value, 2,
         'value properly initialized during _value_variable tie');
    is( $mbe->Subwidget('entry')->get, 'second',
        'entry reflects selected label');
    
    $mbe->destroy;
    my $val_var2 = undef;
    $mbe = $mw->MatchingBE(
                       )->pack;
    $mbe->configure( -labels_and_values => $lv_set);
    $mbe->configure( -value_variable => \$val_var2);
    is($val_var2, undef, 'val_variable has same value (undef) after tie');
    is($mbe->Subwidget('entry')->get, '',
       'empty Entry if valiue_variable set to undef');

    
    $lv_set = [{value => 1, label => 'first'},
               {value => 2, label => 'second'},
               {value => 1, label => 'third'},
              ];
    eval{$mbe->configure(-labels_and_values=> $lv_set)};
    ok($@ ,"won't accept -labels_and_values with non unique values");

    $mbe->configure(-choices=>[qw/foo bar baz/]);
    eval{$mbe->set_selected_value('foo')};
    ok($@ , "can't set_selected_value unless -labels_and_values"
            ." has been set.");
    

}#end SKIP
1;
