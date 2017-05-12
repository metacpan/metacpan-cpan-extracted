use strict;
use 5.005;
use ExtUtils::MakeMaker;
use File::Spec;
use File::Spec::Functions qw(catfile);
use File::Find;

assert_prereqs();

WriteMakefile(
    NAME => 'VCS::SaVeS',
    VERSION_FROM => 'SaVeS.pm',
    PREREQ_PM => {YAML => '0.35'},
    PL_FILES => { 
                  catfile(qw(bin svs.PL)) => catfile(qw(bin svs)),
                  catfile(qw(bin saves.PL)) => catfile(qw(bin saves)),
                },
    EXE_FILES => [ catfile(qw(bin svs)), catfile(qw(bin saves)) ],
    clean => { FILES => join ' ', catfile(qw(bin svs)), 
                                  catfile(qw(bin saves)) },
    ($] >= 5.005
         ? (ABSTRACT => 'Standalone Versioning System',
            AUTHOR => 'Brian Ingerson <ingy@cpan.org>',
           ) 
         : ()
    ),
);

sub assert_prereqs {
    my %prereqs = 
      map {($_, 0)} qw(rcs co ci rcsdiff rlog sh cat xargs);
    find sub {
               my $file = $_;
               for (keys %prereqs) {
                   $prereqs{$_}++ if $file eq $_;
               }
             }, File::Spec->path();
    my @notfound;
    if (@notfound = sort grep {not $prereqs{$_}} keys %prereqs) {
        exit(1) unless prompt(<<END, "N") =~ /^y/i;

WARNING. The following SaVeS prerequisite programs:

    @notfound

cannot be found in your path.

Do you wish to install VCS::SaVeS anyway?

END
    }
}
