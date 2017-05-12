%define module  Unicode-LineBreak
%define version 2017.004
%define release 1%{?dist}
%define sombok_version 2.4.0
%define sombok_max_version 2.99.99

Name:       perl-%{module}
Version:    %{version}
Release:    %{release}
License:    GPL+ or Artistic
Group:      Development/Perl
Summary(ja): UAX #14 Unicode 行分割アルゴリズム
Summary:    UAX #14 Unicode Line Breaking Algorithm
Url:        http://search.cpan.org/dist/%{module}
Source:     http://search.cpan.org/CPAN/authors/id/N/NE/NEZUMI/%{module}-%{version}.tar.gz
Requires: perl(Encode)
Requires: perl(MIME::Charset) >= 1.006.2
Requires: sombok >= %{sombok_version}
Requires: sombok <= %{sombok_max_version}
BuildRequires: perl(ExtUtils::MakeMaker) >= 6.26
BuildRequires: perl(MIME::Charset) >= 1.006.2
BuildRequires: perl(Test::More)
#BuildRequires: perl(Test::Pod)
BuildRequires: sombok-devel >= %{sombok_version}
BuildRequires: sombok-devel <= %{sombok_max_version}
BuildRequires: pkgconfig
BuildRoot:  %{_tmppath}/%{name}-%{version}

AutoProv: yes
AutoReq: no

%description -l ja
Unicode::LineBreak は、Unicode 標準の附属書14 [UAX #14] で述べる
Unicode 行分割アルゴリズムを実行する。分割位置を決定する際に、附属
書11 [UAX #11] で定義される East_Asian_Width 参考特性も考慮する。
%description
Unicode::LineBreak performs Line Breaking Algorithm described in
Unicode Standard Annex #14 [UAX #14]. East_Asian_Width informative
properties defined by Annex #11 [UAX #11] will be concerned to
determine breaking positions.

%prep
%setup -q -n %{module}-%{version} 

%build
%{__perl} Makefile.PL INSTALLDIRS=vendor
make

%check
make test

%install
rm -rf %buildroot
make install DESTDIR=%buildroot
rm -f %{buildroot}%{perl_archlib}/perllocal.pod
rm -f %{buildroot}%{perl_vendorarch}/auto/Unicode/LineBreak/.packlist

mkdir -p %{buildroot}%{_mandir}/ja/man3
for mod in Text::LineFold Unicode::GCString Unicode::LineBreak; do
  mv %{buildroot}%{_mandir}/man3/POD2::JA::$mod.3pm \
     %{buildroot}%{_mandir}/ja/man3/$mod.3pm
done

%clean
rm -rf %buildroot

%files
%defattr(-,root,root)
%doc ARTISTIC Changes* GPL README* Todo*
%{_mandir}/man3/*
%{_mandir}/*/man3/*
%{perl_vendorarch}/*


%changelog

