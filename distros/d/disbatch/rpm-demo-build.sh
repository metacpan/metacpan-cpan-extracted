dzil mkrpmspec
dzil build
cp `grep ^Source: dzil.spec | awk '{print $2}'` ~/rpmbuild/SOURCES/
mv dzil.spec ~/rpmbuild/SPECS/disbatch.spec
rpmbuild -ba ~/rpmbuild/SPECS/disbatch.spec
