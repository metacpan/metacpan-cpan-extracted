use strict;
use ExtUtils::MakeMaker 6.17;

my $EUMM = eval( $ExtUtils::MakeMaker::VERSION );

my $meta = {
  "abstract"         => "Namespace manipulation and prefix mapping for XML, RDF, etc.",
  "author"           => [
                          "Kjetil Kjernsmo <kjetilk\@cpan.org>",
                          "Gregory Todd Williams <gwilliams\@cpan.org>",
                          "Chris Prather (PERIGRIN) <chris\@prather.org>",
                        ],
  "dynamic_config"   => 0,
  "generated_by"     => "Dist::Inkt::Profile::KJETILK version 0.101, CPAN::Meta::Converter version 2.150010",
  "keywords"         => [],
  "license"          => ["perl_5"],
  "meta-spec"        => {
                          url => "http://search.cpan.org/perldoc?CPAN::Meta::Spec",
                          version => 2,
                        },
  "name"             => "URI-NamespaceMap",
  "no_index"         => { directory => ["eg", "examples", "inc", "t", "xt"] },
  "prereqs"          => {
                          configure => { requires => { "ExtUtils::MakeMaker" => 6.17 } },
                          runtime => {
                            recommends => {
                                            "RDF::NS"          => 20130802,
                                            "RDF::NS::Curated" => 0,
                                            "RDF::Prefixes"    => 0,
                                            "XML::CommonNS"    => 0,
                                          },
                            requires   => {
                                            "Carp" => 0,
                                            "IRI" => 0.004,
                                            "Module::Load::Conditional" => 0,
                                            "Moo" => "1.006000",
                                            "namespace::autoclean" => "0.20",
                                            "perl" => 5.008001,
                                            "Sub::Quote" => 0,
                                            "Try::Tiny" => 0,
                                            "Type::Library" => "1.000000",
                                            "Types::URI" => 0.004,
                                            "URI" => 1.52,
                                          },
                          },
                          test => {
                            recommends => { Attean => 0.025 },
                            requires   => {
                                            "Test::Deep"      => 0,
                                            "Test::Exception" => 0,
                                            "Test::More"      => 0.88,
                                            "Test::Requires"  => 0,
                                          },
                            suggests   => { "RDF::Trine" => 0 },
                          },
                        },
  "provides"         => {
                          "Types::Namespace" => { file => "lib/Types/Namespace.pm", version => "1.10" },
                          "URI::Namespace" => { file => "lib/URI/Namespace.pm", version => "1.10" },
                          "URI::NamespaceMap" => { file => "lib/URI/NamespaceMap.pm", version => 1.12 },
                          "URI::NamespaceMap::ReservedLocalParts" => {
                            file => "lib/URI/NamespaceMap/ReservedLocalParts.pm",
                            version => "1.10",
                          },
                        },
  "release_status"   => "stable",
  "resources"        => {
                          bugtracker   => { web => "https://github.com/kjetilk/URI-NamespaceMap/issues" },
                          homepage     => "https://metacpan.org/module/URI::NamespaceMap",
                          license      => ["http://dev.perl.org/licenses/"],
                          repository   => {
                                            type => "git",
                                            web  => "https://github.com/kjetilk/URI-NamespaceMap/",
                                          },
                          x_identifier => "http://purl.org/NET/cpan-uri/dist/URI-NamespaceMap/project",
                        },
  "version"          => 1.12,
  "x_contributors"   => [
                          "Dorian Taylor <dorian\@cpan.org>",
                          "Toby Inkster (TOBYINK) <tobyink\@cpan.org>",
                          "KWAKWA <kwakwa\@cpan.org>",
                        ],
  "x_static_install" => 1,
};

my %dynamic_config;

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


my $mm = WriteMakefile(%WriteMakefileArgs);

exit(0);

