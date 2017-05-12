use strict;
use ExtUtils::MakeMaker 6.17;

my $EUMM = eval( $ExtUtils::MakeMaker::VERSION );

my $meta = {
  "abstract"       => "set the line number for an XML::LibXML::Node",
  "author"         => ["Toby Inkster (TOBYINK) <tobyink\@cpan.org>"],
  "dynamic_config" => 1,
  "generated_by"   => "Dist::Inkt::Profile::TOBYINK version 0.021, CPAN::Meta::Converter version 2.140640",
  "keywords"       => [],
  "license"        => ["perl_5"],
  "meta-spec"      => {
                        url => "http://search.cpan.org/perldoc?CPAN::Meta::Spec",
                        version => 2,
                      },
  "name"           => "XML-LibXML-Devel-SetLineNumber",
  "no_index"       => { directory => ["eg", "examples", "inc", "t", "xt"] },
  "prereqs"        => {
                        configure => {
                          requires => { "ExtUtils::MakeMaker" => 6.17 },
                          suggests => { "ExtUtils::Constant" => 0 },
                        },
                        runtime => {
                          requires => { "perl" => 5.008003, "XML::LibXML" => "1.90", "XML::LibXML::Devel" => 0 },
                        },
                        test => { requires => { "Test::More" => 0.47 } },
                      },
  "provides"       => {
                        "XML::LibXML::Devel::SetLineNumber" => { file => "lib/XML/LibXML/Devel/SetLineNumber.pm", version => 0.002 },
                      },
  "release_status" => "stable",
  "resources"      => {
                        bugtracker   => {
                                          web => "http://rt.cpan.org/Dist/Display.html?Queue=XML-LibXML-Devel-SetLineNumber",
                                        },
                        homepage     => "https://metacpan.org/release/XML-LibXML-Devel-SetLineNumber",
                        license      => ["http://dev.perl.org/licenses/"],
                        repository   => {
                                          type => "git",
                                          url  => "git://github.com/tobyink/p5-xml-libxml-devel-setlinenumber.git",
                                          web  => "https://github.com/tobyink/p5-xml-libxml-devel-setlinenumber",
                                        },
                        x_identifier => "http://purl.org/NET/cpan-uri/dist/XML-LibXML-Devel-SetLineNumber/project",
                      },
  "version"        => 0.002,
};

my %dynamic_config;
do {

sub get_libs ()
{
	return $ENV{PERL_LIBXML_SETLINE_LIBS}
		if $ENV{PERL_LIBXML_SETLINE_LIBS};
	
	my $libs;
	chomp( $libs ||= qx{xml2-config --libs} );
	chomp( $libs ||= qx{pkg-config --libs libxml-2.0} );
	
	# TODO - Alien::LibXML
	
	die "Could not determine location of libxml2 libs.\n"
	  . "Please supply PERL_LIBXML_SETLINE_LIBS environment variable."
		unless $libs =~ /^-/;
	
	return $libs;
}

sub get_inc ()
{
	return $ENV{PERL_LIBXML_SETLINE_INC}
		if $ENV{PERL_LIBXML_SETLINE_INC};
	
	my $incs;
	chomp( $incs ||= qx{xml2-config --cflags} );
	chomp( $incs ||= qx{pkg-config --cflags libxml-2.0} );
	
	# TODO - Alien::LibXML
	
	die "Could not determine location of libxml2 headers.\n"
	  . "Please supply PERL_LIBXML_SETLINE_INC environment variable."
		unless $incs =~ /^-/;
	
	return $incs;
}

$dynamic_config{LIBS}   = get_libs;
$dynamic_config{DEFINE} = '';
$dynamic_config{INC}    = get_inc . ' -I.';
$dynamic_config{OBJECT} = '$(O_FILES)';

};

my %WriteMakefileArgs = (
	ABSTRACT   => $meta->{abstract},
	AUTHOR     => ($EUMM >= 6.5702 ? $meta->{author} : $meta->{author}[0]),
	DISTNAME   => $meta->{name},
	VERSION    => $meta->{version},
	EXE_FILES  => [ map $_->{file}, values %{ $meta->{x_provides_scripts} || {} } ],
	NAME       => do { my $n = $meta->{name}; $n =~ s/-/::/g; $n },
	test       => { TESTS => "t/*.t" },
	%dynamic_config,
);

$WriteMakefileArgs{LICENSE} = $meta->{license}[0] if $EUMM >= 6.3001;

sub deps
{
	my %r;
	for my $stage (@_)
	{
		for my $dep (keys %{$meta->{prereqs}{$stage}{requires}})
		{
			next if $dep eq 'perl';
			my $ver = $meta->{prereqs}{$stage}{requires}{$dep};
			$r{$dep} = $ver if !exists($r{$dep}) || $ver >= $r{$dep};
		}
	}
	\%r;
}

my ($build_requires, $configure_requires, $runtime_requires, $test_requires);
if ($EUMM >= 6.6303)
{
	$WriteMakefileArgs{BUILD_REQUIRES}     ||= deps('build');
	$WriteMakefileArgs{CONFIGURE_REQUIRES} ||= deps('configure');
	$WriteMakefileArgs{TEST_REQUIRES}      ||= deps('test');
	$WriteMakefileArgs{PREREQ_PM}          ||= deps('runtime');
}
elsif ($EUMM >= 6.5503)
{
	$WriteMakefileArgs{BUILD_REQUIRES}     ||= deps('build', 'test');
	$WriteMakefileArgs{CONFIGURE_REQUIRES} ||= deps('configure');
	$WriteMakefileArgs{PREREQ_PM}          ||= deps('runtime');	
}
elsif ($EUMM >= 6.52)
{
	$WriteMakefileArgs{CONFIGURE_REQUIRES} ||= deps('configure');
	$WriteMakefileArgs{PREREQ_PM}          ||= deps('runtime', 'build', 'test');	
}
else
{
	$WriteMakefileArgs{PREREQ_PM}          ||= deps('configure', 'build', 'test', 'runtime');	
}

{
	my ($minperl) = reverse sort(
		grep defined && /^[0-9]+(\.[0-9]+)?$/,
		map $meta->{prereqs}{$_}{requires}{perl},
		qw( configure build runtime )
	);
	
	if (defined($minperl))
	{
		die "Installing $meta->{name} requires Perl >= $minperl"
			unless $] >= $minperl;
		
		$WriteMakefileArgs{MIN_PERL_VERSION} ||= $minperl
			if $EUMM >= 6.48;
	}
}

sub FixMakefile
{
	return unless -d 'inc';
	my $file = shift;
	
	local *MAKEFILE;
	open MAKEFILE, "< $file" or die "FixMakefile: Couldn't open $file: $!; bailing out";
	my $makefile = do { local $/; <MAKEFILE> };
	close MAKEFILE or die $!;
	
	$makefile =~ s/\b(test_harness\(\$\(TEST_VERBOSE\), )/$1'inc', /;
	$makefile =~ s/( -I\$\(INST_ARCHLIB\))/ -Iinc$1/g;
	$makefile =~ s/( "-I\$\(INST_LIB\)")/ "-Iinc"$1/g;
	$makefile =~ s/^(FULLPERL = .*)/$1 "-Iinc"/m;
	$makefile =~ s/^(PERL = .*)/$1 "-Iinc"/m;
	
	open  MAKEFILE, "> $file" or die "FixMakefile: Couldn't open $file: $!; bailing out";
	print MAKEFILE $makefile or die $!;
	close MAKEFILE or die $!;
}

my $mm = WriteMakefile(%WriteMakefileArgs);
FixMakefile($mm->{FIRST_MAKEFILE} || 'Makefile');
exit(0);

