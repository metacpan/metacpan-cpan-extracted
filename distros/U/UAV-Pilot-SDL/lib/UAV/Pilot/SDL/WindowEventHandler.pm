# Copyright (c) 2014  Timm Murray
# All rights reserved.
# 
# Redistribution and use in source and binary forms, with or without 
# modification, are permitted provided that the following conditions are met:
# 
#     * Redistributions of source code must retain the above copyright notice, 
#       this list of conditions and the following disclaimer.
#     * Redistributions in binary form must reproduce the above copyright 
#       notice, this list of conditions and the following disclaimer in the 
#       documentation and/or other materials provided with the distribution.
# 
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" 
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE 
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE 
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE 
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR 
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF 
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS 
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN 
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) 
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE 
# POSSIBILITY OF SUCH DAMAGE.
package UAV::Pilot::SDL::WindowEventHandler;
use v5.14;
use Moose::Role;

has 'width' => (
    is      => 'ro',
    isa     => 'Int',
    default => 0,
    writer  => '_set_width',
);
has 'height' => (
    is      => 'ro',
    isa     => 'Int',
    default => 0,
    writer  => '_set_height',
);

requires 'draw';


sub add_to_window
{
    my ($self, $window, $location) = @_;
    $location //= $window->BOTTOM;
    $window->add_child( $self, $location );
    return 1;
}

sub update_window_rect
{
    my ($self, $window) = @_;
    $window->update_rect( $self->width, $self->height );
    return 1;
}


1;
__END__


=head1 NAME

  UAV::Pilot::SDL::WindowEventHandler

=head1 DESCRIPTION

Role for objects that will be passed into C<UAV::Pilot::SDL::Window> as 
children.

The method C<draw> will be called on the object to draw itself.  It will be 
passed the C<UAV::Pilot::SDL::Window> object.  This is the only method that 
is required for the class doing the role to implement.

The C<update_window_rect> method is passed an C<UAV::Pilot::SDL::Window>, and 
is called after C<draw>.  The default implementation will call 
C<<UAV::Pilot::SDL::Window->update_rect>>, but you may wish to override this 
if you have other means of updating your drawing area.

The C<add_to_window> method should be called on the object after construction 
and passed an C<UAV::Pilot::SDL::Window> object.  A second optional parameter 
is the float value (default bottom).  The handler will add itself as a child to 
this window.  The default code for the method in the role will do this for you, 
adding the child at the bottom.

Also has C<width> and C<height> attributes.  They are read-only attributes, but 
can be set with the C<_set_width> and C<_set_height> methods.  These methods 
should be considered private to the class.

=cut
