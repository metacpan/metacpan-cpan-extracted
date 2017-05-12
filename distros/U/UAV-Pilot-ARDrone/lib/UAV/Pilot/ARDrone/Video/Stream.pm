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
package UAV::Pilot::ARDrone::Video::Stream;
$UAV::Pilot::ARDrone::Video::Stream::VERSION = '1.1';
use v5.14;
use warnings;
use Moose;
use namespace::autoclean;

use constant BUF_READ_SIZE => 4096;

extends 'UAV::Pilot::ARDrone::Video';

has 'out_fh' => (
    is  => 'ro',
    isa => 'Item',
);


sub BUILDARGS
{
    my ($class, $args) = @_;
    my $io = $class->_build_io( $args );

    $$args{'_io'} = $io;
    delete $$args{'host'};
    delete $$args{'port'};
    return $args;
}


sub _process_io
{
    my ($self) = @_;
    my $buf;
    my $read_count = $self->_io->read( $buf, $self->BUF_READ_SIZE );

    $self->out_fh->print( $buf );

    return 1;
}


no Moose;
__PACKAGE__->meta->make_immutable;
1;
__END__


=head1 NAME

  UAV::Pilot::ARDrone::Video::Stream

=head1 DESCRIPTION

A version of C<UAV::Pilot::ARDrone::Video> that writes the video stream to 
another filehandle.  This can be used to write the video to an open file, or 
to an external process over a pipe that will otherwise handle the video stream.

=head1 ATTRIBUTES

=head2 out_fh

The filehandle to write out to.

=cut
