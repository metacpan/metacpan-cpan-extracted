# fix warnings:
%define debug_package %{nil}

Summary: x
Name: a
Version: 1
Release: 1
License: x
Provides: /bin/a
#BuildRequires: gcc
%global __requires_exclude %{?__requires_exclude:%__requires_exclude|}^libc.so|^ld
%global __provides_exclude %{?__provides_exclude:%__provides_exclude|}^libc.so|^ld

%prep
%setup -c -T
# This is a simple static "shell" for scriptlets.
# Thus it must be w/o deps (static) or with self contained deps (included):
cat <<EOF > a.c 
#include <stdio.h>
int main(int argc, char **argv) { 
   FILE *f = fopen(argv[1], "r");
   int c; 
   while ((c = getc(f)) > 0) putchar(c); 
   putchar('\n');
   return 0;
}
EOF

%build
# Try a static build with fallback to dynamic if no static libs/headers
# (in which case we will pull the the wanted libs in %%install):
cc -Wall -static -o a a.c || cc -Wall -o a a.c

%install
rm -rf $RPM_BUILD_ROOT
mkdir -p $RPM_BUILD_ROOT/bin/
cp a $RPM_BUILD_ROOT/bin/a

# Install the wanted libs if not static:
ldd a | sed -e 's/^[ \t]*//' -e 's/.* => //' -e 's/ .*//' > list
grep '/' list | (cd / ; cpio -pumdL %buildroot)
find %buildroot

%clean
rm -rf $RPM_BUILD_ROOT

%description
x

%files
%defattr(-,root,root)
/*
