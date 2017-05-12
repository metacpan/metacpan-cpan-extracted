use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'Test::WWW::Mechanize::JSON',
    VERSION_FROM      => 'lib/Test/WWW/Mechanize/JSON.pm', # finds $VERSION
    PREREQ_PM         => {
		JSON::Any				 => 0,
		Test::WWW::Mechanize => 0,
	},
    ($] >= 5.005 ? (

		ABSTRACT_FROM  => 'lib/Test/WWW/Mechanize/JSON.pm', # retrieve abstract from module
		AUTHOR         => 'Lee Goddard <lgoddard@cpan.org>'

	) : ()),
);

sub MY::postamble {
    return <<'PART0';
fix:
	$(PERLRUN) inc/fix.pl $(DISTVNAME).tar.gz

PART0
}

__END__
