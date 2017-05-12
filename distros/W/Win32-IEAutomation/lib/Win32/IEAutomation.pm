package Win32::IEAutomation;

use strict;
use Win32::OLE qw(EVENTS);

use Win32::IEAutomation::Element;
use Win32::IEAutomation::Table;
use Win32::IEAutomation::WinClicker;

use vars qw($VERSION $warn);
$VERSION = '0.5';

sub new {
	my $class = shift;
	my %options = @_;
	my $self = bless ({ }, $class);
	my ($visible, $maximize);
	if (exists $options{visible}){
		$visible = $options{visible};
	}else{
		$visible = 1;
	}
	if (exists $options{maximize}){
		$maximize = $options{maximize};
	}
	
	if (exists $options{warnings}){
		$warn = $options{warnings};
	}
	
	$self->_startIE($visible, $maximize);
}

sub _startIE{
	my ($self, $visible, $maximize) = @_;
	defined $self->{agent} and return;
	$self->{agent} = Win32::OLE->new("InternetExplorer.Application") || die "Could not start Internet Explorer Application through OLE\n";
	Win32::OLE->Option(Warn => 0);
	Win32::OLE->WithEvents($self->{agent});
	$self->{agent}->{Visible} = $visible;
	if ($maximize){
		my $clicker = Win32::IEAutomation::WinClicker->new();
		$clicker->maximize_ie();
		undef $clicker;
	}
	return $self;
}

sub getAgent { 
	my $self = shift;
	$self->{agent};
}

sub getElement { 
	my $self = shift;
	$self->{element};
}

sub closeIE{
	my $self = shift;
	my $agent = $self->{agent};
	$agent->Quit;
}

sub gotoURL{
	my ($self, $url, $nowait) = @_;
	my $agent = $self->{agent};
	$agent->Navigate($url);
	$self->WaitforDone unless $nowait;
}

sub Back{
	my $self = shift;
	my $agent = $self->{agent};
	$agent->GoBack;
	$self->WaitforDone;
}

sub Reload{
	my $self = shift;
	my $agent = $self->{agent};
	$agent->Refresh2;
	$self->WaitforDone;
	
}

sub URL{
	my $self = shift;
	my $agent = $self->{agent};
	$agent->LocationURL;
}

sub Title{
	my $self = shift;
	my $agent = $self->{agent};
	$agent->document->title;
}

sub Content{
	my $self = shift;
	my $agent = $self->{agent};
	my $html = $agent->document->documentElement->{outerHTML};
	$html =~ s/\r//g;
	my @file = split (/\n/, $html);
	if (wantarray){
		return @file;
	}else{
		return $html;
	}
}

# sub VerifyText{
# 	my ($self, $string) = @_;
# 	my @text = $self->PageText;
# 	foreach my $line (@text){
# 		$line =~ s/^\s+//;
# 		$line =~ s/\s+$//;
# 		if ($line eq $string || $line =~ m/$string/){
# 			return 1;
# 		}
# 	}
# }

sub VerifyText{
	my ($self, $string, $flag) = @_;
	$flag = 0 unless $flag;
	my $textrange = $self->{agent}->document->body->createTextRange;
	return $textrange->findText($string, 0 , $flag);
}

sub PageText{
	my $self = shift;
	my $text = $self->getAgent->document->documentElement->outerText;
	$text =~ s/\r//g;
	my @file = split (/\n/, $text);
	if (wantarray){
		return @file;
	}else{
		return $text;
	}
}
	
sub getLink{
	my ($self, $how, $what) = @_;
	my $agent = $self->{agent};
	my $links = $agent->Document->links;
	my $target_link = __getObject($links, $how, $what) if ($links);
	my $link_object;
	if ($target_link){
		$link_object = Win32::IEAutomation::Element->new();
		$link_object->{element} = $target_link;
		$link_object->{parent} = $self;
	}else{
		$link_object = undef;
		print "WARNING: No link is  present in the document with your specified option $how $what\n" if $warn;
	}
	return $link_object;
}

sub getAllLinks{
	my $self = shift;
	my $agent = $self->{agent};
	my @links_array;
	my $links = $agent->Document->links;
	for (my $n = 0; $n <= $links->length - 1; $n++){
		my $link_object = Win32::IEAutomation::Element->new();
		$link_object->{element} = $links->item($n);
		$link_object->{parent} = $self;
		push (@links_array, $link_object);
	}
	return @links_array;
}

sub getButton{
	my ($self, $how, $what) = @_;
	my $agent = $self->{agent};
	my $buttons = $agent->Document->all->tags("input");
	my $target_button = __getObject($buttons, $how, $what) if ($buttons);
	my $button_object;
	if ($target_button){
		$button_object = Win32::IEAutomation::Element->new();
		$button_object->{element} = $target_button;
		$button_object->{parent} = $self;
	}else{
		$button_object = undef;
		print "WARNING: No button is  present in the document with your specified option $how $what\n" if $warn;
	}
	return $button_object;
}

sub getImage{
	my ($self, $how, $what) = @_;
	my $agent = $self->{agent};
	my $images = $agent->Document->images;
	my $target_image = __getObject($images, $how, $what) if ($images);
	my $image_object;
	if ($target_image){
		$image_object = Win32::IEAutomation::Element->new();
		$image_object->{element} = $target_image;
		$image_object->{parent} = $self;
	}else{
		$image_object = undef;
		print "WARNING: No image is  present in the document with your specified option $how $what\n" if $warn;
	}
	return $image_object;
}

sub getAllImages{
	my $self = shift;
	my $agent = $self->{agent};
	my @image_array;
	my $images = $agent->Document->images;
	for (my $n = 0; $n <= $images->length - 1; $n++){
		my $image_object = Win32::IEAutomation::Element->new();
		$image_object->{element} = $images->item($n);
		$image_object->{parent} = $self;
		push (@image_array, $image_object);
	}
	return @image_array;
}

sub getRadio{
	my ($self, $how, $what) = @_;
	my $agent = $self->{agent};
	my $inputs;
	if ($how eq "beforetext:" || $how eq "aftertext:"){
		$inputs = $agent->Document->all;
	}else{
		$inputs = $agent->Document->all->tags("input");
	}
	my $target_radio = __getObject($inputs, $how, $what, "radio") if ($inputs);
	my $radio_object;
	if ($target_radio){
		$radio_object = Win32::IEAutomation::Element->new();
		$radio_object->{element} = $target_radio;
		$radio_object->{parent} = $self;
	}else{
		$radio_object = undef;
		print "WARNING: No radio button is  present in the document with your specified option $how $what\n" if $warn;
	}
	return $radio_object;
}

sub getCheckbox{
	my ($self, $how, $what) = @_;
	my $agent = $self->{agent};
	my $inputs;
	if ($how eq "beforetext:" || $how eq "aftertext:"){
		$inputs = $agent->Document->all;
	}else{
		$inputs = $agent->Document->all->tags("input");
	}
	my $target_checkbox = __getObject($inputs, $how, $what, "checkbox") if ($inputs);
	my $checkbox_object;
	if ($target_checkbox){
		$checkbox_object = Win32::IEAutomation::Element->new();
		$checkbox_object->{element} = $target_checkbox;
		$checkbox_object->{parent} = $self;
	}else{
		$checkbox_object = undef;
		print "WARNING: No checkbox is  present in the document with your specified option $how $what\n" if $warn;
	}
	return $checkbox_object;
}

sub getSelectList{
	my ($self, $how, $what) = @_;
	my $agent = $self->{agent};
	my $select_lists = $agent->Document->all->tags("select");
	my $target_list = __getObject($select_lists, $how, $what, "select-one|select-multiple") if ($select_lists);
	my $list_object;
	if ($target_list){
		$list_object = Win32::IEAutomation::Element->new();
		$list_object->{element} = $target_list;
		$list_object->{parent} = $self;
	}else{
		$list_object = undef;
		print "WARNING: No select list is  present in the document with your specified option $how $what\n" if $warn;
	}
	return $list_object;
}

sub getTextBox{
	my ($self, $how, $what) = @_;
	my $agent = $self->{agent};
	my ($inputs, $target_field);
	if ($how eq "beforetext:" || $how eq "aftertext:"){
		$inputs = $agent->Document->all;
	}else{
		$inputs = $agent->Document->all->tags("input");
	}
	if ($inputs){
		$target_field = __getObject($inputs, $how, $what, "text|password|file");
	}
	my $text_object;
	if ($target_field){
		$text_object = Win32::IEAutomation::Element->new();
		$text_object->{element} = $target_field;
		$text_object->{parent} = $self;
	}else{
		$text_object = undef;
		print "WARNING: No text box is present in the document with your specified option $how $what\n" if $warn;
	}
	return $text_object;
}

sub getTextArea{
	my ($self, $how, $what) = @_;
	my $agent = $self->{agent};
	my ($inputs, $target_field);
	if ($how eq "beforetext:" || $how eq "aftertext:"){
		$inputs = $agent->Document->all;
	}else{
		$inputs = $agent->Document->all->tags("textarea");
	}
	if ($inputs){
		$target_field = __getObject($inputs, $how, $what, "textarea");
	}
	my $text_object;
	if ($target_field){
		$text_object = Win32::IEAutomation::Element->new();
		$text_object->{element} = $target_field;
		$text_object->{parent} = $self;
	}else{
		$text_object = undef;
		print "WARNING: No text area is present in the document with your specified option $how $what\n" if $warn;
	}
	return $text_object;
}

sub getTable{
	my ($self, $how, $what) = @_;
	my $agent = $self->{agent};
	my ($inputs, $target_table);
	if ($how eq "beforetext:" || $how eq "aftertext:"){
		$inputs = $agent->Document->all;
	}else{
		$inputs = $agent->Document->all->tags("table");
	}
	if ($inputs){
		$target_table = __getObject($inputs, $how, $what);
	}
	my $table_object;
	if ($target_table){
		$table_object = Win32::IEAutomation::Table->new();
		$table_object->{table} = $target_table;
		$table_object->{parent} = $self;
	}else{
		$table_object = undef;
		print "WARNING: No table is present in the document with your specified option $how $what\n" if $warn;
	}
	return $table_object;
}

sub getAllTables{
	my $self = shift;
	my $agent = $self->{agent};
	my @links_array;
	my $links = $agent->Document->all->tags("table");
	for (my $n = 0; $n < $links->length; $n++){
		my $link_object = Win32::IEAutomation::Element->new();
		$link_object->{element} = $links->item($n);
		$link_object->{parent} = $self;
		push (@links_array, $link_object);
	}
	return @links_array;
}
	
sub __getObject{
	my ($coll, $how, $what, $type) = @_;
	my ($aftertext_flag, $input, $index_counter, $regex_flag);
	$regex_flag = 1 if ($what =~ /^?-xism:/);
	for (my $n = 0; $n <= $coll->length - 1; $n++){
		
			if ($how eq "linktext:") {
				my $text = $coll->item($n)->outerText;
				$text = trim_white_spaces($text);
				if ($regex_flag){
					return $coll->item($n) if ($text =~ $what);
				}else{
					return $coll->item($n) if ($text eq $what);
				}
			}
			
			elsif ($how eq "tabtext:") {
				my $text = $coll->item($n)->outerText;
				$text = trim_white_spaces($text);
				if ($regex_flag){
					return $coll->item($n) if ($text =~ $what);
				}else{
					return $coll->item($n) if ($text eq $what);
				}
			}
			
			elsif ($how eq "id:") {
				my $id = $coll->item($n)->id;
				return $coll->item($n) if ($id eq $what);
			}
			
			elsif ($how eq "name:") {
				my $name = $coll->item($n)->name;
				if ($regex_flag){
					return $coll->item($n) if ($name =~ $what);
				}else{
					return $coll->item($n) if ($name eq $what);
				}
			}
			
			elsif ($how eq "value:") {
				my $value = $coll->item($n)->value;
				if ($regex_flag){
					return $coll->item($n) if ($value =~ $what);
				}else{
					return $coll->item($n) if ($value eq $what);
				}
			}
			
			elsif ($how eq "class:") {
				my $class = $coll->item($n)->{className};
				if ($regex_flag){
					return $coll->item($n) if ($class =~ $what);
				}else{
					return $coll->item($n) if ($class eq $what);
				}
			}
			
			elsif ($how eq "index:") {
				$index_counter++ if ($coll->item($n)->type =~ m/^($type)$/);
				return $coll->item($n) if ($index_counter == $what);
			}
			
			elsif ($how eq "caption:") {
				my $value = $coll->item($n)->value;
				if ($regex_flag){
					return $coll->item($n) if ($value =~ $what);
				}else{
					return $coll->item($n) if ($value eq $what);
				}
			}
			
			elsif ($how eq "linkurl:") {
				my $url = $coll->item($n)->href;
				if ($regex_flag){
					return $coll->item($n) if ($url =~ $what);
				}else{
					return $coll->item($n) if ($url eq $what);
				}
			}
			
			elsif ($how eq "imgurl:") {
				my $imgurl = $coll->item($n)->src;
				if ($regex_flag){
					return $coll->item($n) if ($imgurl =~ $what);
				}else{
					return $coll->item($n) if ($imgurl eq $what);
				}
			}
			
			elsif ($how eq "alt:") {
				my $imgurl = $coll->item($n)->alt;
				if ($regex_flag){
					return $coll->item($n) if ($imgurl =~ $what);
				}else{
					return $coll->item($n) if ($imgurl eq $what);
				}
			}
			
			elsif ($how eq "beforetext:") {
				$input =  $coll->item($n) if ($coll->item($n)->tagname eq "INPUT");
				my $text = $coll->item($n)->getAdjacentText("beforeEnd");
				$text = trim_white_spaces($text);
				if ($regex_flag){
					return $input if ($text =~ $what);
				}else{
					return $input if ($text eq $what);
				}
				$text = $coll->item($n)->getAdjacentText("afterEnd");
				$text = trim_white_spaces($text);
				if ($regex_flag){
					return $input if ($text =~ $what);
				}else{
					return $input if ($text eq $what);
				}			 
			}
			
			elsif ($how eq "aftertext:") {
				undef $input;
				$input =  $coll->item($n) if (($coll->item($n)->tagName =~ m/^(INPUT|TEXTAREA)$/) && $coll->item($n)->type =~ m/^($type)$/);
				#print $coll->item($n)->{type}."\n" if ($aftertext_flag == 1 && $input);
				return $input if ($aftertext_flag == 1 && $input);
				unless ($aftertext_flag){
					my $text = $coll->item($n)->getAdjacentText("beforeEnd");
					$text = trim_white_spaces($text);
					if ($regex_flag){
						$aftertext_flag = 1 if ($text =~ $what);
					}else{
						$aftertext_flag = 1 if ($text eq $what);
					}
					$text = $coll->item($n)->getAdjacentText("afterEnd");
					$text = trim_white_spaces($text);
					if ($regex_flag){
						$aftertext_flag = 1 if ($text =~ $what);
					}else{
						$aftertext_flag = 1 if ($text eq $what);
					}
				}
		 }
		 
		 else{
			 print "WARNING: \'$how\' is not supported to get the object\n";
		 }
			 
	}
}

sub getFrame{
	my ($self, $how, $what) = @_;
	my $target_frame;
	my $agent = $self->{agent};
	my $frames = $agent->Document->frames;
	$target_frame = __getObject($frames, $how, $what) if ($frames);
	if ($target_frame){
		my %frame = %{$self};
		my $frameref = \%frame;
		$frameref->{agent} = $target_frame;
		bless $frameref;
		return $frameref;
	}else{
		print "WARNING: No frame is present in the document with your specified option $how $what\n" if $warn;
	}
}

sub getPopupWindow{
	my ($self, $what, $wait) = @_;
	my $counter;
	$wait = 2 unless $wait;
	while($counter <= $wait ){
		my $shApp = Win32::OLE->new("Shell.Application") || die "Could not start Shell.Application\n";
		my $windows = $shApp->Windows;
		for (my $n = 0; $n <= $windows->count - 1; $n++){
			my $window = $windows->Item($n);
			my $title = $window->document->title if $window;
			if ($title eq $what){
				my %popup = %{$self};
				my $popupref = \%popup;
				$popupref->{agent} = $window;
				bless $popupref;
				$popupref->WaitforDone;
				return $popupref;
			}
		}
		sleep 1;
		$counter++
	}
	print "WARNING: No popup window is present with your specified title: $what\n" if $warn;
}	

sub WaitforDone{
	my $self = shift;
	my $agent = $self->{agent};
	while ($agent->Busy || $agent->document->readystate ne "complete"){
		sleep 1;
	}
}

sub WaitforDocumentComplete{
	my $self = shift;
	my $agent = $self->{agent};
	while ($agent->document->readystate ne "complete"){
		sleep 1;
	}
}

sub trim_white_spaces{
	my $string = shift;
	$string =~ s/^\s+//;
	$string =~ s/\s+$//;
	return $string;
}

1;
__END__ 

#######################################################################
# DOCUMENTATION
#

=head1 NAME

Win32::IEAutomation - Web application automation using Internet Explorer

=head1 SYNOPSIS

	use Win32::IEAutomation;
	
	# Creating new instance of Internet Explorer
	my $ie = Win32::IEAutomation->new( visible => 1, maximize => 1);
	
	# Site navigation
	$ie->gotoURL('http://www.google.com');
	
	# Finding hyperlinks and clicking them
	# Using 'linktext:' option (text of the link shown on web page)
	$ie->getLink('linktext:', "About Google")->Click;	
	# Or using 'linktext:' option with pattern matching
	$ie->getLink('linktext:', qr/About Google/)->Click;
	# Or using 'id:' option ( <a id=1a class=q href=......>)
	$ie->getLink('id:', "1a")->Click;
	
	# Finding checkbox and selecting it
	# Using 'name:' option ( <input type = "checkbox" name = "checkme" value = "1"> )
	$ie->getCheckbox('name:', "checkme")->Select;
	# Or using 'aftertext:' option (for checkbox after some text on the web page) 
	$ie->getCheckbox('aftertext:', "some text here")->Select;
	
	# Finding text field and entering data into it
	# Using 'name:' option ( <input type="text" name="username" .......> )
	$ie->getTextBox('name:', "username")->SetValue($user);
	
	# Finding button and clicking it
	# using 'caption:' option
	$ie->getButton('caption:', "Google Search")->Click;
	
	# Accessing controls under frame
	$ie->getFrame("name:", "content")->getLink("linktext:", "All Documents")->Click;
	
	# Nested frames
	$ie->getFrame("name:", "first_frame")->getFrame("name:", "nested_frame");
	
	# Catching the popup as new window and accessing controls in it
	my $popup = $ie->getPopupWindow("title of popup window");
	$popup->getButton('value:', "button_value")->Click;
	
Additionally it provides methods to interact with security alert dialog, conformation dialog, logon dialog etc.
	
	# To navigate to some secure site and pushing 'Yes' button of security alert dialog box
	use Win32::IEAutomation;
	use Win32::IEAutomation::WinClicker; # this will provide methods to interact with dialog box
	
	my $ie = Win32::IEAutomation->new();
	$ie->gotoURL("https://some_secure_site.com", 1); # second argument says that don't wait for complete document loading and allow code to go to next line.
	my $clicker = Win32::IEAutomation::WinClicker->new();
	$clicker->push_security_alert_yes();
	$ie->WaitforDone; # we will wait here for complete loading of navigated site

=head1 DESCRIPTION

This module tries to give web application automation using internet explorer on windows platform. It internally uses Win32::OLE to create automation object for IE.
It drives internet explorer using its DOM properties and methods. The module allows user to interact with web page controls like links, buttons, radios, checkbox, text fields etc.
It also supports frames, popup window and interaction with javascript dialogs like security alert, confirmation, warning dialog etc.

=head1 METHODS

=head2 CONSTRUCTION AND GENERIC METHODS

=over 4

=item * Win32::IEAutomation->new( visible => 1, maximize => 1, warnings => 1 )

This is the constructor for new Internet Explorer instance through Win32::OLE. Calling this function will create
a perl object which internally contains a automation object for internet explorer. Three options are supported to this method in hash format.
All of these are optional.

visible

It sets the visibility of Internet Explorer window. The default value is 1, means by default it will be visible if you don't provide this option.
You can set it to 0 to run it in invisible mode.

maximize

Default value of this is 0, means it runs IE in the size of last run. Setting this to 1 will maximize the window.

warnings

Default value of this is 0. If you want to print warning messages for any object not found, then set it to 1. This is optional.

=item * gotoURL($url, [$nowait])

This method navigates to the given url and waits for it to be loaded completely if second argument is not provided
Second argument is optional and it represents the boolean value for not waiting till page gets loaded.
Giving second argument as 1 (true boolean value) makes your code not to wait for page loading in this 'gotoURL' method.
This is useful if you need to interact with any dialog like security alert. In that case use this method with second argument, then
interact with dialog (methods for interacting with dialog are described below) and then using method 'WaitforDone' (described below)
wait for IE to load page completely.

=item * Back()

Works as IE's Back button and waits for it to be loaded completely

=item * Reload()

Works as IE's Refresh button and waits for it to be loaded completely

=item * URL()

This will return the URL of the current document

=item * Title()

This will return title of the current document

=item * Content()

This will return the HTML of the current document. In scalar context return a single string (with \n characters) and in list context returns array.
Please note that all the tags are UPPER CASED.

=item * VerifyText($string, [iflags])

Verifies that given string is present in the current document text. It returns 1 on success and undefined on failure.
Second  parameter iflags is optional. It is integer value that specifies one or more of the following flags to indicate the type of search.

	0	Default. Match partial words.
	1	Match backwards.
	2	Match whole words only.
	4	Match case.

=item * PageText()

It returns the text in the current page. (no html tags). In scalar context return a single sting (with \n characters) and in list context returns array.

It will assist for using VerifyText method. User can print the returned array to some file and see what string he/she can pass as an argument to the VerifyText method.

=item * WaitforDone()

Waits till IE had came out of busy state and document is loaded completly.
This will poll IE for every one second and check its busy state and document complete state, before we move on.

=item * closeIE()

It will close the instance of internet explorer.

=item * getAgent()

It will return a reference to the Internet Explorer automation object, created using Win32::OLE.

=back

=head2 LINK METHODS

=over 4

=item * getLink($how, $what)

This is the method to access link on web page. It returns Win32::IEAutomation::Element object containing html link element.

$how : This is the option how you want to access the link

$what : This is string or integer, what you are looking for. For this, it also supports pattern matching using 'qr' operator of perl (see example below)

Valid options to use for $how:

'linktext:'	- Find the link by matching the link text i.e. the text that is displayed to the user

'id:'			- Find the link by matching id attribute

'name:'		- Find the link by matching name attribute

'linkurl:'		- Find the link by matching url attribute of the link

'class:'		- Find the link by matching class attribute

Typical Usage:

	$ie->getLink('linktext:', "Sign in"); # access the link that has Sign in as its text
	$ie->getLink('linktext:', qr/About Google/); # access the link whose text matches with 'About Google'
	$ie->getLink('id:', 5); # access the link whose id attribute is having value 5

=item * getAllLinks()

This will return a list of all links present in the current document, in form of Win32::IEAutomation::Element objects.
For return value, in scalar context, gives number of links present and in list context gives array of all link objects.
Each object in the array is similar to one we get using getLink method.

=item B<Methods supported for link object>

=item Click($nowait);

Clicks the link and waits till document is completely loaded.
As it uses click method of DOM, it supports clicking link with javascript in it.

$nowait: This is optional. Giving this argument as 1 (true boolean value) makes your code not to wait for complete page loading after clicking link.
This is useful if you need to interact with any dialog (like logon dialog) after clicking the link. (please see logon() method example for details)


=item linkText();

Returns text of the link

=item linkUrl();

Returns url of the link

=item getProperty($property)

Retrieves the value of the given property for link object. This makes easy to get value of any property that is supported by html link.

=back

=head2 IMAGE METHODS

=over 4

=item * getImage($how, $what)

This is the method to access image on web page. It returns Win32::IEAutomation::Element object containing html image element.

$how : This is the option how you want to access the image

$what : This is string or integer, what you are looking for. For this, it also supports pattern matching using 'qr' operator of perl (see example below)

Valid options to use for $how:

'id:'			- Find the image by matching id attribute

'name:'		- Find the image by matching name attribute

'imgurl:'	- Find the image by matching src attribute of the image

'alt:'			- Find the image by matching alt attribute of the image

'class:'		- Find the image by matching class attribute

Typical Usage:

	$ie->getImage('imgurl:', qr/logo.gif$/); # access the image that matches logo.gif at last of string of its url (src)
	$ie->getImage('alt:', "Google"); # access the image whose alt attribute is 'Google'
	$ie->getImage('class:', $some_class); # access the image whose class attribute is having value $some_class

=item * getAllImages()

This will return a list of all images present in the current document, in form of Win32::IEAutomation::Element objects.
For return value, in scalar context, gives number of images present and in list context gives array of all image objects.
Each object in the array is similar to one we get using getImage method.

=item B<Methods supported for image object>

=item Click($nowait)

Clicks the image and waits till document is completely loaded.
As it uses click method of DOM, it supports clicking link with javascript in it.

$nowait: This is optional. Giving this argument as 1 (true boolean value) makes your code not to wait for complete page loading after clicking image.
This is useful if you need to interact with any dialog (like logon dialog) after clicking the image. (please see logon() method example for details)

=item imgUrl()

Returns url of the image

=item getProperty($property)

Retrieves the value of the given property for image object. This makes easy to get value of any property that is supported by html image.

=back

=head2 BUTTON METHODS

=over 4

=item * getButton($how, $what)

This is the method to access button on web page. It returns Win32::IEAutomation::Element object containing html input type=button or submit element.

$how : This is the option how you want to access the button

$what : This is string or integer, what you are looking for. For this, it also supports pattern matching using 'qr' operator of perl (see example below)

Valid options to use for $how:

'id:'			- Find the button by matching id attribute

'name:'		- Find the button by matching name attribute

'value:'		- Find the button by matching value attribute

'caption:'	- Find the button by matching text shown on button

'class:'		- Find the button by matching class attribute

	If there are more than one button having same value for the option you are quering, then it returns first button of the collection.

Typical Usage:

	$ie->getButton('caption:', "Google Search"); # access the button with 'Google Search' as its caption
	$ie->getButton('name:', "btnG"); # access the button whose name attribute is 'btnG'

=item B<Methods supported for button object>

=item Click($nowait)

Clicks the button and waits till document is completely loaded.

$nowait: This is optional. Giving this argument as 1 (true boolean value) makes your code not to wait for complete page loading after clicking button.
This is useful if you need to interact with any dialog (like logon dialog) after clicking the button. (please see logon() method example for details)

=item getProperty($property)

Retrieves the value of the given property for button object. This makes easy to get value of any property that is supported by html button.

=back

=head2 RADIO and CHECKBOX METHODS

=over 4

=item * getRadio($how, $what)

This is the method to access radio button on web page. It returns Win32::IEAutomation::Element object containing html input type=radio element.

=item * getCheckbox($how, $what)

This is the method to access checkbox on web page. It returns Win32::IEAutomation::Element object containing html input type=checkbox element.

$how : This is the option how you want to access the radio or checkbox

$what : This is string or integer, what you are looking for. For this, it also supports pattern matching using 'qr' operator of perl (see example below)

Valid options to use for $how:

'id:'				- Find the radio or checkbox by matching id attribute

'name:'			- Find the radio or checkbox by matching name attribute

'value:'			- Find the radio or checkbox by matching value attribute

'class:'			- Find the radio or checkbox by matching class attribute

'index:'			- Find the radio or checkbox using the index in the total collection of the radio or checkbox. (see example below)

'beforetext:'	- Find the radio or checkbox before the specified text.

'aftertext:'		- Find the radio or checkbox after the specified text.

	If there are more than one object having same value for the option you are quering, then it returns first object of the collection.

Typical Usage:

	$ie->getRadio('beforetext:', "Option One"); # access the radio which appears before text 'Option One'
	$ie->getRadio('value:', $radio_value); # access the radio whose value attribute is $radio_value
	$ie->getCheckbox('aftertext:', "Remember Password"); # access the checkbox which appears after text 'Remember Password'
	$ie->getCheckbox('index:', 3); # access third checkbox from the collection of checkbox on the current web page

=item B<Methods supported for radio or checkbox object>

=item Select()

It selects the specified radio or checkbox, provided it is not already selected.

	$ie->getRadio('beforetext:', "Option One")->Select;

=item deSelect()

It deselects the specified radio or checkbox, provided it is not already deselected.

	$ie->getCheckbox('aftertext:', "Remember Password")->deSelect;

=item getProperty($property)

Retrieves the value of the given property for radio or checkbox object. This makes easy to get value of any property that is supported by html radio or checkbox.

=back

=head2 SELECT LIST METHODS

=over 4

=item * getSelectList($how, $what)

This is the method to access select list on web page. It returns Win32::IEAutomation::Element object containing html select element.

$how : This is the option how you want to access the select list

$what : This is string or integer, what you are looking for. For this, it also supports pattern matching using 'qr' operator of perl (see example below)

Valid options to use for $how:

'id:'				- Find the select list by matching id attribute

'name:'			- Find the select list by matching name attribute

'class:'			- Find the select list by matching class attribute

'index:'			- Find the select list using the index in the total collection of the select lists. (see example below)

'beforetext:'	- Find the select list before the specified text.

'aftertext:'		- Find the select list after the specified text.

	If there are more than one object having same value for the option you are quering, then it returns first object of the collection.

Typical Usage:

	$ie->getSelectList('aftertext:', "some text"); # access the select list which appears after text 'some text'
	$ie->getSelectList('name:', 'time_zone'); # access the select list whose name attribute is 'time_zone'
	$ie->getSelectList('index:', 3); # access third select list from the collection of select lists on the current web page

=item B<Methods supported for select list object>

=item SelectItem()

It selects one or more items from the select list. You can pass a single or multiple item to this method.
Provide the name of item which is visible to user on web page ( and not that is in html code).
Use this method for selection of multiple items only if select list is supporting multiple selection.

	$ie->getSelectList('name:', 'time_zone')->SelectItem("India"); # selects one item "India" in the select list
	$ie->getSelectList('name:', 'time_zone')->SelectItem("India", "U. S. A.", "Australia"); # selects three items "India", "U. S. A." and "Australia" in the select list

=item deSelectItem()

It deselects one or more items from the select list. You can pass a single or multiple item to this method.
Provide the name of item which is visible to user on web page ( and not that is in html code)

	$ie->getSelectList('name:', 'time_zone')->deSelectItem("India"); # deselect one item "India" in the select list
	$ie->getSelectList('name:', 'time_zone')->deSelectItem("India", "U. S. A.", "Australia"); # deselect three items "India", "U. S. A." and "Australia" in the select list

=item deSelectAll()

It deselects all items from the select list. Call this method without any argument.
This method is useful, when a select list appears with a random selected item and you need to deselect that.

	$ie->getSelectList('name:', 'time_zone')->deSelectAll(); # deselect all items in the select list

=item getProperty($property)

Retrieves the value of the given property for select list object. This makes easy to get value of any property that is supported by html select list.

=back

=head2 TEXTBOX and TEXTAREA METHODS

=over 4 

=item * getTextBox($how, $what)

This is the method to access input text field on web page. It returns Win32::IEAutomation::Element object containing html input type=text or password element.
Additionaly this method works for file upload text field also. (i.e. input type=file).

=item * getTextArea($how, $what)

This is the method to access input text area on web page. It returns Win32::IEAutomation::Element object containing html textarea element.

$how : This is the option how you want to access the select list

$what : This is string or integer, what you are looking for. For this, it also supports pattern matching using 'qr' operator of perl (see example below)

Valid options to use for $how:

'id:'				- Find the text field by matching id attribute

'name:'			- Find the text field by matching name attribute

'value:'			- Find the text field by matching value attribute

'class:'			- Find the text field by matching class attribute

'index:'			- Find the text field using the index in the total collection of the text fields. (see example below)

'beforetext:'	- Find the text field before the specified text.

'aftertext:'		- Find the text field after the specified text.

	If there are more than one object having same value for the option you are quering, then it returns first object of the collection.

Typical Usage:

	$ie->getSelectList('aftertext:', "User Name:"); # access the text fields which appears after text 'User Name:'
	$ie->getSelectList('name:', 'password'); # access the text field whose name attribute is 'password'
	$ie->getSelectList('index:', 3); # access third text field from the collection of text fields on the current web page

=item B<Methods supported for text field object>

=item SetValue($string)

It will set the value of text field or text area to the string provided.

	$ie->getTextBox('name:', "q")->SetValue("web automation"); # it will enter text 'web automation' in the input text filed.
	$ie->getTextBox("name:", "importFile")->SetValue("C:\\temp\\somefile"); # to set somefile in file upload text field

=item GetValue()

It will return the default text present in the textbox or text area.

	$ie->getTextBox('name:', "q")->GetValue() # return the default text present in the textbox

=item ClearValue()

It will clear the text field.

	$ie->getTextBox('name:', "q")->ClearValue() # it will clear the input text field

=item getProperty($property)

Retrieves the value of the given property for text field object. This makes easy to get value of any property that is supported by html input text field.

=back

=head2 TABLE METHOD

=over4

=item * getTable($how, $what)

This is the method to access table on web page. It returns Win32::IEAutomation::Table object containing html table.

$how : This is the option how you want to access the link

$what : This is string or integer, what you are looking for. For this, it also supports pattern matching using 'qr' operator of perl (see example below)

Valid options to use for $how:

'id:'				- Find the table by matching id attribute

'name:'			- Find the table by matching name attribute

'value:'			- Find the table by matching value attribute

'class:'			- Find the table by matching class attribute

If there are more than one object having same value for the option you are quering, then it returns first object of the collection.

Typical Usage:

	$ie->getTable("id:", "1a");		# access the table whose id attribute is '1a'
	$ie->getTable("class:", "data")	# access the table whose class attribute is 'data'

=item * getAllTables()

This will return array containing all table on that page. Each element of an array will be a Win32::IEAutomation::Table object.

Typical Usage:

	my @alltables = $ie->getAllTables;

=item B<Methods supported for table object>

=item rows([index of row])

This method returns the row object/objects from the table. It takes an optional argument, the index number of the row you wish to take.
If this method is used without any argument then it returns array of row objects in the table.  And if you provide an argument,
then it returns a scalar row object present at specified index. The rows are counted inclusing header row.

Typical Usage:

	my @all_rows = $table_object->rows;  # get collection of all row objects in the table
	my $third_row = $table_objects->rows(3) # get third row of the table.

=item getRowHavingText($string);

This method returns a single row object that contains specifed text. If the text string is present in any of the row of the table, then that row
objetc is returned. This method supports perl pattern matching using 'qr' operator.

Typical Usage:

	my $target_row = $table_object->getRowHavingText("Last Name:"); # access the row which contains text "Last Name:". It will try to match eaxact string.
	my $target_row = $table_object->getRowHavingText(qr/First Name:/); # access the row by pattern matching text "First Name:"

=item tableCells([$row, $column])

This method returns an array of all cell objects present in the table. Each element of the array will be a cell object. Please see below for methods on cell object.
Additionaly it also supports two optional parameters, first parameter is index of the row and second is index of column. When these two parameters are used,
it returns a scalar cell object using combination of row and column index.

Typical Usage:

	my @allcells = $table_object->tableCells; # get all cell objects in an array
	my $target_cell = $table_object->tableCells(2, 5); # get cell at second row and fifth column

=item B<Methods supported for row object>

=item cells([index of cell])

This methos returns an array of cell objects present in that cell. Each elemnt of an array will be a cell object.
Additionaly it supports one optional parameter, cell index.
If this method is used without any argument then it returns array of cell objects in that row.  And if you provide an argument,
then it returns a scalar cell object present at specified index.

Typical Usage:

	my @all_cells = $row_object->cells;  # get collection of all cell objects in that row
	my $third_cell = $table_objects->cells(3) # get third cell of that row.

=item B<Methods supported for cell object>

=item cellText

It returns a text present in that cell.

Typical Usage:

	$text = $cell_object->cellText;	# access the text present in that cell.

In addition to this, all methods listed under LINK METHODS, IMAGE METHODS, BUTTON METHODS, RADIO and CHECKBOX METHODS, SELECT LIST METHODS, 
TEXTBOX and TEXTAREA METHODS are supported on cell object.

=back

=head2 FRAME METHOD

=over4

=item * getFrame($how, $what)

It will return the Win32::IEAutomation object for frame document. Frame document is having same structure as that of parent IE instance,
so all methods for link, button, image, text field etc. are supported on frame object.

$how : This is the option how you want to access the select list

$what : This is string or integer, what you are looking for. For this, it also supports pattern matching using 'qr' operator of perl (see example below)

Valid options to use for $how:

'id:'				- Find the frame by matching id attribute

'name:'			- Find the frame by matching name attribute

'value:'			- Find the frame by matching value attribute

'class:'			- Find the frame by matching class attribute

Typical Usage:

	$ie->getFrame('id:', "f1"); # access the frame whose id attribute is 'f1'
	$ie->getFrame('name:', 'groups'); # access the frame whose name attribute is 'groups'

To control any objects under frame, first get the frame object using 'getFrame' method and then use other methods (getLink, getRadio etc.) to access objects.

	$ie->getFrame('name:', 'groups')->getRadio('beforetext:', "Option One")->Select; # select the radio which is under frame

There might be case of frame inside frame (nested farmes), so use getFrame method uptp target frame

	$ie->getFrame("name:", "first_frame")->getFrame("name:", "nested_frame");

=item B<Methods supported for frame object>

All methods listed under GENERIC METHODS, LINK METHODS, IMAGE METHODS, BUTTON METHODS, RADIO and CHECKBOX METHODS, SELECT LIST METHODS, 
TEXTBOX and TEXTAREA METHODS, FRAME METHODare supported.

=back

=head2 POPUP METHOD

=over4

=item * getPopupWindow($title)

It will return the Win32::IEAutomation object for popup window. Popup window is having same structure as that of parent IE instance,
so all methods for link, button, image, text field etc. are supported on popup object.

Provide the exact title of the popup window as an argument to this method.

Typical Usage:

	$ie->getPopupWindow("Popup One"); # access the popup window whose title is "Popup One"

To control any objects under popup, first get the popup object using 'getPopupWindow' method and then use other methods (getLink, getRadio etc.) to access objects.

	my $popup = $ie->getPopupWindow("Popup One") # access the popup window
	$popup->getRadio('beforetext:', "Option One")->Select; # select the radio

There might be case where popup takes time to load its document, so you can use 'WaitforDone' method on popup

	my $popup = $ie->getPopupWindow("Popup One") # access the popup window
	$popup->WaitforDone; # wait so that popup will load its document completly

=item B<Methods supported for popup object>

All methods listed under GENERIC METHODS, LINK METHODS, IMAGE METHODS, BUTTON METHODS, RADIO and CHECKBOX METHODS, SELECT LIST METHODS, 
TEXTBOX and TEXTAREA METHODS, FRAME METHOD are supported.

=back

=head2 DIALOG HANDLING METHODS

Win32::IEAutomation::WinClicker class provides some methods to ineract with dialogs like security alert, confirmation dialog, logon dialog etc.
COM interface to AutoIt (http://www.autoitscript.com/autoit3/) is used to implement these.

You need to create a new instance of Win32::IEAutomation::WinClicker and then use these methods.

=over 4

=item * Win32::IEAutomation::WinClicker->new( warnings => 1)

warnings

Default value of this is 0. If you want to print warning messages for any object not found, then set it to 1. This is optional.

=item * push_security_alert_yes($wait_time)

It will push the 'Yes' button of Security Alert dialog box. Provide wait time so that it will wait for Security Alert dialog box to appear.
Default value of wait time is 5 seconds (if wait time is not provided). It will timeout after wait time, and execute next line of code.

Typical Usage:

    # To navigate to some secure site and pushing 'Yes' button of security alert dialog box
    use Win32::IEAutomation;
    use Win32::IEAutomation::WinClicker; # this will provide methods to interact with dialog box
    
    my $ie = Win32::IEAutomation->new();
    $ie->gotoURL("https://some_secure_site.com", 1); # second argument says that don't wait for complete document loading and allow code to go to next line.
    
    my $clicker = Win32::IEAutomation::WinClicker->new();
    $clicker->push_security_alert_yes();
    $ie->WaitforDone; # we will wait here for complete loading of navigated site

=item * push_button_yes($title, $wait_time)

It will push 'Yes' button of window which is having provided title.

$title: Provide exact title of dialog box

$wait_time: Provide wait time so that it will wait for confirmation dialog box to appear.
Default value of wait time is 5 seconds (if wait time is not provided). It will timeout after wait time, and execute next line of code.

=item * push_confirm_button_ok($title, $wait_time)

It will push the 'OK' button of any confirmation dialog box.

$title: Provide exact title of dialog box

$wait_time: Provide wait time so that it will wait for confirmation dialog box to appear.
Default value of wait time is 5 seconds (if wait time is not provided). It will timeout after wait time, and execute next line of code.

=item * push_confirm_button_cancle($wait_time)

It will push the 'Cancle' button of any confirmation dialog box.

$title: Provide exact title of dialog box

$wait_time: Provide wait time so that it will wait for confirmation dialog box to appear.
Default value of wait time is 5 seconds (if wait time is not provided). It will timeout after wait time, and execute next line of code.

=item * logon($title, $user, $password, $wait_time)

It will fill the logon dialog box with user name and password, and then press enter.

$title: Provide exact title of logon doalog box

$user: Provide user name to enter

$password: Provide password to enter

$wait_time: Provide wait time so that it will wait for logon dialog box to appear.
Default value of wait time is 5 seconds (if wait time is not provided). It will timeout after wait time, and execute next line of code.

Typical Usage:

	# To navigate to some authenticated site and pushing 'Yes' button of security alert dialog box
	use Win32::IEAutomation;
	use Win32::IEAutomation::WinClicker; # this will provide methods to interact with dialog box
	
	my $ie = Win32::IEAutomation->new();
	$ie->gotoURL('http://pause.perl.org'); 
	$ie->getLink('linktext:', "Login")->Click(1); # providing no wait argument says that don't wait for complete document loading and allow code to go to next line.
	
	my $clicker = Win32::IEAutomation::WinClicker->new();
	$clicker->logon("Enter Network Password", $user, $password, $wait_time); # here 'Enter Network Password' is the title of log on window
	$ie->WaitforDone; # we will wait here for complete loading document

=back

=head1 AUTHOR

Prashant Shewale <pvshewale@gmail.com>

=head1 COPYRIGHT AND LICENSE

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut





















	
	
	
	