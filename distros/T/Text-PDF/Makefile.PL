use ExtUtils::MakeMaker;
use Getopt::Std;

getopts('d:rv:');
$opt_v ||= 1;

@scripts = grep {-f } glob("scripts/*");

# incantation to enable MY::pm_to_blib later on
if ($^O eq 'MSWin32')
{
    @extras = (dist => { 'TO_UNIX' => 'perl -Mtounix -e "tounix(\"$(DISTVNAME)\")"' });
}

if ($^O eq 'linux')
{

*MY::postamble = sub
{
    my ($self) = @_;
    my ($res);
    my ($package) = lc($self->{'NAME'});
    my ($pversion) = $self->{'VERSION'};
    my ($sha) = `git rev-parse --short HEAD`;
    my ($sign) = '--auto-debsign' if ($opt_r);
    my ($fpackage);

    $sha =~ s/\s//g;
    $package =~ s/::/-/g;
    $package = "lib${package}-perl";
    $pversion .= "+$sha" unless ($opt_r);
    $fpackage = "$package-$pversion";

    $res = <<"EOT";
deb-base: dist
	rm -fr $self->{'DISTVNAME'}
	rm -fr $fpackage
	tar xvzf $self->{'DISTVNAME'}.tar.gz
	mv $self->{'DISTVNAME'} $fpackage
	tar cfz "${package}_$pversion.orig.tar.gz" $fpackage
	cp -a debian $fpackage
	cd $fpackage && find . -name .svn | xargs rm -rf

# make deb builds an interim deb from svn source for release
deb: deb-base
EOT

    foreach $d (split(' ', $opt_d))
    {
    	$res .= <<"EOT";
	mkdir -p dists/$d	
	dch -D $d -v $pversion-$opt_v -m -b -c $fpackage/debian/changelog "Auto build from perl for $d"
	cd $fpackage && pdebuild --buildresult ../dists/$d -- --basetgz /var/cache/pbuilder/base-$d.tgz $pbuilderopts{$d}
EOT
    }

    return $res;
}

}

WriteMakefile (
        NAME => "Text::PDF",
        VERSION_FROM => "lib/Text/PDF.pm",
#        VERSION => "0.30",
        EXE_FILES => \@scripts,
        AUTHOR => "martin_hosken\@sil.org",
        ABSTRACT => "PDF Manipulation and generation",
        PREREQ_PM => {'Compress::Zlib' => 0},
        META_MERGE => {
          'meta-spec' => { version => 2 },
          resources => {
            repository => {
              type => 'git',
              url => 'https://github.com/silnrsi/text-pdf.git',
              web => 'https://github.com/silnrsi/text-pdf',
            }
          }
        },
        @extras
    );

