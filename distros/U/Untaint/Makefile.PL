# -*- perl -*-
# $Id: Makefile.PL,v 0.02 1998/28/9 09:45:13 kmeltz Exp $
use ExtUtils::MakeMaker;

sub check_required { 
	my ($pkg, $ver) = @_;
	print "Checking for $pkg...";
	eval { my $p; ($p = $pkg . ".pm") =~ s#::#/#g; require $p; };
        my $vstr = ${"${pkg}::VERSION"} ? "found v" . ${"${pkg}::VERSION"}
                                 : "not found";
        my $vnum = ${"${pkg}::VERSION"} || 0;
 
        print $vnum >= $ver ? "ok\n" : " " . $vstr . "\n";
 
        $vnum >= $ver;
}

check_required("Taint", 0.09) or die "Please install Taint.pm (>= v0.09), which is required to\nuse this module";

#%required = ('Taint.pm' => '0.90');

WriteMakefile(
   NAME          => 'Untaint',
   VERSION_FROM  => 'Untaint.pm',
   'dist'        => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
   'clean'       => { FILES => q[*% *.bak *.old *.test]},
#   PREREQ_PM     => \%required
);

