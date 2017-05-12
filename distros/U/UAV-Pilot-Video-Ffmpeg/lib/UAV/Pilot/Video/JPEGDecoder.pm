# Copyright (c) 2015  Timm Murray
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
package UAV::Pilot::Video::JPEGDecoder;
use v5.14;
use Moose;
use namespace::autoclean;

require DynaLoader;
our @ISA = qw(DynaLoader);
bootstrap UAV::Pilot::Video::JPEGDecoder;


with 'UAV::Pilot::Video::JPEGHandler';

has 'displays' => (
    is  => 'ro',
    isa => 'ArrayRef[Item]',
);


# Helper sub to simplifiy throwing exceptions in the xs code
sub _throw_error
{
    my ($class, $error_str) = @_;
    UAV::Pilot::VideoException->throw(
        error => $error_str,
    );
    return 1;
}

# Helper sub to iterate over all displays after processing a frame
sub _iterate_displays
{
    my ($self, $width, $height) = @_;
    foreach my $display (@{ $self->displays }) {
        $display->process_raw_frame( $width, $height, $self );
    }
    return 1;
}


no Moose;
__PACKAGE__->meta->make_immutable;
1;
__END__


=head1 NAME

    UAV::Pilot::Video::JPEGDecoder

=head1 SYNOPSIS

    # $display is some object that does the role UAV::Pilot::Video::RawHandler, like 
    # UAV::Pilot::SDL::Video
    my $display = ...;

    my $decoder = UAV::Pilot::Video::JPEGDecoder->new({
        displays => [ $display ],
    });

=head1 DESCRIPTION

Decodes a JPEG image using ffmpeg.  Does the
C<UAV::Pilot::Video::JPEGHandler> role.

Like C<UAV::Pilot::Video::H264Handler>, this can be used to decode a 
stream of JPEG images for real-time video.

=head1 FETCHING LAST PROCESSED FRAME

After a frame is decoded, there are two ways to fetch it: a fast way for things 
implemented in C, and a slow way for things implemented in Perl.

=head2 get_last_frame_c_obj

Returns a scalar which contains a pointer to the decoded AVFrame object.  In C, 
you can dereference the pointer to get the AVFrame and handle it from there.

=head2 get_last_frame_pixel_arrayref

Converts data of the three YUV channels  into one array each, and then pushes 
those onto an array and returns the an arrayref.  This is really, really slow, 
and not at all suitable for real-time processing.  It has the advantage that you 
can do everything in Perl.

=cut
