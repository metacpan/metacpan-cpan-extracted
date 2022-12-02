use strict;
use ExtUtils::MakeMaker 6.17;

my $EUMM = eval( $ExtUtils::MakeMaker::VERSION );

my $meta = {
  "abstract"       => "why throw exceptions when you can return them?",
  "author"         => ["Toby Inkster (TOBYINK) <tobyink\@cpan.org>"],
  "dynamic_config" => 1,
  "generated_by"   => "Dist::Inkt::Profile::TOBYINK version 0.024, CPAN::Meta::Converter version 2.150010",
  "keywords"       => [],
  "license"        => ["perl_5"],
  "meta-spec"      => {
                        url => "http://search.cpan.org/perldoc?CPAN::Meta::Spec",
                        version => 2,
                      },
  "name"           => "results",
  "no_index"       => { directory => ["eg", "examples", "inc", "t", "xt"] },
  "prereqs"        => {
                        configure => { requires => { "ExtUtils::MakeMaker" => 6.17 } },
                        develop   => { recommends => { "Dist::Inkt" => 0.001 } },
                        runtime   => {
                                       requires => {
                                         "Carp" => 0,
                                         "Devel::StrictMode" => 0,
                                         "Exporter::Shiny" => 0,
                                         "perl" => 5.014,
                                         "Role::Tiny" => 0,
                                         "Scalar::Util" => 0,
                                       },
                                     },
                        test      => {
                                       recommends => { "Type::Utils" => 0 },
                                       requires   => {
                                                       "Test2::Require::AuthorTesting" => 0,
                                                       "Test2::Require::Module" => 0,
                                                       "Test2::Tools::Spec" => 0,
                                                       "Test2::V0" => 0,
                                                       "Type::Nano" => 0,
                                                     },
                                     },
                      },
  "provides"       => {
                        "Result::Err"         => { file => "lib/Result/Err.pm", version => 0.006 },
                        "Result::Ok"          => { file => "lib/Result/Ok.pm", version => 0.006 },
                        "Result::OkList"      => { file => "lib/Result/OkList.pm", version => 0.006 },
                        "Result::Trait"       => { file => "lib/Result/Trait.pm", version => 0.006 },
                        "results"             => { file => "lib/results.pm", version => 0.006 },
                        "results::exceptions" => { file => "lib/results/exceptions.pm", version => 0.006 },
                        "results::wrap"       => { file => "lib/results/wrap.pm", version => 0.006 },
                      },
  "release_status" => "stable",
  "resources"      => {
                        bugtracker   => { web => "https://github.com/tobyink/p5-results/issues" },
                        homepage     => "https://metacpan.org/release/results",
                        license      => ["http://dev.perl.org/licenses/"],
                        repository   => {
                                          type => "git",
                                          url  => "git://github.com/tobyink/p5-results.git",
                                          web  => "https://github.com/tobyink/p5-results",
                                        },
                        x_identifier => "http://purl.org/NET/cpan-uri/dist/results/project",
                      },
  "version"        => 0.006,
};

my %dynamic_config;
do {

	if ( $] ge 5.011002 and $] lt 5.021007 ) {
		$meta->{prereqs}{runtime}{recommends}{'Lexical::Var'} = '0';
	}
	elsif ( $] ge 5.018000 and $] lt 5.037002 ) {
		$meta->{prereqs}{runtime}{recommends}{'Alt::Lexical::Var::ButSupportModernPerl'} = '0.001';
	}

	if ( $] lt 5.034 ) {
		$meta->{prereqs}{runtime}{requires}{'Syntax::Keyword::Try'} = '0';
	}

};

my %WriteMakefileArgs = (
	ABSTRACT   => $meta->{abstract},
	AUTHOR     => ($EUMM >= 6.5702 ? $meta->{author} : $meta->{author}[0]),
	DISTNAME   => $meta->{name},
	VERSION    => $meta->{version},
	EXE_FILES  => [ map $_->{file}, values %{ $meta->{x_provides_scripts} || {} } ],
	NAME       => do { my $n = $meta->{name}; $n =~ s/-/::/g; $n },
	test       => { TESTS => "t/*.t t/integration/*.t t/unit/*.t t/unit/Result/*.t t/unit/results/*.t" },
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

