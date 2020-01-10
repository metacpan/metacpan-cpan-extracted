%define content orig

Summary: x
Name: a
Version: 1
Release: 1
License: x
BuildArch: noarch

%description
tee

%install
rm -rf $RPM_BUILD_ROOT
mkdir -p $RPM_BUILD_ROOT/etc
echo %{content} > $RPM_BUILD_ROOT/etc/config-noreplace
echo %{content} > $RPM_BUILD_ROOT/etc/config
echo %{content} > $RPM_BUILD_ROOT/etc/normal

%clean
rm -rf $RPM_BUILD_ROOT

%files
%verify(not md5 size mtime) %config(noreplace) /etc/config-noreplace
%config /etc/config
/etc/normal
