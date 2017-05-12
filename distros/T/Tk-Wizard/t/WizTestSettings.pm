package WizTestSettings;

use strict;
use warnings;

=head1 NAME

Tk::Wizard::Testing - used in wizard testing

=head1 DESCRIPTION

One subroutine, C<add_test_pages>, that adds pages to a wizard.

=head1 VARIABLES

C<$VERSION> should be set to the release version of C<Wizard.pm> for automated tests.

=cut

use Carp;

our $VERSION; # see POD

	# Set our version to be the relevant $TK::Wizard::VERSION
	$VERSION = do { my @r = ( q$Revision: 2.084 $ =~ /\d+/g ); sprintf "%d." . "%03d" x $#r, @r };

	# Require the correct version
	use lib "../lib";
	eval 'use Tk::Wizard ' . $VERSION . ' ":old"';
	die $@ if $@;

	# Log l4p is we have it
	eval { require Log::Log4perl; };

	# No l4p - add stubs
	if ($@) {
		no strict qw(refs);
		*{"main::$_"} = sub { } for qw(DEBUG INFO WARN ERROR FATAL);
		*{"WizTestSettings::$_"} = sub { } for qw(DEBUG INFO WARN ERROR FATAL);
	}

	# Have l4p - configure
	else {
		no warnings;
		require Log::Log4perl::Level;
		Log::Log4perl::Level->import(__PACKAGE__);
		Log::Log4perl->import(":easy");

		if (not Log::Log4perl::initialized()){
			my $log_conf;
			# my ($fn) = $0 =~ /[^\/]+$/;

			$log_conf = "log4perl.logger                   		= ERROR, Screen\n";
			#  $log_conf.= "log4perl.logger.Tk.Wizard.Installer		= ALL, Screen
			#  		        log4perl.additivity.Tk.Wizard.Installer	= 0\n";


			if ($Log::Log4Perl::VERSION >= 1.11){
				$log_conf .= "log4perl.appender.Screen       	= Log::Log4perl::Appender::ScreenColoredLevels\n";
				$log_conf .= "log4perl.appender.Screen.layout	= PatternLayout::Multiline\n";
			} else {
				$log_conf .= "log4perl.appender.Screen        	= Log::Log4perl::Appender::Screen\n";
				$log_conf .= "log4perl.appender.Screen.layout	= PatternLayout\n";
			}

			$log_conf .= q[
				log4perl.appender.Screen.stderr   				= 1
				log4perl.appender.Screen.layout.ConversionPattern = %7p | %-70m | %M %L%n
			];

			#	log4perl.appender.File            = Log::Log4perl::Appender::File
			#	log4perl.appender.File.filename   = ] . ($ENV{AD2_TEST_LOG} || "$ENV{HOME}/logs/$fn.log") . q[
			#	log4perl.appender.File.mode       = append
			#	log4perl.appender.File.autoflush  = 1
			#	log4perl.appender.File.layout     = PatternLayout::Multiline
			#	log4perl.appender.File.layout.ConversionPattern = %7p | %-70m | %M %L%n
			Log::Log4perl->init( \$log_conf );
		}
	}

sub add_test_pages {
	my ($wiz, $args) = (shift, ref($_[0])? shift : {@_});

    my ( $dir_select, $file_select, $mc1, $mc2, $mc3 );

	$args->{-wait} ||= $ENV{TEST_INTERACTIVE}? -1 : 250,

    $dir_select = $^O =~ m/MSWin32/i ? 'C:\\' : '/';

    $wiz->addPage( sub {
        $wiz->blank_frame(
            -wait     => $args->{-wait},
            -title    => "Intro Page Title ($wiz->{-style} style)",
            -subtitle => "Intro Page Subtitle ($wiz->{-style} style)",
            -text     => sprintf( "This is the Intro Page of %s ($wiz->{-style} style)", __PACKAGE__ ),
        );
    });

    my $s = "This is the text contents for the Tester TextFrame Page ($wiz->{-style} style).
It is stored in a string variable,
and a reference to this string variable is passed to the addTextFramePage() method.";
    $wiz->addTextFramePage(
        -wait       => $args->{-wait},
        -title      => "Tester TextFrame Page Title ($wiz->{-style} style)",
        -subtitle   => "Tester TextFrame Page Subtitle ($wiz->{-style} style)",
        -text       => "This is the text of the Tester TextFrame Page ($wiz->{-style} style)",
        -boxedtext  => \$s,
        -background => 'yellow',
    );

    $wiz->addDirSelectPage(
        -wait       => $args->{-wait},
        -title      => "Tester DirSelect Page Title ($wiz->{-style} style)",
        -subtitle   => "Tester DirSelect Page Subtitle ($wiz->{-style} style)",
        -text       => "This is the Text of the Tester DirSelect Page ($wiz->{-style} style)",
        -nowarnings => 88,
        -variable   => \$dir_select,
        -background => 'yellow',
    );

    $wiz->addFileSelectPage(
        -wait       => $args->{-wait},
        -title      => "Tester FileSelect Page Title ($wiz->{-style} style)",
        -subtitle   => "Tester FileSelect Page Subtitle ($wiz->{-style} style)",
        -text       => "This is the Text of the Tester FileSelect Page ($wiz->{-style} style)",
        -variable   => \$file_select,
        -background => 'yellow',
    );

    $wiz->addMultipleChoicePage(
        -wait     => $args->{-wait},
        -title    => "Tester Multiple-Choice Page Title ($wiz->{-style} style)",
        -subtitle => "Tester Multiple-Choice Page Subtitle ($wiz->{-style} style)",
        -text     => sprintf( "This is the Multiple-Choice Page of %s ($wiz->{-style} style)", __PACKAGE__ ),
        -choices  => [
            {
                -variable => \$mc1,
                -title    => "Option number one",
                -subtitle => "This is the first of three options, any of which may be selected.",
                -checked  => 0,
            },
            {
                -variable => \$mc2,
                -title    => "The Second option is here",
                -subtitle =>
                  "This is the description of the second option.\nNote that this one is selected by default.",
                -checked => 1,
            },
            {
                -variable => \$mc3,
                -title    => "This third option has no subtitle.",
                -checked  => 0,
            },
        ],    # -choices
        -background => 'yellow',
    );

    $wiz->addTaskListPage(
        -wait     => $args->{-wait},
        -title    => "Tester Task List Page Title ($wiz->{-style} style)",
        -subtitle => "Tester Task List Page Subtitle ($wiz->{-style} style)",
        -text     => "This is the Text of the Tester Task List Page ($wiz->{-style} style)",
        -continue => 2,
        -tasks    => [
            "This task will succeed"                       => \&_task_good,
            "This task will fail!"                         => \&_task_fail,
            "This task is not applicable"                  => \&_task_na,
            "Wizard will exit as soon as this one is done" => \&_task_good,
        ],
        -background => 'yellow',
    );

    return $wiz;
}

=head2 Show

Before we actually show the Tester Wizard,
we add one final "finish" page.
This allows the user to add more pages to this Tester Wizard,
which will appear after the default pages,
but there will always be a "content-poor" finish page.

=cut

sub Show {
    my $wiz = shift;
    $wiz->addPage(sub {
        $wiz->blank_frame(
            -wait  => $wiz->{_wait_},
            -title => "Tester Wizard last page ($wiz->{_style_} style)",
        )}
    );
    $wiz->SUPER::Show;
}

sub _task_good {
    sleep 1;
    return 1;
}

sub _task_na {
    sleep 1;
    return undef;
}

sub _task_fail {
    sleep 1;
    return 0;
}

1;


