use 5.008008;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'Text::Template::Library',
    VERSION_FROM      => 'lib/Text/Template/Library.pm',
    PREREQ_PM         => {
			  'Class::Member'=>1.6,
			 },
    ABSTRACT_FROM     => 'lib/Text/Template/Library.pm',
    AUTHOR            => 'Torsten Foertsch <torsten.foertsch@gmx.net>',
    dist              => {
			  PREOP => './mk_README.sh',
			 },
);

sub MY::postamble {
  return <<'EOF';
COMPRESS = gzip -9f

README: lib/Text/Template/Library.pm mk_README.sh
	./mk_README.sh

rpm: dist
	$(PERL) -i -pe 's/^(Version:\s*).*/$${1}$(VERSION)/' perl-Text-Template-Library.spec
	rpmbuild -ba perl-Text-Template-Library.spec
EOF
}
