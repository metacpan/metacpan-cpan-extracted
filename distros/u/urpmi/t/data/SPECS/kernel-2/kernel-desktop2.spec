Summary: x
Name: kernel-desktop
Version: 5.15.42
Release: 1
License: x

%package -n kernel-desktop-latest
Summary: x
Requires: kernel-desktop = %{version}-%{release}

%description
Kernel naming as used in mga9+.
Each kernel is named "kernel".
So we can have multiple packages named "kernel" installed at the same time, with different versions

%description -n kernel-desktop-latest
x

%files
%files -n kernel-desktop-latest
