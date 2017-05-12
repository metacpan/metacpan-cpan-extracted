Summary: x
Name: preun
Version: 1
Release: 1
License: x
Group: x
Url: x
BuildRoot: %{_tmppath}/%{name}

%description
x

%preun -p <lua>
print("%{name}-%{version}")
exit(1)

%files
