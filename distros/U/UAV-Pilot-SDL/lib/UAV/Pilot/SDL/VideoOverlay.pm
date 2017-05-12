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
package UAV::Pilot::SDL::VideoOverlay;
use v5.14;
use Moose::Role;

requires 'process_video_overlay';

has 'video_overlay' => (
    is     => 'ro',
    isa    => 'Maybe[UAV::Pilot::SDL::Video]',
    writer => '_set_video_overlay',
);


sub init_video_overlay
{
    my ($self, $video) = @_;
    $self->_set_video_overlay( $video );
    return 1;
}


1;
__END__


=head1 NAME

  UAV::Pilot::SDL::VideoOverlay

=head1 DESCRIPTION

A role for objects to draw on top of a video.  Requires a
C<process_video_overlay()> method, which will be passed the C<UAV::Pilot::SDL::Window> object that the video is drawing to.

Where C<$video> is an C<UAV::Pilot::SDL::Video> object, you can set an 
C<$overlay> object with:

    $video->register_video_overlay( $overlay );

B<NOTE>: This is still experimental.  Lines tend to flicker and show up as 
black.  This is probably due to the SDL YUV hardware overlay.

=cut
