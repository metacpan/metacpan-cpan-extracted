Summary: x
Name: pretrans
Version: 1
Release: 1
License: x
Group: x
Url: x
BuildRoot: %{_tmppath}/%{name}

%description
x

%pretrans -p <lua>
print("%{name}-%{version}")
exit(1)

%files
