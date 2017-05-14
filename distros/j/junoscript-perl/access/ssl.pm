#
# $Id: ssl.pm,v 1.5 2003/11/11 19:08:27 rjohnst Exp $
#
# COPYRIGHT AND LICENSE
# Copyright (c) 2001-2003, Juniper Networks, Inc.  
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

@acmethod_ssl_classes = qw(  
    	    openssl
    	    Net::SSLeay 
);

@acmethod_ssl_classes_excp = qw(
);

@ssl_c_modules = qw(
    openssl
);

%ssl_prereqs = (
            Net::SSLeay => "1.25",
            openssl => "0.9.6g",
);

%ssl_estimates = (
            Net::SSLeay => "00:01:15",
            openssl => "00:04:08",
);

%ssl_tarballs = (
            Net::SSLeay => "Net_SSLeay.pm-1.25.tar.gz",
            openssl => "openssl-0.9.6g.tar.gz",
);

%ssl_authors = (
            Net::SSLeay => 'Sampo Kellomaki (sampo@iki.fi)',
            openssl => 'OpenSSL (openssl-bugs@openssl.org)',
);

%ssl_class_searchers = (
            openssl => "install::openssl_exists",
);

%ssl_install_flags = (
            Net::SSLeay => get_executable_path('openssl')?get_executable_path('openssl') . "/..":"",
);

sub openssl_exists
{
    my ($binary, $install_directory) = @_;

    my $path = get_executable_path('openssl');
    if ($path) {
        my $info = `openssl version`;
        my ($prog, $version) = split(" ", $info);
        if ($version eq get_version('openssl')) {
            # Net::SSLeay assumes openssl is always under a bin directory
            set_install_flags('Net::SSLeay', "$path/..");
            return 1;
        }
   }

   return 0;
}

sub ssl_add_install_flags
{
    my ($install_directory) = @_;
    # set the default install paths anyway just in case -force_override is
    # turned on.
    if ($install_directory) {
        set_install_flags('Net::SSLeay', "$install_directory/..");
    }
    install::set_install_flags('openssl',
        $install_directory?"./config --prefix=$install_directory/..":"./config");
}

add_access_method(
    name => 'ssl',
    c_modules => \@ssl_c_modules,
    prereqs => \%ssl_prereqs,
    estimates => \%ssl_estimates,
    tarballs => \%ssl_tarballs,
    authors => \%ssl_authors,
    class_searchers => \%ssl_class_searchers,
    install_flags => \%ssl_install_flags,
);

1;
