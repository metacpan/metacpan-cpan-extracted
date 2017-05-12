# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..3\n"; }
END {print "not ok 1\n" unless $loaded;}
use Tk;
use Tk::CursorControl;
$loaded = 1;
print "Test program will autodestruct in 60 seconds..\n";
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

my %button;
my $trans='hide';

my $mw=tkinit;
$mw->after(60*1000,sub{$mw->destroy});
$mw->protocol('WM_DELETE_WINDOW'=>sub{$mw->destroy});
$cursor=$mw->CursorControl;
$cursor1=$mw->CursorControl;
if ($cursor eq $cursor1){
	print "This is a GOOD thing. It recognizes the original object!!\n";
	print "ok 2\n";
}
else {
	print "not ok 2\n";
}

$button{one} = $mw->Button(-text=>'Press, Hold and Move to see a confined cursor')->grid(-sticky=>'ew',-row=>0, -column=>0);

#test a few aliased commands
$button{one}->bind('<ButtonPress-1>',sub{$cursor->jail($button{one})});
$button{one}->bind('<ButtonRelease-1>',sub{$cursor->free});

$button{two}= $mw->Button(-text=>'Do you see a cursor when over this button ??',-cursor=>'hand2')->grid(-sticky=>'ew',-row=>1, -column=>0);
$cursor->hide($button{two});

$mw->Checkbutton(
	-text=>'<<--Hide Cursor?',
	-onvalue=>'hide',
	-offvalue=>'show',
	-variable=>\$trans,
	-command=>\&toggle)->grid(-sticky=>'w',-row=>1, -column=>1);

$mw->Button(-text=>'Jump to Middle of Button 1',
	-command=>sub{
		$cursor->warpto($button{one});
	})->grid(-row=>2, -column=>0,-sticky=>'ew');
$mw->Button(-text=>'Jump to the NorthWest corner of Button 1',
	-command=>sub{
		$cursor->warpto($button{one},0,0);
	})->grid(-row=>3, -column=>0, -sticky=>'ew');

$mw->Button(-text=>'Jump to Northeast corner of screen',
	-command=>sub{
		$cursor->warpto($mw->screenwidth,0);
	})->grid(-row=>4, -column=>0, -sticky=>'ew');

MainLoop;

print "ok 3\n";

sub toggle {
	$cursor->${trans}($button{two});
}

__END__


