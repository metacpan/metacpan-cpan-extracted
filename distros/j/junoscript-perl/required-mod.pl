#
# $Id: required-mod.pl,v 1.7 2003/03/02 11:12:01 dsw Exp $
#
# COPYRIGHT AND LICENSE
# Copyright (c) 2001, 2003, Juniper Networks, Inc.  
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

use install;

#
# Set AUTOFLUSH to true
#
$| = 1;

use constant USED_BY_DEFAULT => 'default';

print "\nIt will take a few minutes to look for all required modules...\n";

my $access = shift || "all";
my $used_by = shift || USED_BY_DEFAULT;
my @modules = install::get_auto_classes($access, $used_by);
my @byhand = install::get_manual_classes($access, $used_by);
install::redirect_output("$0.log", 0);
my @missing = ();
for my $class (@modules,@byhand) {
    if (install::is_c_module($class)) {
        push(@missing, $class) if (!install::c_module_exists($class, $ENV{PERL5LIB}));
    } else {
        my $vers = install::get_version($class);
        push(@missing, $class) if (!install::class_exists($class, $vers));
    }
}

install::restore_output;

if(scalar(@missing)) {
    print "\nThe following modules are not found:\n";
    foreach my $m (@missing) {
	print "    $m\n";
    }
    print "Please make sure the search paths for perl are correct.\n";
    print join("\n", @INC),"\n";
    print "If the search paths are correct, run install-prereqs.pl to \n";
    die "install the missing modules.\n\n";
}

if ($used_by eq USED_BY_DEFAULT){
    print "\nAll modules required by JUNOS::Device are installed.\n\n";
} else {
    print "\nAll modules required by $used_by are installed.\n\n";
}
