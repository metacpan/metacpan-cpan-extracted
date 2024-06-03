# This one is not directly used by the testsuite.
# It has been used to generate once t/data/rpm-i586-to-i686/*
# using:
#   linux32 rpmbuild -ba libfoobar.spec --target i586
#   linux32 rpmbuild -ba libfoobar.spec --target i686
# Which are the pkgs actually used by the testsuite for simulating an i586 to
# i686 upgrade

# Fix build with rpm-4.20:
%global debug_package %{nil}


# we could build with -static but then pkg goes up from 8.5kb to 280Kb:
%global __requires_exclude %{?__requires_exclude:%__requires_exclude|}libc.so
Summary: x
Name: libfoobar
Version: 1
Release: 1
License: x

%build
cat > t.c <<EOF
void main () {}
EOF
#linux32 gcc -m32 -march=i586 -o t t.c
cc -o t t.c

%install
mkdir -p %buildroot/%_bindir
cp -a t %buildroot/%_bindir

%description
binary lib

%files
%_bindir/t
