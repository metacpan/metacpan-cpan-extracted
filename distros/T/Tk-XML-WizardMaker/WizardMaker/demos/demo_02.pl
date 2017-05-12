#!/usr/bin/perl -w
################################################################################
#  File : demo_02.pl                                                           #
#  Class driver / testing code                                                 #
#  We create here an WizardMaker with some predefined pages described as       #
#  XML elements.                                                               #
#                                                                              #
#  But in addition we create a page not described in XML file. We reffer to    #
#  such pages as "external pages". We use the object oriented API provided     #
#  with WizardMaker.                                                           #
#                                                                              #
#  This demo could be used as template to expand WizardMaker by new page types #
#                                                                              #
################################################################################

use Tk;
use Tk::XML::WizardMaker;
use Tk::Pane;

# initialize a new WizardMaker instance.
# As template is used the default file gui.xml in current directory
my $mw = MainWindow->new();
my $w  = $mw->WizardMaker();

# add all generic pages as described in default file "gui.xml" in the same
# directory. The installation procedure self is described in the
# pre_next_button_code of the page labeled as "StartInstallation"
$w->add_all_pages();

# Anonymous hash describes the external page. We want this page to contain
# a picture. Assistant do not provided such a page type.
#
# When build new external page the full hash will be automatically cloned
# into WizardMaker object. So it is possible to save and address all features
# of new page.
#
# For this reason I use Storable::dclone. So it is impossible to use CODE REF
# at this place. You can use strings, just like I am using string for
# "code" - key. The string will be evaluated by WizardMaker.
#
# If you want to use CODE REF you can do it after node of the page was
# build (see below).
my $cat_page = {
  name              =>'CatPage',                      # requred, unique
  title             =>"My cat Bilbo",                 # good for style
  subtitle          =>"He is no hobbit ...",          # good for style
  text              =>"Demo 02 shows how to create ". # good for style
                      "external nonstandard pages " .
                      "not described in GUI.XML. ",
  help_text         =>"No Help for cats!",            # optional
  photo_file        =>"cat.gif",                      # optional
  photo_name        =>"My cat Bilbo",                 # optional
  code              =>"print qq/\nBuild CatPage /;",  # optional
 };

# build and link node for new page.
$w->build_external_node($cat_page);
$w->link_node('CatPage', 'before', 'first');

# Now the page node was build and is linked as the first page.
# But it is not current page yet. So the assistent would started
# with the second page. So we make the actual first page to be current.
$w->current_node('first');

# make some bindings for new page. We are using a CODE REF here:
my $page_ref = $w->get_page('CatPage');
$page_ref->{pre_next_button_code} = sub {print "\nCat Page pre next"};

# build the content of external node. Let it be a gif file
#my $user_frame = $w->get_user_frame('CatPage');
&build_pictured_page($w, 'CatPage');

# lets go
$w->show();

print "\nStart Main loop ...\n";
MainLoop;
print "\nStop Main loop\n";

# this is an example how to build an external page. Parameters are:
#  - Reference to the WizardMaker instance,
#  - page name
# We could name such pages 'PicturedPage' or similar :-)
sub build_pictured_page{
  my ($wizard, $page_name) = @_;

  # retrive REF to the page hash (we have clonet here all given attributes)
  my $p = $wizard->get_page($page_name);

  # we create an image
  my $image = $wizard->Photo($p->{photo_name}, -file=>$p->{photo_file},);

  # get user frame associated with this page
  my $f = $w->get_user_frame($page_name);

  # and draw the picture in
  my $pane = $f->Scrolled(
    Pane,
    -scrollbars => 'osoe',
    -sticky => 'we',
    -gridded => 'y',
   )->pack(-expand=>1, -fill=>'both');

  $pane->Label(-image => $p->{photo_name})->pack(-expand=>1, -fill=>'both');

} # sub

