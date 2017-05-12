# Copyright 2004, Phill Wolf.  See README.

# Win32::ActAcc (Active Accessibility)

# This sample finds each-and-every already-open Notepad window and
# traverses its application and System menus, displaying the menu
# choices on the console window.

use Win32::OLE;
use Win32::ActAcc qw(:all);
use Win32::GuiTest;

# Active Accessibility uses OLE
Win32::OLE->Initialize();

# You may uncomment this line to watch the actions 
# Win32::ActAcc is taking.
#$Win32::ActAcc::LOG_ACTIONS = 1;

&main;

sub main
  {
    clearEvents();

    my @app = 
      Desktop()->
        dig(
            +[
              '{client}',
              +{
                'role'=>ROLE_SYSTEM_WINDOW(),
                'get_accName'=>qr/Notepad$/,
                'visible'=>1,
                'code'=>sub
                {
                  my $ao = shift;
                  my $state = $ao->get_accState();
                  return undef
                    unless ($state & (STATE_SYSTEM_FOCUSED() 
                                      | STATE_SYSTEM_FOCUSABLE()));
                  1;
                }
               }
             ],
            +{
              'min'=>0,
              'trace'=>0
             }
           );

    if (!@app)
      {
        die("I did not find a Notepad window.\n");
      }

    foreach my $ao (@app)
      {
        print "\n\n\n=== App window: ". $ao->describe() . " ===\n";

        $ao->accSelect(SELFLAG_TAKEFOCUS());
        awaitCalm();

        my %menubar; # describe() -> AO (helps avoid duplicates)
        $ao->
          tree(
               sub
               {
                 my ($ao, $monkey) = @_;
                 if ($ao->either_INVISIBLE_or_negative())
                   {
                     $monkey->prune();
                     return;
                   }
                 my $r = $ao->get_accRole();
                 if ($r == ROLE_SYSTEM_MENUBAR())
                   {
                     $menubar{$ao->describe()} = $ao;
                     $monkey->prune();
                     return;
                   }
                 elsif (($r != ROLE_SYSTEM_WINDOW()) 
                        && ($r != ROLE_SYSTEM_CLIENT())
                        && ($r != ROLE_SYSTEM_PANE())
                        && ($r != ROLE_SYSTEM_TOOLBAR()))
                   {
                     $monkey->prune();
                     return;
                   }
               },
               +{ 'trace'=>0 }
              );

        foreach my $ao (values %menubar)
          {
            print "\n  --- Menubar: " . $ao->describe() . "\n";
            $ao->
              tree
                (
                 sub 
                 {
                   my ($ao, $monkey) = @_;
                   
                   print ' 'x($monkey->level()).$ao->describe()."\n";
                   
                   if ($monkey->level() > 2) # 299
                     {
                       $monkey->prune();
                     }
                 },
                 +{ 'active'=>1, 'trace'=>0 } # optional iterator flags-hash
                );
          }

      }

  }
