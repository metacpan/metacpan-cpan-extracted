use strict;
use ExtUtils::MakeMaker 6.17;

my $EUMM = eval( $ExtUtils::MakeMaker::VERSION );

my $meta = {
  "abstract"       => "extend XML::LibXML::{Attr,Element,Document} on a per-namespace/element basis",
  "author"         => ["Toby Inkster <tobyink\@cpan.org>"],
  "dynamic_config" => 0,
  "generated_by"   => "Dist::Inkt::Profile::TOBYINK version 0.021, CPAN::Meta::Converter version 2.140640",
  "keywords"       => [],
  "license"        => ["perl_5"],
  "meta-spec"      => {
                        url => "http://search.cpan.org/perldoc?CPAN::Meta::Spec",
                        version => 2,
                      },
  "name"           => "XML-LibXML-Augment",
  "no_index"       => { directory => ["eg", "examples", "inc", "t", "xt"] },
  "prereqs"        => {
                        configure => { requires => { "ExtUtils::MakeMaker" => 6.17 } },
                        runtime => {
                          requires => {
                            "Class::Inspector" => 0,
                            "match::simple" => 0,
                            "Module::Runtime" => 0,
                            "perl" => 5.008,
                            "XML::LibXML" => 1.95,
                          },
                        },
                        test => { requires => { "Test::More" => 0.61 } },
                      },
  "provides"       => {
                        "XML::LibXML::Augment"                   => { file => "lib/XML/LibXML/Augment.pm", version => 0.004 },
                        "XML::LibXML::Augment::Attr"             => { file => "lib/XML/LibXML/Augment.pm" },
                        "XML::LibXML::Augment::CDATASection"     => { file => "lib/XML/LibXML/Augment.pm" },
                        "XML::LibXML::Augment::Comment"          => { file => "lib/XML/LibXML/Augment.pm" },
                        "XML::LibXML::Augment::Document"         => { file => "lib/XML/LibXML/Augment.pm" },
                        "XML::LibXML::Augment::DocumentFragment" => { file => "lib/XML/LibXML/Augment.pm" },
                        "XML::LibXML::Augment::Dtd"              => { file => "lib/XML/LibXML/Augment.pm" },
                        "XML::LibXML::Augment::Element"          => { file => "lib/XML/LibXML/Augment.pm" },
                        "XML::LibXML::Augment::Node"             => { file => "lib/XML/LibXML/Augment.pm" },
                        "XML::LibXML::Augment::NodeList"         => { file => "lib/XML/LibXML/Augment.pm" },
                        "XML::LibXML::Augment::PI"               => { file => "lib/XML/LibXML/Augment.pm" },
                        "XML::LibXML::Augment::Text"             => { file => "lib/XML/LibXML/Augment.pm" },
                      },
  "release_status" => "stable",
  "resources"      => {
                        bugtracker   => {
                                          web => "http://rt.cpan.org/Dist/Display.html?Queue=XML-LibXML-Augment",
                                        },
                        homepage     => "https://metacpan.org/release/XML-LibXML-Augment",
                        license      => ["http://dev.perl.org/licenses/"],
                        repository   => {
                                          type => "git",
                                          url  => "git://github.com/tobyink/p5-xml-libxml-augment.git",
                                          web  => "https://github.com/tobyink/p5-xml-libxml-augment",
                                        },
                        x_identifier => "http://purl.org/NET/cpan-uri/dist/XML-LibXML-Augment/project",
                      },
  "version"        => 0.004,
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

