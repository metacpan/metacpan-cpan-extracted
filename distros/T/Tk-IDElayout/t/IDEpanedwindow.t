#
#  Test Case for the Tk::IDEpanedwindow
#
#   Expected Results
#     After initial window creation, frames inside the panewindow should resize proportionaly when the
#       whole window is resized

# With nothing on the command line, the script will quit after the text completes
my $dontExit = shift @ARGV;

use Tk;

use Tk::IDEpanedwindow;

print "1..1\n";

my $TOP = MainWindow->new;


# top level horizontal paned window ################################
my $pwH = $TOP->IDEpanedwindow(qw/-sashpad 1 -sashwidth 3 -sashrelief groove/);;
$pwH->pack(qw/-side top -expand yes -fill both /);

    my $label1 = $pwH->Label(-text => "This is the\nleft side", -background => 'yellow');

    my $Frame2 = $pwH->Frame();
    
    $pwH->add($label1, -expandfactor => 1, $Frame2, -expandfactor => 1);
    
#######################################################################################
## vertical paned window
    my $pw2 = $Frame2->IDEpanedwindow(qw/-orient vertical  -sashpad 1 -sashwidth 10 -sashrelief groove/);
    $pw2->pack(qw/-side top -expand yes -fill both /);

    my $paneList = [
        'List of Tk Widgets', qw/
        button
        canvas
        checkbutton
        entry
        frame
        label
        labelframe
        listbox
        menu
        menubutton
        message
        panedwindow
        radiobutton
        scale
        scrollbar
        spinbox
        text
        toplevel
        /,
    ];

    my $f1 = $pw2->Frame;
    my $lb = $f1->Listbox(-listvariable => $paneList);
    $lb->pack(qw/-fill both -expand 1/);
    my ($fg, $bg) = ($lb->cget(-foreground), $lb->cget(-background));
    $lb->itemconfigure(0, 
	-background => $fg,
        -foreground => $bg,
    );

    my $f2 = $pw2->Frame;
    my $t = $f2->Text(qw/-width 30 -wrap none -height 5/);

    $t->pack(qw/-fill both -expand 1 /);
    $t->insert('1.0', 'This is just a normal text widget');
    
    $pw2->add($f1, -expandfactor => 1,  $f2, -expandfactor => 1);
    #$pw2->paneconfigure( $f2, -sticky => 'nsew');
    #$TOP->bind('<Motion>', sub{ print "Motion\n"});

    # Quit the test after two seconds
    unless( $dontExit){
            $TOP->after(2000,sub{
                    print "Test Complete... Exiting\n";
                    $TOP->destroy;
            });
    }
    
MainLoop;

print "ok 1\n";



