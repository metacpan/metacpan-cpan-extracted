package XML::WMM::ASX;

use strict;
use vars qw($ASX_Version %auto $AUTOLOAD $VERSION);

$VERSION     = 0.30;
$ASX_Version = 3.0;
%auto        = (
		ABSTRACT  => 1,
		TITLE     => 1,
		COPYRIGHT => 1, 
		AUTHOR    => 1,
		);

sub new {
    my $proto        = shift;
    my $class        = ref($proto) || $proto;
    my $self         = {};
    %{$self->{args}} = @_;
	
    bless($self, $class);

    $self;
}

sub header {
    my $self = shift;
    my %args = @_;
    my $out;
    $out .= qq|previewmode = "yes"| if $args{previewmode};
    return <<"EOT";
<ASX version = "$ASX_Version" $out>
EOT
}

sub AUTOLOAD {
    my $self  = shift;
    my %args  = @_;
    $AUTOLOAD =~s/.*:://; 
    my $name  = uc $AUTOLOAD;    
    my $text  = $args{text} || "Missing $name";

    unless ($auto{$name}) {
	warn "$name: no such tag/method\n";
        return;
	}
  
    return <<EOT;
<$name>$text</$name>
EOT
}

sub startentry {
    return <<EOT;
<ENTRY>
EOT
}

sub endentry {

    return <<EOT;
</ENTRY>
EOT
}

sub end {
    
    return <<EOT;
</ASX>
EOT
}

sub ref {
    my $self = shift;
    my %args = @_;
    my $type = $args{type};
    my $path = $args{path};
    if ($type eq "file" && ! -e $path)
    {
      warn("No such file $path");
    }

    return <<EOT;
<ref HREF="$type://$path" /> 			      
EOT
}		  

sub logo {
    my $self  = shift;
    my %args  = @_;
    my $path  = $args{path};
    my $style = $args{style} || "ICON";  #or MARK
    
    return <<EOT;
<Logo HREF = "$path" Style = "$style" />
EOT
}

sub banner {
    my $self = shift;
    my %args = @_;
    my $path = $args{path};
    my $out;
    $out .= $self->abstract(text=>$args{abstract}) if $args{abstract};
    $out .= $self->moreinfo(path=>$args{moreinfo}) if $args{moreinfo};

    return <<EOT;
<BANNER HREF="$path">
$out</BANNER>
EOT
}

sub base {
    my $self = shift;
    my %args = @_;
    my $path = $args{path} || '';
    
    return <<EOT;
<Base HREF = "$path" />
EOT
}

sub duration {
    my $self  = shift;
    my %args  = @_;
    my $value = $args{value} || '';
    
    return <<EOT;
<Duration value = "$value" />
EOT
}

sub previewduration {
    my $self  = shift;
    my %args  = @_;
    my $value = $args{value} || '';
    
    return <<EOT;
<PreviewDuration value = "$value" />
EOT
}

sub starttime {
    my $self  = shift;
    my %args  = @_;
    my $value = $args{value} || '';
    
    return <<EOT;
<StartTime value = "$value" />
EOT
}

sub moreinfo {
    my $self = shift;
    my %args = @_;
    my $path = $args{path} || '';
    
    return <<EOT;
<MoreInfo href = "$path" />
EOT
}

sub startmarker {
    my $self  = shift;
    my %args  = @_;
    my $value = $args{value};
    my $str   = (($value =~ /\D/)? "name = " : "number = ") . qq|"$value"|; 
    
    return <<EOT;
<StartMarker $str />
EOT
}

sub endmarker {
    my $self  = shift;
    my %args  = @_;
    my $value = $args{value};
    my $str   = (($value =~ /\D/)? "name = " : "number = ") . qq|"$value"|; 
    
    return <<EOT;
<EndMarker $str />
EOT
}

sub startrepeat {
    my $self  = shift;
    my %args  = @_;
    my $value = $args{value} || 2;

    return <<EOT;
<Repeat Count = "$value">
EOT
}

sub endrepeat {
    return <<EOT;
</Repeat>
EOT
}

sub endref {  
    return <<EOT;
</Ref> 
EOT
}

sub startevent {
    my $self  = shift;
    my %args  = @_;
    my $name  = $args{name} || "";
    
    return <<EOT;
<Event Name = "$name" WhenDone = "RESUME">
EOT
} 

sub endevent {
    return <<EOT;
</Event>
EOT
} 

sub entryref {
    my $self  = shift;
    my %args  = @_;
    my $path  = $args{path};

    return <<EOT;
<EntryRef href = "$path" 
           ClientBind = "no" />
EOT
}

sub validate {}
sub DESTROY {}

1;
__END__


=pod

=head1 NAME 

XML::WMM::ASX - a very simple OO interface to create Windows Media Metafile ASX.

=head1 SYNOPSIS

    use XML::WMM::ASX
    $asx = new XML::WMM::ASX;

=head1 DESCRIPTION

This simple module allows you to create ASX file.

=head1 METHODS

The following methods are available:

=over 4

=item $asx = XML::WMM::ASX->new

The constructor returns a new C<ASX> object.

=item $asx->header()

The asx header, you may set different modes: $asx->header(previewmode=>1).

=item $asx->startentry()

Create entry element.

=item $asx->endentry()

Create entry footer.

=item $asx->end()

Return ASX footer.

=item $asx->ref(path=>$URL)

Reference to external asx files. 

=item $asx->logo(path=>$path)

The Logo element specifies the URL for a graphic file that is 
associated with an ASX or Entry element (a show or clip). 
These graphic files are displayed in the player as they are 
defined by the Logo style attributes. The style attribute can 
value of either ICON or MARK.

=item $asx->banner(path=>$path, moreinfo=>$url, abstract=>$text)

A Banner element defines a URL to a graphic file that will appear 
in the display panel beneath the video content. Windows Media Player 
reserves a space 32 pixels high by 194 pixels wide (the banner bar) 
for the graphic. If the graphic defined in the URL is smaller than 
that, it displays at its original size.

=item $asx->base(path=>$path)

The Base element defines a URL string appended to (the front of) 
URL-flip URLs sent to the client.

=item $asx->duration(value=>$time)

The Value attribute for the Duration element defines the length 
of time a stream is to be rendered by the client. It is possible 
to set the Value attribute to a length of time that exceeds the 
end of the content stream, in which case the stream terminates 
normally.

=item $asx->previewduration(value=>$time)

The PreviewDuration element defines the length of time the clip 
defined in the associated Entry or Ref element is played when 
the client is in Preview mode. If PreviewDuration is associated 
with the ASX element, the time value applies to all clips in the 
metafile.

=item $asx->starttime(value=>$time)

The StartTime element defines a time index from which Windows 
Media Player will start rendering the stream. The StartTime element 
can be used only with on-demand content that has been indexed.

=item $asx->moreinfo(path=>$path)

The MoreInfo element adds hyperlinks to areas of the Windows 
Media Player interface.

=item $asx->startmarker(value=>$value)

See description of endmarker.

=item $asx->endmarker(value=>$value)

The EndMarker element defines the named or numeric marker index 
where the player is to stop rendering the stream defined in the 
associated Entry or Ref element. An associated element is the 
parent element of an element.

=item $asx->startrepeat(value=>$counter)

The default count value is two. Please note this method must be
used in pair with endrepeat. 

=back

=head1 AUTHORS

Chicheng Zhang<chichengzhang@hotmail.com>

=cut



