use strict;
use warnings;


use Test::More qw/tests 22/;

my $mw;
BEGIN{use_ok('Tk');
      require_ok ('Tk::EntrySet');
      require_ok ('Tk::ChoicesSet');
  }
eval{$mw = MainWindow->new};

SKIP: {
    diag "Could not create MainWindow. Please check, if your X-server is running: $@\n" if ($@);
    skip "MainWindow instantiation failed: $@", 19 if ($@);
    
    my $mbe;
    
    $mw->geometry($mw->screenwidth
                  ."x"
                  .$mw->screenheight
                  ."+0+0");

    eval{
        $mbe = $mw->ChoicesSet->pack(-fill   => 'both',
                                     -expand => 1);
        $mw->update;
    };

    isa_ok ($mbe , 'Tk::ChoicesSet', 'Tk::ChoicesSet instance creation');
    my ($labels, $labels_and_values);
    eval{
        $mbe->choices([qw/foo bar baz/]);
        $labels  = $mbe->choices;
        $mw->update;
        
    };
    is_deeply($labels, [qw/foo bar baz/], 'Setting choices');
    my $lv_set = [{value => 1, label => 'first'},
                  {value => 2, label => 'second'},
                  {value => 3, label => 'third'},
              ];
    eval{
        $mbe->labels_and_values( $lv_set );
        $labels  = $mbe->get_labels;
        $labels_and_values = $mbe->labels_and_values;
        $mw->update;
    };
    is_deeply ($labels_and_values, $lv_set,
               'Setting/getting labels_and_values');
    is_deeply ($labels, [qw/first second third/], 'getting labels');

    my $sel;
    my $valuelist;
    eval{
        $mbe->valuelist_variable( \$sel );
        $sel = [1];
        $valuelist = $mbe->valuelist;
        $mw->update;
    };
    is_deeply($valuelist, [1], '-valuelist_variable tie');
    eval{
        $mbe->valuelist([1,2]);
        $mw->update;
        $valuelist = $sel;
    };
    is_deeply($valuelist, [1,2], 'read tied variable');
    eval{
        $sel = [1,3];
        $mw->update;
        $valuelist = $mbe->valuelist;
    };
    is_deeply($valuelist, [1,3], 'write tied variable');
    $mw->update;
    
    ### Invoke some methods of MatchingEE ###
    my ($val, $first_entry);
    ### wrap these in TODO because of problems with eventGenerate
    ### and some wm...
  TODO: {
        local $TODO = 'three tests that depend on eventGenerate might fail';
                     
        eval{
            $first_entry = $mbe->{_EntrySet}{entries}[0];
            $first_entry->focus;
            $mw->update;
            $first_entry->icursor('end');
            $mw->update;
            $first_entry->eventGenerate('<Key-BackSpace>');
            $first_entry->focus;
            $mw->update;
            $first_entry->eventGenerate('<Key-Return>');
            $mw->update;
            $val = $first_entry->get_selected_value;
        };
        ok (! $@, 'Additional MBE tests');
        is ($val, 'first', 'MBE get_selected_value');
        eval{
            $first_entry->focus;
            $mw->update;
            $first_entry->icursor(2);
            $mw->update;
            $first_entry->focus;   
            $first_entry->eventGenerate('<Key-BackSpace>');
            $first_entry->eventGenerate('<Key-Return>');
            $mw->update;
            $val = $first_entry->get_selected_value;
        };
        is ($val, undef, 'No Match: MBE value set to undef');

    }                           ###end TODO

    $mbe->destroy;
    
    ### Some tests for Tk::EntrySet ###

    my ($es, $list);
    my $check = 0;
    eval{
        $es = $mw->EntrySet(-changed_command => sub{$check++})->pack;
        $mw->update;
    };
    isa_ok($es, 'Tk::EntrySet', 'Tk::EntrySet instance creation');
    eval{
        $es->valuelist([qw/foo bar baz/]);
        $list = $es->valuelist;
        $mw->update;
    };
    is_deeply($list, [qw/foo bar baz/], 'get/set EntrySet valuelist');
    
    TODO: {
          local $TODO = 'test for -changed_command depends on '
                        .'eventGenerate and might fail';
          eval{
              $first_entry = $es->{_EntrySet}{entries}[0];
              $first_entry->focus;
              $mw->update;
              $first_entry->eventGenerate('<Return>');
              $mw->update;
          };
    is($check, 1, 'calling -changed_command Callback');
    } ### end TODO

    $es->destroy;

### check instantiation with given -valuelist -valuelist_variable options

    eval{
        $es = $mw->EntrySet(-valuelist => [qw/foo bar baz/])->pack;
        $mw->update;
    };
    is_deeply ($es->valuelist ,[qw/foo bar baz/],
               'Entryset instantiation with valuelist option set');

    $es->destroy;
    $valuelist = [];
    eval{
        $es = $mw->EntrySet(-valuelist => [qw/foo bar baz/],
                            -valuelist_variable => \$valuelist,
                        )->pack;
        $mw->update;
    };
    is_deeply ($valuelist ,[qw/foo bar baz/],
               'Entryset instantiation with valuelist '
               .'and valuelist_variable set');

    $es->destroy;

### check for valuelist_variable being untied after $es->destroy...
    eval{
        $valuelist = [];
    };
    ok( ! $@,
        "assignment of valuelist_variable after EntrySet->destroy: $@");
    
### the same for ChoicesSet


    
    eval{
        $mbe = $mw->ChoicesSet(-labels_and_values => $lv_set,
                               -valuelist => [1,2],
                               )->pack;
        $mw->update;
    };
    is_deeply ($mbe->valuelist ,[1,2],
               'ChoicesSet instantiation with valuelist option set'); 
    $mbe->destroy;


    $valuelist = [];
    eval{
        $mbe = $mw->ChoicesSet(-labels_and_values => $lv_set,
                               -valuelist => [1,2],
                               -valuelist_variable => \$valuelist,
                               )->pack;
        $mw->update;
    };
    is_deeply ($valuelist ,[1,2],
               'ChoicesSet instantiation with valuelist '
               .'and valuelist_variable option set');
    $mbe->destroy;

    eval{
        $mbe = $mw->EntrySet()->pack;
        $mbe->valuelist([1,2,3]);
        $mw->update;
        my $entries = $mbe->{_EntrySet}{entries};
        is (@$entries, 4, 'Should create 4 Entries for 3 values');
    };

}# END SKIP
