From henning@forge.tanstaafl.de  Mon Mar  9 12:47:00 1998
Received: by en1.engelschall.com (Sendmail 8.8.8) via UUCP for rse
	id MAA01349; Mon, 9 Mar 1998 12:47:00 +0100 (MET)
Received: (qmail 6383 invoked from network); 9 Mar 1998 07:28:08 -0000
Received: from world.engelschall.com (192.76.162.15)
  by slarti.muc.de with SMTP; 9 Mar 1998 07:28:08 -0000
Received: from babsi.tanstaafl.de (babsi.tanstaafl.de [194.231.172.1]) by world.engelschall.com (8.7.5/8.7.3) with ESMTP id IAA00305 for <rse@engelschall.com>; Mon, 9 Mar 1998 08:28:17 +0100 (CET)
Received: (from daemon@localhost)
	by babsi.tanstaafl.de (8.8.8/8.8.8) id IAA25435
	for <rse@engelschall.com>; Mon, 9 Mar 1998 08:28:13 +0100
Received: from forge.tanstaafl.de(194.231.172.2)
	via SMTP by babsi.tanstaafl.de, id smtpda25433; Mon Mar  9 08:28:12 1998
Received: (from henning@localhost)
	by forge.tanstaafl.de (8.8.8/8.8.8) id IAA20129
	for rse@engelschall.com; Mon, 9 Mar 1998 08:28:10 +0100
Message-Id: <199803090728.IAA20129@forge.tanstaafl.de>
Subject: eperl Spec File fuer RedHat
To: rse@engelschall.com
Date: Mon, 9 Mar 1998 08:28:10 +0100 (MET)
From: "Henning P. Schmiedehausen" <hps@tanstaafl.de>
Reply-To: hps@tanstaafl.de
Content-Type: text
Status: ROr

Hi,

anbei ein .spec File um eperl unter RedHat 4.2 mit perl 5.004_04 zu bauen und
zu verpacken. Vielleicht was fuer Dein Contrib.

	Have Fun
		Henning


--- cut ---
Summary: Embedded Perl Language
Name: eperl
Version: 2.2.12
Release: 3
Copyright: GPL
Group: Utilities/System
Source0: http://www.engelschall.com/sw/eperl/distrib/eperl-2.2.12.tar.gz
Packager: Henning Schmiedehausen <hps@tanstaafl.de>
Distribution: TANSTAAFL! intern
BuildRoot: /var/tmp/perl-root
Requires: perl

%description
ePerl interprets an ASCII file bristled with Perl 5 program statements by
evaluating the Perl 5 code while passing through the plain ASCII data. It
can operate in various ways: As a stand-alone Unix filter or integrated Perl
5 module for general file generation tasks and as a powerful Webserver
scripting language for dynamic HTML page programming. 

%package demos
Summary: Demo Pages for eperl
Group: doc/html

%description demos
Demonstration pages for the eperl language

%prep
rm -rf $RPM_BUILD_ROOT
%setup

%build
CFLAGS="$RPM_OPT_FLAGS"
./configure --prefix=/usr
make
cp Makefile Makefile.nph
rm *.o
perl Makefile.PL
make

%install

pod2html eperl.pod > eperl.html
mkdir -p $RPM_BUILD_ROOT/usr/lib/perl5/i386-linux/5.00404
mkdir -p $RPM_BUILD_ROOT/home/httpd/cgi-bin $RPM_BUILD_ROOT/home/httpd/html/eperl
mkdir -p $RPM_BUILD_ROOT/usr/lib/perl5/pod
make install
make -f Makefile.nph prefix=$RPM_BUILD_ROOT/usr install

mv $RPM_BUILD_ROOT/usr/bin/eperl $RPM_BUILD_ROOT/home/httpd/cgi-bin/nph-eperl
chown root.root $RPM_BUILD_ROOT/home/httpd/cgi-bin/nph-eperl
chmod u+s       $RPM_BUILD_ROOT/home/httpd/cgi-bin/nph-eperl
mv $RPM_BUILD_ROOT/usr/lib/eperl/* $RPM_BUILD_ROOT/home/httpd/html/eperl

cp eperl.pod $RPM_BUILD_ROOT/usr/lib/perl5/pod
cp eperl.html $RPM_BUILD_ROOT/home/httpd/html/eperl

%clean
rm -rf $RPM_BUILD_ROOT

%files
%dir /usr/lib/perl5/site_perl/Apache
%dir /usr/lib/perl5/site_perl/Parse
%dir /usr/lib/perl5/site_perl/auto/Parse
%dir /usr/lib/perl5/site_perl/auto/Parse/ePerl
%dir /usr/lib/perl5/site_perl/i386-linux/auto/Parse
%dir /usr/lib/perl5/site_perl/i386-linux/auto/Parse/ePerl
%dir /home/httpd/html/eperl

/home/httpd/cgi-bin/nph-eperl
/home/httpd/html/eperl/eperl.html
/usr/lib/perl5/man/man3/Apache::ePerl.3
/usr/lib/perl5/man/man3/Parse::ePerl.3
/usr/lib/perl5/pod/eperl.pod
/usr/lib/perl5/site_perl/Apache/ePerl.pm
/usr/lib/perl5/site_perl/Parse/ePerl.pm
/usr/lib/perl5/site_perl/auto/Parse/ePerl/autosplit.ix
/usr/lib/perl5/site_perl/i386-linux/auto/Parse/ePerl/ePerl.bs
/usr/lib/perl5/site_perl/i386-linux/auto/Parse/ePerl/ePerl.so
/usr/man/man1/eperl.1

%files demos
%dir /home/httpd/html/eperl
/home/httpd/html/eperl/*
--- cut ---



-- 
Dipl.-Inf. Henning P. Schmiedehausen --                hps@tanstaafl.de
TANSTAAFL! Consulting - Unix, Internet, Security      

Hutweide 15                   Fon.: 09131 / 50654-0    "There ain't no such
D-91054 Buckenhof             Fax.: 09131 / 50654-20    thing as a free Linux"

