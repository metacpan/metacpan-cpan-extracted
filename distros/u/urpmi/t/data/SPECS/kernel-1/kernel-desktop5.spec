%global ver 5.15.45
Summary: x
Name: kernel-desktop-%{ver}-1
Version: 1
Release: 1
License: x

%package -n kernel-desktop-latest
Summary: x
Version: %ver
Requires: kernel-desktop-%{ver}-1

%description
Kernel naming as used in mdv & mga[1-8].
Each kernel has an unique name ("kernel-v-r")
Thus fullname is "kernel-v-r-1-1".

%description -n kernel-desktop-latest
x

%files
%files -n kernel-desktop-latest
