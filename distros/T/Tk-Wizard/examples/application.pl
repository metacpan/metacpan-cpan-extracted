#!perl -w

# This is a BROKEN example of using a Wizard embedded in an application.

# Based on code supplied by Peter Weber.

use strict;
use warnings;

BEGIN {
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
			my $Log_Conf = q[
				log4perl.logger                   = TRACE, Screen
				log4perl.appender.Screen          = Log::Log4perl::Appender::ScreenColoredLevels
				log4perl.appender.Screen.stderr   = 1
				log4perl.appender.Screen.layout   = PatternLayout::Multiline
				log4perl.appender.Screen.layout.ConversionPattern = %7p | %-70m | %M %L%n
			];
			Log::Log4perl->init( \$Log_Conf );
		}
	}
}

use ExtUtils::testlib;    # Allows execution before installing the module
use lib "../lib";		  # Dev
use Tk;
use Tk::Wizard 2.076;

my $mw = new MainWindow;
our $wizard;

$wizard = $mw->Wizard(
    # -debug => 1,
    -title    => 'Component Wizard',
    -style    => 'top',
    -tag_text => "Component Wizard",
);


$wizard->addPage(
    sub {
        $wizard->blank_frame(
            -title    => "First Frame",
            -subtitle => "Step by step setup",
            -text     => "This wizard will guide you through the complete setup"
        );
    }
);

$wizard->addPage(
    sub {
        $wizard->blank_frame(
            -title    => "Second page",
            -subtitle => "Second step setup",
            -text     => "Second test text"
        );
    }
);

$wizard->addPage(
    sub {
        $wizard->blank_frame(
            -title    => "Last Frame",
            -subtitle => "LAST step setup",
            -text     => "LAST test text"
        );
    }
);

$mw->Label( -text => "This is the application's MainWindow.", )->pack;
$mw->Label( -text => "When you click this button, the Wizard will start.", )->pack;

my $button = $mw->Button(
    -text    => "Start Wizard",
    -command => sub {
        $wizard->Show();
    }
)->pack();

MainLoop;

__END__
