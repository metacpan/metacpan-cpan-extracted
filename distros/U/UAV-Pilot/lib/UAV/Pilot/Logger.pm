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
package UAV::Pilot::Logger;
$UAV::Pilot::Logger::VERSION = '1.3';
use v5.14;
use Moose::Role;
use UAV::Pilot;
use Log::Log4perl;

my $LOGGER = undef;


sub _logger
{
    my ($class) = @_;
    return $LOGGER if defined $LOGGER;
    UAV::Pilot->init_log;
    return Log::Log4perl->get_logger( $class->_logger_name );
}

sub _logger_name
{
    my ($self) = @_;
    return ref $self;
}


1;
__END__


=head1 NAME

  UAV::Pilot::Logger

=head1 DESCRIPTION

A Moose role for C<UAV::Pilot> classes that want to log things.

Provides the attribute C<_logger>, which returns a C<Log::Log4perl::Logger> for 
your object.

Also provides a method C<_logger_name> for fetching the logger name.  This will 
be your class's name by default.  Override as you see fit.

=cut
