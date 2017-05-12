##==============================================================================
## test.pl
##==============================================================================
## $Id: test.pl,v 1.1 2002/03/18 01:34:25 kevin Exp $
##==============================================================================

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..2\n"; }
END {print "not ok 1\n" unless $loaded;}
use Tk;
use Tk::Task;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

eval {
	use strict;
	use vars qw($mw $task $label_text $counter);
	
	$mw = MainWindow->new;
	$mw->title('Test of Tk::Task');
	$mw->Label(
		-width => 60,
		-textvariable => \$label_text,
	)->pack(-fill => 'both', -expand => 1);
	
	$mw->Button(
		-text => 'Exit',
		-command => sub {
			$mw->destroy;
		},
	)->pack();
	
	$mw->Task(
		[ [
			sub {
				my $task = shift;
				if (++$counter > 4) {
					$task->break;
				} else {
					$label_text = "One potato"; 
				}
			}, TASK
		  ],
		  [
			sub {
				my $task = shift;
				$label_text = "Two potato";
			}, TASK
		  ],
		  [
			sub {
				my $task = shift;
				$label_text = "Three potato";
			}, TASK
		  ],
		  [
			sub {
				my $task = shift;
				$label_text = "Four!";
			}, TASK
		  ],
		],
		[
			sub {
				$mw->destroy;
			},
		],
	)->start;
	
	MainLoop;
};

if ($@) {
	print "not ok 2\n";
} else {
	print "ok 2\n";
}

##==============================================================================
## $Log: test.pl,v $
## Revision 1.1  2002/03/18 01:34:25  kevin
## Initial revision
##
##==============================================================================
