# Copyright 2001, 2004, Phill Wolf.  See README.

# Win32::ActAcc (Active Accessibility)

# This sample runs Notepad (which must be on the Path), "types" a
# prompt from Eliza into Notepad, and waits for you to respond and
# press Enter.  The conversation continues until you close Notepad.

# Note that it only works if you keep the cursor at the end of the
# editing area.  It is, in short, quite a silly use of Notepad.

use strict;
use Win32::OLE;
use Win32::GuiTest qw(SendKeys);
use Win32::ActAcc;
use Chatbot::Eliza;

Win32::OLE->Initialize();
srand( time ^ ($$ + ($$ << 15)) );  # from Eliza sample
notepadEliza(StartNotepad());

sub StartNotepad
{
    my $eh = Win32::ActAcc::createEventMonitor(1);
    Win32::ActAcc::clearEvents();
    sleep(3);
    system("start notepad");
    my $aoNotepad = Win32::ActAcc::waitForEvent(
	+{ 
      'event'=>Win32::ActAcc::EVENT_OBJECT_SHOW(),
	  'name'=>qr/Notepad/,
	  'role'=>Win32::ActAcc::ROLE_SYSTEM_WINDOW()
     },
     +{
      'trace'=>1
     });
    die unless defined($aoNotepad);
    return $aoNotepad;
}

sub textArea
{
    my $aoNotepad = shift;
    my $ta = $aoNotepad->drill("{editable text}", +{'max'=>1, 'min'=>1});
    return $ta;
}

sub notepadEliza
{
    my $aoNotepad = shift;
    print "Notepad: " . $aoNotepad->describe() . "\n";

    my $ta = textArea($aoNotepad);

    # Make a note of the HWND of the Notepad window,
    # for comparison with window-close events.
    my $hwndNotepad = $aoNotepad->WindowFromAccessibleObject();

    my $eliza = new Chatbot::Eliza;

    # The introductory message comes from Emacs' "doctor".
    my $msgToUser = "I am the psychotherapist.  Please, describe your problems. {ENTER}Press Enter to signal me to answer. {ENTER}When the consultation is over, please close Notepad.{ENTER}{ENTER}";
    SendKeys($msgToUser);
    sleep(1);
    Win32::ActAcc::clearEvents();
    my $x = Win32::ActAcc::IEH()->eventLoop
      (
       +[
         # Watch for an event signaling a change to the text-field.
        +{'event'=>Win32::ActAcc::EVENT_OBJECT_VALUECHANGE(), 
        'role'=>Win32::ActAcc::ROLE_SYSTEM_TEXT(),
        'hwnd'=>$ta->WindowFromAccessibleObject(),
        'code'=> sub
            {
                my $v = $ta->get_accValue();
                # Does the text END with a carriage-return?
                if ($v =~ /(.+)\n\z/)
                {
                    my $p = $1;
                    if ($p && ($p !~ / \z/))
                    {
                        # Display user's remark
                        print "$p\n";
                        # Consult Eliza
                        $msgToUser = "{ENTER}"
                          . join('', 
                                 map("\{$_\}",
                                     split(//,$eliza->transform($p)))) 
                            . " {ENTER}{ENTER}";
                        # Issue response
                        SendKeys($msgToUser);
                        sleep(1);
                        Win32::ActAcc::clearEvents();
                    }
                }
                return undef;
            }
        }

        , 
         # Watch also for event signaling Notepad closed.
        +{'event'=>Win32::ActAcc::EVENT_OBJECT_DESTROY(), 
        'hwnd'=>$hwndNotepad,
        'code'=> sub
            {
              print STDERR "Exiting because Notepad window is being destroyed\n";
                1;
            }
        }


    ]);
}

