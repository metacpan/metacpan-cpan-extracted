package XML::ASX::Entry;

use strict;
use vars qw($VERSION $AUTOLOAD %ASX_SLOTS @ISA);

@ISA = qw(XML::ASX);

use overload '""' => \&xml;

$VERSION = '0.01';

my %RW_SLOTS = (
			   title => '',
			   moreinfo => '',
			   target => '',
			   duration => '',
			   copyright => '',
			   base => '',
			   author => '',
			   abstract => '',
			   clientskip => 'YES',

			   duration => '00:00:00.00',
			   previewduration => '',
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

sub add_ref {
	my $self = shift;
	push @{$self->{refs}}, shift if @_;
	return $self->{refs}->[scalar @{$self->{refs}} - 1];
}

sub each_ref {
	my $self = shift;
	return $self->{refs} ? @{$self->{refs}} : ();
}

sub xml {
	my $self = shift;

	die __PACKAGE__.': clientskip() must be "YES" or "NO"' if ($self->clientskip ne 'YES' and $self->clientskip ne 'NO');

	my $refstr = '';
	foreach my $ref ($self->each_ref){
		$refstr .= $self->entag('Ref','',{href=>$ref},1);
	}

	my $paramstr = '';
	my %param = $self->each_param;
	foreach my $key (keys %param){
	  $paramstr .= $self->entag('PARAM','',{NAME=>$key,VALUE=>$param{$key}},1);
	}

	my $bannercontent = '';
	$bannercontent .= $self->entag('MoreInfo','',{href=>$self->moreinfo,target=>$self->target},1)		if $self->moreinfo;
	$bannercontent .= $self->entag('Abstract',$self->abstract) if $self->abstract;

	my $content = '';
	$content .= $self->entag('Duration','',{value=>$self->duration},1)	if $self->duration;
	$content .= $self->entag('PreviewDuration','',{value=>$self->duration},1)	if $self->previewduration;
	$content .= $self->entag('Title',$self->title) 				if $self->title;
	$content .= $self->entag('Copyright',$self->copyright) 			if $self->copyright;
	$content .= $self->entag('Logo','',{href=>$self->logo_icon,Style=>'ICON'},1) if $self->logo_icon;
	$content .= $self->entag('Logo','',{href=>$self->logo_mark,Style=>'MARK'},1) if $self->logo_mark;
	$content .= $self->entag('MoreInfo','',{href=>$self->moreinfo,target=>$self->target},1) if $self->moreinfo;
	$content .= $self->entag('Banner',$bannercontent,{href=>$self->banner}) if $self->banner;
	$content .= $refstr;
	$content .= $paramstr;
	return $self->entag('Entry',
		$content,
		{ClientSkip => $self->clientskip},0
	);
}

1;
__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

XML::ASX::Entry - Describe a media source

=head1 SYNOPSIS

  use XML::ASX::Entry;
  $entry = XML::ASX::Entry->new;
  $entry->banner('http://some/bmp');
  $entry->ref('http://source/1.asf');
  $entry->ref('http://mirror/1.asf');
  $entry->ref('mms://mirror2/1.asf');

=head1 DESCRIPTION

XML::ASX::Entry represents a playlist entry in an ASX XML document.

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
 base        none               just like HTML
 clientskip  YES                is the client allowed to skip the entry?
                                may be 'YES' or 'NO'.
 copyright   none               who holds rights to the file
 duration    00:00:00.00        how long should we play the stream?
 previewduration none           and for how long in preview mode?
 logo_icon   none               URL to 16x16 image to be displayed in
                                WMP control bar
 logo_mark   none               URL to 82x30 image displayed before and
                                after queue is played
 moreinfo    none               text to display when mouse hovers over
                                logo or banner
 target      none               url to open in web browser when banner
                                is clicked
 title       none               title of the file for WMP to display

=head2 MORE ACCESSORS

sub add_ref() - add a network-addressable path to a media source.
multiple calls may be made to add_ref() for rollover/redundancy.

sub each_ref() - returns a list of items added by add_ref().

sub xml() - returns XML from <ENTRY> to </ENTRY>

=head1 AUTHOR

Allen Day, <allenday@ucla.edu>

=head1 SEE ALSO

XML::ASX

=cut
