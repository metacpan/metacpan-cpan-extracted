# Copyright 2004, Phill Wolf.  See README.

# Win32::ActAcc (Active Accessibility)

use Win32::OLE;
use Win32::ActAcc qw(:all);
use Time::HiRes;
use FindBin qw($Bin);
use Getopt::Long (qw(GetOptions));
use Win32::GuiTest; # for menus and focus control

# Active Accessibility uses OLE
Win32::OLE->Initialize();

# Script can run in "quiet" mode, or normal mode with more messages.
our $quiet;

die unless GetOptions
  (
   "quiet!" => \$quiet
  );

&main;

sub main
  {
    # Display a msg whenever ActAcc performs "default action":
    $Win32::ActAcc::AO::accDoDefaultActionHook = 
      sub
        {
          my $ao = shift;
          print "DDA: ".$ao->describe()."\n" unless $quiet;
        };

    # Check that we can find the playpen app.
    my $playpen_exe = "$Bin\\playpen\\ActAccPlaypen.exe";
    die("Can't find $playpen_exe") unless -e $playpen_exe;

    # test_of('GetOleaccVersionInfo')
    print "You have Oleacc version: ". GetOleaccVersionInfo()."\n" 
      unless $quiet;

    # Install WinEvent hook.
    # test_of('standardEventMonitor')
    standardEventMonitor(); # (clearEvents would also work)

    # Start at the Desktop.
    my $aoDesktop = Desktop();

    # Start the ActAccPlaypen process. 
    # Since we'll detect the appearance of the program's
    # window by following WinEvents, it's a good idea
    # to erase all past WinEvents.
    clearEvents(); # test_of('clearEvents')
    system("start $playpen_exe"); 

    # Allow a certain amount of time for the window to appear.
    my $timeoutSeconds = 30;

    # Wait for EVENT_OBJECT_SHOW of an AO with a certain name.
    # test_of('waitForEvent')
    my $aoPlaypen =
      waitForEvent(
                   +{ 
                     'event'=>EVENT_OBJECT_SHOW(),
                     'ao_profile'=>'ActAcc Playpen'
                     }, $timeoutSeconds);

    # Here's how we might find the window if it had
    # already been displayed... 
    # i.e., 
    #  1. start at the Desktop.
    #  2. among its children, select one with role ROLE_SYSTEM_CLIENT.
    #  3. among its children, select one named "ActAcc Playpen".
    if (0) 
      {
        # Find an open "ActAcc Playpen" window.
        my $aoPlaypen = $aoDesktop->dig(
                                        +[
                                          '{client}', 
                                          'ActAcc Playpen'
                                         ], 
                                        +{'min'=>1});

        # Bring it to the top (if not already).
        # Note: Active Accessibility servers often fail to
        # heed attempts to change focus or selection through
        # Active Accessibility. Consider using Win32::GuiTest
        # to fake a click instead.
        $aoPlaypen->accSelect(SELFLAG_TAKEFOCUS());
      }

    # Play with iterators.
    test_iterators_for_consistency($aoPlaypen);

    # test_of('dig.scalar_context.positive')
    # test_of('dig.1_step')
    my $aoClient = $aoPlaypen->dig(+['{client}'], +{'min'=>1}); 
    # test_of('get_accParent.window')
    die unless $aoClient->get_accParent()->get_accName() 
      eq $aoPlaypen->get_accName();
    die unless $aoClient->get_accParent()->get_accRole() 
      == ROLE_SYSTEM_WINDOW();

    print STDERR "Finding the list-box...\n" unless $quiet;

    # Note: Identifying either the list-box or the list-view
    # would be simpler if they weren't peers!

    # test_of('dig.N_step')
    # test_of('dig.scalar_context.positive')
    my $aoListBox = $aoPlaypen->dig
      (
       +[
         '{client}',
         '{window}',
         '{page tab list}', 
         '{window}', 
         '{client}', 
         # Different versions of Windows name List Views differently.
         +{'role'=>ROLE_SYSTEM_WINDOW(), 'name'=>qr/^List (box|view)$/},
         # Find a ROLE_SYSTEM_LIST that doesn't contain a ROLE_SYSTEM_WINDOW.
         new Win32::ActAcc::Test_and
         (
          +[
            new Win32::ActAcc::Test_role_in(+['list']),
            new Win32::ActAcc::Test_not
            (
             new Win32::ActAcc::Test_dig
             (
              +['{window}']
             )
            )
           ]
         ),
        ], 
       +{'min'=>1,'max'=>1,'trace'=>!$quiet}
      );
    die(GetRoleText($aoListBox->get_accRole()) . " is not list")
      unless GetRoleText($aoListBox->get_accRole()) eq 'list';
    my @lsel = $aoListBox->get_accSelection();
    warn("Wasn't expecting any selected items, but got: ".
       join(",", map("$_\n",@lsel))) unless !@lsel;
    
    # test_of('accNavigate')
    my $aoListBoxItem1 = $aoListBox->accNavigate(NAVDIR_FIRSTCHILD());
    $aoListBoxItem1->accSelect(SELFLAG_TAKEFOCUS());
    sleep(1);
    # test_of('get_accSelection.1')
    my @lsel1 = $aoListBox->get_accSelection();
    sleep(1);
    die("Was expecting 1 selected item, but got: ".
       join(",", map("$_\n",@lsel1))) unless 1==@lsel1;
    my $sel1 = $lsel1[0];
    print "Selected item: $sel1\n" unless $quiet;
    die("Was expecting Adair, but got $sel1") unless ("$sel1" =~ /Adair/);

    print STDERR "Finding the list-view...\n" unless $quiet;
    # test_of('dig.N_step')
    # test_of('dig.scalar_context.positive')
    my $aoListView = $aoPlaypen->dig
      (
       +[
         '{client}',
         '{window}',
         '{page tab list}', 
         '{window}', 
         '{client}', 
         # Different versions of Windows name List Views differently.
         +{'role'=>ROLE_SYSTEM_WINDOW(), 'name'=>qr/List (box|view)/}, 
         # Find a ROLE_SYSTEM_LIST that contains a ROLE_SYSTEM_WINDOW.
         new Win32::ActAcc::Test_and
         (
          +[
            new Win32::ActAcc::Test_role_in(+['list']),
            new Win32::ActAcc::Test_dig
            (
             +['{window}']
            )
           ]
         ),
        ], 
       +{'min'=>1,'max'=>1,'trace'=>!$quiet}
      );

    $Win32::ActAcc::LOG_ACTIONS = 1;
    $aoListView->focus();
    $Win32::ActAcc::LOG_ACTIONS = undef;

    # Demonstrate that the list-view has fewer than 998 items.
    my @aoLVis;
    # test_of('dig.array_context.min_not_met')
    eval
      {
        @aoLVis = $aoListView->dig
          (
           +['{list item}'],
           +{'min'=>998}
          );
      };
    die("Expected error did not occur") unless ($@);
    undef $@;

    # Retrieve a list-item from the list-view.
    # test_of('dig.array_context.capped')
    @aoLVis = $aoListView->dig
      (
       +['{list item}'],
       +{'max'=>1}
      );
    die unless (1 == @aoLVis);

    # Retrieve at-least-2 list-items from the list-view.
    # test_of('dig.array_context.min_met')
    # test_of('dig.1_step') 
    @aoLVis = $aoListView->dig
      (
       +['{list item}'],
       +{'min'=>2}
      );
    die unless 2 < @aoLVis;

    # Horse around with the selection.
    $aoListView->accSelect(SELFLAG_TAKEFOCUS());
    my @s1 = $aoListView->get_accSelection();
    warn("Wasn't expecting any selected items, but got: ".
       join(",", map("$_\n",@s1))) unless !@s1;
    print "List items of the list-view: \n" unless $quiet;
    print join(",", map("$_\n",@aoLVis)) unless $quiet;
    (my $L, $T) = $aoLVis[0]->accLocation();
    Win32::ActAcc::click($L+1,$T+1);
    awaitCalm();
    $aoLVis[0]->accSelect(SELFLAG_TAKEFOCUS() | SELFLAG_ADDSELECTION());
    #sleep(1);
    $aoLVis[2]->accSelect(SELFLAG_ADDSELECTION());
    #sleep(1);
    my @s2 = $aoListView->get_accSelection();
    die("Was expecting 2 selected items, but got: ".
       join(",", map("$_\n",@s2))) unless (2==@s2);
    die("Was expecting Allamakee") unless $s2[0]->describe()=~/Allamakee/;
    die("Was expecting Benton") unless $s2[1]->describe()=~/Benton/;

    # test_of('get_accParent.child_id')
    die unless $aoListBoxItem1->get_accParent()->describe() 
      eq $aoListBox->describe(); 

    # Choose menu item File | Open Halfway
    # test_of('Window::menuPick')
    $aoPlaypen->menuPick
      (
       +[
         'File', 
         'Open Halfway'
        ]
      ); 

    # Find the status bar.
    my $aoStatusBar = $aoPlaypen->dig
      (+['{client}', '{window}', '{status bar}']);

    # test_of('dig.scalar_context.negative')
    undef $@;
    eval
      {
        my $aoX = $aoPlaypen->dig(+['{client}', '{window}NoSuchWindow']);
      };
    die("Expected error did not occur") unless $@;
    undef $@;

    # test_of('dig.array_context.none')
    my @aoX = $aoPlaypen->dig(+['NoSuchWindow'], +{'min'=>0});
    die("Expected none, got some") if(@aoX);

    # Combo box (looks like a spinbox).
    my $aoCombo = $aoPlaypen->dig
      (+['{client}', '{window}Watts', '{combo box}']);
    # test_of('Combobox::spinner')
    # test_of('SpinButton::button_down')
    my $aoSpinner = $aoCombo->spinner();
    my $aoDown = $aoSpinner->button_down(); 
    # test_of('accSelect')
    $aoDown->accSelect(SELFLAG_TAKEFOCUS()); 
    # test_of('AO::click')
    $aoDown->click(); 
    # test_of('Combobox::edit_box')
    my $aoEdit = $aoCombo->edit_box(); 
    # test_of('get_accValue')
    print "New wattage: " . $aoEdit->get_accValue() . "\n" unless $quiet; 

    # Context menu
    my $aoHollow = $aoPlaypen->dig
      (+['{client}', '{window}RightClickMe']);
    # test_of('AO::context_menu')
    my $cxmenu = $aoHollow->context_menu();
    # test_of('MenuPopup::menuPick')
    clearEvents(); # so we can reliably detect the dialog box that opens
    $cxmenu->menuPick(+['Octosaurus']); 

    # OK-box
    my $okbox = waitForEvent(+{'event'=>EVENT_SYSTEM_DIALOGSTART()}, 5);
    my $okbtn = $okbox->dig(+['{dialog}', '{window}OK', '{push button}'], +{'min'=>1});
    $okbtn->doActionIfDefault('Press'); # test_of('doActionIfDefault.is_default')

    # Switch tabs
    my $aoTreeTabBtn = $aoPlaypen->dig
      (+['{client}', '{window}', '{page tab list}', '{page tab}Tree']);
    clearEvents();
    # test_of('Switch')
    $aoTreeTabBtn->dda_Switch(); 
    # test_of('awaitCalm')
    awaitCalm(); 

    # Tree-view
    #    Win32::ActAcc::IEH()->debug_spin(3);
    my $aoOutline = $aoPlaypen->dig
      (+[
         '{client}',
         '{window}',
         '{page tab list}',
         '{window}Tree',
         '{client}',
         '{window}',
         '{outline}']);
    # visit and print-out elements without expanding outline 
    # (the elements are mostly invisible+offscreen).
    my $flatTreeItemCount=0;
    {
      my $iter = $aoOutline->iterator();
      $iter->open();
      my $aoi;
      while ($aoi = $iter->nextAO())
        {
          print $aoi->describe() . "\n" unless $quiet;
          $flatTreeItemCount++;
        }
      $iter->close();
    }
    die($flatTreeItemCount) unless 16==$flatTreeItemCount;
    # Use active iterator
    print "\nUsing active iterator:\n" unless $quiet;
    {
      my $iter = $aoOutline->iterator( +{'active'=>1} ); 
      $iter->open();
      Time::HiRes::sleep(0.25); # just for viewer's pleasure
      my $aoi;
      while ($aoi = $iter->nextAO())
        {
          print $aoi->describe() . "\n" unless $quiet;
        }
      $iter->close(); # closes-up the outline it expanded!
    }
    # Select Stuff-Animal-Mammals-Dogs-Large.
    # test_of('OutlineIterator')
    # test_of('dig.scalar_context.outline')
    my $aoLarge = $aoOutline->dig
      (+[
         'Stuff', 
         'Animal', 
         'Mammals', 
         'Dogs', 
         'Large'], 
      );
    print "Large dog: " . $aoLarge->describe() . "\n" unless $quiet;
    $aoLarge->click();

    # Close app
    my $aoOK = $aoPlaypen->dig
      (+['{client}', '{window}OK', '{push button}'] );
    # test_of('dda_Press')
    $aoOK->dda_Press(); 

    # Debrief
    print "Count of AOs discovered by NavIterator but not AOIterator: $Win32::ActAcc::AONavIterator::AONavFruitsFromNavOnly\n" unless $quiet;
  }

sub tree_node_test
  {
    my $subsub = shift;
    return sub 
      {
        my ($vao,$tree)=@_; 
        if (!$vao->either_INVISIBLE_or_negative() && ($tree->level() < 4)) 
          { 
            &$subsub($vao,$tree);
          } 
        else 
          {
            $tree->prune();
          }
      };
  }

sub test_iterators_for_consistency
  {
    my $ao = shift;
    my %w;
    # test_of('tree')
    $ao->tree(
              tree_node_test(sub{my ($vao,$tree)=@_; $w{$vao->describe(1)}=$vao;})
             );

    for my $technique ('perfunctory', 'nav')
      {
        print "$technique:\n" unless $quiet;
        my %p;
        $ao->tree
          (
           tree_node_test
           (sub
            {
              my ($vao,$tree)=@_; 
              $p{$vao->describe(1)}=$vao; 
              print ' 'x$tree->level() . $vao->describe(1)."\n" unless $quiet;
            }
           ) ,
           +{$technique=>1});
        for (keys %p)
          {
            if(! exists($w{$_})) { die "$technique unexpectedly found $_\n"; }
          }
        for (keys %w)
          {
            if (!exists($p{$_})) { die "$technique unexpectedly did NOT find $_\n"; }
          }
      }
  }


