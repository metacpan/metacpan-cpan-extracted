################################################################################
#  File         WizardMaker.pm                                                 #
#  Desc         Perl Object class for building of Installation Wizards and     #
#               Software Assistents.                                           #
#                                                                              #
#               Main feature: All the Wizard pages can be build directt from   #
#               aan XML  ini file.                                             #
#                                                                              #
#               Inspired by  Tk::Wizard (Daniel T. Hable)                      #
#                        and XML::Simple (Grant McLean)                        #
#  Usage Example                                                               #
#               use Tk;                                                        #
#               use Tk::XML::WizardMaker;                                      #
#                                                                              #
#               my $mw = MainWindow->new();                                    #
#               my $w = $mw->WizardMaker(-gui_file=>'gui.xml')->build_all();   #
#               MainLoop;                                                      #
#                                                                              #
#  Plattform    Win32, linux                                                   #
#                                                                              #
#  Version      see variable $VERSION below                                    #
#                                                                              #
#  Author       V.Zimmermann (ZiMTraining@gmx.net)                             #
#                                                                              #
#  History      07.10.2003   Version 0.01 Created.                             #
#                                                                              #
#                                                                              #
################################################################################

# start package
package Tk::XML::WizardMaker;

# version
our $VERSION = '0.91';

################################################################################
# modules we use                                                               #
################################################################################

BEGIN {
  use 5.0;
  use warnings;

  use strict;              # all variables must be declared
  use Storable 'dclone';   #
  use English;             # no crypt variable names
  use Cwd;                 # current working directory

  eval "use Data::Dumper"; # usefull for debugging
  eval "use Config";       # infos about perl distribution(path to images etc.)

  # GUI
  use Tk;
  use Tk::LabEntry;
  use Tk::Font;
  use Tk::DirTree;
  use Tk::ProgressBar;

  # init and file processing
  use XML::Simple;
  use File::Path;
  use File::Find;
  use File::Copy;
  use File::Basename;

  # Win32 specific
  eval "use Win32";
  eval 'require Win32API::File';

  # class variables
  our $defs;
}


################################################################################
# Standard perl and Tk object magic.                                           #
# We must override Tk functions  ClassInit and Populate!                       #
################################################################################

use base qw/Tk::Derived Tk::Frame/;

Tk::Widget->Construct('WizardMaker');

# Tk standard function to initialize class
sub ClassInit{
  my ($class, $main_window) = @_;

  # init the instance variables.
  # You can use more than one WizardMaker object adonce
  $defs->{counter} = 0;

  # only this page types can be generated now. But ExternalPage
  # can be used to emulate every page form.
  $defs->{known_page_types} = [
    qw(TextPage LabeledEntriesPage RadioButtonPage
       CheckButtonPage ExternalPage)
   ];

  # dirs to look for files
  $defs->{dirs} = $OSNAME eq 'MSWin32'?
    [ cwd, $Config{installsitearch}, $ENV{windir} , "C:\\TEMP", ]:
      [ cwd, $Config{installsitearch}, '/etc', $ENV{HOME}, '/tmp'];

  # some defaults
  $defs->{font}->{title_font} = "-family Helvetica -size 24 -weight demi";
  $defs->{font}->{subtitle_font} = "-family arial -size 18";
  $defs->{font}->{subsubtitle_font} = "-family arial -size 12";
  $defs->{font}->{small_font} = "-family Helvetica -size 10";
  $defs->{font}->{text_font}  = "-family Helvetica -size 12";
  $defs->{font}->{radio_font} = "-family Courier -size 12 -weight demi";
  $defs->{font}->{fixed_font} = "-family Courier -size 12";
  $defs->{font}->{button_font} = "-family Courier -size 12 -slant italic";

  $defs->{button_help} ="HELP";
  $defs->{button_next}="NEXT >";
  $defs->{button_back}="< BACK";
  $defs->{button_finish}="FINISH";
  $defs->{button_cancel}="CANCEL";
  $defs->{button_log}="Show Log";
  $defs->{button_done}="Done";
  $defs->{button_dir_select}=" . . . ";
  $defs->{button_file_open}=" . . . ";

  $defs->{foreground}="black";
  $defs->{background}="#f6f6f6";
  $defs->{select_foreground}="blue";
  $defs->{select_background}="white";

  $defs->{header_background}="#f6f6f6";        # header frame
  $defs->{header_foreground}="blue";
  $defs->{header_background1}="#f6f6f6";       #title
  $defs->{header_foreground1}="blue";
  $defs->{header_background2}="#f6f6f6";       #subtitle
  $defs->{header_foreground2}="blue";
  $defs->{header_background3}="#f6f6f6";       #title text (subsubtitle)
  $defs->{header_foreground3}="blue";
  $defs->{select_header_background}="white";
  $defs->{select_header_foreround}="blue";

  $defs->{button_background}="lightgrey";
  $defs->{button_foreground}="black";
  $defs->{button_select_foreground}="grey";
  $defs->{button_select_background}="white";
  $defs->{button_disabled_foreground}="grey";
  $defs->{progress_bar_color}="#1079ef";

  $defs->{radio_button_foreground}=$defs->{foreground};
  $defs->{radio_button_background}=$defs->{background};
  $defs->{radio_button_select_foreground}=$defs->{select_foreground};
  $defs->{radio_button_select_background}=$defs->{select_background};
  $defs->{radio_button_disabled_foreground}=$defs->{button_disabled_foreground};

  $defs->{check_button_foreground}=$defs->{foreground};
  $defs->{check_button_background}=$defs->{background};
  $defs->{check_button_select_foreground}=$defs->{select_header_foreround};
  $defs->{check_button_select_indicator}=$defs->{select_background};
  $defs->{check_button_select_background}=$defs->{select_background};
  $defs->{check_button_disabled_foreground}=$defs->{button_disabled_foreground};

  $defs->{entry_foreground}=$defs->{foreground};
  $defs->{entry_background}=$defs->{background};
  $defs->{entry_highlightbackground}=$defs->{background};
  $defs->{entry_highlightcolor}=$defs->{foreground};
  $defs->{entry_select_foreground}=$defs->{select_foreground};
  $defs->{entry_select_background}=$defs->{select_background};

  $defs->{button_frame_background}="gray";
  $defs->{button_frame_select_foreground}="gray";
  $defs->{button_frame_select_background}="gray";

  # can be flat, groove, raised, ridge, solid, or sunken
  $defs->{relief}="flat";
  $defs->{buttons_relief}="raised";

  $defs->{title} = "XML Perl WizardMaker. Version ". $VERSION;

  $defs->{help_title}      = "Online Help";
  $defs->{no_help_text}    = 'Sorry. No online help provided for this page';

  $defs->{warning_title}   = "Warning!";
  $defs->{no_warning_text} = 'Something seems to be wrong!';

  $defs->{error_title}     = "Error!";
  $defs->{no_error_text}   = 'An unexpected error occures!';

  $defs->{info_title}      = "Info";
  $defs->{no_info_text}    = 'Sorry. No infos at this place';

  $defs->{wish_width}="800";
  $defs->{wish_height}="600";
  $defs->{wish_x}="+50";
  $defs->{wish_y}="+50";

  # call to superclass
  $class->SUPER::ClassInit($main_window);
} # sub

# Tk standard function to initialize object
sub Populate{
  my($self, $args) = @_;

  # set up class variables
  $defs->{counter}++;


  # Configure options for X database
  $self->ConfigSpecs(
      # Some common non Tk options. All others are configured separate
      -gui_file     => ['PASSIVE', undef, undef, 'gui.xml'],
      -gui          => ['PASSIVE', undef, undef, undef],
      -left_image   => ['PASSIVE', 'left_image', 'LeftImage', 'left_image.gif'],
      -top_image    => ['PASSIVE', 'top_image', 'TopImage', 'top_image.gif'],

      # event handler
      -preNextButtonAction    => ['PASSIVE',undef,undef,undef],
      -postNextButtonAction   => ['PASSIVE',undef,undef,undef],
      -preBackButtonAction    => ['PASSIVE',undef,undef,undef],
      -postBackButtonAction   => ['PASSIVE',undef,undef,undef],
      -helpButtonAction       => ['PASSIVE',undef,undef,undef],
      -finishButtonAction     => ['PASSIVE',undef,undef,undef],
      -preCancelButtonAction  => ['PASSIVE',undef, undef, undef],
      -preCloseWindowAction   => ['PASSIVE',undef, undef, undef],
     );

  # instance variables / external options
  $self->initialize_externals($args);

  # instance variables for internal use
  $self->{internal} = {
    assistent_id => $defs->{counter}, # common for fonts, images etc.
    current_node => undef,            # important for navigation
    total_pages  => 0,                # total pages build (linked or not)
    pages        => {},               # all generated pages
    status       => 'CANCELED',       # will change to GOOD if properly finished
  };

  # call to superclass
  $self->SUPER::Populate($args);

  # construct all common gui objects
  $self->create_fonts();
  $self->construct_common_frame_objects();
}

################################################################################
# Some auxillary function for constructing WizardMaker structure               #
################################################################################

# initialize some options either from hash or from an XML file.
# The parameter is an args HASH. Does not returns any meaning value.
sub initialize_externals{
  my ($self, $args) = @_;

  # initialize gui options hash - from a hash or from an XML file
  my @inis = ('-gui', );

  if ( defined $args->{'-opt_file'} or defined $args->{'-opt'}){
    push @inis, '-opt' ;
  }
  else{
    # minimum initialization
    $self->{opt}->{gui} = {};
  }

  for my $i (@inis){
    (my $j = $i) =~ s/^-//;

    # from hash
    if ($args->{$i}){
      $self->{$j} = $args->{$i};
    }
    # from file
    else {
      my $file = $args->{"${i}_file"}?$args->{"${i}_file"}:"$j.xml";
      $self->{$j} = XMLin(
        $file,
        forcearray => [ 'page', 'CheckButton', 'LabeledEntry', 'RadioButton' ],
        keyattr => 'NOT_USED',
        searchpath =>$defs->{dirs},
      ) or warn "Can not initialize WizardMaker from XML file ",$file;
    }
  }


  # if opt - hash (or file) was defined, it can be  be evaluated:
  foreach my $k ( keys %{$self->{opt}->{gui}} ) {
    if ( defined $self->{opt}->{gui}->{$k}->{evaluate} and
      $self->{opt}->{gui}->{$k}->{evaluate}){

      $self->{opt}->{gui}->{$k}->{value} =
        eval $self->{opt}->{gui}->{$k}->{value};
    }
  }

  # left and top images
  for my $i ('-left', '-top'){
    (my $j = $i) =~ s/^-//;

    if (exists $args->{"${i}_image"} and -e $args->{"${i}_image"}){
      $self->{gui}->{"${j}_image"} = $args->{"${i}_image"};
    }
    else{
      $self->{gui}->{"${i}_image"} = undef
        unless ($self->{gui}->{"${j}_image"}
           and -e $self->{gui}->{"${j}_image"});
    }
  }

  # any inspecific instance variables given either in args or in gui - hash
  for my $i (keys %$args) {
    (my $j = $i) =~ s/^-//;
    $self->{gui}->{"$j"} = $args->{"$i"};

    # register the option for Tk
    $self->ConfigSpecs( "$i"  => ['PASSIVE', undef, undef, undef], );
  }

  # all unspecified options take values from $defs defaults
  for my $k (keys %{$defs}){
    $self->{gui}->{$k} = $defs->{$k} unless exists $self->{gui}->{$k};
  }
} # sub

################################################################################
# Construction of the common GUI elements                                      #
################################################################################

# construct common frame objects: command frame and buttons, deco frame,
# user frame and image frames
sub construct_common_frame_objects{
  my $self = shift;
  my $id = $self->{internal}->{assistent_id};

  # wished geometry
  $self->parent->geometry("=".
    $self->{gui}->{wish_width} . "x" .  $self->{gui}->{wish_height} .
    $self->{gui}->{wish_x} . $self->{gui}->{wish_y} );

  # wished title
  $self->parent->configure(-title => $self->{gui}->{title});


  # main frame - container of all elements
  my $mf = $self->{internal}->{main_frame} = $self->parent->Frame(
   -background => $self->{gui}->{background},
   -highlightbackground => $self->{gui}->{select_background},
   -highlightcolor => $self->{gui}->{select_foreground},
   );

  # command frame
  my $cf = $self->{internal}->{command_frame} = $mf->Frame(
    -background => $self->{gui}->{button_frame_background},
    -highlightbackground => $self->{gui}->{button_frame_select_background},
    -highlightcolor => $self->{gui}->{button_frame_select_foreground},
    );

  # user frame - where all user data will be shown
  $self->{internal}->{user_frame} =
    $mf->Frame(
      -background => $self->{gui}->{background},
      -highlightbackground =>$self->{gui}->{select_background},
      -highlightcolor => $self->{gui}->{select_foreground},
      );

  # deco line
  $self->{internal}->{deco_frame} =
    $mf->Frame(-background => 'black', -height=>'1',);

  # dummies for left and top images
  for my $i (qw/left top/){
    $self->{internal}->{"${i}_image"} = $mf->Label();
  }

  # command buttons: HELP, NEXT, BACK, FINISH and CANCEL
  for my $b (qw/button_cancel button_next button_back button_help/){
    my $side = $b eq 'button_help'?'left':'right';
    my $text = $self->{gui}->{$b};

    $self->{internal}->{$b} = $cf->Button(
      -text  => $text,
      -font  => "button_font$id",
      -relief=>$self->{gui}->{buttons_relief},
      -width =>10,
     )->pack(-side=>$side, -expand=>0, -padx=>2,);
  }

  # reset buttons and config special commands (event loop)
  $self->reset_buttons();

  $self->{internal}->{button_next}->configure (
    -command => sub {$self->next_button_event();}, );

  $self->{internal}->{button_back}->configure (
    -command => sub {$self->back_button_event();}, );

  $self->{internal}->{button_cancel}->configure (
    -command => sub {$self->cancel_button_event();}, );

  $self->{internal}->{button_help}->configure (
    -command => sub {$self->help_button_event();}, );
} # sub

# PUBLIC. reset visual features all common buttons to default values.
# parameter is a list of
sub reset_buttons {
  my $self = shift;
  my @buttons = @_;

  # reset all buttons if no params are given
  @buttons = (qw/button_cancel button_next button_back button_help/)
    unless (@buttons);

  for my $b (@buttons){
    $self->{internal}->{$b}->configure (
      -text               => $self->{gui}->{$b},
      -background         => $self->{gui}->{button_background},
      -foreground         => $self->{gui}->{button_foreground},
      -activeforeground   => $self->{gui}->{button_select_foreground},
      -activebackground   => $self->{gui}->{button_select_background},
      -disabledforeground => $self->{gui}->{button_disabled_foreground},
      -state              => 'normal',
    );
  }
} # sub

# construct all fonts
sub create_fonts{
  my $self = shift;
  my $id = $self->{internal}->{assistent_id};

  for my $k (keys %{$defs->{font}}){
    my $font = $self->{gui}->{$k}?$self->{gui}->{$k}:$defs->{font}->{$k};
    $self->fontCreate("$k$id",  split (/ /, $font));
  }
} # sub

# PUBLIC. show the assistent frame with all contents
#(main_frame, command_frame, deco_frame) and renders current node.
sub show{
  my $self = shift;

  # show the main frame
  my $mf = $self->{internal}->{main_frame}->pack(-fill=>'both', -expand=>'1');

  # show the command frame and the deco line in the main frame.
  $self->{internal}->{command_frame}
    ->pack(-in =>$mf, -side=>'bottom', -fill=>'x',
     -expand=>'0', -ipadx=>10, -ipady=>10);

  $self->{internal}->{deco_frame}
    ->pack(-in =>$mf, -side=>'bottom', -fill=>'x', -expand=>'0', -padx=>0,);

  # show user frame (only this part is really dynamic)
  $self->render($self->current_node) if ($self->current_node);

} # sub

################################################################################
# Show WizardMaker                                                             #
################################################################################

# PUBLIC. build all pages and show the assistent
sub build_all{
  my $self = shift;

  $self->add_all_pages();
  $self->show();

} # sub

# render current page (node)
sub render {
  my ($self, $node) = @_;
  my $page_ref = $self->get_page($node);
  my $image_position = 'top';

  # common frames
  my $mf = $self->{internal}->{main_frame};
  my $uf = $self->{internal}->{user_frame};
  my $ti = $self->{internal}->{top_image};
  my $li = $self->{internal}->{left_image};

  # the frame of the node to be rendered
  my $cpt= $self->{internal}->{pages}->{$node}->{title_frame};
  my $cpf= $self->{internal}->{pages}->{$node}->{frame};

  # forget all pack slaves in $user frame and some of those in main frame
  foreach my $s ( $uf->packSlaves ){ $s->packForget };
  $uf->packForget();
  $ti->packForget();
  $li->packForget();

  # pack top or left image frames
  if ($node eq $self->first_node or $node eq $self->last_node){
    $image_position = 'left';
    $li->pack(-in =>$mf, -side=>'left',
	      -expand=>'0', -padx=>20, -pady=>20, -anchor=>'s');
  }
  else{
    $ti->pack(-in =>$cpt, -side=>'right',
	      -expand=>'1', -padx=>10, -pady=>10, -anchor=>'e' , );
  }

  # set top / left images for current page
  if (defined $page_ref->{$image_position . '_image_name'} and
	defined $page_ref->{$image_position . '_image_file'}){

    $self->set_common_image(
      $image_position, $page_ref->{$image_position . '_image_name'},
      $page_ref->{$image_position . '_image_file'});
  }
  else {
    $self->set_common_image(
      $image_position, $image_position . '_image',
      $self->{gui}->{$image_position . '_image'});
  }

  # reset buttons
  $self->reset_buttons();

  # command buttons for first page
  if ($node eq $self->first_node){
    $self->configure_common_element('button_back', (-state => 'disabled',));
  }

  # command buttons for last page
  if ($node eq $self->last_node){
    $self->configure_common_element('button_next', (
      -text => $self->{gui}->{button_finish}, )
    );

    $self->configure_common_element('button_help', (
      -text => $self->{gui}->{button_log}, )
    );

    $self->configure_common_element('button_back', (-state => 'disabled'));
  }

  # dispatch callback I.
  $self->dispatch_generic_callback('pre_display_code');

  # rerender user frame
  $cpt->pack(-in =>$uf, -side=>'top',   -fill=>'x', -expand=>'0');
  $cpf->pack(-in =>$uf, -side=>'bottom', -fill=>'both', -expand=>'1');
  $uf->pack( -in =>$mf, -side=>'bottom', -fill=>'both', -expand=>'1');

  # dispatch callback II.
  $self->dispatch_generic_callback('post_display_code');

} # sub

################################################################################
# Construct the pages and navigating structure (double linked list)            #
#                                                                              #
# The common srtucture looks like this:                                        #
#                                                                              #
# $self->{internal}->{pages}->{$name} = {                                      #
#   id    => ..., # a Number. not really used                                  #
#   frame => ..., # a reference to the Tk::Frame object (page content)         #
#   left  => ..., # element of  double linked list to navigate                 #
#   right => ..., # through the pages. We set them in link_node()              #
# }                                                                            #
################################################################################

# PUBLIC. build and link all generic pages (in the list @{$self->{gui}->page})
sub add_all_pages{
  my $self = shift;
  my ($name, $p);

  for my $n (0 .. scalar @{$self->{gui}->{page}}-1){

    $p = $self->{gui}->{page}->[$n];
    $name = $p->{name}?$p->{name}:$self->{internal}->{total_pages};

    # only valid pages from the xml ini file will be processed
    if (exists $p->{status} and $p->{status} ne 'invalid'){
      $self->build_generic_node($p);
      $self->link_node($name, 'after', 'last');
    }
  }

  # set the curren page to the first
  $self->current_node('first');

} # sub

# PUBLIC. build and link all generic pages (in the list @{$self->{gui}->page})
sub drop_page{
  my ($self, $page) = @_;
  my $name = $self->find_node($page);

  if ($name){
    $self->unlink_node($name);
    $self->{internal}->{pages}->{$name} = undef;
  }

} # sub

# PUBLIC. set up node structure. Returns the name of new node
sub  build_node{
  my ($self, $page) = @_;

  my $id = ++$self->{internal}->{total_pages};
  my $name = $page->{name}?$page->{name}:$id;

  $self->{internal}->{pages}->{$name}->{id} = $id;

  # all xml attributes are copied into the new node
  $self->{internal}->{pages}->{$name} = dclone($page);

  return $name;

} # sub

# PUBLIC. set up page structure:
sub  build_generic_node{
  my ($self, $page) = @_;

  $name = $self->build_node($page);

  # important for navigating thrue tk - objects of the page:
  $self->{internal}->{pages}->{$name}->{tk_object}->{title} = {};
  $self->{internal}->{pages}->{$name}->{tk_object}->{subtitle} = {};
  $self->{internal}->{pages}->{$name}->{tk_object}->{text} = {};
  $self->{internal}->{pages}->{$name}->{tk_object}->{body_container} = {};
  $self->{internal}->{pages}->{$name}->{tk_object}->{summary_text} = {};
  $self->{internal}->{pages}->{$name}->{tk_object}->{CheckButton} = {};
  $self->{internal}->{pages}->{$name}->{tk_object}->{LabeledEntry} = {};
  $self->{internal}->{pages}->{$name}->{tk_object}->{RadioButton} = {};

  # list of the header frame and of the user frame
  (
    $self->{internal}->{pages}->{$name}->{title_frame},
    $self->{internal}->{pages}->{$name}->{frame},
   ) = $self->build_generic_page(\$self->{internal}->{pages}->{$name});

} # sub

# PUBLIC. set up page structure:
sub  build_external_node{
  my ($self, $page) = @_;

  $name = $self->build_node($page);

  # important for navigating thrue tk - objects of the page:
  $self->{internal}->{pages}->{$name}->{tk_object}->{title} = {};
  $self->{internal}->{pages}->{$name}->{tk_object}->{subtitle} = {};
  $self->{internal}->{pages}->{$name}->{tk_object}->{text} = {};
  $self->{internal}->{pages}->{$name}->{tk_object}->{body_container} = {};
  $self->{internal}->{pages}->{$name}->{tk_object}->{summary_text} = {};
  $self->{internal}->{pages}->{$name}->{tk_object}->{CheckButton} = {};
  $self->{internal}->{pages}->{$name}->{tk_object}->{LabeledEntry} = {};
  $self->{internal}->{pages}->{$name}->{tk_object}->{RadioButton} = {};
  # list of the header frame and of the user frame
  (
    $self->{internal}->{pages}->{$name}->{title_frame},
    $self->{internal}->{pages}->{$name}->{frame},
   ) = $self->build_external_page($self->{internal}->{pages}->{$name});

} # sub


# PUBLIC. insert the page in the double linked list.
# Parameter are:
# $page     - unique page name.
# $where    - can be 'before' or 'after'.
#             All other strings are processed as 'after'
# $position - can be 'first', 'last' or unique page of existent page.
#             All other strings are processed as 'last'
sub link_node{
  my ($self, $page, $where, $position) = @_;
  return if $self->is_linked($page);

  # find asked page
  $position = $self->find_node($position);

  if($position){
    return undef if (!$position or $position eq $page);

    # insert the new page in the list
    $link_to   = $where eq 'before' ? 'left' : 'right';
    $link_from = $where eq 'before' ? 'right' : 'left';

    $sibling = $self->{internal}->{pages}->{$position}->{$link_to};

    $self->{internal}->{pages}->{$position}->{$link_to} = $page;
    $self->{internal}->{pages}->{$sibling}->{$link_from} = $page
      if ($sibling ne 'NULL');

    $self->{internal}->{pages}->{$page}->{$link_from} = $position;
    $self->{internal}->{pages}->{$page}->{$link_to} = $sibling;
  }
  # first element in the list
  else{
    $self->{internal}->{pages}->{$page}->{left}  = 'NULL';
    $self->{internal}->{pages}->{$page}->{right} = 'NULL';
  }
  return 1;
}

# PUBLIC. remove page from list. The page will not be really deleted!
sub unlink_node{
  my ($self, $page) = @_;
  return unless  $self->{internal}->{pages}->{$page};
  return unless $self->is_linked($page);

  my $left_node  = $self->{internal}->{pages}->{$page}->{left};
  my $right_node = $self->{internal}->{pages}->{$page}->{right};

  # element in the middle of the list
  if ($left_node ne 'NULL' and $right_node ne 'NULL'){
    $self->{internal}->{pages}->{$left_node}->{right} = $right_node;
    $self->{internal}->{pages}->{$right_node}->{left} = $left_node;
  }
  # last element in the list
  elsif($left_node ne 'NULL'){
    $self->{internal}->{pages}->{$left_node}->{right} = 'NULL'
      if (exists $self->{internal}->{pages}->{$left_node});
  }
  # first element in the list
  elsif($right_node ne 'NULL'){
    $self->{internal}->{pages}->{$right_node}->{left} = 'NULL'
      if (exists $self->{internal}->{pages}->{$right_node});
  }

  $self->{internal}->{pages}->{$page}->{left}  = undef;
  $self->{internal}->{pages}->{$page}->{right} = undef;
}

# PUBLIC. find first page in the list
sub first_node{
  my $self = shift;

  foreach my $name (keys %{$self->{internal}->{pages}}){
    if ($name){
      if (defined $self->{internal}->{pages}->{$name}->{left}){
        return $name
          if ($self->{internal}->{pages}->{$name}->{left} eq 'NULL');
      }
    }
  }

  return undef;
} # sub

# PUBLIC. find last page in the list
sub last_node{
  my $self = shift;

  foreach my $name (keys %{$self->{internal}->{pages}}){
    if ($name){
      if (defined $self->{internal}->{pages}->{$name}->{right}){
        return $name
          if ($self->{internal}->{pages}->{$name}->{right} eq 'NULL');
      }
    }
  }
  return undef;
} # sub

# PUBLIC. return current page name or set current page to name
sub current_node{
  my ($self, $page)  = @_;

  return $self->{internal}->{current_node}
    unless ( $page and defined $self->find_node($page));

  return $self->{internal}->{current_node} = $self->find_node($page);

} #sub

# PUBLIC. find page (as 'first', 'last', or by name).
sub find_node{
  my ($self, $page)  = @_;

  return $self->first_node if ($page eq 'first');
  return $self->last_node if ($page eq 'last');
  return undef if (not exists $self->{internal}->{pages}->{$page});
  return $page;

} # sub

# PUBLIC. returns 1 if a node is linked
sub is_linked{
  my ($self, $page) = @_;

  return defined $self->{internal}->{pages}->{$page}->{left} and
         defined $self->{internal}->{pages}->{$page}->{right}?1:0;
} # sub


################################################################################
# Construct pages (frames) according to the gui.xml file                       #
################################################################################
# PUBLIC. build generic page. $p is a hash like that from gui.xml.
# Returns a list of the header and page frames
sub build_generic_page{
  my ($self, $page_ref) = @_;
  my $p = $$page_ref;
  my $uf = $self->{internal}->{user_frame};

  # page body and page header frames
  my $pf = $uf->Frame(
    -background => $self->{gui}->{background},
    -highlightbackground => $self->{gui}->{select_background},
    -highlightcolor => $self->{gui}->{select_foreground},
    );
  my $hf = $uf->Frame(
    -background => $self->{gui}->{header_background},
    -highlightbackground => $self->{gui}->{select_header_background},
    -highlightcolor => $self->{gui}->{select_header_background},
    );

  my @known_page_types = @{$defs->{known_page_types}};

  # page head construction and code execution
  if(grep {/^$p->{type}$/} @known_page_types) {
    $self->page_header($hf, $p);
    eval $p->{code} if( exists $p->{code} and $p->{code} );
  }
  # UNKNOWN page
  else{
    $p->{title} = 'Unknown Page Type' unless defined $p->{title};
    $p->{subtitle} = "Unknown Page Type $p->{type}";
    $self->page_header($hf, $p);
  }

  # construct the page
  if(   $p->{type} eq "TextPage"){$self->add_text_page($pf, $p);}
  elsif($p->{type} eq "LabeledEntriesPage"){$self->add_le_page($pf, $p);}
  elsif($p->{type} eq "RadioButtonPage"){$self->add_rb_page($pf, $p); }
  elsif($p->{type} eq "CheckButtonPage"){$self->add_cb_page($pf, $p); }
  elsif($p->{type} eq "ExternalPage"){$self->add_external_frame($pf, $p); }

  # unknown page type
  else{ print "\nPage Type $p->{type} is not implemented!";}
  return ($hf, $pf);
} # sub

# page head construction. returns title frame. Parameters are
# the actual user frame, title, subtitle and descriptive text.
sub page_header{
  my ($self, $frame, $p) = @_;
  (my $text = $p->{text}) =~ s/\\n/\n/gs;

  my $tf = $frame->Frame();
  my $assistent_id = $self->{internal}->{assistent_id};

  # if an external page is constructing, some options may not been set
  $p->{tk_object}->{title} = $tf->Label(
    -justify =>'left',
    -anchor=>'w',
    -padx=>'20',
    -text=> $p->{title},
    -wraplength=>$self->{gui}->{wish_width} - 200,
    -font=> "title_font$assistent_id",
    -background=>$self->{gui}->{header_background1},
    -foreground=>$self->{gui}->{header_foreground1},
   )->pack(-side=>'top',-expand=>1,-fill=>'x',
     -ipady=>10, -ipadx=>10, -pady=>0, -padx=>0);

  $p->{tk_object}->{subtitle} =   $tf->Label(
    -justify => 'left',
    -anchor=> 'w',
    -padx=>'30',
    -text=> $p->{subtitle},
    -wraplength=>$self->{gui}->{wish_width} - 200,
    -font=>"subtitle_font$assistent_id",
    -background=>$self->{gui}->{header_background2},
    -foreground=>$self->{gui}->{header_foreground2},
   )->pack(-side=>'top', -expand=>1, -fill=>'x',
     -ipady=>5, -ipadx=>10,-pady=>0, -padx=>0);

  $p->{tk_object}->{text} =   $tf->Label(
    -justify => 'left',
    -anchor=> 'w',
    -padx=>'20',
    -text=> $text, -wraplength=>$self->{gui}->{wish_width} - 200,
    -font=>"subsubtitle_font$assistent_id",
    -background=>$self->{gui}->{header_background3},
    -foreground=>$self->{gui}->{header_foreground3},
   )->pack(-side=>'bottom', -expand=>1, -fill=>'x',
     -ipady=>5, -ipadx=>10,-pady=>0, -padx=>0);

  return $tf->pack(-side=>'left',-expand=>1,-fill=>'x',);

} #sub

# page body construction. parameters are - actual frame and actual page
# returns body frame (scrolled text)
sub page_body_container{
  my ($self, $frame, $p) = @_;
  my $id = $self->{internal}->{assistent_id};

  # some optic defaults
  my $font   = "fixed_font$id";
  my $width  = 12;
  my $height = 12;
  my $relief = $self->{gui}->{relief},
  my $wrap   = 'word';
  my $cursor = 'left_ptr';
  my $bg = $self->{gui}->{background};
  my $fg = $self->{gui}->{foreground};

  #define optic correctly
  $font = $p->{font}."$id" if (defined $p->{font});
  $width = $p->{width}     if (defined $p->{width});
  $height = $p->{height}   if (defined $p->{height});
  $relief = $p->{relief}   if (defined $p->{relief});
  $wrap = $p->{wrap}       if (defined $p->{wrap});
  $cursor = $p->{cursor}   if (defined $p->{cursor});
  $bg = $p->{background}   if (defined $p->{background});
  $fg = $p->{foreground}   if (defined $p->{foreground});

  # scrolled container for page contents
  $p->{tk_object}->{body_container} = $frame->Scrolled(
    "Text",
    -scrollbars         =>'osoe',
    -relief             => $relief,
    -width              => $width,
    -height             => $height,
    -wrap               => $wrap,
    -cursor             => $cursor,
    -background         => $bg,
    -foreground         => $fg,
    -font               => $font,
    -setgrid            => 0,
    )->pack(-fill => 'both', -expand=>'1', -side => 'top');

  # returns the container frame for all page elements
  return $p->{tk_object}->{body_container};

} # sub

# PUBLIC. build external page (frame). The Hash %external should have a similar
# structure like that from XML ini - files.
sub build_external_page{
  my ($self, $external) = @_;
  $external->{type} = 'ExternalPage';
  return ($self->build_generic_page(\$external));
} # sub

# PUBLIC. add a Text Page. The Hash the $self->{opt} here is important now
sub add_text_page{
  my ($self, $frame, $p) = @_;
  my $summary = '';
  my $o = $self->{opt}->{gui};
  $o = eval $p->{opt_section} if (defined $p->{opt_section});

  # construct all common page elements
  $p->{tk_object}->{summary_text} = $self->page_body_container($frame, $p);

  # summary text. Some simple substitution here.
  if (defined $p->{summary}){
    $summary = $p->{summary};
    $summary =~ s/\\n/\n/gs;
    $summary =~ s/\\t/\t/gs;
  }
  elsif(defined $p->{file}){
    $summary = $self->read_file_into_string($p->{file});
  }

  $p->{tk_object}->{summary_text}->insert('0.0', $summary);
  $p->{tk_object}->{summary_text}->configure(-wrap=>'word',-state=>"disabled");
  $p->{tk_object}->{summary_text}->
    pack(-fill => 'both', -expand=>'1', -side => 'top');

  return $p->{tk_object}->{summary_text};

} # sub

# PUBLIC. add a page containing only labeled entries (possible with buttons)
sub add_le_page{
  my ($self, $frame, $p) = @_;
  my $o = $self->{opt}->{gui};
  $o = eval $p->{opt_section} if (defined $p->{opt_section});

  # construct all common page elements
  my $f = $self->page_body_container($frame, $p);

  # compute the largest title:
  my $title_length = 0;
  for my $i (0 .. scalar @{$p->{LabeledEntry}} - 1){
    if ($p->{LabeledEntry}[$i]->{status} ne 'invalid'){

      # some titles must be evaluated...
      my $title = $p->{LabeledEntry}[$i]->{title};
      $title = eval $title if $p->{LabeledEntry}[$i]->{evaluate};

      $title_length = length($title)
	if ( length($title) ) > $title_length;
    }
  }

  # paint list of labeled entries
  for my $i (0 .. scalar @{$p->{LabeledEntry}} - 1) {
    if ($p->{LabeledEntry}[$i]->{status} ne 'invalid'){

      my $name = $p->{LabeledEntry}[$i]->{name};
      my $title = $p->{LabeledEntry}[$i]->{title};
      $title = eval $title if $p->{LabeledEntry}[$i]->{evaluate};

      # here are fererences to all three objects of LabeledEntry
      (
	$p->{tk_object}->{LabeledEntry}->{$name}->{label},
	$p->{tk_object}->{LabeledEntry}->{$name}->{entry},
	$p->{tk_object}->{LabeledEntry}->{$name}->{commando},
       ) = $self->add_labeled_entry(
	 $f, $title,                                  # frame and title
	 \$o->{$name}->{value},                       # textvariable
	 $p->{LabeledEntry}[$i]->{status},            # status
	 $title_length,                               # geometry
	 $p->{LabeledEntry}[$i]->{entry_widht},       # geometry
	 $p->{LabeledEntry}[$i]->{button},
       );
    }
  }

  $f->configure(-wrap=>'none', -state => "disabled");
  return $f;

} # sub

# PUBLIC. add a page containing only Radio Buttons
sub add_rb_page{
  my ($self, $frame, $p) = @_;
  my $o = $self->{opt}->{gui};
  $o = eval $p->{opt_section} if (defined $p->{opt_section});

  # construct all common page elements
  my $f = $self->page_body_container($frame, $p);

  # compute the largest title:
  my $title_length = 0;
  for my $i (0 .. scalar @{$p->{RadioButton}} - 1){
    if ($p->{RadioButton}[$i]->{status} ne 'invalid'){
      # some titles must be evaluated...
      my $title = $p->{RadioButton}[$i]->{title};
      $title = eval $title if $p->{RadioButton}[$i]->{evaluate};
      $title_length = length($title)
	if ( length($title) ) > $title_length;
    }
  }

  # paint all check buttons
  for my $i (0 .. scalar @{$p->{RadioButton}} - 1){
    if ($p->{RadioButton}[$i]->{status} ne 'invalid'){
      my $name = $p->{RadioButton}[$i]->{name};
      my $title = $p->{RadioButton}[$i]->{title};
      $title = eval $title if $p->{RadioButton}[$i]->{evaluate};

      $p->{tk_object}->{RadioButton}->{$name} = $self->add_radio_button(
        $f, $title,                           # frame and title
        \$o->{$p->{variable}}->{value},       # variable
        $name,                                # value
        $p->{RadioButton}->[$i]->{status},    # status
        $title_length,                        # length
       );
    }
  }
  $f->configure(-wrap=>'none', -state => "disabled");
  return $f;
} # sub


# PUBLIC. add a page containing only Check Buttons
sub add_cb_page{
  my ($self, $frame, $p) = @_;
  my $o = $self->{opt}->{gui};
  $o = eval $p->{opt_section} if (defined $p->{opt_section});

  # construct all common page elements
  my $f = $self->page_body_container($frame, $p);

  # compute the largest title:
  my $title_length = 0;
  for my $i (0 .. scalar @{$p->{CheckButton}} - 1){
    if ($p->{CheckButton}[$i]->{status} ne 'invalid'){
      # some titles must be evaluated...
      my $title = $p->{CheckButton}[$i]->{title};
      $title = eval $title if $p->{CheckButton}[$i]->{evaluate};
      $title_length = length($title) if ( length($title) ) > $title_length;
    }
  }

  # paint all check buttons
  for my $i (0 .. scalar @{$p->{CheckButton}} - 1){
    if ($p->{CheckButton}[$i]->{status} ne 'invalid'){

      # some titles must be evaluated...
      my $name  = $p->{CheckButton}[$i]->{name};
      my $title = $p->{CheckButton}[$i]->{title};
      $title = eval $title if $p->{CheckButton}[$i]->{evaluate};

      $p->{tk_object}->{CheckButton}->{$name} = $self->add_check_button(
        $f,                                         # container
        $title,                                     # title
        $p->{CheckButton}[$i]->{status},            # status
        \$o->{$p->{CheckButton}[$i]->{name}}->{value},
        $title_length,
       );
    }
  }

  $f->configure(-wrap=>'none', -state => "disabled");
  return $f;

} #sub

# PUBLIC. This sub gives the user a possibility to create its oun code.
sub add_external_frame{
  my ($self, $pf, $p) = @_;
  &{$p->{build_frame_code}}($self, $pf, $p) if (exists $p->{build_frame_code});
}

# PUBLIC. add a labeled entry into given frame.
# A lab entry can contain some buttons too
sub add_labeled_entry{
  my ($self, $frame, $lable_text, $ref_text_var, $state, $lw, $ew, $button) = @_;
  my $id = $self->{internal}->{assistent_id};
  my $bg = $frame->cget('-background');
  my ($label, $entry, $commando);

  # default length of an entry
  $lw = $lw?$lw:30;
  $ew = $ew?$ew:40;

  $label = $frame->Label(
    -text => $lable_text,
    -font => "radio_font$id",
    -width=> $lw,
    -anchor=>'w',
    -background=>$bg,
    -pady     => '6',
   );

  $entry = $frame->Entry(
    -font => "fixed_font$id",
    -width=> $ew,
    -textvariable => $ref_text_var,
    -state => "$state",
    -fg => $self->{gui}->{entry_foreground},
    -bg => $self->{gui}->{entry_background},
    -highlightbackground => $self->{gui}->{entry_highlightbackground},
    -highlightcolor      => $self->{gui}->{entry_highlightcolor},
    -selectforeground    => $self->{gui}->{entry_select_foreground},
    -selectbackground    => $self->{gui}->{entry_select_background},
   );

  # some entries can have buttons (f.e. for easy select dirs and files)
  if ($button and $button eq 'dir_select'){
    $commando = $frame->Button(
      -text    => $self->{gui}->{button_dir_select},
      -width   => 10,
      -relief  => $self->{gui}->{buttons_relief},
      -fg      => $self->{gui}->{button_foreground},
      -bg      => $self->{gui}->{button_background},
      -activeforeground => $self->{gui}->{button_select_foreground},
      -activebackground => $self->{gui}->{button_select_background},
      -disabledforeground => $self->{gui}->{button_disabled_foreground},
      -command => sub {
          $self->dir_select_dialog( $ref_text_var, $lable_text, );
        }
    );
  }
  elsif($button and $button eq 'file_open'){
    $commando = $frame->Button(
      -text    => $self->{gui}->{button_file_open},
      -width   => 10,
      -relief  => $self->{gui}->{buttons_relief},
      -fg      => $self->{gui}->{button_foreground},
      -bg      => $self->{gui}->{button_background},
      -activeforeground => $self->{gui}->{button_select_foreground},
      -activebackground => $self->{gui}->{button_select_background},
      -disabledforeground => $self->{gui}->{button_disabled_foreground},
      -command => sub { $$ref_text_var =
          $self->file_open_dialog( $$ref_text_var, $lable_text, );
        }
    );
  }

  $frame->insert('end', "  ");
  $frame->windowCreate('end',-window=>$f,-padx=>2,-pady=>1,-stretch=>1);
  $frame->windowCreate('end',-window=>$label,-padx=>2,-pady=>1,-stretch=>1);
  $frame->windowCreate('end',-window=>$entry,-padx=>2,-pady=>1,-stretch=>1);
  $frame->windowCreate('end',-window=>$commando,-padx=>2,-pady=>1,-stretch=>1);
  $frame->insert('end', "\n");
  return ($label, $entry, $commando);

}# sub

# PUBLIC. add a radio button into the given frame
sub add_radio_button{
  my ($self, $frame, $text, $variable, $value, $state, $width) = @_;
  my $id = $self->{internal}->{assistent_id};
  my $bg = $frame->cget('-background');

  my $button  = $frame->Radiobutton(
    -variable => $variable,
    -text     => $text,
    -value    => $value,
    -state    => $state,
    -anchor   => 'w',
    -font     => "radio_font$id",
    -width    => $width,
    -pady     => '6',
    -fg       => $self->{gui}->{radio_button_foreground},
    -bg       => $self->{gui}->{radio_button_background},
    -activeforeground => $self->{gui}->{radio_button_select_foreground},
    -activebackground => $self->{gui}->{radio_button_select_background},
    -disabledforeground => $self->{gui}->{radio_button_disabled_foreground},
   );

  $frame->insert('end', "  ");
  $frame->windowCreate('end',-window=>$button,-padx=>2,-pady=>1,-stretch=>1);
  $frame->insert('end', "\n");
  return $button;
}# sub


# PUBLIC. add CheckButton into the given frame
sub add_check_button{
  my ($self, $frame, $text, $state, $value_ref, $title_length) = @_;
  my $id = $self->{internal}->{assistent_id};
  my $bg = $frame->cget('-background');

  my $button = $frame->Checkbutton (
    -variable    => $value_ref,
    -indicatoron => 1,
    -text        => $text,
    -justify     => 'left',
    -font        => "radio_font$id",
    -anchor      => 'w',
    -state       => $state,
    -width       => $title_length,
    -pady     => '6',
    -fg       => $self->{gui}->{radio_button_foreground},
    -bg       => $self->{gui}->{radio_button_background},
    -activeforeground => $self->{gui}->{check_button_select_foreground},
    -activebackground => $self->{gui}->{check_button_select_background},
    -disabledforeground => $self->{gui}->{check_button_disabled_foreground},
    -selectcolor => $self->{gui}->{check_button_select_indicator},
   );

  $frame->insert('end', "  ");
  $frame->windowCreate('end',-window=>$button,-padx=>2,-pady=>1,-stretch=>1);
  $frame->insert('end', "\n");
  return $button;

}# sub

# PUBLIC. dialog to help user to fild directory.
sub dir_select_dialog{
  my ($self, $ref_text_var, $lable_text, ) = @_;
  my $font = "fixed_font" . $self->{internal}->{assistent_id};
  my $startdir = '/';
  my $current_directory = cwd;

  # transient top level window
  my $w = $self->parent->Toplevel( -title => $lable_text, );
  $w->geometry('=640x480');
  $w->grab;

  #DirTree frame is displayed at the dialog bottom
  my $dir_tree  = $w->Scrolled (
    "DirTree",
    -scrollbars       => 'osoe',
    -selectmode       => 'browse',
    -relief           => $self->{gui}->{relief},
    -selectbackground => 'navy',
    -selectforeground => $self->{gui}->{select_foreground},
    -browsecmd        => sub {$$ref_text_var = shift },
    -background       => $defs->{background},
    -foreground       => $defs->{foreground},
    -font             => $font,
   )->pack(-side => 'bottom', -fill=>"both",
           -expand=>1, -padx=>0, -pady=>0, -ipadx=>10,);

  # top frame with the result entry and device buttons
  my $top_frame = $w->Frame(
    )->pack(-side=>'top', -expand=>0, -fill=>'x', -padx=>10, -pady=>10);

  # entry field to write the path into
  my $entry  = $top_frame->Entry(
    -justify      => 'left',
    -textvariable => $ref_text_var,
    -font         => $font,
    -fg => $self->{gui}->{entry_foreground},
    -bg => $self->{gui}->{entry_background},
    -highlightbackground => $self->{gui}->{entry_highlightbackground},
    -highlightcolor      => $self->{gui}->{entry_highlightcolor},
    -selectforeground    => $self->{gui}->{entry_select_foreground},
    -selectbackground    => $self->{gui}->{entry_select_background},
   )->pack(-side=>'top', -anchor=>'w',
           -expand =>1, -fill=>"x",
           -padx=>10, -pady=>10);

  # device buttons (only for windows)
  if ( $OSNAME eq "MSWin32" ){

    $startdir = "C:\\";
    my %drives_button;
    my @logical_drives = Win32API::File::getLogicalDrives();

    foreach my $d (@logical_drives){
      $top_frame->Button(
        -text    => "$d",
        -relief  => $self->{gui}->{buttons_relief},
        -fg      => $self->{gui}->{button_foreground},
        -bg      => $self->{gui}->{button_background},
        -activeforeground => $self->{gui}->{button_select_foreground},
        -activebackground => $self->{gui}->{button_select_background},
        -disabledforeground => $self->{gui}->{button_disabled_foreground},
        -command => sub {
            $dir_tree->delete('all');
            chdir $d && $dir_tree->configure(-directory=>$d);
            return 1;
          },
      )->pack(-side=>'left', expand=>0, -fill=>'x', -padx=>2,);
    }
  }

  # done button - end of dialog. in the command is build chdir to start dir
  $top_frame->Button(
    -text   => $defs->{button_done},
    -width  => 10,
    -relief  => $self->{gui}->{buttons_relief},
    -fg      => $self->{gui}->{button_foreground},
    -bg      => $self->{gui}->{button_background},
    -activeforeground => $self->{gui}->{button_select_foreground},
    -activebackground => $self->{gui}->{button_select_background},
    -disabledforeground => $self->{gui}->{button_disabled_foreground},
    -command=> sub { chdir $current_directory ; $w->destroy(); },
   )->pack( -side=>'right', -expand =>0, -fill=>'x', -padx=>10, -pady=>10);

  # initial directory
  $dir_tree->delete('all');
  if ( defined $$ref_text_var and -d $$ref_text_var ){
    $startdir = $$ref_text_var;
  }
  elsif(defined $$ref_text_var and -d dirname $$ref_text_var){
    $startdir = dirname $$ref_text_var;
  }

  $dir_tree->configure(-directory=>$startdir);

  return 1;
}# sub


# PUBLIC. file open dialog
sub file_open_dialog{
  my ($self, $text_var, $lable_text, ) = @_;
  my $font = "fixed_font" . $self->{internal}->{assistent_id};

  # under windows and under linux getOpenFile is more beauty
  if ($OSNAME =~ /win/i or $OSNAME =~ /^linux/i ) {
    return $self->parent->getOpenFile(-title=>$lable_text,);
  }
  # this is portable, Motiff look and feel
  else {
    return $self->parent->FileSelect(-directory => '.', -title=>$lable_text)->Show;
    }
}# sub


################################################################################
# event handling                                                               #
################################################################################

# Asiistent wide dispatch event handler if any. returns 0 if OK
sub dispatch {
  my ($self, $handler) = @_;
  return (!($handler->())) if defined $handler;
  return 0;
} # sub

# Page Wide dispatch event handler. Containing in page hash.
# standard actions are
#
#   pre_display_code
#   post_display_code
#   pre_next_button_code
#   pre_back_button_code
#   post_next_button_code
#   post_back_button_code
#   pre_close_windows_code
#   post_close_windows_code
#   finish_button_code
#   help_button_code
#   pre_cancel_button_code
#
# returns 0 if OK
sub dispatch_generic_callback{
  my ($self, $action) = @_;
  my $current_node = $self->current_node();
  my $current_object = $self->get_page($current_node);

  return 0 unless (exists $current_object->{$action});

  # action defined as code ref (from hash)
  return (! &{$current_object->{$action}}( $self ) )
    if (ref $current_object->{$action} eq 'CODE');

  # action defined as string (from XML)
  return (! eval $current_object->{$action} )
    if(not ref $current_object->{$action});

  return 0;
}

# next button callback
sub next_button_event{
  my $self = shift;

  my $current_node = $self->current_node();
  my $next_node = $self->get_page($current_node)->{right};

  # dispatch user defined event processing
  return if ($self->dispatch($self->cget(-preNextButtonAction)));

  # not the last page
  if ( $next_node ne 'NULL'){
    # dispatch event processing defined in page hash
    return if $self->dispatch_generic_callback('pre_next_button_code');

    # go next
    # 1. The current node was not changed in callback:
    if ($current_node eq $self->current_node){
      $current_node = $self->current_node($next_node);
    }
  }

  # very last page
  else{
    return if $self->dispatch_generic_callback('pre_next_button_code');

    # destroy the parent window and do not render anything
    $self->finish_button_event;

    # but the post processing code should run
    $self->dispatch( $self->cget(-postNextButtonAction));
    $self->dispatch_generic_callback('post_next_button_code');

    return;
  }

  # show me
  $self->render($self->current_node);

  # post processing code
  $self->dispatch( $self->cget(-postNextButtonAction));

  # dispatch event processing defined in page hash
  $self->dispatch_generic_callback('post_next_button_code');

} # sub

# finish_button_event
sub finish_button_event{
  my $self = shift;

  # dispatch event processing
  return if ($self->dispatch( $self->cget(-finishButtonAction)));
  return if $self->dispatch_generic_callback('finish_button_code');

  # set WizardMaker return status
  $self->{internal}->{status} = 'GOOD';

  # destroy the parent window and do not render anything
  $self->close_window_event();

  return;
}

# back button callback
sub back_button_event{
  my $self = shift;

  my $current_node = $self->current_node();
  my $pre_node = $self->get_page($current_node)->{left};

  # dispatch user defined event processing
  return if ($self->dispatch( $self->cget(-preBackButtonAction)));

  # not the last page
  if ( $pre_node ne 'NULL'){
    # dispatch event processing defined in page hash
    return if ($self->dispatch_generic_callback('pre_back_button_code'));

    # go back
    $current_node = $self->current_node($pre_node);
  }

  # show me
  $self->render($self->current_node);
  $self->dispatch( $self->cget(-postBackButtonAction));

  # dispatch event processing defined in page hash
  $self->dispatch_generic_callback('post_back_button_code');

} # sub

# help button callback
sub help_button_event{
  my $self = shift;
  my $id = $self->{internal}->{assistent_id};

  # dispatch user defined event processing
  return if ($self->dispatch( $self->cget(-HelpButtonAction)));

  # dispatch event processing defined in page hash
  return if ($self->dispatch_generic_callback('help_button_code'));

  # determine help text
  my $current_node = $self->current_node;
  my $text = $self->get_page($current_node)->{help_text}
    if (exists $self->get_page($current_node)->{help_text});

  # show help
  $self->show_message ($text, 'help');

} #sub

# cancel button callback
sub cancel_button_event{
  my $self = shift;

  # dispatch user defined event processing

  return if ($self->dispatch( $self->cget(-preCancelButtonAction)));

  # dispatch event processing defined in page hash end EXIT
  return if ($self->dispatch_generic_callback('pre_cancel_button_code'));

  # this is not really important here
  $self->{internal}->{status} = 'CANCELED';

  # TODO: here - warning
  $self->close_window_event();

} # sub

# close window callback
sub close_window_event{
  my $self= shift;

  # dispatch user defined event processing
  return if ($self->dispatch( $self->cget(-preCloseWindowAction)));

  # dispatch event processing defined in page hash end EXIT
  return if ($self->dispatch_generic_callback('pre_close_windows_code'));

  # this is the trick - the parent window will be destroyed but not the
  # WizardMaker instance
  $self->parent->WmDeleteWindow;

  return if ($self->dispatch_generic_callback('post_close_windows_code'));

} # sub

################################################################################
# some help finctions                                                          #
################################################################################
# reads a file into string and returns it. It was designed for small READMEs
# with variable substitutions.
sub read_file_into_string{
  my ($self, $file) = @_;
  my $text = "could not open file : $file ";

  if (open(README, "<$file")) {
    $text = join '', <README>;
    close README;
  }
  return eval "qq($text)";
}# sub

# PUBLIC. display warning message box
sub show_message {
  my ($self, $message, $type, $title, $buttons)  = @_;
  my $icon = $type;

  $buttons = 'OK' unless defined $buttons;
  if (not defined $type) { $icon = 'info'; $type = 'info';}
  elsif($type eq 'help') {$icon = 'question'; }

  $title = $defs->{$type . '_title'} unless defined $title;
  $message = $defs->{'no_' . $type  .'_text'} unless defined $message;

  my $answer_text = $self->messageBox(
      -icon    => $icon,
      -title   => $title,
      -message => $message,
      -type    => $buttons,
      );

  return 1 if ($answer_text eq 'yes' or $answer_text eq 'Yes');
  return 0;
}# sub

# PUBLIC. only for debugging of the page creation and navigation
sub walk{
  my $self = shift;
  my $page = $self->first_node();

  if ($page){
    while  ($self->{internal}->{pages}->{$page}->{right} ne 'NULL'){
      print "\n\tPage: ", $page;
      $page = $self->{internal}->{pages}->{$page}->{right};
    }
    print "\n\tPage: ", $page;
  }
}# sub

################################################################################
#  Some matipulator functions just like get* and set*                          #
################################################################################
# PUBLIC. returns commont element as Object ref. Common elements are :
# WizardMaker_id, total_pages, buttons and frames (main_frame, user_frame, ...)
sub get_common_element{
  my ($self, $element_name)  = @_;
  return $self->{internal}->{$element_name};
} #sub

# PUBLIC. Returns current value of given commont element options. Just like cget.
sub cget_common_element{
  my ($self, $element_name, $option)  = @_;
  return $self->{internal}->{$element_name}->cget($option);
} #sub

# PUBLIC. Configures common element. Just like Tk - configure. This is only
# usefull, if common element is a Tk - element like button or frame
sub configure_common_element{
  my ($self, $element_name, @options)  = @_;
  return $self->{internal}->{$element_name}->configure(@options);
} #sub

# PUBLIC. Adds a new common element. Parameter are element name and REF to it.
sub add_common_element{
  my ($self, $element_name, $element_ref_or_value)  = @_;
  $self->{internal}->{$element_name} = $element_ref_or_value;

} #sub

# PUBLIC. Removes common element. All packed subelements are forgotten.
sub drop_common_element{
  my ($self, $element_name)  = @_;

  foreach my $s ($self->{internal}->{$element_name}->packSlaves){
    $s->packForget;
  }

  $self->{internal}->{$element_name}->packForget;
  $self->{internal}->{$element_name} = undef;

} # sub

# PUBLIC. Sets left/top images. Parameters are:
# position (can be 'top' or 'left'), image name and image file
sub set_common_image{
  my ( $self, $position, $image_name, $image_file ) = @_;

  return 1 unless ($position eq 'top' or $position eq 'left');

  my $id = $self->{internal}->{assistent_id};
  my $image;

  eval {
    $image = $self->Photo(${image_name}.${id}, -file=>$image_file);
    $self->configure_common_element($position . '_image', ('-image', $image));
  };

  warn $@ if $@;     # where good for debugging ...
  return 0;

} # sub


# PUBLIC. returns page as Object ref.
sub get_page{
  my ($self, $page)  = @_;
  my $name = $self->find_node($page);

  return $self->{internal}->{pages}->{$name} if ($name);
  return undef;

} # sub

# PUBLIC. returns page element as Object Reference
sub get_page_element{
  my ($self, $page_name, $element, $subelement)  = @_;

  my $page = $self->get_page($page_name);
  return unless $page;

  if(grep {/^$element$/} qw/RadioButton CheckButton LabeledEntry/ ) {
    return $page->{tk_object}->{$element}->{$subelement};
  }
  elsif($element eq 'summary_text' and $subelement){
    return $page->{tk_object}->{$element}->{SubWidget}->{$subelement};
  }
  else{
    return $page->{tk_object}->{$element};
  }

} #sub

# PUBLIC. Returns current value of given element options. Just like cget.
sub cget_tk_element{
  my ($self, $element_ref, $option)  = @_;
  return $element_ref->cget($option);
} # sub

# PUBLIC. Manipulate the Title of a builded page. Just like configure.
sub configure_tk_element{
  my ($self, $element_ref, @options)  = @_;
  return $element_ref->configure(@options);
} # sub

# PUBLIC. get the instance ID
sub get_assistent_id{
  my $self  = shift;
  return $self->{internal}->{assistent_id};
} # sub

# PUBLIC.
sub get_user_frame{
  my ($self, $page)  = @_;
  return $self->{internal}->{pages}->{$page}->{frame};
} # sub

# PUBLIC. get or set GUI option
sub gui_option{
  my ($self, $key_name, $key_value) = @_;

  $self->{opt}->{gui}->{$key_name}->{value} = $key_value if (defined $key_value);
  return $self->{opt}->{gui}->{$key_name}->{value};
} # sub

# PUBLIC. find page as Object.
sub get_page_frame{
  my ($self, $page)  = @_;
  return $self->{internal}->{pages}->{$self->find_node($page)}->{frame};
} # sub

# PUBLIC. get or set subtitle
sub page_subtitle{
  my ($self, $page, $new_subtitle)  = @_;
  $self->{internal}->{pages}->{$self->find_node($page)}->{subtitle} = $new_subtitle
    if (defined $new_subtitle);
  return $self->{internal}->{pages}->{$self->find_node($page)}->{subtitle};
} # sub

# PUBLIC. get or set text (the 3th. element in the title)
sub page_text{
  my ($self, $page, $new_text)  = @_;
  $self->{internal}->{pages}->{$self->find_node($page)}->{text} = $new_text
    if (defined $new_text);
  return $self->{internal}->{pages}->{$self->find_node($page)}->{text};
} # sub

#PUBLIC
sub create_progress_bar{
  my ($self, $steps, $colors)  = @_;

  $colors = [0, $self->{gui}->{progress_bar_color}] unless (defined $colors);
  $steps  = 100 unless (defined $steps)  ;

  $self->{gui}->{progress_bar} = 0;

  my $deco = $self->get_common_element('deco_frame');

  my $pb = $deco->ProgressBar(
      -width    => 20,
      -length   => 800,
      -anchor   => 'w',
      -from     => 0,
      -to       => 100,
      -blocks   => $steps,
      -colors   => $colors,
      -variable => \$self->{gui}->{progress_bar},
     )->pack();

  $self->add_common_element('progress_bar', $pb);
  $self->parent->update;
}

sub set_progress_bar{
  my ( $self, $value, $op  ) = @_;

  if(not defined $op or $op eq 'set'){
      $self->{gui}->{progress_bar} = $value;
  }
  else{
    $self->{gui}->{progress_bar} += $value;
  }

  # show updates
  $self->parent->update;

} #sub

sub drop_progress_bar{
  mx $self = shift;

  $self->drop_common_element('progress_bar');
  $self->configure_common_element('deco_frame', (-height=>'1'));
  $self->parent->update;

} #sub


1;


__END__

################################################################################
#  POD documentation                                                           #
################################################################################

=head1 NAME

Tk::XML::WizardMaker - easy way to build the Software Assistants and
Installation Wizards based on XML description.

=head1 SYNOPSIS

To use Tk::XML::WizardMaker just provide an XML file with descriptions of
the WizardMaker's features and of the feaures of all its pages. Then use
something like this:

  use Tk;
  use Tk::XML::WizardMaker;

  my $mw = MainWindow->new();
  $mw->WizardMaker([<options>])->build_all();

  MainLoop;

For B<other usage possibilities> please see the methods description below.

=head1 DESCRIPTION

=head2 What is the Tk::XML::WizardMaker?

The Software Wizards are popular for tasks like software installation,
upgrade or just gathering of configuration options. There is a lot of
good software (often called as Install Schild) which provides
developers with APIs for building of those Wizards.

This package is just one "Install Shild" more.

Many of those Install Shields provide only API interface. You have
a lot of functions or methods to build a wizard page and to bind
some callbacks. So if you develope an install script, you have to
code in how to create and maintain all its wizard pages.

If you maintains this script some time later (because the new
release of your software is ready in 6 months), you will have to
change a lot of code. If you want to add a new page into the old
script, you have to program:

  1. prepare variables to hold new values.
  2. the code to create the new page with all its components.
  3. changes in callbacks (what to do on the NEXT button)

But all this is not your problem as it is a new developer
who must maintain your script now ...

After some new releases your script is less readeable and seems to
have bugs.

Not so if you use the Tk::XML::WizardMaker. It does provide an API interface
too, but it can help you separate the page building from what to do
with information gathered.

You just describe the entire wizard in XML. All the pages will be than
generated automatically.

All callbacks can be described both in XML or directly in the script
code. All callbacks can be individual functions for every page -
your code is more.

If you will maintain your script some time later, the only you
have to do is to program

  1. what to do with new informations.

All other things can be descriptive XML code.


=head2 Why to use Tk::XML::WizardMaker?

Here are some features of the Tk::XML::WizardMaker:

=over

=item *

It is easy to use.

=item *

It separates the program logic from the GUI generation and event processing.

=item *

It provides a simle XML description of all GUI features in one file.

=item *

Some types of page layouts are predefined. So you can simply describe
what kind of page you wanto to have and which elemets have to be
displayed with it.

=item *

To add a new page into the Program is as simple as to write some
lines of XML code.

=item *

You don't have to insert any event handling code into
your program. But If you need this, it is possible to include
event handling subroutines direct into XML description for
any page.

=item *

An object oriented interface is although provided. So you can be
creative developing new page layouts and extending features.

=back

=head2 How to use It?

=over

=item B<1. GUI FILE. Prepare XML file with GUI description.>

This file should look like this (four pages here, for more complex
examples look below in this document and in the demo files):

=over 8

=item *

<my_assistent

  title="Demo WizardMaker"
  left_image="left_image.gif"
  top_image="top_image.gif">

    <page name     = "Start"
          status   = "normal"
          type     = "TextPage"
          title    = "The first generic Page"
          subtitle = "The first generic Page Subtitle"
          text     = "The first generic Page Text"
          summary  = "Welcome to the Installatin WizardMaker. blah blah blah ..."
          help_text= "Press NEXT to install or CANCEL to abort!"
    />

   <page name      ="UserInfo"
          status   ="normal"
          type     ="LabeledEntriesPage"
          title    ="User Information"
          subtitle ="Some customer data.">

      <LabeledEntry name="Name"    title="Name"     status="normal"/>
      <LabeledEntry name="Company" title="Company"  status="normal" />
      <LabeledEntry name="Install_path"  title="Directory"
                    status="normal" button = "dir_select"/>
    </page>

   <page name      ="SelectComponents"
          status   ="normal"
          type     ="CheckButtonPage"
          title    ="Software Components"
          subtitle ="List of available sotfware components."
          text     ="Please select components you want to install.">

      <CheckButton name="Java"   title="Java SDK"     status="normal" />
      <CheckButton name="Office" title="Office Suite" status="normal" />
      <CheckButton name="DB"     title="Database"     status="normal" />

    </page>

    <page name="StartInstallation"
          status="normal"
          type="TextPage"
          title="Start Installation"
          subtitle="Installation will start now."
          text="Press Start button to process the Installation."
          summary="All software yuo have choosen will be installed. NOW!"
          help_text="Press Start button to process the Installation!"
          pre_next_button_code="
            print qq/\n\tYou can place the installation code here!/;
            sleep 3;
            return 1;
          "
    />

    <page name     ="Finish"
          status   ="normal"
          type     ="TextPage"
          title    ="Finish"
          subtitle ="Installationd is complete."
          text     ="Press FINISH to end Wizard."
          summary  ="Installation complete."
    />

</my_assistent>

=back

I shell refer this file as GUI.XML.

In the current implementation, all structures comming from GUI.XML
file are saved in hash $self->{gui}. All pages constructed on the
basis of GUI.XML are then saved in the hash $self->{internal}->{pages}.
This inplementation details can change, but there are methods to
refer to this structures.

The XML files will be parsed with XML::Simple. So be carefull in
how to write the file.


=item B<2. OPT FILE. Optionally prepare XML file with Installation
description.>

This file should contain default values for GUI pages and action
descriptions to process installation. I shell refer this file as
OPT.XML. It is not really nessesary. I use it for two reasons.

  - I want to separate the GUI from what to do to install the
    software. So I describe all the installation steps in this
    separate file. The tags here are free except of <gui> - tag.

  - I want to have only one place for all variables used in the GUI.
    So I place all default values in the OPT file under <gui>. Then
    in the WizardMaker these variables can change values.

    All them are currently maintained as $self->{opt}->{gui} hash.
    Use method gui_option() to get or set this values in your
    script.

    This way all the variables can be comfortably pre- or
    postprocessed.

If you do not like the OPT.XML you have just to set default values
manually in you script. See demo_04 for how to do so.

A simple version of OPT.XML may looks like this (the element names
here are the same as the corresponding attribute "name" in the GUI
file). Once again - only <gui> tag is important, all other tags
CAN be used by you to describe the installation steps.

<opt>

  <gui>

    <Name          value="MyName" />
    <Company       value="MyCompany" />
    <Office        value="1" />
    <DB            value="0" />
    <Install_path  value="C:\\Programs" />

  </gui>

  <instal>
    <part name="database">
      <command="copy" src="D:\\database\\dings.dll" dest="C:\\WINNT" />
      <command="exec" command="SetupDB.exe" dest="$self->gui_option(q/Install_path/)" />
      <command="eval" command="
        main::patch_registry(qq/Software\\myDB\\description/, $self->gui_option(q/Name/))"
        />
    </part>
  </instal>

</opt>


=item B<3. WIZARD FILE.>

Now you can use the WizardMaker in your Wizard (or what is the
name of your Program?):

  use Tk::XML::WizardMaker;

  # The WizardMaker is based on Tk::Frame, so we need a MainWindow
  my $mw = Tk::MainWindow->new();

  # initialize a new instance. There are no pages yet.
  my $w = $mw->WizardMaker(
    -gui_file => 'gui.xml',
    -opt_file => 'opt.xml');

  # add all valid pages to the instance.
  $w->build_all();

  # Go!
  Tk::MainLoop;



Don't forget to write the installation code as well...

=back


=head1 OPTIONS

=over

=item *

Almost all features and beheavors of Tk::XML::WizardMaker can be customised.

=item *

All options can be defined in an XML file. The only exceptions are
options B<-gui>, B<-gui_file>, B<-opt>, B<-opt_file> which self define wich
XML files to use.

=item *

All options have build in defaults.

=item *

I don't really use the X11 resource database
and do provide some replacement options due to compatibility reasons.

=back

=head2 Instance whide options

Since Assistant is a Tk::Frame, there can be more then one WizardMaker
instances in one time.

All instance wide options can be overwritten during WizardMaker
creation or later with given API or direct with Tk commando
B<configure>.


They have form of document root attributes if defined in XML file:

  background = "gray"

or, they can be defined as perl list if specified as call or
config option:

  $main_window->WizardMaker( -background => 'gray');

GUI Description (only one of the following options is possible)

  -gui              # a perl hash with assistent discription
  -gui_file         # an XML file with assistent discription. If you
                    # read it with XML::Simple->XMLIn, it beckoms the same
                    # form as -gui - hash.

Process Instruction Descriptions and default values. (One or no
of the options must be defined)

  -opt              # a perl hash
  -opt_file         # an XML file

Grafic images to use on the WizardMaker pages (GIF files). The left
image will be displayed on the first and last pages, on all other
pages will be displayed top_image. The options can be redefined
for every page with top_image_name and top_image_file (see demo_03).

  -top_image        # file to display on top of WizardMaker
  -left_image       # file to display on its left site

Default Fonts (can be rewritten on the page level):

  -title_font        # for the page title
  -subtitle_font     # for the page subtitle
  -subsubtitle_font  # for the page subsubtitle
  -small_font        # small font (not really used)
  -text_font         # text font
  -radio_font        # for radio buttons, check buttond and entries
  -fixed_font        # fixed font
  -button_font       # for command buttons

Default Texts

  -title             # in the title of parent window
  -help_title        # in the title of the online help
  -no_help_text      # default help text
  -warning_title     # in the title of warnings
  -no_warning_text   # default warning text
  -error_title       # in the title of the error messages
  -no_error_text     # default error text
  -info_title        # in the title of the online info
  -no_info_text      # default info text

  -button_help       # for help button
  -button_next       # for next button
  -button_back       # for back button
  -button_finish     # for finish button
  -button_cancel     # forcancel button
  -button_log        # for show log button
  -button_done       # for done button
  -button_dir_select # for dir select button
  -button_file_open  # for file open button

Default Colors and Reliefs (can be rewritten on the page level):

  -foreground         # for all common elements
  -background         # for all common elements
  -select_foreground  # for all common elements (heilight)
  -select_background  # for all common elements (heilight)

  -header_background        # for page headers
  -header_foreground        # for page headers
  -select_header_background # for page headers (heilight)
  -select_header_foreround  # for page headers (heilight)

  -header_background1 # for page header's title
  -header_foreground1 # for page header's title
  -header_background2 # for page header's subtitle
  -header_foreground2 # for page header's subtitle
  -header_background3 # for page header's subsubtitle
  -header_foreground3 # for page header's subsubtitle

  -button_background          # for buttons
  -button_foreground          #
  -button_select_foreground   #
  -button_select_background   #
  -button_disabled_foreground #

  -button_frame_background    # for the buttons' frame
  -button_frame_select_foreground
  -button_frame_select_background

  -radio_button_foreground    # for radio buttons
  -radio_button_background
  -radio_button_select_foreground
  -radio_button_select_background
  -radio_button_disabled_foreground

  -check_button_foreground    # for check buttons
  -check_button_background
  -check_button_select_foreground
  -check_button_select_indicator
  -check_button_select_background
  -check_button_disabled_foreground

  -entry_foreground           # for text entries
  -entry_background
  -entry_highlightbackground
  -entry_highlightcolor
  -entry_select_foreground
  -entry_select_background

  -relief            # relief (see Tk man pages) for common elements
  -buttons_relief    # relief (see Tk man pages) for buttons

Geometry of the parent window (values following are user in -geometry option):

  -wish_width
  -wish_height
  -wish_x
  -wish_y

=head2 Page types and its options.

The WizardMaker can process pages of some predefined types. This is no really
restriction - as you have access to the Programming Interface, you can
design any page layouts.

=over

=item *
  TextPage

  Pages of this type contain only a message text such as release notes
  or license agreements.

  Page specific options / attributes / elements:

    summary    # Option. Text to display
    file       # Option. File whith Text to display


=item *
  LabeledEntriesPage

  Pages of this type contain only entries to put single text. An entry can
  optionally have a button to search files and directories in file system.

  Page specific options / attributes / elements:

    LabeledEntry # Element with attributes:

      name       # Internal name of element
      title      # Label
      status     # display status (normal or disabled)
      evaluate   # when 1, the title will be evalueted befor displaying.
      button     # predefined Button at right site
                 # (at present only dir_select / file_open)

=item *
  RadioButtonPage

  Pages of this type contain only Radio Buttons.

  Page specific options / attributes / elements:

    RadioButton  # Element with attributes:

      name       # Internal name of element
      title      # Label
      status     # display status (normal or disabled)
      evaluate   # when 1, the title will be evalueted befor displaying.


=item *
  CheckButtonPage

  Pages of this type contain only Check Buttons.

  Page specific options / attributes / elements:

    RadioButton  # Element with attributes:

      name       # Internal name of element
      title      # Label
      status     # display status (normal or disabled)
      evaluate   # when 1, the title will be evalueted befor displaying.


=item *
  ExternalPage

  Pages of this type are of free layout. The WizardMaker don't knows
  how to build them. Use the method

  build_external_page()

  to build such pages.

=back


=head1 API (Methods)

=head2 Building WizardMaker:

=over

=item * new

  It is simple the Tk - constructor. It creates new instance of
  WizardMaker. No pages are added yet.

  Parameters are -gui, -gui_file, -opt, -opt_file

  Usage Example:
    my $wizard = MainWindow->new()->WizardMaker(-gui_file=>'my_gui_file.xml');

=item * build_all

  Processes all options , creates all pages and shows the assistent

  Usage Example:
    $wizard->build_all();

=item * add_all_pages

  Processes all options , creates all pages

  Usage Example:
    $wizard->add_all_pages();

=item * show

  Shows the assistent

  Usage Example:
    $wizard->show();

=back

=head2 Node building and navigation

=over

=item * build_node

  Create only node structure.

  The only parameter is a hash reference to page attributes

  Usage Example:
    $wizard->build_node($p);

=item * build_generic_node

  Calls build_node and makes some preparations for common layout.
  This method should never be used directly.

  The only parameter is a hash reference to attributes of new page.

  Usage Example:
    $wizard->build_generic_node($p);

=item * build_external_node

  This procedure is intend to build page types not provided by
  WizardMaker themself.

  The only parameter is a hash reference to attributes of new page.

  Usage Example:
    $wizard->build_external_node($p);

=item * link_node

  All pages are bind together with double linked list.
  This method links a node on the given position.

  Paremeters are:

    page name
    how to link ('after', 'before')
    where to link   (name, 'first', 'last')

  Usage Example:
    $wizard->link_node('myVeryFirstPage', 'before', 'first');
    $wizard->link_node('myVeryLastPage', 'after', 'last');
    $wizard->link_node('mySecondPage', 'after', 'myVeryFirstPage');

=item * unlink_node

  Unlinks a node from node list. The node can be accessed
  afterwards by its name.

  Usage Example:
    $wizard->unlink_node('myVeryFirstPage');

=item * find_node

  Returns name of searched page or undef if page does not exist.

  The only parameter is the description of node( name, 'first', 'last')

  Usage Example:
    my $page_name = $wizard->find_node('last');

=item * first_node

  Retutns the first node name in the node list

  Usage Example:
    my $page_name = $wizard->first_node();

=item * last_node

  Retutns the last node name in the node list

  Usage Example:
    my $page_name = $wizard->last_node();

=item * current_node

  Sets or returns the current node name in the node list

  Usage Example:
    my $page_name = $wizard->current_node();
    $wizard->current_node('myNewPage');

=item * is_linked

  Retutns true if node is linked into the node list

  Usage Example:
    print 'I am insite' if ($wizard->is_linked('myGoodPage'));

=back

=head2 Page building

=over

=item * add_text_page

  After a node was created, a Text Page will be constructed.

  Parameters are: Page frame and page description - hash reference

  Usage Example:
    $wizard->add_text_page($pf, $p);

=item * add_le_page

  After a node was created, a labeled Entry Page will be constructed

  Parameters are: Page frame and page desctiption hash reference

  Usage Example:
    $wizard->add_le_page($pf, $p);

=item * add_rb_page

  After a node was created, a RadioButton Page will be constructed

  Parameters are: Page frame and page desctiption hash reference

  Usage Example:
    $wizard->add_rb_page($pf, $p);

=item * add_cb_page

  After a node was created, a CheckButton Page will be constructed

  Parameters are: Page frame and page desctiption hash reference

  Usage Example:
    $wizard->add_cb_page($pf, $p);

=item * add_external_frame

  After a node was created, an External Page will be constructed

  Parameters are: Page frame and page desctiption hash reference

  Usage Example:
    $wizard->add_external_frame($pf, $p);

  This method is usefull only if exists $p->{build_frame_code}.
  It must be a CODE REF.

=item * add_radio_button

  Adds a radio button to RadioButton Page

  Parameters are:
    target frame
    title
    variable behind the entry
    initial value of this variable
    state
    width of value

  Usage Example see in demo directory.

=item * add_check_button

  Adds a Check button to CheckButton Page

  Parameters are:
    target frame
    label text
    state,
    reference to the variable behind the entry
    width of title

  Usage Example see in demo directory.

=item * drop_page

  Drops a given page (inclusive node)

  The only parameter is the page name

  Usage Example:
    $wizard->drop_page('BadPage');

=back

=head2 Common Elements

=over

=item * dir_select_dialog

  opens dialog to help user to fild directory.

  Parameters are
    - reference to variable for directory name
    - Toplevel window title

  Usage Example see in demo directory.

=item * file_open_dialog

  opens standard system dialog to help user to fild a file.

  Parameters are
    - textvariable for file name
    - Toplevel window title

  Usage Example see in demo directory.

=item * show_message

  opens a message windows

  Parameters are
    message text
    type  (info/help/warning/error)
    title text
    buttons description (see -type option of Tk::messageBox)

  Usage Example see in demo directory.

=back

=head2 Configure element options

=over

=item * get_assistent_id

  It is possible to have more than one WizardMaker instance opened
  by parallel. get_assistent_id returns an internal instance ID.

  Usage Example:
    $wizard->get_assistent_id();

=item * get_common_element

  Returns value of a commont element, so you can direct manipulate
  things like buttons and images.

    assistent_id   - only usefull if you have more then one instance
    current_node   - name of the current node
    total_pages    - pages builded (not used)
    status         - 'GOOD' or 'CANCELED' if WizardMaker was not finished propertly

    BUTTONS:
      button_back
      button_cancel
      button_help
      button_next

    FRAMES:
      main_frame
      user_frame
      command_frame
      deco_frame

    IMAGES (as Tk::Label):
      left_image
      top_image

    ALL PAGES (as HASH REFS):
      pages

  The only parameter is the name of common element

  Usage Example:
    $wizard->get_common_element('current_node');

=item * cget_common_element

  Returns current value of given common element options. Just like cget.
  This method is only usefull for common elements - Tk objects.

  Parameters are the element name and option name.

  Usage Example:
    $wizard->cget_common_element('left_image', 'image');

=item * configure_common_element

  Manipulate common element options. Just like configure.

  Parameters are the element name and an option list.

  Usage Example:
    my $image = $wizard->Photo('other_image', -file=>'other_image.gif');
    $wizard->configure_common_element('left_image', ('image', $image));

=item * add_common_element

  Adds a new common element. Parameter are element name and its value. The
  Value can be an object reference too.

  Usage Example:
    $wizard->add_common_element('newHiddenStatusElement', 'OK');

=item * drop_common_element

  Removes common element. All packed subelements are forgotten.

  Usage Example:
    $wizard->drop_common_element('newHiddenStatusElement');


=item * set_common_image

  Sets left/top image. The left_image and right_image are common
  elements shown at the left site of WizardMaker's first and last
  pages and on the top of all other pages. The images are static,
  but you can manipulate them dynamic with this method. Alternative
  you can use get_common_element() and configure_common_element().

  Parameters are:
    - position (can be 'top' or 'left'),
    - image name
    - image file

  Usage Example:
    In the XML description of a page:

    <page name="this_page"
        status="normal"
        type="TextPage"
        title="This Page"
        subtitle="This Page Subtitle"

        pre_next_button_code="
          $self->set_common_image('top', 'next_picture', 'next_picture.gif');
          1;
        "
     />

=item * reset_buttons

  Resets visual options of standard buttons to defaults.
  Paremeter is list of button names. If ommited, all buttons (button_back,
  button_cancel, button_help, button_next) will be reseted.


=item * get_page

  Returns page as Object ref.

  The only parameter is the page name

  Usage Example:
    $wizard->get_page('myPage');

=item * get_page_element

  Returns page element as Object Reference

  Parameters are the page name and element description.
  The element description can be element name or one of
  following

    RadioButton
    CheckButton
    LabeledEntry
    summary_text.

  In the last case the third parameter - subelement should be used.

  Usage Example see in demo directory.

=item * cget_tk_element

  Returns current value of given element options. Just like cget.

  Parameters are the element reference (like given by get_page_element)
  and the option name.

  Usage Example see in demo directory.

=item * configure_tk_element

  Manipulate the Title of a builded page. Just like configure.
  Parameters are the element reference (like given by get_page_element)
  and an option list.

  Usage Example see in demo directory.

=item * get_user_frame

  Returns the user frame of given page. The user frame is a part
  of page frame.

  The only parameter is page name.

=item * gui_option

  Get or set GUI option. Usefull for programmatic manipulation of
  GUI values. The initial values are set normally over OPT.XML
  file.

  The options are placed in WizardMaker as
    $self->{opt}->{gui}->{$option_name}->{$option_value}

  Parameters are option name and option value.

  Usage Example see in demo directory.

=item * get_page_frame

  Returns page frame as Object.

  The only parameter is page name.

  Usage Example see in demo directory.

=back

=head1 DEPENDANCIES

    Tk
    XML::Simple     (requires XML::Parser and File::Spec)
    Data::Dumper
    Storable
    Win32           (Win32 plattform only)
    Win32API::File  (Win32 plattform only)


=head1 SEE ALSO

 XML::Simple, Tk::Wizard

=head1 AUTHOR

Viktor Zimmermann, E<lt>ZiMTraining@gmx.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2004 by Viktor Zimmermann

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.


=cut
