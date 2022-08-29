# Perl-LibXML-xmlsec
Perl bindings for xmlsec

This modules provides glue for the XMLSec Library, as seen on https://www.aleksey.com/xmlsec/

PREREQUISITES:

You need a running xmlsec library installed on your system for this module to work.
There are binaries available for several linux distributions.

Ubuntu: sudo aptitude install libxmlsec1-dev libxmlsec1-openssl

CentOS: sudo yum install xmlsec1-devel xmlsec1-openssl-devel

For Win32, there are binaries available at https://www.zlatkovic.com/projects/libxml/index.html
You should be able to compile the module with dmake on a MinGW gcc environment, setting the aproppiate 
libraries and header files.


INSTALLATION
 
To install this module, run the following commands:
 
        perl Makefile.PL
        make
        make test
        make install


CREDITS

XMLSec Library is authored by Aleksey Sanin <aleksey-at-aleksey-dot-com> et al.


