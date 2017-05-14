# COPYRIGHT AND LICENSE
# Copyright (c) 2001, Juniper Networks, Inc.
# All rights reserved.
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are
# met:
# 	1.	Redistributions of source code must retain the above
# copyright notice, this list of conditions and the following
# disclaimer. 
# 	2.	Redistributions in binary form must reproduce the above
# copyright notice, this list of conditions and the following disclaimer
# in the documentation and/or other materials provided with the
# distribution. 
# 	3.	The name of the copyright owner may not be used to 
# endorse or promote products derived from this software without specific 
# prior written permission. 
# THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR
# IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT,
# INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
# HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
# STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING
# IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.
#
#

use ExtUtils::MakeMaker;

$VERSION = ( exists $ENV{'RELEASE'} ? $ENV{'RELEASE'} : '6.4I0' );

sub MY::libscan
{
    package MY;

    my ($self, $file) = @_;

    # Don't install these PM files (or Emacs or other backups: *~ *.bak)
    return undef if $file =~ /(CVS$|.cvsignore$|install.*.pl|install.pm|required-mod.pl|~$|\.bak$)/;

    return $self->SUPER::libscan ($file);
}

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

WriteMakefile(
    NAME         => 'junoscript-perl',
    AUTHOR       => 'Juniper Networks, Inc',
    ABSTRACT     => 'junoscript libraries for perl',
    VERSION_FROM => 'Makefile.PL',
    PREREQ_PM    => {
	    MIME::Base64 => "0",
	    URI => "0",
	    Date::Manip => "0",
	    Parse::Yapp::Driver => "0",
	    HTML::Tagset => "0",
	    HTML::Parser => "0",
	    LWP => "0",
	    XML::Parser => "0",
	    XML::Parser::PerlSAX => "0",
	    XML::DOM => "0",
	    IO::Tty => "0",
	    },
);
