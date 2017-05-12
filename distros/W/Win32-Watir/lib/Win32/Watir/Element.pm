package Win32::Watir::Element;

use strict;
use vars qw($VERSION);
$VERSION = '0.5c';

sub new {
	my $class = shift;
	my $self  = { };
	$self->{element} = undef;
	$self->{parent} = undef;
	$self = bless ($self, $class);
	return $self;
}

sub getElement { 
	my $self = shift;
	return $self->{element};
}

sub getProperty {
	my ($self, $property) = @_;
	return $self->{element}->{$property};
}

sub linkText {
	my $self = shift;
	return $self->{element}->{outerText};
}

sub text {
	my $self = shift;
	return $self->{element}->{outerText};
}

sub linkUrl {
	my $self = shift;
	return $self->{element}->{href};
}

sub url {
	my $self = shift;
	return $self->linkUrl;
}

sub href {
	my $self = shift;
	return $self->linkUrl;
}

sub className {
	my $self = shift;
	return $self->{element}->{className};
}

sub class {
	my $self = shift;
	return $self->className;
}

sub id {
	my $self = shift;
	return $self->{element}->{id};
}

sub imgUrl {
	my $self = shift;
	return $self->{element}->{src};
}

sub src {
	my $self = shift;
	return $self->imgUrl;
}

sub Click {
	my ($self, $nowait) = @_;
	$self->{element}->click;
	$self->{parent}->WaitforDone unless $nowait;
}
sub click {
	my $self = shift;
	return $self->Click(@_);
}

sub click_nowait {
	my ($self, $nowait) = @_;
	$self->{element}->click;
}
sub click_no_wait {
	my $self = shift;
	$self->click_nowait(@_);
}

sub FireEvent {
	my ($self, $eventname) = @_;
	$self->{element}->fireEvent($eventname);
	$self->{parent}->WaitforDone;
}

sub Select {
	my $self = shift;
	unless ($self->{element}->{checked}){
		$self->{element}->{checked} = 1;
		$self->{element}->fireEvent("onclick");
		$self->{parent}->WaitforDone;
	}
}

sub deSelect {
	my $self = shift;
	if ($self->{element}->{checked}){
		$self->{element}->{checked} = 0;
		$self->{parent}->WaitforDone;
	}
}

sub SelectItem {
	my $self = shift;
	my @items = @_;
	my $item_present_flag;
	foreach my $item (@items){
		$item_present_flag = 0;
		my $options = $self->{element}->options;
		for (my $n =0; $n <= $options->length - 1; $n++){
			my $text = $options->item($n)->innerText;
			$text = trim_white_spaces($text);
			if ($text eq $item){
				$item_present_flag = 1;
				unless ($options->item($n)->selected){
					$options->item($n)->{selected} = 1;
					$self->{element}->fireEvent("onchange");
					$self->{parent}->WaitforDone;
					last;
				}
			}
		}
		print "WARNING: Your provided item \'$item\' is not present in the select list.\n" if ($item_present_flag == 0);
	}
	return $item_present_flag;
}

sub deSelectItem {
	my $self = shift;
	my @items = @_;
	foreach my $item (@items){
		my $options = $self->{element}->options;
		for (my $n =0; $n <= $options->length - 1; $n++){
			my $text = $options->item($n)->innerText;
			$text = trim_white_spaces($text);
			if ($text eq $item){
				$options->item($n)->{selected} = 0 if $options->item($n)->selected;
				$self->{element}->fireEvent("onchange");
				$self->{parent}->WaitforDone;
				last;
			}
		}
	}
}

sub deSelectAll {
	my $self = shift;
	my @items = @_;
		my $options = $self->{element}->options;
		for (my $n =0; $n <= $options->length - 1; $n++){
				$options->item($n)->{selected} = 0 if $options->item($n)->selected;
				$self->{element}->fireEvent("onchange");
				$self->{parent}->WaitforDone;
		}
}

sub SetValue {
	my ($self, $string) = @_;
	if ($self->getProperty("type") eq "file"){
		$self->{element}->focus;
		my $clicker = Win32::Watir::WinClicker->new();
		$clicker->{autoit}->Send($string);
	}else{
		$self->{element}->{value} = $string;
	}
}
sub set {
	my $self = shift;
	return $self->SetValue(@_);
}
sub setvalue {
	my $self = shift;
	return $self->SetValue(@_);
}

sub GetValue {
	my $self = shift;
	return $self->{element}->{value};
}
sub value {
	my $self = shift;
	return $self->{element}->{value};
}
sub getvalue {
	my $self = shift;
	return $self->{element}->{value};
}

sub ClearValue {
	my $self = shift;
	$self->{element}->{value} = "";
}
sub clear {
	my $self = shift;
	$self->{element}->{value} = "";
}

sub trim_white_spaces {
	if (ref($_[0]) =~ /^Win32::Watir/){
		my $self = shift;
	}
	my $string = shift;
	$string =~ s/^\s+//;
	$string =~ s/\s+$//;
	return $string;
}
	 
1;
__END__ 
