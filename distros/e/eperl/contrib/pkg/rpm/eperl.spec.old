Summary: Embedded Perl Language
Name: eperl
Version: 2.2.11
Release: 1
Group: Utilities/System
Source: http://www.engelschall.com/sw/eperl/distrib/eperl-2.2.11.tar.gz
Copyright: GPL or Artistic
Requires: perl

%package modules
Summary: Perl module files
Group: Development/Libraries

%description
ePerl interprets an ASCII file bristled with Perl 5 program statements by
evaluating the Perl 5 code while passing through the plain ASCII data. It
can operate in various ways: As a stand-alone Unix filter or integrated Perl
5 module for general file generation tasks and as a powerful Webserver
scripting language for dynamic HTML page programming. 

%description modules
This package includes the Perl 5 modules from ePerl:
Parse::ePerl and Apache::ePerl.

%prep

%setup

%build
CFLAGS="$RPM_OPT_FLAGS" ./configure --prefix=/tmp
make

%install
make install

%clean

%post

%files
%doc docs/*
/bin/eperl
/man/eperl.1

%files modules
