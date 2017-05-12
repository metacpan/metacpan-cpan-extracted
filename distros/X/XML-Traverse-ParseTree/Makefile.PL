#use 5.008006;
use ExtUtils::MakeMaker;

{
package MY;

sub metafile {
    my $self = shift;
    my $inject = <<"META_EXTRA";
abstract: $self->{ABSTRACT}
author: 
  - $self->{AUTHOR}
no_index:
  dir:
    - t
  file:
    - perltidy_glob.BAT
    - perltidy.conf
meta-spec:
  version: 1.2
  url: http://module-build.sourceforge.net/META-spec-v1.2.html
resources:
  homepage: http://martin.busik.de 
META_EXTRA

    $inject = join "\n\t",  map { '$(NOECHO) $(ECHO) "'.$_.'" >>META_new.yml' }
                            split /(?:\012\015?|\015\012?)/, $inject;

    my $t = $self->SUPER::metafile_target(@_);
    my $mvCmd = q|-$(NOECHO) $(MV)|;
    my $pat = quotemeta($mvCmd);
    $t =~ s/$pat/$inject\n\t$mvCmd/s;
    return $t;
}

sub postamble {

    my $result = <<'_Q_';
all :: ReleaseNotes

# Make search.cpan.org happy but still follow GNU standards:
# (Thanks to Graham Barr for the hint)
ReleaseNotes: Changes
	$(ABSPERLRUN) -MExtUtils::Command -e cat Changes >$@

_Q_

    my @paths = qw(
		/lib/XML/Traverse/ParseTree*.pm
    );
    my $paths = join("\\\n\t\t",@paths);

my  $TIDY = "perltidy";
    $TIDY = "perltidy_glob" if $^O =~ /MSWin32/;

    $result .= <<"_QQ_";
# development feature: format code using Perl::Tidy
# depending on the plattform, perfom explicit glob()
my_tidy :
	$TIDY -b -pro=perltidy.conf \$(TO_INST_PM) $paths

_QQ_
}

1;
};

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'XML::Traverse::ParseTree',
    VERSION_FROM      => 'lib/XML/Traverse/ParseTree.pm', # finds $VERSION
    PREREQ_PM         => {
				Test::More => 0.47,
                XML::Parser => 2.34,
			}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT       => "access to xml contents by means of iterators and getters",
       AUTHOR         => 'Martin Busik <martin.busik@busik.de>') : ()),
);
