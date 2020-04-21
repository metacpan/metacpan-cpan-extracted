# fix warnings:
%define debug_package %{nil}

Summary: x
Name: a
Version: 1
Release: 1
License: x
Provides: /bin/a
BuildRequires: gcc
%global __requires_exclude %{?__requires_exclude:%__requires_exclude|}^libc.so

%prep
%setup -c -T
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
gcc -Wall -o a a.c

%install
rm -rf $RPM_BUILD_ROOT
mkdir -p $RPM_BUILD_ROOT/bin/
cp a $RPM_BUILD_ROOT/bin/a

%clean
rm -rf $RPM_BUILD_ROOT

%description
x

%files
%defattr(-,root,root)
/bin/*
