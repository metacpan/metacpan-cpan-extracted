use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Tie::Plural',
    'VERSION_FROM'	=> 'Plural.pm', # finds $VERSION
    'PREREQ_PM'		=> {},
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'Plural.pm', # retrieve abstract from module
       AUTHOR     => 'Eric Roode <roode@cpan.org>') : ()),
);


package MY;

sub dist_core
{
    my $text = shift->SUPER::dist_core(@_);
    $text =~ s/^(\$\(DISTVNAME\)[^:]*): (.*)/$1: ppd ppm $2/mg;
    return $text;
}

sub realclean
{
    my $text = shift->SUPER::realclean(@_);
    $text .= <<'CLEAN';
	rm -rf $(PPDFILE) $(PPMFILE)
CLEAN
    return $text;
}

sub ppd
{
    my $self = shift;
    my $text = $self->SUPER::ppd(@_);
    $text =~ s/(ppd\s*:)/$1 \$(PPDFILE)\n\n\$(PPDFILE) :/;
    $text =~ s[(?<=<CODEBASE HREF=\\")]
              [http://search.cpan.org/src/ROODE/$self->{DISTNAME}-$self->{VERSION}/$self->{DISTNAME}-ppm.tar.gz];

    # This release is allegedly OS and architecture independent (as it's pure perl)
    $text =~ s/<OS NAME[^>]+>(?:\\[nt])*//;
    $text =~ s/<ARCHITECTURE NAME[^>]+>(?:\\[nt])*//;

    $text = <<'PRE' . $text;

PPMNAME = $(DISTNAME)-ppm
PPDFILE = $(DISTNAME).ppd
PPMFILE = $(PPMNAME).tar.gz

PRE

    $text .= <<'PPM';


ppm: $(PPMFILE)

$(PPMFILE): pm_to_blib $(INST_LIBDIR)/.exists $(INST_ARCHAUTODIR)/.exists $(INST_AUTODIR)/.exists
	$(TAR) $(TARFLAGS) - blib | $(COMPRESS) -c > $(PPMFILE)
PPM
    return $text;
}
