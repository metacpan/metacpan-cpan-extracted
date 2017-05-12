#############################################################################
## Name:        lib/Wx/DemoModules/wxXrcCustom.pm
## Purpose:     wxWidgets' XML Resources demo
## Author:      Mattia Barbon
## Created:     25/08/2003
## RCS-ID:      $Id: wxXrcCustom.pm 2189 2007-08-21 18:15:31Z mbarbon $
## Copyright:   (c) 2003, 2006 Mattia Barbon
## Licence:     This program is free software; you can redistribute it and/or
##              modify it under the same terms as Perl itself
#############################################################################

use Wx::XRC;
use Wx::FS;

package Wx::DemoModules::wxXrcCustom::XmlHandler;

use strict;
use base 'Wx::PlXmlResourceHandler';

# this methods must return true if the handler can handle
# the given XML node
sub CanHandle {
    my( $self, $xmlnode ) = @_;
    return $self->IsOfClass( $xmlnode, 'HelloWorld' );
}

# this method is where the actual creation takes place
sub DoCreateResource {
    my( $self ) = shift;

    # this is the case when the user called LoadOnXXX, to load
    # an already created object. We could handle this case as well,
    # (just calling ->Create instead of ->new), but that would
    # just complicate the code
    die 'LoadOnXXX not supported by this handler' if $self->GetInstance;

    my $ctrl = Wx::DemoModules::wxXrcCustom::HelloWorldCtrl->new
      ( $self->GetParentAsWindow,
        $self->GetID,
        $self->GetColour( 'colour' ),
        $self->GetPosition,
        $self->GetSize,
        $self->GetStyle( "style", 0 ),
        $self->GetName );

    $self->SetupWindow( $ctrl );
    $self->CreateChildren( $ctrl );

    return $ctrl;
}

package Wx::DemoModules::wxXrcCustom;

use strict;
use base qw(Wx::Panel);
use Wx qw(wxDefaultPosition wxDefaultSize wxVERSION_STRING
          wxOK wxICON_INFORMATION wxPOINT wxSIZE);

sub new {
    my( $class, $parent ) = @_;

    # could load from file, but this keeps the code inline
    Wx::FileSystem::AddHandler( Wx::MemoryFSHandler->new );
    local $/;
    Wx::MemoryFSHandler::AddTextFile( 'sample.xrc', <<EOT );
<?xml version="1.0" encoding="utf-8"?>
<resource>
  <object class="wxPanel" name="MyPanel">
    <object class="HelloWorld">
      <colour>#ffffff</colour>
      <pos>20, 20</pos>
      <size>100, 20</size>
    </object>
    <object class="HelloWorld">
      <colour>#ff0000</colour>
      <pos>20, 60</pos>
      <size>200, 50</size>
    </object>
    <size>300, 300</size>
  </object>
</resource>
EOT

    my $res = Wx::XmlResource->new;

    $res->InitAllHandlers();
    $res->AddHandler( Wx::DemoModules::wxXrcCustom::XmlHandler->new );
    $res->Load( 'memory:sample.xrc' );

    my $self = $res->LoadPanel( $parent, 'MyPanel' );

    return $self;
}

sub tags { [ 'misc/xrc', 'XRC' ] }
sub add_to_tags { qw(misc/xrc) }
sub title { 'Custom handler' }

package Wx::DemoModules::wxXrcCustom::HelloWorldCtrl;

use strict;
use base 'Wx::StaticText';

use Wx qw(wxBLACK);

sub new {
  my( $class, $parent, $id, $colour, $pos, $size, $style, $name ) = @_;

  $colour ||= wxBLACK;

  my $self = $class->SUPER::new( $parent, $id, 'Hello, world!', $pos, $size,
                                 $style, $name );

  $self->SetForegroundColour( $colour );

  return $self;
}

1;
