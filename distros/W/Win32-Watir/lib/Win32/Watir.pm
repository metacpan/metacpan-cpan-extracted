=head1 NAME

Win32::Watir - Perl extension for automating Internet Explorer.

=head1 SYNOPSIS

 use Win32::Watir;

 # Creating new instance of Internet Explorer
 my $ie = Win32::Watir::new(
   visible => 1,
   maximize => 1,
 );
 # show google, search 'Perl Win32::Watir' keyword.
 $ie->goto("http://www.google.co.jp/");
 $ie->text_field('name:', "q")->setvalue("Perl Win32::Watir")

=head1 DESCRIPTION

Win32::Watir helps you to write tests that are easy to read and easy to
maintain.

Watir drives browsers the same way people do.
It clicks links, fills in forms, presses buttons.
Watir also checks results, such as whether expected text appears on the page.

Win32::Watir is inspired on Ruby/Watir, then fork Win32::IEAutomation.

 Win32::IEAutomation special nice interface at perl and windows, but
 some method doesn't support IE7, IE8 for Window/Dialog name changes.
 Win32::Watir are support IE7, IE8 and use more compatible/like Ruby/Watir
 method names, ..etc.

* Ruby/Watir :
 http://wtr.rubyforge.org/

* Win32::IEAutomation :
 http://search.cpan.org/perldoc?Win32::IEAutomation

you may require setup Multiple_IE when using this with IE6.0 

=cut

package Win32::Watir;

use 5.010000;
use strict;
use warnings;
use vars qw($warn);

use Win32;
use Win32::OLE qw(EVENTS);
use Win32::Watir::Element;
use Win32::Watir::Table;
use Config;

our $VERSION = '0.06';

# methods go here.

=head2 new - construct.

options are supported to this method in hash format.

 warnings => 0 or 1
  0: output no warning.
  1: output some warnings.

 maximize => 0 or 1
  0: default window size.
  1: maximize IE window when IE start.

 visible => 0 or 1
  0: IE window invisible.
  1: IE window visible.

 codepage => undef or 'utf8'
  undef:  use default codepage at your Windows.
  utf8 :  use Win32::OLE::CP_UTF8 codepage.

 ie (IE executable path) :
  specify your multiple IE executable path.
  ex) c:/path_to/multipleIE/iexplorer.exe

 find :
  If "find" key exists, find IE window in
  current workspace

if no options specified, use those default.

 $ie = new Win32::Watir(
   warnings => 0,
   maximize => 0,
   visible  => 1,
   codepage => undef,
 );

=cut

sub new {
	my $class = shift;
	my %opts = @_;
	$opts{visible} = 1  unless (exists $opts{visible});
	$warn = $opts{warnings} if (exists $opts{warnings});
	my $self = bless (\%opts, $class);
	$self->_check_os_name();
	if ( $opts{'ie'} or $opts{'find'} ){
		return $self->_startCustomIE();
	} else {
		return $self->_startIE();
	}
}

sub _set_codepage {
	my $self = shift;
	if ($self->{codepage} and ($self->{codepage} =~ /UTF8/i || $self->{codepage} =~ /UTF-8/i)){
		Win32::OLE->Option(CP => Win32::OLE::CP_UTF8);
		binmode(STDOUT, ":utf8");
		binmode(STDERR, ":utf8");
		print STDERR "DEBUG: Win32::OLE::CP=".Win32::OLE->Option('CP')."\n" if ($self->{warnings});
	}
}

sub _startIE {
	my $self = shift;
	defined $self->{agent} and return;
	$self->{agent} = Win32::OLE->new("InternetExplorer.Application") || 
		die "Could not start Internet Explorer Application through OLE\n";
	Win32::OLE->Option(Warn => 0);
	Win32::OLE->WithEvents($self->{agent});
	$self->_set_codepage();
	$self->{agent}->{Visible} = $self->{visible};
	$self->{IE_VERSION} = $self->_check_ie_version();
	if ($self->{maximize}){
		$self->maximize_ie();
	}
	return $self;
}

sub _startCustomIE {
	my $self = shift;
	if ( defined($self->{agent}) ){
		print STDERR "Notice: IE already initialized..\n";
		return $self->{agent};
	}
	if ( exists($self->{ie}) ){
		my $ie = $self->{ie};
		die "Error: Coud not execute '$ie'\n" unless ( -x "$ie" );
		if ( exists($ENV{OSTYPE}) && $ENV{OSTYPE} eq 'cygwin' ){
			system("cygstart.exe '${ie}'");
		} else {
			system("start '${ie}'");
		}
		# find current windows opened.
	} else {
		$self->_log("DEBUG: find IE from current windows....\n");
	}
	my $shApp = Win32::OLE->new("Shell.Application") || die "Could not start Shell.Application\n";
	my $_wait = time();
	while ( ! defined($self->{agent})  ) {
		my $windows = $shApp->Windows;
		for (my $n = 0; $n <= $windows->count - 1; $n++){
			my $window = $windows->Item($n);
			my $name = $window->name;
			if ($name =~ /(\w+) Internet Explorer$/i){
				my $_ie_prefix = $1;
				$self->{IE_VERSION} = 6 if ($_ie_prefix eq 'Microsoft');
				$self->{agent} = $window;
				$self->{agent}->WaitforDone;
			}
		}
		if ( (time() - $_wait) > 10 ){
			die "Could not start or detect Internet Explorer\n";
		}
		sleep 2;
	}
	die "Could not start or detect Internet Explorer\n" unless(defined($self->{agent}));
	$self->_set_codepage();
	$self->{IE_VERSION} = $self->_check_ie_version() unless ($self->{IE_VERSION});
	$self->{agent}->{Visible} = $self->{visible};
	if ($self->{maximize}){
		$self->maximize_ie();
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

=head2 close()

=head2 closeIE()

close IE window.

=cut

sub closeIE {
	my $self = shift;
	my $agent = $self->{agent};
	$agent->Quit;
}
sub close {
	my $self = shift;
	$self->closeIE(@_);
}

=head2 goto(url)

=head2 gotoURL(url)

Site navigate to specified URL.

 ex). go cpan-site.
  $ie->goto('http://search.cpan.org/');

=cut

sub gotoURL {
	my ($self, $url, $nowait) = @_;
	my $agent = $self->{agent};
	$agent->Navigate($url);
	$self->WaitforDone unless $nowait;
}
sub goto {
	my $self = shift;
	$self->gotoURL(@_);
}

=head2 back()

=head2 Back()

IE window back. same as "back button" or type Backspace key.

=cut

sub Back {
	my $self = shift;
	my $agent = $self->{agent};
	$agent->GoBack;
	$self->WaitforDone;
}
sub back {
	my $self = shift;
	$self->Back(@_);
}

=head2 reload()

=head2 Reload()

reload, refresh IE page.
same as type 'F5' key.

=cut

sub Reload {
	my $self = shift;
	my $agent = $self->{agent};
	$agent->Refresh2;
	$self->WaitforDone;
}
sub reload {
	my $self = shift;
	$self->Reload(@_);
}

=head2 URL()

return current page URL.

=cut

sub URL {
	my $self = shift;
	my $agent = $self->{agent};
	$agent->LocationURL;
}

=head2 title()

=head2 Title()

return current page title.

=cut

sub Title {
	my $self = shift;
	my $agent = $self->{agent};
	$agent->document->title;
}
sub title {
	my $self = shift;
	return $self->Title(@_);
}

=head2 html()

=head2 Content()

return current page html.

 notice: "CR" code (\r) removed from html.

=cut

sub Content {
	my $self = shift;
	my $agent = $self->{agent};
	my $html = $agent->document->documentElement->{outerHTML};
	$html =~ s/\r//g;
	if (wantarray){
		return split (/\n/, $html);
	} else {
		return $html;
	}
}
sub html {
	my $self = shift;
	return $self->Content(@_);
}

=head2 VerifyText(text, flag)

verify current document include specified "text" .

 text : string
 flag :
 	0 (default)
 	1 (?)
 
 [ToDO] check createTextRange()

=cut

sub VerifyText {
	my ($self, $string, $flag) = @_;
	$flag = 0 unless $flag;
	my $textrange = $self->{agent}->document->body->createTextRange;
	return $textrange->findText($string, 0 , $flag);
}

=head2 PageText()

=head2 text()

return current page as Plain TEXT which removed HTML tags.

=cut

sub PageText {
	my $self = shift;
	my $text = $self->getAgent->document->documentElement->outerText;
	$text =~ s/\r//g;
	if (wantarray){
		return split (/\n/, $text);
	} else {
		return $text;
	}
}
sub text {
	my $self = shift;
	return $self->PageText(@_);
}

=head2 link(how, value)

=head2 getLink(how, value)

Finding hyperlinks.

ex).
 Using 'linktext:' option (text of the link shown on web page)
  $ie->getLink('linktext:', "About Google")->Click;	

 Using 'linktext:' option with pattern matching
  $ie->getLink('linktext:', qr/About Google/)->Click;

 Using 'id:' option ( <a id=1a class=q href=......>)
  $ie->getLink('id:', "1a")->Click;

 Using 'href:' option ( <a href=......>)
  $ie->getLink('id:', qr/search.cpan.org/)->click;

=cut

sub getLink {
	my ($self, $how, $what) = @_;
	my $agent = $self->{agent};
	my $links = $agent->Document->links;
	my $target_link = __getObject($links, $how, $what) if ($links);
	my $link_object;
	if ($target_link){
		$link_object = Win32::Watir::Element->new();
		$link_object->{element} = $target_link;
		$link_object->{parent} = $self;
	} else  {
		$link_object = undef;
		$self->_log("WARNING: No link is  present in the document with your specified option $how $what");
	}
	return $link_object;
}
sub link {
	my $self = shift;
	return $self->getLink(@_);
}

=head2 links()

=head2 getAllLinks()

return all array of link_object.

 ex). print pagename at google search result.
  foreach my $ln ( $ie->getAllLinks ){
    print $ln->text."\n" if ($ln->class eq 'l');
  }

=cut

sub getAllLinks {
	my $self = shift;
	my $agent = $self->{agent};
	my @links_array;
	my $links = $agent->Document->links;
	for (my $n = 0; $n <= $links->length - 1; $n++){
		my $link_object = Win32::Watir::Element->new();
		$link_object->{element} = $links->item($n);
		$link_object->{parent} = $self;
		push (@links_array, $link_object);
	}
	return @links_array;
}
sub links {
	my $self = shift;
	return $self->getAllLinks();
}

=head2 button(how, what)

=head2 getButton(how, what)

finding input buttons.

=cut

sub getButton {
	my ($self, $how, $what) = @_;
	my $agent = $self->{agent};
	my $buttons = $agent->Document->all->tags("input");
	my $target_button = __getObject($buttons, $how, $what, 'button|img|submit|cancel') if ($buttons);
	my $button_object;
	if ($target_button){
		$button_object = Win32::Watir::Element->new();
		$button_object->{element} = $target_button;
		$button_object->{parent} = $self;
	} else {
		$button_object = undef;
		$self->_log("WARNING: No button is  present in the document with your specified option $how $what");
	}
	return $button_object;
}
sub button {
	my $self = shift;
	return $self->getButton(@_);
}

=head2 image(how, what)

=head2 getImage(how, what)

finding img.

=cut

sub getImage {
	my ($self, $how, $what) = @_;
	my $agent = $self->{agent};
	my $images = $agent->Document->images;
	my $target_image = __getObject($images, $how, $what) if ($images);
	my $image_object;
	if ($target_image){
		$image_object = Win32::Watir::Element->new();
		$image_object->{element} = $target_image;
		$image_object->{parent} = $self;
	} else {
		$image_object = undef;
		$self->_log("WARNING: No image is  present in the document with your specified option $how $what\n");
	}
	return $image_object;
}
sub image {
	my $self = shift;
	return $self->getImage(@_);
}

=head2 images()

=head2 getAllImages()

return array of all image tag.

=cut

sub getAllImages {
	my $self = shift;
	my $agent = $self->{agent};
	my @image_array;
	my $images = $agent->Document->images;
	for (my $n = 0; $n <= $images->length - 1; $n++){
		my $image_object = Win32::Watir::Element->new();
		$image_object->{element} = $images->item($n);
		$image_object->{parent} = $self;
		push (@image_array, $image_object);
	}
	return @image_array;
}
sub images {
	my $self = shift;
	return $self->getAllImages(@_);
}

=head2 radio(how, what)

=head2 getRadio(how, what)

return input radio object.

=cut

sub getRadio {
	my ($self, $how, $what) = @_;
	my $agent = $self->{agent};
	my $inputs;
	if ($how eq "beforetext:" || $how eq "aftertext:"){
		$inputs = $agent->Document->all;
	} else {
		$inputs = $agent->Document->all->tags("input");
	}
	my $target_radio = __getObject($inputs, $how, $what, "radio") if ($inputs);
	my $radio_object;
	if ($target_radio){
		$radio_object = Win32::Watir::Element->new();
		$radio_object->{element} = $target_radio;
		$radio_object->{parent} = $self;
	} else {
		$radio_object = undef;
		$self->_log("WARNING: No radio button is  present in the document with your specified option $how $what\n");
	}
	return $radio_object;
}
sub radio {
	my $self = shift;
	return $self->getRadio(@_);
}

=head2 checkbox(how, what)

=head2 getCheckbox(how, what)

return input checkbox object.

=cut

sub getCheckbox {
	my ($self, $how, $what) = @_;
	my $agent = $self->{agent};
	my $inputs;
	if ($how eq "beforetext:" || $how eq "aftertext:"){
		$inputs = $agent->Document->all;
	} else {
		$inputs = $agent->Document->all->tags("input");
	}
	my $target_checkbox = __getObject($inputs, $how, $what, "checkbox") if ($inputs);
	my $checkbox_object;
	if ($target_checkbox){
		$checkbox_object = Win32::Watir::Element->new();
		$checkbox_object->{element} = $target_checkbox;
		$checkbox_object->{parent} = $self;
	} else {
		$checkbox_object = undef;
		$self->_log("WARNING: No checkbox is  present in the document with your specified option $how $what\n");
	}
	return $checkbox_object;
}
sub checkbox {
	my $self = shift;
	return $self->getCheckbox(@_);
}

sub getSelectList {
	my ($self, $how, $what) = @_;
	my $agent = $self->{agent};
	my $select_lists = $agent->Document->all->tags("select");
	my $target_list = __getObject($select_lists, $how, $what, "select-one|select-multiple") if ($select_lists);
	my $list_object;
	if ($target_list){
		$list_object = Win32::Watir::Element->new();
		$list_object->{element} = $target_list;
		$list_object->{parent} = $self;
	} else {
		$list_object = undef;
		$self->_log("WARNING: No select list is  present in the document with your specified option $how $what\n");
	}
	return $list_object;
}
sub select_list {
	my $self = shift;
	return $self->getSelectList(@_);
}

=head2 getTextBox(how, what)

return input (type=text) object.

=cut

sub getTextBox {
	my ($self, $how, $what) = @_;
	my $agent = $self->{agent};
	my ($inputs, $target_field);
	if ($how eq "beforetext:" || $how eq "aftertext:"){
		$inputs = $agent->Document->all;
	} else {
		$inputs = $agent->Document->all->tags("input");
	}
	if ($inputs){
		$target_field = __getObject($inputs, $how, $what, "text|password|file");
	}
	my $text_object;
	if ($target_field){
		$text_object = Win32::Watir::Element->new();
		$text_object->{element} = $target_field;
		$text_object->{parent} = $self;
	} else {
		$text_object = undef;
		$self->_log("WARNING: No text box is present in the document with your specified option $how $what\n");
	}
	return $text_object;
}

=head2 getTextArea(how, what)

return textarea object.

=cut

sub getTextArea {
	my ($self, $how, $what) = @_;
	my $agent = $self->{agent};
	my ($inputs, $target_field);
	if ($how eq "beforetext:" || $how eq "aftertext:"){
		$inputs = $agent->Document->all;
	} else {
		$inputs = $agent->Document->all->tags("textarea");
	}
	if ($inputs){
		$target_field = __getObject($inputs, $how, $what, "textarea");
	}
	my $text_object;
	if ($target_field){
		$text_object = Win32::Watir::Element->new();
		$text_object->{element} = $target_field;
		$text_object->{parent} = $self;
	} else {
		$text_object = undef;
		$self->_log("WARNING: No text area is present in the document with your specified option $how $what\n");
	}
	return $text_object;
}

=head2 text_field(how, what)

=cut

sub text_field {
	my ($self, $how, $what) = @_;
	my $object = $self->getTextBox($how, $what);
	if ($object){
		return $object;
	} else {
		return $self->getTextArea($how, $what);
	}
}

sub getTable {
	my ($self, $how, $what) = @_;
	my $agent = $self->{agent};
	my ($inputs, $target_table);
	if ($how eq "beforetext:" || $how eq "aftertext:"){
		$inputs = $agent->Document->all;
	} else {
		$inputs = $agent->Document->all->tags("table");
	}
	if ($inputs){
		$target_table = __getObject($inputs, $how, $what);
	}
	my $table_object;
	if ($target_table){
		$table_object = Win32::Watir::Table->new();
		$table_object->{table} = $target_table;
		$table_object->{parent} = $self;
	} else {
		$table_object = undef;
		$self->_log("WARNING: No table is present in the document with your specified option $how $what\n");
	}
	return $table_object;
}

sub getAllTables {
	my $self = shift;
	my $agent = $self->{agent};
	my @links_array;
	my $links = $agent->Document->all->tags("table");
	for (my $n = 0; $n < $links->length; $n++){
		my $link_object = Win32::Watir::Element->new();
		$link_object->{element} = $links->item($n);
		$link_object->{parent} = $self;
		push (@links_array, $link_object);
	}
	return @links_array;
}


=head2 getAllDivs()

return all array of div tag.

=cut

sub getAllDivs {
	my $self = shift;
	my $agent = $self->{agent};
	my @divs_array;
	my $divs = $agent->Document->divs;
	for (my $n = 0; $n <= $divs->length - 1; $n++){
		my $link_object = Win32::Watir::Element->new();
		$link_object->{element} = $divs->item($n);
		$link_object->{parent} = $self;
		push (@divs_array, $link_object);
	}
	return @divs_array;
}
sub divs {
	my $self = shift;
	return $self->getAllDivs();
}

sub __getObject {
	my ($coll, $how, $what, $type) = @_;
	my ($aftertext_flag, $input, $index_counter, $regex_flag);
	my @_re = ();
	$index_counter = 0 unless (defined $index_counter);
	$regex_flag = 1 if (ref($what) eq 'Regexp');
	for (my $n = 0; $n <= $coll->length - 1; $n++){

			if ($how eq "linktext:" or $how eq 'text:') {
				my $text = $coll->item($n)->outerText;
				$text = trim_white_spaces($text);
				if ($regex_flag){
					return $coll->item($n) if ($text =~ $what);
				} else {
					return $coll->item($n) if ($text eq $what);
				}
			}

			elsif ($how eq "tabtext:") {
				my $text = $coll->item($n)->outerText;
				$text = trim_white_spaces($text);
				if ($regex_flag){
					return $coll->item($n) if ($text =~ $what);
				} else {
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
				} else {
					return $coll->item($n) if ($name eq $what);
				}
			}

			elsif ($how eq "value:") {
				my $value = $coll->item($n)->value;
				if ($regex_flag){
					return $coll->item($n) if ($value =~ $what);
				} else {
					return $coll->item($n) if ($value eq $what);
				}
			}

			elsif ($how eq "class:") {
				my $class = $coll->item($n)->{className};
				if ($regex_flag){
					if ($class =~ $what){
						if (wantarray){
							push(@_re,$coll->item($n));
							next;
						} else {
							return $coll->item($n);
						}
					}
				} else {
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
				} else {
					return $coll->item($n) if ($value eq $what);
				}
			}

			elsif ($how eq "linkurl:" or $how eq 'url:' or $how eq 'href') {
				my $url = $coll->item($n)->href;
				if ($regex_flag){
					return $coll->item($n) if ($url =~ $what);
				} else {
					return $coll->item($n) if ($url eq $what);
				}
			}

			elsif ($how eq "imgurl:" or $how eq 'src:') {
				my $imgurl = $coll->item($n)->src;
				if ($regex_flag){
					return $coll->item($n) if ($imgurl =~ $what);
				} else {
					return $coll->item($n) if ($imgurl eq $what);
				}
			}

			elsif ($how eq "alt:") {
				my $imgurl = $coll->item($n)->alt;
				if ($regex_flag){
					return $coll->item($n) if ($imgurl =~ $what);
				} else {
					return $coll->item($n) if ($imgurl eq $what);
				}
			}

			elsif ($how eq "beforetext:") {
				$input =  $coll->item($n) if ($coll->item($n)->tagname eq "INPUT");
				my $text = $coll->item($n)->getAdjacentText("beforeEnd");
				$text = trim_white_spaces($text);
				if ($regex_flag){
					return $input if ($text =~ $what);
				} else {
					return $input if ($text eq $what);
				}
				$text = $coll->item($n)->getAdjacentText("afterEnd");
				$text = trim_white_spaces($text);
				if ($regex_flag){
					return $input if ($text =~ $what);
				} else {
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
					} else {
						$aftertext_flag = 1 if ($text eq $what);
					}
					$text = $coll->item($n)->getAdjacentText("afterEnd");
					$text = trim_white_spaces($text);
					if ($regex_flag){
						$aftertext_flag = 1 if ($text =~ $what);
					} else {
						$aftertext_flag = 1 if ($text eq $what);
					}
				}
		 	}

			else {
				print "WARNING: \'$how\' is not supported to get the object\n";
			}
	}
	return @_re;
}

# * __getObject hasn't type?
sub getFrame {
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
	} else {
		$self->_log("WARNING: No frame is present in the document with your specified option $how $what\n");
	}
}
sub frame {
	my $self = shift;
	return $self->getFrame(@_);
}

sub getAllFrames {
	my $self = shift;
	my $agent = $self->{agent};
	my @frames_array;
	my $frames = $agent->Document->frames;

	for (my $n = 0; $n <= $frames->length - 1; $n++){
		my %frame = %{$self};
		my $frameref = \%frame;
		$frameref->{agent} = $frames->item($n);
		bless $frameref;
		push(@frames_array, $frameref);
	}
	return @frames_array;
}
sub frames {
	my $self = shift;
	return $self->getAllFrames(@_);
}

sub getPopupWindow {
	my $self = shift;
	my ($what, $wait) = @_;
	my $counter = 0;
	$wait = 2 unless $wait;
	while($counter <= $wait ){
		my $shApp = Win32::OLE->new("Shell.Application") || die "Could not start Shell.Application\n";
		my $windows = $shApp->Windows;
		for (my $n = 0; $n <= $windows->count - 1; $n++){
			my $window = $windows->Item($n);
			my $title = $window->document->title if ($window && defined $window->document);
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
	$self->_log("WARNING: No popup window is present with your specified title: $what");
}	

sub WaitforDone {
	my $self = shift;
	my $agent = $self->{agent};
	while ($agent->Busy || $agent->document->readystate ne "complete"){
		sleep 1;
	}
}

sub WaitforDocumentComplete {
	my $self = shift;
	my $agent = $self->{agent};
	while ($agent->document->readystate ne "complete"){
		sleep 1;
	}
}

=head2 autoit

return AutoItX3.Control

=cut

sub autoit {
	my $self = shift;
	unless ( defined $self->{autoit} ){
		$self->{autoit} = Win32::OLE->new("AutoItX3.Control");
	}
	unless ($self->{autoit}){
		my $autoitx_dll = $self->_find_autoitx_dll();
		if ($autoitx_dll){
			register_autoitx_dll($autoitx_dll);
			$self->{autoit} = Win32::OLE->new("AutoItX3.Control") || 
			die "Could not start AutoItX3.Control through OLE\n";
		} else {
			$self->_log("Error: AutoItX3.Control is not present in the module.");
			exit 1;
		}
	}
	return $self->{autoit};
}

=head2 bring_to_front()

make IE window active.

=cut

sub bring_to_front {
	my $self = shift;
	my $title = shift;
	unless ($title){
		if ($self->ie_version == 6){
			$title = 'Microsoft Internet Explorer';
		} elsif ($self->ie_version >= 7){
			$title = 'Windows Internet Explorer';
		}
	}
	$self->autoit->AutoItSetOption("WinTitleMatchMode", 2);
	$self->autoit->WinActivate($title);
	$self->autoit->AutoItSetOption("WinTitleMatchMode", 1);
}

=head2 ie_version()

return IE major version (6 or 7 or 8).

=cut

sub ie_version {
	my $self = shift;
	return $self->{IE_VERSION};
}
sub _check_ie_version {
	my $self = shift;
	## HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Internet Explorer
	##     Version    REG_SZ    8.0.6001.18813
	my $_cmd = 'reg query "HKLM\SOFTWARE\Microsoft\Internet Explorer" /v Version';
	my $_result = `$_cmd`;
	my $_ver;
	foreach my $line ( split(/[\n\r]+/,$_result) ){
		if ($line =~ /Version\s+REG_SZ\s+([\d\.]+)/){
			$_ver = $1;
			$self->_log("DEBUG: IE_VERSION=$_ver\n") if ($self->{warnings} or $warn);
		}
	}
	if ($_ver){
		my $_major_ver = $_ver;
		   $_major_ver =~ s/\..*$//;
		if ($_major_ver >= 5.0 && $_major_ver <= 6.0){
			die "Could not use IE version 5.x\n";
		}
		elsif ($_major_ver >= 6.0 && $_major_ver < 7.0){
			return 6;
		}
		elsif ($_major_ver >= 7.0 && $_major_ver < 8.0){
			return 7;
		}
		elsif ($_major_ver >= 8.0 && $_major_ver < 9.0){
			return 8;
		}
		elsif ($_major_ver >= 9.0 && $_major_ver < 10.0){
			return 9;
		} else {
			die "Unknown Internet Explorer VERSION - '$_ver'\n";
		}
	} else {
		die "Can't get Internet Explorer VERSION.\n";
	}
}

sub _check_os_name {
	my $self = shift;
	unless ( exists($self->{OS_NAME}) ){
		$self->{OS_NAME} = Win32::GetOSName();
	}
	print STDERR "DEBUG: _check_os_name(): ".$self->{OS_NAME}."\n" if ($self->{warnings});
	return $self->{OS_NAME};
}

sub _find_autoitx_dll {
	my $self = shift;
	my $dllname = "AutoItX3.dll";
	   $dllname = "AutoItX3_x64.dll" if ( $Config{'archname'} =~ /MSWin32-x64/ );
	foreach my $libdir (@INC)
	{
		if ( $libdir =~ /^\/cygdrive\/(\w+)\/(.*)$/i ){
			$libdir = "${1}:/${2}";
		}
		my $dllpath = "$libdir/Win32/Watir/$dllname";
		if ( -e "$dllpath" ){
			$self->_log("DEBUG: _find_autoitx_dll: $dllpath");
			return $dllpath;
		}
	}
	return "";
}

=head2 register_autoitx_dll(dll_path)

Register specified dll to Server.

 arg[0] : dll path.

=cut

sub register_autoitx_dll {
	my $self = shift if (ref($_[0]) eq 'Win32::Watir');
	my $dll = shift;
	my $_tit = "Attension: Registering AutoItX.Control";
	my $_msg = "Win32::Watir require AutoItX.Control, register AutoItX now?\r\n".
		"You must be Administrator (or 'administrator mode').";
	my $_ret = msgbox("$_tit","$_msg",4);
	if ($_ret == 6){
		Win32::RegisterServer($dll);
	} else {
		msgbox("$_tit","registration canceled, script exit.",0);
	}
}

=head2 push_security_alert_yes(wait)

push "Yes" button at "Security Alert" dialog window.

 wait: number of sec, for waiting.

=cut

sub push_security_alert_yes {
	my ($self, $wait) = @_;
	$wait = 5 unless $wait;
	my $title;
	if ( $self->ie_version == 6 ){
		$title = 'Security Alert';
	} else {
		$title = 'Security Alert'; # ToDO
	}
	my $window = $self->autoit->WinWait($title, "", $wait);
	if ($window){
		$self->autoit->WinActivate("$title");
		$self->autoit->Send('!y');
	} else {
		$self->_log("WARNING: No Security Alert dialog is present. Function push_security_alert_yes is timed out.");
	}
}

=head2 push_confirm_button_ok(title, wait)

type enter key (OK) at JavaScript confirm dialog window.

=cut

sub push_confirm_button_ok {
	my ($self, $title, $wait) = @_;
	$title = 'Windows Internet Explorer' unless $title;
	$wait = 5 unless $wait;
	my $window = $self->autoit->WinWait($title, "", $wait);
	if ($window){
		$self->autoit->WinActivate($title);
		$self->autoit->Send('{ENTER}');
	}
}

=head2 push_button_yes()

push "Yes" button at JavaScript confirm dialog window.

=cut

sub push_button_yes {
	my ($self, $title, $wait) = @_;
	$title = 'Windows Internet Explorer' unless $title;
	$wait = 5 unless $wait;
	my $window = $self->autoit->WinWait($title, "", $wait);
	if ($window){
		$self->autoit->WinActivate($title);
		$self->autoit->Send('!y');
	} else {
		$self->_log("WARNING: No dialog is present with title: $title. Function push_button_yes is timed out.");
	}
}

=head2 push_confirm_button_cancel(title, wait)

type escape key (cancel) at JavaScript confirm dialog window.

=cut

sub push_confirm_button_cancel {
	my ($self, $title, $wait) = @_;
	$title = 'Windows Internet Explorer' unless $title;
	$wait = 5 unless $wait;
	my $window = $self->autoit->WinWait($title, "", $wait);
	if ($window){
		$self->autoit->WinActivate($title);
		$self->autoit->Send('{ESCAPE}');
	}
}

=head2 logon(options)

Enter username, password at Basic Auth dialog window.

 options : hash

  title    : dialog window title.
  user     : username.
  password : username.

 ex)
   $ie->goto('https://pause.perl.org/pause/authenquery', 1); ## no wait
   $ie->logon(
     title => "pause.perl.org へ接続",
     user => "myname",
     password => "mypassword",
   );

=cut

sub logon {
	my $self = shift;
	my %opt = @_;
	$opt{wait} = 5 unless ( $opt{wait} );
	my $window = $self->autoit->WinWait($opt{title}, "", $opt{wait});
	if ($window){
		$self->autoit->WinActivate($opt{title});
		$self->autoit->Send($opt{user});
		$self->autoit->Send('{TAB}');
		$self->autoit->Send($opt{password});
		$self->autoit->Send('{ENTER}');
	} else {
		$self->_log("WARNING: No logon dialog is present with title \'$opt{title}\'. Function logon is timed out.\n");
	}
}

=head2 maximize_ie(title)

maximize specified title window.

 arg[0] : window Title name (optional)

=cut

sub maximize_ie {
	my $self = shift;
	my $title = shift;
	unless ($title){
		if ($self->ie_version == 6){
			$title = 'Microsoft Internet Explorer';
		} elsif ($self->ie_version >= 7){
			$title = 'Windows Internet Explorer';
		}
	}
	$self->autoit->AutoItSetOption("WinTitleMatchMode", 2);
	$self->autoit->WinSetState("$title", "", $self->autoit->SW_MAXIMIZE);
	$self->autoit->AutoItSetOption("WinTitleMatchMode", 1);
	return 1;
}

=head2 delete_cookie()

delete IE cookies.

=cut

sub delete_cookie {
	my $self = shift;
	my $folder = Win32::GetFolderPath(Win32::CSIDL_COOKIES, undef);
	opendir(my $_dh,"$folder") or die $@;
	my @files = grep { /^\w+/ && -w "$folder\\$_" } readdir($_dh);
	my $deleted = 0;
	foreach my $_f (@files){
		next if ($_f =~ /desktop\.ini$/i);
		if ( unlink("$folder\\$_f") ){
			$deleted++;
			print STDERR "DEBUG: delete_cookie(): $folder\\$_f\n" if ($self->{warnings});
		}
	}
	closedir($_dh);
	return $deleted;
}

=head2 delete_cache()

delete IE caches.

=cut

sub delete_cache {
	my $self = shift;
	my $folder = Win32::GetFolderPath(Win32::CSIDL_INTERNET_CACHE, undef);
	opendir(my $_dh,"$folder") or die $@;
	my @files = grep { /^\w+/ && -w "$folder\\$_" } readdir($_dh);
	my $deleted = 0;
	foreach my $i (@files){
		next if (-d "$folder\\$i" or $i =~ /desktop\.ini$/i);
		if ( -f "$folder\\$i" ){
			if ( unlink("$folder\\$i") ){
				$deleted++;
				print STDERR "DEBUG: delete_cache(): $folder\\$i\n" if ($self->{warnings});
			} else {
				print STDERR "DEBUG: delete_cache(): can't delete $folder\\$i\n" if ($self->{warnings});
			}
		} elsif ( -d "$folder\\$i" ){
			if ( rmdir("$folder\\$i") ){
				$deleted++;
			} else {
				print STDERR "DEBUG: delete_cache(): can't delete $folder\\$i\n" if ($self->{warnings});
			}
		} else {
			print STDERR "DEBUG: delete_cache(): skipped - $folder\\$i\n";
		}
	}
	closedir($_dh);
	return $deleted;
}


=head2 msgbox(title, message, mode)

show PopUp dialog window.

 title  : dialog window title.
 message: messages.
 mode   : mode of buttons:
 .      0 = OK
 .      1 = OK and Cancel
 .      2 = Abort, Retry, and Ignore
 .      3 = Yes, No and Cancel
 .      4 = Yes and No
 .      5 = Retry and Cancel
 return values:
 .      0  Error
 .      1  OK
 .      2  Cancel
 .      3  Abort
 .      4  Retry
 .      5  Ignore
 .      6  Yes
 .      7  No

see more detail: http://search.cpan.org/perldoc?Win32

=cut

sub msgbox {
	my $title = shift;
	my $message = shift;
	my $mode = shift || 0;
	my $_ret = Win32::MSgBox($message,$mode,$title);
	return $_ret;
}


=head2 trim_white_spacs()

return string - trim \s+

=cut

sub trim_white_spaces {
	my $string = shift;
	$string =~ s/^\s+//;
	$string =~ s/\s+$//;
	return $string;
}

=head2 _log(string)

private method for testing.
use only with t/*.t test.

=cut

sub _log {
	my $self = shift;
	return 1 if ($warn or $self->{warnings});
	my $str = shift;
	chomp($str);
	unless ($str){ return 1; }
	select STDERR; $| = 1;
	select STDOUT; $| = 1;
	foreach my $line (split(/\n/,$str)){
		chomp($line);
		print STDERR "[$$]: $line\n";
	}
}

1;
__END__ 

=head1 SEE ALSO

 Win32
 Win32::OLE
 Win32::IEAutomation

=head1 AUTHOR

 Kazuhito Shimizu, <kazuhito.shimizu@gmail.com>

=head1 COPYRIGHT AND LICENSE

same as Win32::IEAutomation..

=cut
