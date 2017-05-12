Name: perl-<% $zilla->name %>
Version: <% (my $v = $zilla->version) =~ s/^v//; $v %>
Release: 1%{?dist}

Summary: <% $zilla->abstract %>
License: Artistic
Group: Development/Libraries
BuildArch: noarch
URL: <% $zilla->license->url %>
Vendor: <% $zilla->license->holder %>
Source: <% $archive %>
BuildRoot: %{_tmppath}/%{name}-%{version}-BUILD
BuildRequires: perl >= 0:5.010
BuildRequires: perl(Module::Build)
BuildRequires: perl(Test::Roo)
BuildRequires: perl(Log::Any)
BuildRequires: perl(URI)
BuildRequires: perl(autodie)
BuildRequires: perl(JSON)
BuildRequires: perl(LWP::UserAgent)
BuildRequires: perl(Hash::Merge)
BuildRequires: perl(List::Util)
BuildRequires: perl(Test::Fatal)
BuildRequires: perl(Test::Deep)
BuildRequires: perl(DateTime)
Requires:      perl(:MODULE_COMPAT_%(eval "`%{__perl} -V:version`"; echo $version))
Requires:      perl(Moo)
Requires:      perl(Log::Any)
Requires:      perl(URI)
Requires:      perl(autodie)
Requires:      perl(JSON)
Requires:      perl(LWP::UserAgent)
Requires:      perl(Hash::Merge)
Requires:      perl(List::Util)
Requires:      perl(List::MoreUtils)

%description
<% $zilla->abstract %>

%prep
%setup -q -n <% $zilla->name %>-%{version}

%build
%{__perl} Build.PL installdirs=vendor
./Build

%check
./Build test

%install
rm -rf $RPM_BUILD_ROOT

./Build install destdir=$RPM_BUILD_ROOT create_packlist=0
find $RPM_BUILD_ROOT -depth -type d -exec rmdir {} 2>/dev/null \;

%{_fixperms} $RPM_BUILD_ROOT/*

%clean
rm -rf $RPM_BUILD_ROOT

%files
%defattr(-,root,root,-)
%{perl_vendorlib}/*
