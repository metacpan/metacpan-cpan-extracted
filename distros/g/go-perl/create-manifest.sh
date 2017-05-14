svn list -R | egrep -v "/$" | sort -u > MANIFEST
#cvs status | perl -ne 'print "$1\n" if m@Repository revision.*/cvsroot/geneontology/go\-dev/go\-perl/(.*),v@' > MANIFEST
find GO/xsl -name "*.xsl" >> MANIFEST
