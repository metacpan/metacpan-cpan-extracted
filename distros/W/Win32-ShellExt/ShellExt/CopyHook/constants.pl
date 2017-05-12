# -*- cperl -*-
# taken from constants.h in Compress::Zlib
#
#!/home/paul/perl/install/redhat6.1/bleed/bin/perl5.7.2 -w
use ExtUtils::Constant qw (constant_types C_constant XS_constant);

my $types = {map {($_, 1)} qw(IV PV)};
my @names = qw(FO_COPY
                FO_DELETE
                FO_MOVE
                FO_RENAME

                FOF_ALLOWUNDO
                FOF_CONFIRMMOUSE
                FOF_FILESONLY
                FOF_MULTIDESTFILES
                FOF_NOCONFIRMATION
                FOF_NOCONFIRMMKDIR
                FOF_NO_CONNECTED_ELEMENTS
                FOF_NOCOPYSECURITYATTRIBS
                FOF_NOERRORUI
                FOF_NORECURSION
                FOF_RECURSEREPARSE
                FOF_NORECURSEREPARSE
                FOF_RENAMEONCOLLISION
                FOF_SILENT
                FOF_SIMPLEPROGRESS
                FOF_WANTMAPPINGHANDLE
                FOF_WANTNUKEWARNING

                IDYES
                IDNO
                IDCANCEL);

print constant_types(); # macro defs
foreach (C_constant ("CopyHook", 'constant', 'IV', $types, undef, 3, @names) ) {
    print $_, "\n"; # C constant subs
}
print "#### XS Section:\n";
print XS_constant ("CopyHook", $types);


