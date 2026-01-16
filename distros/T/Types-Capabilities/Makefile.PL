use strict;
use ExtUtils::MakeMaker 6.17;

my $EUMM = eval( $ExtUtils::MakeMaker::VERSION );

my $meta = {
  "abstract"         => "don't care what type of data you are given, just what you can do with it",
  "author"           => ["Toby Inkster (TOBYINK) <tobyink\@cpan.org>"],
  "dynamic_config"   => 0,
  "generated_by"     => "Dist::Inkt::Profile::TOBYINK version 0.024, CPAN::Meta::Converter version 2.150010",
  "keywords"         => [],
  "license"          => ["perl_5"],
  "meta-spec"        => {
                          url => "http://search.cpan.org/perldoc?CPAN::Meta::Spec",
                          version => 2,
                        },
  "name"             => "Types-Capabilities",
  "no_index"         => { directory => ["eg", "examples", "inc", "t", "xt"] },
  "prereqs"          => {
                          configure => { requires => { "ExtUtils::MakeMaker" => 6.17 } },
                          develop   => { recommends => { "Dist::Inkt" => 0.001 } },
                          runtime   => {
                                         requires => {
                                           "Carp" => 0,
                                           "Class::Method::Modifiers" => 0,
                                           "Module::Runtime" => 0,
                                           "parent" => 0,
                                           "perl" => 5.010001,
                                           "Sub::HandlesVia::CodeGenerator" => 0.050006,
                                           "Sub::HandlesVia::Handler" => 0.050006,
                                           "Type::Library" => "2.000000",
                                           "Type::Tiny::Duck" => "2.000000",
                                           "Types::Common" => 0,
                                           "Types::Path::Tiny" => 0,
                                           "Types::TypeTiny" => "2.000000",
                                         },
                                       },
                          test      => {
                                         requires => {
                                           "Path::Tiny"                    => 0.066,
                                           "Test2::Plugin::BailOnFail"     => 0,
                                           "Test2::Require::AuthorTesting" => 0,
                                           "Test2::Require::Module"        => 0,
                                           "Test2::Tools::Spec"            => 0,
                                           "Test2::V0"                     => 0,
                                           "Types::Common"                 => 0,
                                         },
                                       },
                        },
  "provides"         => {
                          "Types::Capabilities"                           => { file => "lib/Types/Capabilities.pm", version => "0.003000" },
                          "Types::Capabilities::CoercedValue::ARRAYREF"   => {
                                                                               file => "lib/Types/Capabilities/CoercedValue/ARRAYREF.pm",
                                                                               version => "0.003000",
                                                                             },
                          "Types::Capabilities::CoercedValue::CODEREF"    => {
                                                                               file => "lib/Types/Capabilities/CoercedValue/CODEREF.pm",
                                                                               version => "0.003000",
                                                                             },
                          "Types::Capabilities::CoercedValue::FILEHANDLE" => {
                                                                               file => "lib/Types/Capabilities/CoercedValue/FILEHANDLE.pm",
                                                                               version => "0.003000",
                                                                             },
                          "Types::Capabilities::CoercedValue::QUEUE"      => {
                                                                               file => "lib/Types/Capabilities/CoercedValue/QUEUE.pm",
                                                                               version => "0.003000",
                                                                             },
                          "Types::Capabilities::CoercedValue::STACK"      => {
                                                                               file => "lib/Types/Capabilities/CoercedValue/STACK.pm",
                                                                               version => "0.003000",
                                                                             },
                          "Types::Capabilities::Constraint"               => {
                                                                               file => "lib/Types/Capabilities/Constraint.pm",
                                                                               version => "0.003000",
                                                                             },
                        },
  "release_status"   => "stable",
  "resources"        => {
                          bugtracker   => {
                                            web => "https://github.com/tobyink/p5-types-capabilities/issues",
                                          },
                          homepage     => "https://metacpan.org/release/Types-Capabilities",
                          license      => ["http://dev.perl.org/licenses/"],
                          repository   => {
                                            type => "git",
                                            url  => "git://github.com/tobyink/p5-types-capabilities.git",
                                            web  => "https://github.com/tobyink/p5-types-capabilities",
                                          },
                          x_identifier => "http://purl.org/NET/cpan-uri/dist/Types-Capabilities/project",
                        },
  "version"          => "0.003000",
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
	test       => { TESTS => "t/*.t t/integration/*.t t/unit/Types/*.t" },
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

