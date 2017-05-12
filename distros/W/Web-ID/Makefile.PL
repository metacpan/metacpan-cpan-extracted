use strict;
use ExtUtils::MakeMaker 6.17;

my $EUMM = eval( $ExtUtils::MakeMaker::VERSION );

my $meta = {
  "abstract"       => "implementation of WebID (a.k.a. FOAF+SSL)",
  "author"         => ["Toby Inkster (TOBYINK) <tobyink\@cpan.org>"],
  "dynamic_config" => 1,
  "generated_by"   => "Dist::Inkt::Profile::TOBYINK version 0.015, CPAN::Meta::Converter version 2.120921",
  "keywords"       => [],
  "license"        => ["perl_5"],
  "meta-spec"      => {
                        url => "http://search.cpan.org/perldoc?CPAN::Meta::Spec",
                        version => 2,
                      },
  "name"           => "Web-ID",
  "no_index"       => { directory => ["eg", "examples", "inc", "t", "xt"] },
  "prereqs"        => {
                        configure => {
                          requires => { "ExtUtils::MakeMaker" => 6.17, "File::ShareDir" => 0 },
                        },
                        runtime => {
                          requires => {
                            "Crypt::X509"      => 0,
                            "DateTime"         => 0,
                            "Digest::SHA"      => 0,
                            "Exporter::Tiny"   => 0,
                            "File::ShareDir"   => 0,
                            "List::MoreUtils"  => 0,
                            "match::simple"    => 0.008,
                            "Moose"            => "2.0600",
                            "namespace::sweep" => 0,
                            "Path::Tiny"       => 0.017,
                            "perl"             => "5.010",
                            "Plack"            => 0,
                            "RDF::Query"       => "2.900",
                            "RDF::Trine"       => "1.000",
                            "Types::DateTime"  => 0,
                            "Types::Standard"  => "0.040",
                            "Types::URI"       => 0,
                            "URI"              => 0,
                          },
                        },
                        test => { requires => { "Test::More" => 0.96 } },
                      },
  "provides"       => {
                        "Plack::Middleware::Auth::WebID"  => { file => "lib/Plack/Middleware/Auth/WebID.pm", version => 1.927 },
                        "Web::ID"                         => { file => "lib/Web/ID.pm", version => 1.927 },
                        "Web::ID::Certificate"            => { file => "lib/Web/ID/Certificate.pm", version => 1.927 },
                        "Web::ID::Certificate::Generator" => { file => "lib/Web/ID/Certificate/Generator.pm", version => 1.927 },
                        "Web::ID::RSAKey"                 => { file => "lib/Web/ID/RSAKey.pm", version => 1.927 },
                        "Web::ID::SAN"                    => { file => "lib/Web/ID/SAN.pm", version => 1.927 },
                        "Web::ID::SAN::Email"             => { file => "lib/Web/ID/SAN/Email.pm", version => 1.927 },
                        "Web::ID::SAN::URI"               => { file => "lib/Web/ID/SAN/URI.pm", version => 1.927 },
                        "Web::ID::Types"                  => { file => "lib/Web/ID/Types.pm", version => 1.927 },
                        "Web::ID::Util"                   => { file => "lib/Web/ID/Util.pm", version => 1.927 },
                        "Web::ID::Util::FindOpenSSL"      => { file => "lib/Web/ID/Util/FindOpenSSL.pm", version => 1.927 },
                      },
  "release_status" => "stable",
  "resources"      => {
                        bugtracker   => { web => "http://rt.cpan.org/Dist/Display.html?Queue=Web-ID" },
                        homepage     => "https://metacpan.org/release/Web-ID",
                        license      => ["http://dev.perl.org/licenses/"],
                        repository   => {
                                          type => "git",
                                          url  => "git://github.com/tobyink/p5-web-id.git",
                                          web  => "https://github.com/tobyink/p5-web-id",
                                        },
                        X_identifier => "http://purl.org/NET/cpan-uri/dist/Web-ID/project",
                      },
  "version"        => 1.927,
};

my %dynamic_config;
do {
	# If we can't find openssl via normal techniques,
	# add a dependency on Alien::OpenSSL.
	#
	use lib "lib";
	require Web::ID::Util::FindOpenSSL;
	$meta->{prereqs}{runtime}{requires}{"Alien::OpenSSL"} = "0.03"
		unless -x Web::ID::Util::FindOpenSSL::find_openssl();

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

