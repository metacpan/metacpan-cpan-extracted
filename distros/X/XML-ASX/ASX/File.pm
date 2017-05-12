package XML::ASX::File;

use strict;
use vars qw($VERSION $AUTOLOAD @ISA %ASX_SLOTS);

@ISA = qw(XML::ASX);

use XML::ASX::Entry;
use XML::ASX::Repeat;
use XML::ASX::Event;

use overload '""' => \&xml;

$VERSION = '0.01';

my %RW_SLOTS = (
				title => '',
				moreinfo => '',
				target => '',
				copyright => '',
				base => '',
				author => '',
				abstract => '',

				version => '3.0',
				previewmode => 'YES',
				bannerbar => 'AUTO',

				banner => '',
				logo_icon => '',
				logo_mark => '',
);

sub AUTOLOAD {
  my $self = shift;
  my $param = $AUTOLOAD;
  $param =~ s/.*:://;
  die(__PACKAGE__." doesn't implement $param") unless defined($RW_SLOTS{$param}) or defined($ASX_SLOTS{$param});
  $self->{$param} = shift if @_;
  return $self->{$param};
}

sub new {
  my $class = shift;
  my %param = @_;
  my $self = bless {}, $class;

  $self->$_($ASX_SLOTS{$_}) foreach keys %ASX_SLOTS;
  $self->$_($RW_SLOTS{$_}) foreach keys %RW_SLOTS;
  $self->$_($param{$_}) foreach keys %param;

  return $self;
}

sub add_repeat {
	my $self = shift;
	my $repeat = shift || XML::ASX::Repeat->new;
	push @{$self->{queue}}, $repeat;

	return $self->{queue}->[scalar @{$self->{queue}} - 1];
}

sub add_entry {
	my $self = shift;
	my $entry = shift || XML::ASX::Entry->new;
	push @{$self->{queue}}, $entry;

	return $self->{queue}->[scalar @{$self->{queue}} - 1];
}

sub add_event {
	my $self = shift;
	my $event = shift || XML::ASX::Event->new;
	push @{$self->{queue}}, $event;

	return $self->{queue}->[scalar @{$self->{queue}} - 1];
}

sub xml {
	my $self = shift;

	my $paramstr = '';
	my %param = $self->each_param;
	foreach my $key (keys %param){
	  $paramstr .= $self->entag('PARAM','',{NAME=>$key,VALUE=>$param{$key}},1);
	}

	my $bannercontent = '';
	$bannercontent .= $self->entag('MoreInfo','',{href=>$self->moreinfo,target=>$self->target},1)		if $self->moreinfo;
	$bannercontent .= $self->entag('Abstract',$self->abstract) if $self->abstract;

	my $content = '';
	$content .= $self->entag('ABSTRACT',$self->abstract)				if $self->abstract;
	$content .= $self->entag('TITLE',$self->title)					if $self->title;
	$content .= $self->entag('AUTHOR',$self->author)				if $self->author;
	$content .= $self->entag('BASE','',{href=>$self->base}) if $self->base;
	$content .= $self->entag('COPYRIGHT',$self->copyright)				if $self->copyright;
	$content .= $self->entag('Logo','',{href=>$self->logo_icon,style=>'ICON'},1)	if $self->logo_icon;
	$content .= $self->entag('Logo','',{href=>$self->logo_mark,style=>'MARK'},1)	if $self->logo_mark;
	$content .= $self->entag('Banner',$bannercontent,{href=>$self->banner}) if $self->banner;
	$content .= $self->entag('MoreInfo','',{href=>$self->moreinfo,target=>$self->target},1)		if $self->moreinfo;
	$content .= $paramstr;

	$content .= join "", ($self->each_in_queue);

	return $self->entag('ASX',$content,{previewmode => $self->previewmode, version => $self->version, BannerBar => $self->bannerbar},0);
}

1;
__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

XML::ASX - An ASX file - methods for everything from <ASX> to </ASX>

=head1 SYNOPSIS

  use XML::ASX::File;
  my $asx = XML::ASX::File->new;
  print $asx;

=head1 DESCRIPTION

Represents the ASX file itself.  Use this class to add Repeat blocks,
ASP Events, and Refs (audio and video media sources).

=head1 METHODS

=head2 CONSTRUCTOR

=head2 ACCESSORS

The following are readable by calling without argument, and settable
by calling with argument.

 Method      Default Value      Purpose
 ---------------------------------------------------------------------
 abstract    none               one line summary of file content
 author      none               who made the file
 banner      none               URL to 82x30 image to be displayed
                                during play, just below the media
 bannerbar   AUTO               ???  May be 'FIXED' or 'AUTO'
 base        none               just like HTML
 copyright   none               who holds rights to the file
 logo_icon   none               URL to 16x16 image to be displayed in
                                WMP control bar
 logo_mark   none               URL to 82x30 image displayed before and
                                after queue is played
 moreinfo    none               text to display when mouse hovers over
                                logo or banner
 previewmode YES                ??? May be 'YES' or 'NO'
 target      none               url to open in web browser when banner
                                is clicked
 title       none               title of the file for WMP to display
 version     3.0                ASX version -- don't mess with it

=head2 MORE ACCESSORS

add_repeat() - add an XML::ASX::Repeat object to the end of the
playlist.  Give it an object as argument, or it creates one for you and
returns it.

add_entry() - add an XML::ASX::Entry object to the end of the playlist.
Give it an object as argument, or it creates one for you and returns
it.

add_event() - add an XML::ASX::Event object to the end of the playlist.
Give it an object as argument, or it creates one for you and returns it.

xml() - print the playlist

=head1 AUTHOR

Allen Day, <allenday@ucla.edu>

=head1 SEE ALSO

 XML::ASX::Repeat
 XML::ASX::Entry
 XML::ASX::Event

=cut
