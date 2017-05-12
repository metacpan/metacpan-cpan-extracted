# Note that this is NOT a relocatable package
%define rel      1

Summary:   Write BLADE applications in Perl
Name:      pBLADE
Version:   0.10
Release:   %rel
License:   GPL or Artistic License
Group:     Development/Libraries
Source:    pBLADE-0.10.tar.gz
URL:       http://www.thestuff.net/bob/projects/blade
BuildRoot: /tmp/pBLADE-%{PACKAGE_VERSION}-root
Packager:  Pete Ratzlaff <pratzlaff@cfa.harvard.edu>

%description
pBLADE is a Perl interface to the BLADE web development environment.

%changelog

%prep

%setup
perl Makefile.PL PREFIX=$RPM_BUILD_ROOT/opt/local

%build
make

%install
rm -rf $RPM_BUILD_ROOT
make install install_prefix=$RPM_BUILD_ROOT

%clean
rm -rf $RPM_BUILD_ROOT

%files
%defattr(-, root, root)

/*
