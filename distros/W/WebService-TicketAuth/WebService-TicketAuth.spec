
%define pkgname   WebService-TicketAuth
%define filelist  %{pkgname}-%{version}-filelist
%define NVR       %{pkgname}-%{version}-%{release}
%define maketest  1
name:		  perl-%{pkgname}
summary:	  %{pkgname} - Ticket-based Authentication for SOAP
version:	  1.05
release:	  1
vendor:		  Open Source Development Labs
packager:	  Bryce Harrington <bryce@osdl.org>
license:	  Same as Perl
group:		  Applications/CPAN
url:		  http://soaplite.com
buildroot:	  %{_tmppath}/%{name}-%{version}-%(id -u -n)
buildarch:	  noarch
source:		  %{pkgname}-%{version}.tar.gz

%description
WebService::TicketAuth is an authentication module for SOAP-based web
services, that provides a signature token (like a cookie) to the client
that it can use for further interactions with the server.  This means
that the user can login and establish their credentials for their
session, then use various tools without having to provide a password for
each operation.  Sessions can be timed out, to mitigate against a ticket
being used inappropriately.

%prep
%setup -q -n %{pkgname}-%{version} 
chmod -R u+w %{_builddir}/%{pkgname}-%{version}

%build
CFLAGS="$RPM_OPT_FLAGS"
# DEBUG:  REMOVING ANY EXISTING Makefile
rm -f Makefile
# DEBUG:  CREATING THE MAKEFILE
%{__perl} Makefile.PL DESTDIR=%{buildroot} `%{__perl} -MExtUtils::MakeMaker -e ' print qq|PREFIX=%{buildroot}%{_prefix}| if \$ExtUtils::MakeMaker::VERSION =~ /5\.9[1-6]|6\.0[0-5]/ '`

# DEBUG:  MAKING THE SOFTWARE
%{__make} 

%if %maketest
# DEBUG:  RUNNING MAKE TEST
%{__make} test
%endif

%install
[ "%{buildroot}" != "/" ] && rm -rf %{buildroot}
mkdir -p $RPM_BUILD_ROOT/usr
%{makeinstall} `%{__perl} -MExtUtils::MakeMaker -e ' print \$ExtUtils::MakeMaker::VERSION <= 6.05 ? qq|PREFIX=%{buildroot}%{_prefix}| : qq|DESTDIR=%{buildroot}| '`
[ -x /usr/lib/rpm/brp-compress ] && /usr/lib/rpm/brp-compress
# SuSE Linux
if [ -e /etc/SuSE-release ]; then
%{__mkdir_p} %{buildroot}/var/adm/perl-modules
%{__cat} `find %{buildroot} -name "perllocal.pod"`  \
| %{__sed} -e s+%{buildroot}++g                 \
> %{buildroot}/var/adm/perl-modules/%{name}
fi
# remove special files
find %{buildroot} -name "perllocal.pod" \
-o -name ".packlist"                \
-o -name "*.bs"                     \
|xargs -i rm -f {}
# no empty directories
find %{buildroot}%{_prefix}             \
-type d -depth                      \
-exec rmdir {} \; 2>/dev/null
%{__perl} -MFile::Find -le '
find({ wanted => \&wanted, no_chdir => 1}, "%{buildroot}%{_prefix}" );
print "%defattr(-,root,root)";
print "%doc  doc INSTALL README";
for my $x (sort @dirs, @files) {
    push @ret, $x unless indirs($x);
}
print join "\n", sort @ret;
sub wanted {
    return if /auto$/;
    local $_ = $File::Find::name;
    my $f = $_; s|^%{buildroot}||;
    return unless length;
    return $files[@files] = $_ if -f $f;
    $d = $_;
    /\Q$d\E/ && return for reverse sort @INC;
    $d =~ /\Q$_\E/ && return
    for qw|/etc %_prefix/man %_prefix/bin %_prefix/share|;
    $dirs[@dirs] = $_;
}
sub indirs {
    my $x = shift;
    $x =~ /^\Q$_\E\// && $x ne $_ && return 1 for @dirs;
}
' > %filelist
cat %filelist
echo "####"
[ -z %filelist ] && {
echo "ERROR: empty %files listing"
exit -1
}
grep -rsl '^#!.*perl'  etc doc scripts INSTALL README |
grep -v '.bak$' |xargs --no-run-if-empty \
%__perl -MExtUtils::MakeMaker -e 'MY->fixin(@ARGV)'

%clean
[ "%{buildroot}" != "/" ] && rm -rf %{buildroot}

%files -f %filelist

%changelog
* Wed Oct 28 2004 bryce@osdl.org
- Reused for WebService-TicketAuth
* Fri Oct 01 2004 bryce@osdl.org
- Rewrote from rackview specfile for WebService-TestSystem
* Wed Jul 30 2003 kees@osdl.org
- Rebuilt to fix up some location issues.
* Mon May 30 2003 brycehar@bryceharrington.com
- Initial build.
