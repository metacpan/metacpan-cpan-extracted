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
package UAV::Pilot::Video::FileDump;
$UAV::Pilot::Video::FileDump::VERSION = '1.3';
use v5.14;
use Moose;
use namespace::autoclean;

with 'UAV::Pilot::Video::H264Handler';

has 'file' => (
    is  => 'ro',
    isa => 'Str',
);
has 'single_frame' => (
    is      => 'ro',
    isa     => 'Bool',
    default => 0,
);
has '_frame_count' => (
    is      => 'rw',
    isa     => 'Int',
    default => 0,
);
has '_fh' => (
    is  => 'ro',
    isa => 'Item',
);


sub BUILDARGS
{
    my ($class, $args) = @_;

    if(! $args->{single_frame} ) {
        my $fh;
        if( defined $args->{file}) {
            open( my $fh, '>', $args->{file} )
                or die "Can't open $$args{file}: $!\n";
        }
        else {
            $fh = $args->{fh} // \*STDOUT;
        }

        $args->{'_fh'} = $fh;
    }

    return $args;
}

sub process_h264_frame
{
    my ($self, $packet) = @_;

    my $data = pack( 'C*', @$packet );
    if( $self->single_frame) {
        my $base_file = $self->file;
        my $full_file = sprintf(
            $base_file . '.%05i',
            $self->_frame_count
        );

        open( my $fh, '>', $full_file )
            or die "Can't open $full_file: $!\n";
        print $fh $data;
        close $fh;
    }
    else {
        my $fh = $self->_fh;
        print $fh $data;

    }

    $self->_frame_count( $self->_frame_count + 1 );
    return 1;
}

sub close
{
    my ($self) = @_;
    $self->_fh->close if defined $self->_fh;
    return 1;
}


no Moose;
__PACKAGE__->meta->make_immutable;
1;
__END__


=head1 NAME

  UAV::Pilot::Video::FileDump

=head1 SYNOPSIS

    open( my $vid_out, '>', 'video.h264' ) or die $!;
    my $file_dump = UAV::Pilot::Video::FileDump->new({
        fh => $vid_out,
    });
    my $video = UAV::Pilot::Driver::ARDrone::Video->new({
        handler => $file_dump,
        ...
    });

=head1 DESCRIPTION

Writes the h264 video frames to a file.  Afterwords, you should be able to play this file 
with mplayer or other video players that support h264 without being inside a container 
format.

=cut
