use strict;
use ExtUtils::MakeMaker 6.17;

my $EUMM = eval( $ExtUtils::MakeMaker::VERSION );

my $meta = {
  "abstract"           => "manage a collection of author tests shared between multiple projects",
  "author"             => ["Toby Inkster (TOBYINK) <tobyink\@cpan.org>"],
  "dynamic_config"     => 0,
  "generated_by"       => "Dist::Inkt::Profile::TOBYINK version 0.013, CPAN::Meta::Converter version 2.120921",
  "keywords"           => [],
  "license"            => ["perl_5"],
  "meta-spec"          => {
                            url => "http://search.cpan.org/perldoc?CPAN::Meta::Spec",
                            version => 2,
                          },
  "name"               => "XT-Manager",
  "no_index"           => { directory => ["eg", "examples", "inc", "t", "xt"] },
  "prereqs"            => {
                            configure => { requires => { "ExtUtils::MakeMaker" => 6.17 } },
                            runtime => {
                              requires => {
                                "App::Cmd"          => "0.300",
                                "match::simple"     => 0.004,
                                "Moo"               => "1.002000",
                                "Path::Tiny"        => 0.017,
                                "Syntax::Collector" => 0.006,
                                "thanks"            => 0.001,
                                "Throwable"         => "0.200000",
                                "Types::Standard"   => 0.004,
                                "XT::Util"          => 0.001,
                              },
                            },
                            test => { requires => { "Test::More" => 0.96 } },
                          },
  "provides"           => {
                            "XT::Manager"                          => { file => "lib/XT/Manager.pm", version => 0.006 },
                            "XT::Manager::API"                     => { file => "lib/XT/Manager/API.pm", version => 0.006 },
                            "XT::Manager::API::Syntax"             => { file => "lib/XT/Manager/API.pm", version => 0 },
                            "XT::Manager::API::Types"              => { file => "lib/XT/Manager/API.pm", version => 0 },
                            "XT::Manager::Command"                 => { file => "lib/XT/Manager/Command.pm", version => 0.006 },
                            "XT::Manager::Command::pull"           => { file => "lib/XT/Manager/Command/pull.pm", version => 0.006 },
                            "XT::Manager::Command::push"           => { file => "lib/XT/Manager/Command/push.pm", version => 0.006 },
                            "XT::Manager::Command::remove"         => { file => "lib/XT/Manager/Command/remove.pm", version => 0.006 },
                            "XT::Manager::Command::status"         => { file => "lib/XT/Manager/Command/status.pm", version => 0.006 },
                            "XT::Manager::Comparison"              => { file => "lib/XT/Manager/API.pm", version => 0 },
                            "XT::Manager::Exception::FileNotFound" => { file => "lib/XT/Manager/API.pm", version => 0 },
                            "XT::Manager::FileSystemTestSet"       => { file => "lib/XT/Manager/API.pm", version => 0 },
                            "XT::Manager::Repository"              => { file => "lib/XT/Manager/API.pm", version => 0 },
                            "XT::Manager::Test"                    => { file => "lib/XT/Manager/API.pm", version => 0 },
                            "XT::Manager::TestSet"                 => { file => "lib/XT/Manager/API.pm", version => 0 },
                            "XT::Manager::XTdir"                   => { file => "lib/XT/Manager/API.pm", version => 0 },
                          },
  "release_status"     => "stable",
  "resources"          => {
                            bugtracker   => { web => "http://rt.cpan.org/Dist/Display.html?Queue=XT-Manager" },
                            homepage     => "https://metacpan.org/release/XT-Manager",
                            license      => ["http://dev.perl.org/licenses/"],
                            repository   => { type => "git", web => "https://github.com/tobyink/p5-xt-manager" },
                            X_identifier => "http://purl.org/NET/cpan-uri/dist/XT-Manager/project",
                          },
  "version"            => 0.006,
  "x_provides_scripts" => { "perl-xt-manager" => { file => "bin/perl-xt-manager" } },
};

my %dynamic_config;

my %WriteMakefileArgs = (
	ABSTRACT   => $meta->{abstract},
	AUTHOR     => ($EUMM >= 6.5702 ? $meta->{author} : $meta->{author}[0]),
	DISTNAME   => $meta->{name},
	VERSION    => $meta->{version},
	EXE_FILES  => [ map $_->{file}, values %{ $meta->{x_provides_scripts} || {} } ],
	NAME       => do { my $n = $meta->{name}; $n =~ s/-/::/g; $n },
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

