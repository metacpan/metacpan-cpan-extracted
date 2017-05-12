use 5.006;
use strict;
use ExtUtils::MakeMaker;

WriteMakefile(
	NAME => 'rpm-build-perl',
	VERSION_FROM => 'lib/B/PerlReq.pm',
	EXE_FILES => [ qw(perl.req perl.req.files perl.prov perl.prov.files perl.clean) ],
	PREREQ_PM => { B => 0, O => 0, Safe => 0, "Test::More" => 0, Encode => 0 },
	AUTHOR => 'Alexey Tourbin <at@altlinux.org>',
	ABSTRACT => 'Calculate dependencies for Perl sources',
	dist => { COMPRESS => 'gzip -9f' },
);

package MY;
sub install {
	my $self = shift;
	return $self->SUPER::install(@_) . <<'EOF';

Changes: rpm-build-perl.spec
	rpmquery --specfile $< --changelog | $(PERL) -ne \
	's/\@altlinux[^>]*>/\@altlinux>/g; last if /^\* .+ 0\.3/; next if /^\Z/; print "\n" if /^\* / && $$.>1; print' >$@
EOF

}
