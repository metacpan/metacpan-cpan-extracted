use XML::RSSLite;
print "1..2\n";

print "ok 1 #Require\n";

print 'not ' unless defined($XML::RSSLite::VERSION);
print "ok 2 #VERSION\n";
