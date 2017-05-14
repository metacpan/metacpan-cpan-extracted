%define perl_vendorlib %(eval "`perl -V:installvendorlib`"; echo $installvendorlib)
%define perl_vendorarch %(eval "`perl -V:installvendorarch`"; echo $installvendorarch)

Summary:     BeanCounter portfolio performance toolkit
Name:        beancounter
Version:     0.8.6
Release:     1
License:     GNU GPL
Group:       Applications/Finance
BuildRoot:   /var/tmp/build-rpm
URL:	     http://dirk.eddelbuettel.com/code/beancounter.html

Source:      http://dirk.eddelbuettel.com/code/beancounter/beancounter-%{version}.tar.gz

Requires:    perl-Statistics-Descriptive

%description
Ever wondered what happened to your portfolio on a day the market
moved 500 points? Ever wondered what your portfolio returned over the
last (odd and arbitrary) period? Ever wondered what the Value-at-Risk
(VaR) was? Ever wondererd what the marginal risk contribution of a
given stock in your portfolio was? Ever wondered if you could easily
database the (public) prices info for further analysis? Ever wondered
if there was a simple cron job to report all this on a daily basis?

BeanCounter does all this, and provides an easy-to-use command-line
tool as well as a Perl module that can be used with other pursuits.
It stores its data (price, volume, earnings --- whatever Yahoo!
supplies) in a PostgreSQL relational database system.  BeanCounter
works with equities from exchanges in the US, Canada, Europe and Asia.
Options, foreign exchange rates, some commodities as well as US mutual
funds are also supported as the data is provided by Yahoo!

%changelog

%prep

%setup -q

rm -rf $RPM_BUILD_ROOT
mkdir -p $RPM_BUILD_ROOT

%build
# perl Makefile.PL
CFLAGS="%{optflags}" %{__perl} Makefile.PL \
	PREFIX="%{buildroot}%{_prefix}" \
	INSTALLDIRS="vendor"
# make
%{__make} %{?_smp_mflags}

%install

make PREFIX=$RPM_BUILD_ROOT/usr SITEPREFIX=$RPM_BUILD_ROOT/usr install

%clean
rm -rf $RPM_BUILD_ROOT

%files
%defattr(-,root,root)
%doc README THANKS TODO example.beancounterrc beancounter.html 
%doc *txt contrib/*
/usr/bin/*
%doc %{_mandir}/man*/*
%{perl_vendorlib}/*

%changelog
* Tue Dec 28 2004 R P Herrold <info@owlriver.com> 0.7.6-1orc
- rework a .spec file dateing from 0.4.0 to a proper one, which will build 
 as non-root, and properly cascade version information with a minimal edit

