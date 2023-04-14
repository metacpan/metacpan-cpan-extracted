use strict;
use ExtUtils::MakeMaker 6.17;

my $EUMM = eval( $ExtUtils::MakeMaker::VERSION );

my $meta = {
  "abstract"         => "generate fairly flashy websites for CPAN distributions",
  "author"           => ["Toby Inkster (TOBYINK) <tobyink\@cpan.org>"],
  "dynamic_config"   => 0,
  "generated_by"     => "Dist::Inkt::Profile::TOBYINK version 0.024, CPAN::Meta::Converter version 2.150010",
  "keywords"         => [],
  "license"          => ["perl_5"],
  "meta-spec"        => {
                          url => "http://search.cpan.org/perldoc?CPAN::Meta::Spec",
                          version => 2,
                        },
  "name"             => "Web-PerlDistSite",
  "no_index"         => { directory => ["eg", "examples", "inc", "t", "xt"] },
  "prereqs"          => {
                          configure => { requires => { "ExtUtils::MakeMaker" => 6.17 } },
                          develop   => { recommends => { "Dist::Inkt" => 0.001 } },
                          runtime   => {
                                         requires => {
                                           "Colouring::In"            => 0,
                                           "Data::Section"            => 0,
                                           "Exporter::Almighty"       => 0,
                                           "HTML::HTML5::Entities"    => 0,
                                           "HTML::HTML5::Parser"      => 0,
                                           "HTML::HTML5::Sanity"      => 0,
                                           "HTML::HTML5::Writer"      => 0,
                                           "Lingua::EN::Titlecase"    => 0,
                                           "Module::Runtime"          => 0,
                                           "Moo"                      => 0,
                                           "Moo::Role"                => 0,
                                           "Path::Tiny"               => 0,
                                           "perl"                     => "5.026000",
                                           "Pod::Find"                => 0,
                                           "Pod::POM"                 => 0,
                                           "Text::Markdown"           => 0,
                                           "TOBYINK::Pod::HTML"       => 0,
                                           "Type::Params"             => 0,
                                           "Types::Common"            => 0,
                                           "URI::Escape"              => 0,
                                           "XML::LibXML::PrettyPrint" => 0,
                                           "YAML::PP"                 => 0,
                                         },
                                       },
                          test      => {
                                         requires => {
                                           "Test2::Plugin::BailOnFail"     => 0,
                                           "Test2::Require::AuthorTesting" => 0,
                                           "Test2::Require::Module"        => 0,
                                           "Test2::Tools::Spec"            => 0,
                                           "Test2::V0"                     => 0,
                                         },
                                       },
                        },
  "provides"         => {
                          "Web::PerlDistSite"                         => { file => "lib/Web/PerlDistSite.pm", version => "0.001010" },
                          "Web::PerlDistSite::Common"                 => { file => "lib/Web/PerlDistSite/Common.pm", version => "0.001010" },
                          "Web::PerlDistSite::Compile"                => { file => "lib/Web/PerlDistSite/Compile.pm", version => "0.001010" },
                          "Web::PerlDistSite::Component"              => { file => "lib/Web/PerlDistSite/Component.pm", version => "0.001010" },
                          "Web::PerlDistSite::Component::LayoutScss"  => {
                                                                           file => "lib/Web/PerlDistSite/Component/LayoutScss.pm",
                                                                           version => "0.001010",
                                                                         },
                          "Web::PerlDistSite::Component::MainScss"    => {
                                                                           file => "lib/Web/PerlDistSite/Component/MainScss.pm",
                                                                           version => "0.001010",
                                                                         },
                          "Web::PerlDistSite::MenuItem"               => { file => "lib/Web/PerlDistSite/MenuItem.pm", version => "0.001010" },
                          "Web::PerlDistSite::MenuItem::Divider"      => {
                                                                           file => "lib/Web/PerlDistSite/MenuItem/Divider.pm",
                                                                           version => "0.001010",
                                                                         },
                          "Web::PerlDistSite::MenuItem::File"         => {
                                                                           file => "lib/Web/PerlDistSite/MenuItem/File.pm",
                                                                           version => "0.001010",
                                                                         },
                          "Web::PerlDistSite::MenuItem::Homepage"     => {
                                                                           file => "lib/Web/PerlDistSite/MenuItem/Homepage.pm",
                                                                           version => "0.001010",
                                                                         },
                          "Web::PerlDistSite::MenuItem::MarkdownFile" => {
                                                                           file => "lib/Web/PerlDistSite/MenuItem/MarkdownFile.pm",
                                                                           version => "0.001010",
                                                                         },
                          "Web::PerlDistSite::MenuItem::Pod"          => {
                                                                           file => "lib/Web/PerlDistSite/MenuItem/Pod.pm",
                                                                           version => "0.001010",
                                                                         },
                          "Web::PerlDistSite::MenuItem::PodFile"      => {
                                                                           file => "lib/Web/PerlDistSite/MenuItem/PodFile.pm",
                                                                           version => "0.001010",
                                                                         },
                        },
  "release_status"   => "stable",
  "resources"        => {
                          bugtracker   => { web => "https://github.com/tobyink/p5-web-perldistsite/issues" },
                          homepage     => "https://metacpan.org/release/Web-PerlDistSite",
                          license      => ["http://dev.perl.org/licenses/"],
                          repository   => {
                                            type => "git",
                                            url  => "git://github.com/tobyink/p5-web-perldistsite.git",
                                            web  => "https://github.com/tobyink/p5-web-perldistsite",
                                          },
                          x_identifier => "http://purl.org/NET/cpan-uri/dist/Web-PerlDistSite/project",
                        },
  "version"          => "0.001010",
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
	test       => { TESTS => "t/*.t t/unit/Web/*.t" },
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

