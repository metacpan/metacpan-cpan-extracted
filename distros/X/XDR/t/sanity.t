# -*-Perl-*-

# Just try loading the module.
eval 'use XDR qw(:all);';
my $not = $@ ? 'not' : '';
print "1..1\n${not}ok\n";
exit 0;
