use ExtUtils::MakeMaker;

WriteMakefile(
  NAME => 'jsonpretty',
  AUTHOR => 'Matt S Trout <mst@shadowcat.co.uk>',
  VERSION_FROM => 'lib/App/JSONPretty.pm',
  ABSTRACT_FROM => 'lib/App/JSONPretty.pm',
  LICENSE => 'perl',
  EXE_FILES => [ 'script/jsonpretty' ],
);

sub MY::postamble { <<'END';

create_distdir : pack

pack:
	mkdir -p script
	mkdir -p fp/lib
	cd fp; fatpack packlists-for strictures.pm JSON.pm JSON/PP.pm Try/Tiny.pm >packlists
	cd fp; fatpack tree `cat packlists`
	cd fp; (echo '#!/usr/bin/env perl'; echo; fatpack file; cat ../lib/App/JSONPretty.pm) >../script/jsonpretty
	chmod 755 script/jsonpretty
END

}
