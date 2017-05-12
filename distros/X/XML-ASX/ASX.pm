package XML::ASX;

use strict;
use vars qw($VERSION $AUTOLOAD %ASX_SLOTS);

use XML::ASX::File;

use overload '""' => \&xml;

$VERSION = '0.01';

%ASX_SLOTS = (
			 );

sub new {
  my $class = shift;
  return XML::ASX::File->new(@_);
}

sub add_param {
  my($self,$key,$value) = @_;
  $self->{param}->{$key} = $value;
  return $self->{param}->{$key};
}

sub each_param {
  my $self = shift;
  return $self->{param} ? %{$self->{param}} : ();
}

sub each_in_queue {
	my $self = shift;
	return $self->{queue} ? @{$self->{queue}} : ();
}

sub entag {
  my $self = shift;
  my $tag = shift;
  my $content = shift;
  my $attr = shift;
  my $closed = shift;

  my $output = '';
  $output .= "<$tag";

  if($attr){
	foreach(keys %$attr){
	  $output .= ' ' . $_ . '="' . $attr->{$_} . '"';
	}
  }

  $output .= "/>\n" and return $output if $closed;

  $output .= ">$content</$tag>\n";

  return $output;
}

1;
__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

XML::ASX - Create ASX (Advanced Streaming XML) files for Windows Media Player

=head1 SYNOPSIS

  use XML::ASX;
  my $asx = XML::ASX->new;
  print $asx;

=head1 DESCRIPTION

XML::ASX generates ASX v3.0-compliant XML files.  ASX files are used by the 
Windows Media Player (WMP) to play a queue of files.

Attributes can be added to several ASX tags to achieve a 'scripting' effect.
You can define items to begin playing at an offset from the beginning, can
cause items to repeat, and can even prevent users from fast-forwarding to the
next item in the playlist (think advertising).

Microsoft has even added tags that allow you to 'brand' WMP by placing
customized 16x16 icons and 80x32 clickable banners inside the player.  What
more can you ask for?

=head1 METHODS

XML::ASX is a parent class for the XML::ASX::* suite.  Methods not documented
in subclasses are documented here, or not at all. :)

All subclasses overload '""' with xml().  Just call print $thing to get the
scalar.

=head2 CONSTRUCTOR

new() - really returns XML::ASX::File::new().  Read about that instead.

=head2 ACCESSORS

add_param(key,value) - add a key/value parameter to an XML::ASX::Entry or 
XML::ASX::File object.  You can add as many as you like.

each_param() - returns a hash of parameters that were added with add_param().

each_in_queue() - returns a (possibly heterogenous) list of XML::ASX::Entry,
XML::ASX::Event, and XML::ASX::Repeat objects.  They are in the same order
that they were added to the queue.  See subclasses for details about how to
enqueue objects.

=head2 INTERNAL METHODS

entag() - function for building XML.  ugly.

=head1 AUTHOR

Allen Day, <allenday@ucla.edu>

=head1 SEE ALSO

=head2 SUBCLASSES

 XML::ASX::File
 XML::ASX::Entry
 XML::ASX::Event
 XML::ASX::Repeat

=head2 RELATED MODULES

 Video::Info
 MP3::Info
 Multimedia::Playlist
 Apache::MP3
 Apache::Jukebox

=head2 REFERENCES

 MSDN: All About Windows Media Metafiles
 http://msdn.microsoft.com/library/en-us/dnwmt/thml/asx.asp

=cut
