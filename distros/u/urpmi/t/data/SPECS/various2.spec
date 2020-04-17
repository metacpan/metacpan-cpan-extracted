Summary: various2
Name: various2
Version: 1
Release: 1
License: x

%prep
echo foo > foo

%build

%install
rm -rf $RPM_BUILD_ROOT
for i in /etc/test-%{name} \
         /var/lib/test-%{name}/foo1 /var/lib/test-%{name}/foo2 /var/lib/test-%{name}/foo3 \
	 /usr/share/locale/fr/LC_MESSAGES/test-%{name}.mo \
         /usr/test-%{name}/foo; do
	 mkdir -p `dirname $RPM_BUILD_ROOT$i`
	 echo foo > $RPM_BUILD_ROOT$i
done

%find_lang test-%{name}

%clean
rm -rf $RPM_BUILD_ROOT

%description
x

%files -f test-%{name}.lang
%defattr(-,root,root)
%doc foo
%config(noreplace) /etc/*
/var/lib/*
/usr/test-%{name}
