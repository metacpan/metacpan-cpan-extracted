#!/usr/bin/perl -w

use strict;

use Tk qw(MainLoop);

# all GUI interactions should be in the Tidyview:: namespace
use TidyView::Frame;
use TidyView::Options;
use TidyView::Display;
use TidyView::VERSION;

use Tk::FBox;
use Tk::DiffText;

# all interactions with perltidy should be in the PerlTidy:: namespace
use PerlTidy::Run;

use Getopt::Long;
use Pod::Usage;

use IO::File;

use Data::Dumper;

use Carp qw(longmess);

GetOptions(
	   "l|log=s"   => \(my $logConfigFile = "log.conf"),
	   "h|help"    => \(my $help),
	   "m|man"     => \(my $man),
	   "v|version" => \(my $version),
	  );

pod2usage(1) if $help;
pod2usage(
	  -exitstatus => 1,
	  -verbose    => 2
	 ) if $man;

__PACKAGE__->showVersion() if $version;

# whilst we are still in aphla, we should keep this - perhaps we'll remove this once its more mature and we need less introspection
use Log::Log4perl qw( :levels get_logger );

unless (-e $logConfigFile) {
  my $logConfigString = <<EOC;
log4perl.logger=WARN, CONSOLE

log4perl.appender.CONSOLE=Log::Log4perl::Appender::Screen
log4perl.appender.CONSOLE.stderr=1

log4perl.appender.CONSOLE.layout=Log::Log4perl::Layout::PatternLayout
log4perl.appender.CONSOLE.layout.ConversionPattern=%d %c - %p - %m%n
EOC

  $logConfigFile = \$logConfigString; # L::L4p knows how to read a scalar ref
}

Log::Log4perl->init($logConfigFile);

my $logger = get_logger((caller(0))[3]);

my $fileToTidy = $ARGV[0] || $0; # user provided file or this script

my $currentConfigFile;

# setup our initial GUI layout
(my $top = MainWindow->new())->minsize(800, 600);
$top->withdraw();

# Frame for the all the load/save/exit/etc buttons

my $buttonFrame = TidyView::Frame->new(
				       parent       => $top,
				       frameOptions => {
							-relief      => 'flat',
							-borderwidth => 0,
						       },
				       packOptions  => {
							-side   => 'bottom',
							-fill   => 'x',
							-expand => 0,
						       },
				      );

# right at the very bottom of the button frame is the exit button
(my $exitButton = $buttonFrame->Button(
				       -text    => "Exit",
				       -command => sub { exit; },
				      ))->pack(
					       -side   =>'bottom',
					       -anchor => 's',
					       -fill   => 'x',				      );

# build the option frame - and push to the very top
my $optionFrame       = TidyView::Frame->new(
					     parent      => $top,
					     packOptions => {
							     -side   => 'top',
							     -fill   => 'x',
							     -expand => 0,
							    },
					    );

# Option Population

# fill in the frame with all the options as at perltidy v20031021
TidyView::Options->build(parent => $optionFrame);

# Frame for the Save buttons
my $saveButtonFrame =  TidyView::Frame->new(
					    parent      => $buttonFrame,
					    frameOptions => {
							     -relief      => 'flat',
							     -borderwidth => 0,
							    },
					    packOptions => {
							    -side   => 'bottom',
							    -fill   => 'x',
							    -expand => 0,
							   },
					   );

# another button for generating the .perltidyrc with the users currently selected option set
(my $saveOptions = $saveButtonFrame->Button(
					    -text    => "Save perltidy config",
					    -command => __PACKAGE__->createGenerateOptionsCallback(parent => $saveButtonFrame),
					   ))->pack(
						    -side   =>'left',
						    -anchor => 's',
						    -fill   => 'x',
						    -expand => 1,
						   );

# another button for generating the .perltidyrc with the users currently selected option set, but asking for the name to save as
(my $saveOptionsAs = $saveButtonFrame->Button(
					      -text    => "Save perltidy config As...",
					      -command => __PACKAGE__->createGenerateOptionsFromDialogueCallback(parent => $saveButtonFrame),
					     ))->pack(
						      -side   =>'right',
						      -anchor => 's',
						      -fill   => 'x',
						      -expand => 1,
						     );

# widget to compare original and tidied text
my $DiffTextWidget = $top->DiffText(
	-background       => 'white',
	-foreground       => 'black',
	-gutterforeground => '#a0a0a0',
	-gutterbackground => '#e0e0e0',
	-diffcolors => {
		add => [-background => '#8aff8a'],
		del => [-background => '#ff8a8a'],
		mod => [-background => '#aea7ff'],
		pad => [-background => '#f8f8f8'],
	},
)->pack(-fill => 'both', -expand => 1);

TidyView::Display->preview_tidy_changes(
	rootWindow     => $top,
	fileToTidy     => $fileToTidy,
	DiffTextWidget => $DiffTextWidget,
);

# hit this button to run perltidy with your currently selected options and see the reformatted code in righthand frame
(my $runButton = $buttonFrame->Button(
				      -text    => "Run PerlTidy with these options",
				      -command => __PACKAGE__->createRunPerlTidyCallback(
											 fileToTidy     => $fileToTidy,
											 DiffTextWidget => $DiffTextWidget,
											),
				     ))->pack(
					      -side   =>'top',
					      -anchor => 's',
					      -fill   => 'x',
					     );

# hit this button to load a new  perltidy config file
(my $loadButton = $buttonFrame->Button(
				       -text    => "Load .perltidyrc ...",
				       -command => __PACKAGE__->createLoadPerlTidyRcCallback(
											     parent         => $optionFrame,
											     fileToTidy     => $fileToTidy,
											     DiffTextWidget => $DiffTextWidget,
											    ),
				      ))->pack(
					       -side   =>'top',
					       -anchor => 's',
					       -fill   => 'x',
					      );

$top->update();
$top->deiconify();
$top->raise();
$top->update();
MainLoop;

exit 0;

# create a sub that is run when the run button is pressed
sub createRunPerlTidyCallback {
  my ($self, %args) = @_;

  my ($fileToTidy, $DiffTextWidget) = @args{qw(fileToTidy DiffTextWidget)};

  return sub {
    my $logger = get_logger((caller(0))[3]);
    TidyView::Display->preview_tidy_changes(
					    rootWindow     => $top,
					    fileToTidy     => $fileToTidy,
					    DiffTextWidget => $DiffTextWidget,
					   );
  }
}

# create a sub that formats the options they have selected into a nice layout, and write out to a .perltidyrc
# one day it would be good to take a path argument for where we'd like the .perltidyrc to go. Also. one day
# it would be nice to generate CVS/Subversion/ClearCase/whatever pre/post commit hok scripts

sub createGenerateOptionsCallback {
  my ($self, %args) = @_;

  my ($parent) = @args{qw(parent)};

  return sub {
    my $logger = get_logger((caller(0))[3]);

    if (not defined $currentConfigFile) {
      $currentConfigFile = $parent->FBox(-type => 'save')->Show();
    }

    return unless defined $currentConfigFile; # cancelled picking a file ?

    $self->saveOptions($currentConfigFile);
  };
}

sub createLoadPerlTidyRcCallback {
  my ($self, %args) = @_;

  my ($parent, $fileToTidy, $originalTextWidget, $tidyTextWidget) = @args{qw(parent fileToTidy originalTextWidget tidyTextWidget)};

  return sub {
    my $logger = get_logger((caller(0))[3]);

    my $configFileName = $parent->FBox(-type => 'open')->Show();

    my $fh = IO::File->new($configFileName, O_RDONLY)
      or $top->messageBox(
			  -title   => 'Problem opening File',
			  -icon    => 'warning',
			  -type    => 'Ok',
			  -message => "Problem opening $configFileName\n\n$!"
			 )
	and return;

    my $perltidyOptions = {};	# destination for parsed config
    my $stderrCapture   = PerlTidy::Run->parseConfig(
						     handle      => $fh,
						     destination => $perltidyOptions,
						    );

    if ($stderrCapture) {
      $top->messageBox(
		       -title   => 'Problem parsing File',
		       -icon    => 'warning',
		       -type    => 'Ok',
		       -message => "Problem parsing $configFileName\n$stderrCapture\n$!"
		      );
      exit;
    }

    # now sometimes the parsed options will have options that arent supported by tidyview
    # these options live in section 0 and 13.

    # store these options away, and make them available to Tidyview::Options::assembleOptions()
    # but first, clear away the unsupported options

    TidyView::Options->clearUnsupportedOptions();

    TidyView::Options->storeUnsupportedOptions(rawOptions => $perltidyOptions);

    # and populate GUI...

    TidyView::Options->buildFromConfig(
					config => $perltidyOptions,
					parent => $parent, # the frame to rebuild the options pane in
				       );

    # run perltidy with this new config
    TidyView::Display->preview_tidy_changes(
					    rootWindow     => $top,
					    fileToTidy     => $fileToTidy,
					    DiffTextWidget => $DiffTextWidget,
					   );

    # do save to here from now on, until told to change...
    $currentConfigFile = $configFileName;

    return;
  };
}

sub createGenerateOptionsFromDialogueCallback {
  my ($self, %args) = @_;

  my ($parent) = @args{qw(parent)};

  return sub {
    my $logger = get_logger((caller(0))[3]);

    my $possibleNewConfigFile = $parent->FBox(-type => 'save')->Show();

    return unless defined $possibleNewConfigFile;

    $self->saveOptions($currentConfigFile = $possibleNewConfigFile);
  };
}

sub saveOptions {
  my ($self, $fileName) = @_;

  my $fh = IO::File->new($fileName, O_RDWR | O_CREAT | O_TRUNC)
    or $top->messageBox(
			-title   => 'Problem opening save File',
			-icon    => 'warning',
			-type    => 'Ok',
			-message => "Problem saving $fileName\n\n$!"
		       )
      and return;

  $fh->print(TidyView::Options->assembleOptions(separator => "\n")); # output options, one per line

  $fh->print(TidyView::Options->assembleUnsupportedOptions(separator => "\n"));

  $fh->close();

  return;
}

# when tidyview called with -v|--version, do this...
sub showVersion {
  print <<"EOM";
This is tidyview, v$VERSION::VERSION

Copyright 2006, Leif Eriksen

Tidyview is free software and may be copied under the terms of the GNU
General Public License, which is included in the distribution files.

Complete documentation for tidyview can be found using 'tidyview --help'.

EOM
}
__END__

=pod

=head1 NAME

tidyview - a previewer for the effects of perltidy's plethora of options

=head1 SYNOPSIS

  tidyview
  tidyview [--log <log4perl config file>] [<perl code file>]

=head1 DESCRIPTION

tidyview is a Tk-based GUI that assists with selecting options for use with perltidy, a source code reformatter and indenter for Perl.

As good as perltidy is, it suffers a little from the huge number of options it supports - so whilst it is possible to find a set of options to layout the code exactly how you want, finding that set of options can be quite time consuming, requiring lots of back-to-back comparisons to find the effect your looking for. And thats where tidyview can help.

tidyview allows you to see the effect of perltidy options side-by-side with your original code. All of perltidy's options that affect code layout (rather than the operation of perltidy itself) are able to be selected, with Tk widgets that constrain them to valid values where possible.

Additionally, once your happy with the selected options, tidyview allows you to generate the selected options as a .perltidyrc configuration file, for further use.

=head1 OPTION CATEGORY

Within the tidyview application, the perltidy options are grouped into broad categories, in a drop-down list titled "Formatting Section". These formatting sections match the sections in the perltidy documention, being

=over

=item Basic Formatting Options

=item Code Indentation Control

=item Whitespace Control

=item Comment Controls

=item Linebreak Controls

=item Controlling list formatting

=item Retaining or ignoring existing line breaks

=item Blank line Control

=item Styles

=item Other Controls

=item HTML options

=item pod2html options

=back

Each of these sections presents a set of options to the user, generally 

=over

=item A set of checkbox style options

=item A set of integer-based options, either as a spinbox or a textbox, depending on your version of Tk

=item A set of text-based options - note, at the moment, no validation of what you enter is done, perltidy and not tidyview will complain.

=item A set of list-based options, as a scrolling listbox

=item A set of colour dialogues, for things like POD colour options

=back

Note that not all option sections will display all these sets, as not all section have options that need these sets - for example in the HTML options section, the only set displayed is the checkbox set, as perltidy does not support any other option sets.

=head1 TODO

perltidy is a very young application, so there are many ways it can be improved. Some of these include

=over

=item The ability to read an existing .perltidyrc

=item The ability to check that the parse tree has not been altered by the reformatting and indentation. This is planned to be support through PPI::Signature

=item Support for displaying the before and after formatting as a colourised diff

=item Support for generating CVS/Subversion/<insert favourite version management here> pre/post-commit hooks

=item Reorganise really long option lists so that things dont get pushed off the screen.

=item everyones favouriites - more doco and tests

=back

AUTHORS

Leif Eriksen <F<tidyview@sourceforge.net>>

=cut
