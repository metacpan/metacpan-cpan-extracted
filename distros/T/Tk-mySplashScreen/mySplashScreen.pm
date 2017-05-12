###################################################
## mySplashScreen.pm
## Andrew N. Hicox 
## WorldCom Customer Security Development Group
## 
## Based on Tk::MainWindow
###################################################


## Global Stuff ###################################
 #Tk Version String
  $Tk::mySplashScreen::VERSION = '1.0.3';
 #package declaration
  package Tk::mySplashScreen;
 #export so that we don't need to call Tk::mySplashScreen, just mySplashScreen
  @mySplashScreen::ISA = 'Tk::mySplashScreen';
 #widgets to be used
  use Tk::widgets ("Photo","Label","MainWindow");
 #this is derived
  use base ("Tk::Derived", "Tk::MainWindow");
 #cast magic missile (make this a bona-fide Tk widget)
  Construct Tk::MainWindow 'SplashScreen';
 #default configSpecs
  our %defaultSpecs = (
      #'-image'	=> "./default.gif",
      '-image'	=> Tk->findINC('mySplashScreen/default.gif'),
      '-text'	=> "Tk::mySplashScreen version: $Tk::mySplashScreen::VERSION",
      '-anchor'	=> "w"
  );


## Populate #######################################
sub Populate {
	my ($self, $args) = @_;
    #make gui
    $self->makeGUI();
   #configspecs!
    $self->ConfigSpecs(
       #native stuff (don't monk wit)
		'-width'			=> [PASSIVE => undef, undef, 0],
		'-length'			=> [PASSIVE => undef, undef, 0],
	   #local stuff
		'-image'			=> [METHOD, undef, undef, $defaultSpecs{'-image'}],
		'-text'				=> [$self->{Mesg}, undef, undef, $defaultSpecs{'-text'}],
		'-anchor'			=> [$self->{Mesg}, undef, undef, $defaultSpecs{'-anchor'}],
		'-hide'				=> [METHOD, undef, undef, 0]
    );
   #draw the main frame
	$self->SUPER::Populate($args);
  
}


## makeGUI ########################################
sub makeGUI {
   #local vars
	my $self = shift();
   #auto-placement stuffs
	$self->{desk_width} = Tk::winfo($self, 'screenwidth');
    $self->{desk_height} = Tk::winfo($self, 'screenheight');
    Tk::wm(
        $self,
        "geometry",
        "+" . int($self->{desk_width}/4 - $self->{'-width'}/2) .
        "+" . int($self->{desk_height}/5 -$self->{'height'}/2)
    );
   #the image label
    $self->{Image} = $self->Label()->pack(-fill => 'both', -expand=> 1, -padx => '2');
   #the 'AltContent' frame
    $self->{AltContentFrame} = $self->Frame(
        -borderwidth	=> 0,
        -relief		=> 'groove'
    )->pack(-fill =>'both');
   #the status message
    $self->{Mesg} = $self->Label()->pack(-fill => 'x');
   #highlight in TkPreferences
    $self->{Status_Disp}->{Highlight} = 1;
}


## image ##########################################
##can't just pass to image label because we need to intercept possible filenames
##and convert to Tk::Photo object here
sub image {
	my ($self, $image) = @_;
	if (ref($image) eq "Tk::Photo"){
		##do the object thang
		$self->{splash_image} = $image;
		$self->{Image}->configure(-image => $self->{splash_image});
	}else{
	   #load the image file
		$self->{splash_image} = $self->Photo(-file => $image);
	    $self->{Image}->configure(-image => $self->{splash_image});
	    $self->{Image}->update();
	}
}

## hide ###########################################
 ##hides the splash screen
 sub hide {
    my ($self, $state)  = @_;
    if ($state == 1){
    	unless ($self->{show_flag}){
    		$self->{show_flag} = 1;
    		$self->withdraw();
    	}
    }elsif ($self->{show_flag}){
    	$self->{show_flag} = 0;
    	$self->deiconify();
    	$self->raise();
  	}
 }
 
 
## AltContent ######################################
 sub AltContent {
     ($self, %p) = @_;
     my $temp = $self->{AltContentFrame}->Frame(%p)->pack();
     return ($temp);
 }
 
 
## True For Perl Include ##########################
 1;
