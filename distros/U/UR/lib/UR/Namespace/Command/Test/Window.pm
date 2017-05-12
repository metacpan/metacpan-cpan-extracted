
use strict;
use warnings;

use above 'UR';

package UR::Namespace::Command::Test::Window;
require UR;
our $VERSION = "0.46"; # UR $VERSION;

UR::Object::Type->define(
    class_name => __PACKAGE__,
    is => 'Command',
    has => {
        src => {
            is_optional => 1,
            is_many => 1,
            shell_args_position => 1
        }
    },
    doc => 'repl tk window'
);

sub execute {
    my $self = shift;
    require Tk;
    
    my $src = [$self->src];
    if (@$src > 0) {
        for my $code (@$src) {
            no strict;
            no warnings;
            eval $code;
            print $@;
        }
    }
    else {
        UR::Namespace::Command::Test::Window::Tk->activate_with_gtk_support;
    }

}

package UR::Namespace::Command::Test::Window::Tk;;

our $tmp;
our $workspace;

sub new {
    if ($^O eq 'MSWin32' || $^O eq 'cygwin') {
        #$tmp = $ENV{TEMP};
        $tmp ||= 'C:/temp';
    }
    else {
        $tmp = $ENV{TMPDIR};
        $tmp ||= '/tmp';
    }

    # Make a window
    my $debug_window  = new MainWindow(-title=>"Debug");

    # The top pane is for inputing Perl
    my $in  = $debug_window->Scrolled("Text", -scrollbars=>'os',-exportselection => 1)->pack(-expand => 0, -fill => 'x');

    # The middle is a frame with an eval button
    my $frame  = $debug_window->Frame()->pack(-expand=>0,-fill=>'both',-anchor=>'nw');
    my $go  = $frame->Button(-text => 'eval()', -command => sub { &exec_debug($debug_window) } )->pack(-expand => 0, -fill => 'none', -anchor=>'nw', -side=>'left');
    
    # The bottom is a pane for output
    my $out = $debug_window->Scrolled("Text", -scrollbars=>'osoe',-wrap => 'none')->pack(-fill => 'both', -expand => 1);

    # See if there is a workspace file for an app with this name
    my $user = $ENV{USER};
    $user ||= 'anonymous';
    
    $0 =~ /([^\/\s]+)$/;
    my $core_name = $1;
    
    $workspace ||= "$user\@$core_name";
    print STDOUT "Workspace is $workspace\n";
    
    if (open(LAST_WORKSPACE,"${tmp}/$workspace"))
    {
        while (<LAST_WORKSPACE>)
        {
            $in->insert("end",$_);
        }
        close LAST_WORKSPACE;
    }

    $debug_window->{in} = $in;
    $debug_window->{out} = $out;

    return $debug_window;
}

sub new_gtk {
    require Gtk;
    my $debug_window = DebugWindow::new();
    my $frame = $debug_window->Frame()->pack(-expand=>0,-fill=>'both',-anchor=>'nw');
    my $continuous_refresh = 0;

    $frame->Button(-text => 'One Gtk', -command => sub 
        {
            Gtk->main_iteration
        })->pack(-expand => 0, -fill => 'none', -anchor=>'nw', -side=>'left');
        
        
    $frame->Button(-text => 'All Gtk', -command => sub 
        {
            while (Gtk->events_pending) 
            {
                Gtk->main_iteration;    
            }
        })->pack(-expand => 0, -fill => 'none', -anchor=>'nw', -side=>'left');
       
    my $handleGtk; 
    $handleGtk = sub
    {
        return unless (Exists($debug_window) and $continuous_refresh);
        Gtk->main_iteration;
        
        my $delay = (Gtk->events_pending ? 5 : 500);            
        Tk->after($delay, $handleGtk);
    };
    
    $frame->Button
    (
        -text => 'Gtk Cont', 
        -command => sub 
            { 
                $continuous_refresh = (not $continuous_refresh);
                &$handleGtk;
            } 
    )->pack(-expand => 0, -fill => 'none', -anchor=>'nw', -side=>'left');
}

sub activate {
    my $window=&new;
    $window->waitWindow();
    Tk->MainLoop;

}

sub activate_with_gtk_support {
    &new_gtk;
    Tk->MainLoop;
}

sub hook_button {
    
}

sub hook_gtk_button {
    my $gtk_button = shift;
    $gtk_button->signal_connect('button_press_event', sub
    {
        my ($self,$event) = @_;
        
        # Test the Gtk widget event to see which button was clicked.
        
        if ($event->{button} == 3)
        {
            # Instantiate the debug window with the special Gtk buttons on it.
            my $debug_window = DebugWindow::new_gtk();
            Tk->MainLoop();
        }
        return(1);
    });
}

sub show_new {
    # Legacy function
    &new(@_);
}

sub exec_debug {
    my $self = $_[0];
    my $in = $self->{in};
    my $out = $self->{out};

    # Clear the results window.
    $out->delete("1.0","end");

    # Get all of the text in the workspace window.    
    my $perl = $in->get("1.0","end");    
    
    # If there is a valid selection override the above with just the selected text.
    eval { $perl = $in->get("sel.first","sel.last"); };
    
    # Open a temporary output file to catch the STDOUT
    my $filename = "${tmp}/${workspace}_output";
    
    open (DEBUG_FH,">$filename") or die "Failed to open temp file '$filename': $!\n";
    
    # Redirect STDOUT temporarily
    *ORIG_STDOUT = *STDOUT;
    *STDOUT = *DEBUG_FH;
    
    # Run the perl.
    eval ("package main;\n" . $perl);

    # Print any errors
    print $@;

    # Restore STDOUT
    *STDOUT = *ORIG_STDOUT;
    close DEBUG_FH;
    
    # Get the script output
    my $fh = IO::File->new("${tmp}/${workspace}_output");
    my $text;
    if ($fh)
    {
    	my @text = $fh->getlines;
	$fh->close;
    	$text = join("",@text);
    }
    
    # Print to the console as well as the result widget.
    print $text;
    
    # For some reason embedded \n causese every other row to disappear.
    # Split on line boundaries and feed the output to the widget in pieces.
    foreach my $row (split /$/, $text) {
        $out->insert('end',$row);
    }
    
    # Save the whole workspace like we do when the app closes
    save_workspace($self);
}

sub save_workspace {
    my $self = $_[0];
    my $in = $self->{in};
    
    # Save the workspace
    if (open (SCRIPT_FH, ">${tmp}/$workspace"))
    {
        print SCRIPT_FH $in->get("1.0","end");
        close SCRIPT_FH;
	print "Saved to ${tmp}/$workspace\n";
    }
    else
    {
        print STDOUT "Failed to save the current workspace (${tmp}/$workspace)!";
    }
}

1;

