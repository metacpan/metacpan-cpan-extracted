package Tk::Wizard::Tasks;

use strict;
use warnings;
use warnings::register;
use lib "../../";
use vars '$VERSION';
$VERSION = do { my @r = ( q$Revision: 2.80 $ =~ /\d+/g ); sprintf "%d." . "%03d" x $#r, @r };

use vars qw(@ISA @EXPORT);
BEGIN {
	eval { require Log::Log4perl; };

	# No Log4perl so bluff: see Log4perl FAQ
	if($@) {
		no strict qw"refs";
		*{__PACKAGE__."::$_"} = sub { } for qw(TRACE DEBUG INFO WARN ERROR FATAL);
	}

	# Setup log4perl
	else {
		no warnings;
		no strict qw"refs";
		require Log::Log4perl::Level;
		Log::Log4perl::Level->import(__PACKAGE__);
		Log::Log4perl->import(":easy");
		if ($Log::Log4perl::VERSION < 1.11){
			*{__PACKAGE__."::TRACE"} = *DEBUG;
		}
	}

    require Exporter;    # Exporting Tk's MainLoop so that
    @ISA    = ( "Exporter", );    # I can just use strict and Tk::Wizard without
    @EXPORT = ("MainLoop");       # having to use Tk
}

use Carp ();
use Tk::LabFrame;
use Tk::DirTree;
use Tk::Wizard::Image;

my $WINDOZE = ($^O =~ m/MSWin32/i);
my $dir_term 	 = $WINDOZE ? 'folder' : 'directory';
my $dir_term_ucf = ucfirst $dir_term;


=head1 NAME

Tk::Wizard::Tasks - C<Tk::Wizard> pages to perform sequential tasks

=head1 SYNOPSIS

Currently automatically loaded by C<Tk::Wizard>, though this
behaviour is deprecated and is expected to change in 2008.

=head1 DESCRIPTION

Adds a number of methods to C<Tk::Wizard>, to allow the end-user to access
the filesystem.

=head1 METHODS


=head2 addTaskListPage

Adds a page to the Wizard that will perform a series of tasks, keeping the user
informed by ticking-off a list as each task is accomplished.

Whilst the task list is being executed, both the I<Back> and I<Next> buttons
are disabled.

Parameters are as for L</blank_frame>, plus:

=over 4

=item -tasks

The tasks to perform, supplied as a reference to an array, where each
entry is a pair (i.e. a two-member list), the first of which is a text
string to display, the second a reference to code to execute.

=item -delay

The length of the delay, in milliseconds, after the page has been
displayed and before execution the task list is begun.
Default is 1000 milliseconds (1 second).
See L<Tk::after>.

=item -continue

Display the next Wizard page once the job is done: invokes the
callback of the I<Next> button at the end of the task.

=item -todo_photo

=item -doing_photo

=item -ok_photo

=item -error_photo

=item -na_photo

Optional: all L<Tk::Photo|Tk::Photo> objects, displayed as appropriate.
C<-na_photo> is displayed if the task code reference returns an undef value, otherwise:
C<-ok_photo> is displayed if the task code reference returns a true value, otherwise:
C<-error_photo> is displayed.
These have defaults taken from L<Tk::Wizard::Image|Tk::Wizard::Image>.

=item -label_frame_title

The label above the L<Tk::LabFrame|Tk::LabFrame> object which
contains the task list.  Default label is the boring C<Performing Tasks:>.

=item -frame_args

Optional: the arguments to pass in the creation of the C<Frame> object used to contain the list.

=item -frame_pack

Optional: array-refernce to pass to the C<pack> method of the C<Frame> containing the list.

=back

=head3 TASK LIST EXAMPLE

  $wizard->addTaskListPage(
    -title => "Toy example",
    -tasks => [
      "Wait five seconds" => sub { sleep 5; 1; },
      "Wait ten seconds!" => sub { sleep 10; 1; },
      ],
    );

=cut

sub Tk::Wizard::addTaskListPage {
    my $self = shift;
    my $args = {@_};

    $self->addPage( sub { $self->_page_taskList($args) } );
}

sub Tk::Wizard::_page_taskList {
    my $self = shift;
    my $args = shift;
    my @tasks;
    my @states = qw[ todo doing ok error na ];
    my $photos = {};
    foreach my $state (@states) {
        my $sArg = "-" . $state . "_photo";
        if ( !$args->{$sArg} ) {
            $photos->{$state} = $self->Photo( $state, -data => $Tk::Wizard::Image::TASK_LIST{$state} );
        }
#        elsif (!-r $args->{$sArg}
#            || !$self->Photo( $state, -file => $args->{$sArg} ) )
#        {
#            warn "# Could not read $sArg from " . $args->{$sArg};
#        }
		elsif ( ref($args->{$sArg}) eq 'SCALAR' ) {
			$photos->{$state} = $self->Photo(
				$state,
				-data => ${$args->{$sArg}}
			) || WARN "Could not read $sArg from referenced data " . ${$args->{$sArg}};
		}
		elsif (-r $args->{$sArg}) {
			$photos->{$state} = $self->Photo(
				$state,
				-file => $args->{$sArg}
			) || WARN "Could not read $sArg from file " . $args->{$sArg};
		}
		else {
			WARN "Could not read $sArg from " . $args->{$sArg};
		}
    }

    $args->{-frame_pack} = [qw/-expand 1 -fill x -padx 30 -pady 10/]
      unless $args->{-frame_pack};

    $args->{-frame_args} = [
        -background => $self->{background},
        -relief     => "flat",
        -bd         => 0,
        -label => $args->{-label_frame_title} || "Performing Tasks: ",
        -labelside => "acrosstop"
	] unless $args->{-frame_args};

    my $frame = $self->blank_frame(
        -title    => $args->{-title}    || "Performing Tasks",
        -subtitle => $args->{-subtitle} || "Please wait whilst the Wizard performs these tasks.",
        -text     => $args->{-text}     || "",
        -wait     => $args->{ -wait },
    );

    if ( $#{ $args->{-tasks} } > -1 ) {
        my $task_frame =
          $frame->LabFrame( @{ $args->{-frame_args} }, -background => $self->{background}, )
          ->pack( @{ $args->{-frame_pack} }, );

        foreach ( my $i = 0 ; $i <= $#{ $args->{-tasks} } ; $i += 2 ) {
            my $icn = "-1";
            my $p = $task_frame->Frame( -background => $self->{background}, )->pack( -side => 'top', -anchor => "w" );
            if ( exists $photos->{todo} ) {
                $icn = $p->Label(
                    -image      => "todo",
                    -anchor     => "w",
                    -background => $self->{background},
                )->pack( -side => "left" );
            }
            $p->Label(
                -font       => $self->{defaultFont},
                -text       => @{ $args->{-tasks} }[$i],
                -anchor     => "w",
                -background => $self->{background},
            )->pack( -side => "left" );
            push @tasks, [ $icn, @{ $args->{-tasks} }[ $i + 1 ] ];
        }

    }

    else {
        $args->{-delay} = 1;
    }

    if ( $args->{ -wait } ) {
        # If we got a non-zero -wait argument, we must be part of an
        # automated test.  In any case, this page is going to auto-flip to
        # the next page soon (via a call to $widget->after).  We do NOT
        # want to start executing our tasks, only to have the Wizard flip
        # to the next page while we're still executing, because then we'll
        # be trying to update Photos that no longer exist (or worse).
    }

    else {
        # Do not let the user click any buttons while we're working:
        $self->{nextButton}->configure( -state => "disabled" )
          if Tk::Exists( $self->{nextButton} );

        $self->{backButton}->configure( -state => "disabled" )
          if Tk::Exists( $self->{backButton} );

        $frame->after(
            $args->{-delay} || 1000,

            sub {
                foreach my $task (@tasks) {
                    if ( Tk::Exists( $task->[0] ) ) {
                        $task->[0]->configure( -image => "doing" );
                        $task->[0]->update;
                    }
                    my $result = &{ $task->[1] };
                    if ( Tk::Exists( $task->[0] ) ) {
                        $task->[0]->configure(
                            -image => defined($result)
                            ? $result
                                  ? 'ok'
                                  : 'error'
                            : 'na'
                        );
                        $task->[0]->update;
                    }
                }

                # We're all done, the user can click buttons again:
                $self->{backButton}->configure( -state => "normal" ) if Tk::Exists( $self->{backButton} );

                if ( Tk::Exists( $self->{nextButton} ) ) {
                    $self->{nextButton}->configure( -state => "normal" );
                    # RT#54904
                    $self->{nextButton}->invoke if $args->{ -continue };
                }
              },

        );
    }
    return $frame;
}




1;

=head1 AUTHOR

Lee Goddard (lgoddard@cpan.org).

=head1 COPYRIGHT

Copyright (C) Lee Goddard, 11/2002 - 01/2008 ff.

Made available under the same terms as Perl itself.
