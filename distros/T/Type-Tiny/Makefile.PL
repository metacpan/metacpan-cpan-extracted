use strict;
use ExtUtils::MakeMaker 6.17;

my $EUMM = eval( $ExtUtils::MakeMaker::VERSION );

my $meta = {
  "abstract"       => "tiny, yet Moo(se)-compatible type constraint",
  "author"         => ["Toby Inkster (TOBYINK) <tobyink\@cpan.org>"],
  "dynamic_config" => 1,
  "generated_by"   => "Dist::Inkt::Profile::TOBYINK version 0.024, CPAN::Meta::Converter version 2.150010",
  "keywords"       => [
                        "Argument Checking",
                        "Argument Validation",
                        "Moo",
                        "Moose",
                        "Mouse",
                        "Parameter Checking",
                        "Parameter Validation",
                        "Schema",
                        "Type Coercion",
                        "Type Constraint",
                        "Type Library",
                        "Validation",
                      ],
  "license"        => ["perl_5"],
  "meta-spec"      => {
                        url => "http://search.cpan.org/perldoc?CPAN::Meta::Spec",
                        version => 2,
                      },
  "name"           => "Type-Tiny",
  "no_index"       => { directory => ["eg", "examples", "inc", "t", "xt"] },
  "prereqs"        => {
                        configure => {
                                       recommends => { "CPAN::Meta::Requirements" => "2.000" },
                                       requires   => { "ExtUtils::MakeMaker" => 6.17 },
                                     },
                        develop   => {
                                       recommends => { "Test::Memory::Cycle" => 0 },
                                       suggests   => { "Dist::Inkt::Profile::TOBYINK" => 0 },
                                     },
                        runtime   => {
                                       conflicts  => { "Kavorka" => "<= 0.013", "Types::ReadOnly" => "<= 0.001" },
                                       recommends => {
                                                       "Class::XSAccessor" => 1.17,
                                                       "Devel::LexAlias"   => 0.05,
                                                       "Devel::StackTrace" => 0,
                                                       "perl"              => 5.010001,
                                                       "Ref::Util::XS"     => "0.100",
                                                       "Regexp::Util"      => 0.003,
                                                       "Sub::Util"         => 0,
                                                       "Type::Tiny::XS"    => 0.016,
                                                     },
                                       requires   => { "Exporter::Tiny" => 1.004001, "perl" => 5.008001 },
                                       suggests   => { Moo => "1.006000", Moose => "2.0000", Mouse => "1.00", Reply => 0 },
                                     },
                        test      => {
                                       recommends => { "Test::Deep" => 0, "Test::Tester" => 0.109, "Test::Warnings" => 0 },
                                       requires   => { "Test::More" => 0.96 },
                                       suggests   => { "Test::Memory::Cycle" => 0 },
                                     },
                      },
  "provides"       => {
                        "Devel::TypeTiny::Perl58Compat"            => { file => "lib/Devel/TypeTiny/Perl58Compat.pm", version => 2.000001 },
                        "Error::TypeTiny"                          => { file => "lib/Error/TypeTiny.pm", version => 2.000001 },
                        "Error::TypeTiny::Assertion"               => { file => "lib/Error/TypeTiny/Assertion.pm", version => 2.000001 },
                        "Error::TypeTiny::Compilation"             => { file => "lib/Error/TypeTiny/Compilation.pm", version => 2.000001 },
                        "Error::TypeTiny::WrongNumberOfParameters" => {
                                                                        file => "lib/Error/TypeTiny/WrongNumberOfParameters.pm",
                                                                        version => 2.000001,
                                                                      },
                        "Eval::TypeTiny"                           => { file => "lib/Eval/TypeTiny.pm", version => 2.000001 },
                        "Eval::TypeTiny::CodeAccumulator"          => { file => "lib/Eval/TypeTiny/CodeAccumulator.pm", version => 2.000001 },
                        "Reply::Plugin::TypeTiny"                  => { file => "lib/Reply/Plugin/TypeTiny.pm", version => 2.000001 },
                        "Test::TypeTiny"                           => { file => "lib/Test/TypeTiny.pm", version => 2.000001 },
                        "Type::Coercion"                           => { file => "lib/Type/Coercion.pm", version => 2.000001 },
                        "Type::Coercion::FromMoose"                => { file => "lib/Type/Coercion/FromMoose.pm", version => 2.000001 },
                        "Type::Coercion::Union"                    => { file => "lib/Type/Coercion/Union.pm", version => 2.000001 },
                        "Type::Library"                            => { file => "lib/Type/Library.pm", version => 2.000001 },
                        "Type::Params"                             => { file => "lib/Type/Params.pm", version => 2.000001 },
                        "Type::Params::Alternatives"               => { file => "lib/Type/Params/Alternatives.pm", version => 2.000001 },
                        "Type::Params::Parameter"                  => { file => "lib/Type/Params/Parameter.pm", version => 2.000001 },
                        "Type::Params::Signature"                  => { file => "lib/Type/Params/Signature.pm", version => 2.000001 },
                        "Type::Parser"                             => { file => "lib/Type/Parser.pm", version => 2.000001 },
                        "Type::Parser::AstBuilder"                 => { file => "lib/Type/Parser.pm", version => 2.000001 },
                        "Type::Parser::Token"                      => { file => "lib/Type/Parser.pm", version => 2.000001 },
                        "Type::Parser::TokenStream"                => { file => "lib/Type/Parser.pm", version => 2.000001 },
                        "Type::Registry"                           => { file => "lib/Type/Registry.pm", version => 2.000001 },
                        "Type::Tie"                                => { file => "lib/Type/Tie.pm", version => 2.000001 },
                        "Type::Tie::ARRAY"                         => { file => "lib/Type/Tie.pm", version => 2.000001 },
                        "Type::Tie::BASE"                          => { file => "lib/Type/Tie.pm", version => 2.000001 },
                        "Type::Tie::HASH"                          => { file => "lib/Type/Tie.pm", version => 2.000001 },
                        "Type::Tie::SCALAR"                        => { file => "lib/Type/Tie.pm", version => 2.000001 },
                        "Type::Tiny"                               => { file => "lib/Type/Tiny.pm", version => 2.000001 },
                        "Type::Tiny::Class"                        => { file => "lib/Type/Tiny/Class.pm", version => 2.000001 },
                        "Type::Tiny::ConstrainedObject"            => { file => "lib/Type/Tiny/ConstrainedObject.pm", version => 2.000001 },
                        "Type::Tiny::Duck"                         => { file => "lib/Type/Tiny/Duck.pm", version => 2.000001 },
                        "Type::Tiny::Enum"                         => { file => "lib/Type/Tiny/Enum.pm", version => 2.000001 },
                        "Type::Tiny::Intersection"                 => { file => "lib/Type/Tiny/Intersection.pm", version => 2.000001 },
                        "Type::Tiny::Role"                         => { file => "lib/Type/Tiny/Role.pm", version => 2.000001 },
                        "Type::Tiny::Union"                        => { file => "lib/Type/Tiny/Union.pm", version => 2.000001 },
                        "Type::Utils"                              => { file => "lib/Type/Utils.pm", version => 2.000001 },
                        "Types::Common"                            => { file => "lib/Types/Common.pm", version => 2.000001 },
                        "Types::Common::Numeric"                   => { file => "lib/Types/Common/Numeric.pm", version => 2.000001 },
                        "Types::Common::String"                    => { file => "lib/Types/Common/String.pm", version => 2.000001 },
                        "Types::Standard"                          => { file => "lib/Types/Standard.pm", version => 2.000001 },
                        "Types::Standard::ArrayRef"                => { file => "lib/Types/Standard/ArrayRef.pm", version => 2.000001 },
                        "Types::Standard::CycleTuple"              => { file => "lib/Types/Standard/CycleTuple.pm", version => 2.000001 },
                        "Types::Standard::Dict"                    => { file => "lib/Types/Standard/Dict.pm", version => 2.000001 },
                        "Types::Standard::HashRef"                 => { file => "lib/Types/Standard/HashRef.pm", version => 2.000001 },
                        "Types::Standard::Map"                     => { file => "lib/Types/Standard/Map.pm", version => 2.000001 },
                        "Types::Standard::ScalarRef"               => { file => "lib/Types/Standard/ScalarRef.pm", version => 2.000001 },
                        "Types::Standard::StrMatch"                => { file => "lib/Types/Standard/StrMatch.pm", version => 2.000001 },
                        "Types::Standard::Tied"                    => { file => "lib/Types/Standard/Tied.pm", version => 2.000001 },
                        "Types::Standard::Tuple"                   => { file => "lib/Types/Standard/Tuple.pm", version => 2.000001 },
                        "Types::TypeTiny"                          => { file => "lib/Types/TypeTiny.pm", version => 2.000001 },
                      },
  "release_status" => "stable",
  "resources"      => {
                        bugtracker   => { web => "https://github.com/tobyink/p5-type-tiny/issues" },
                        homepage     => "https://typetiny.toby.ink/",
                        license      => ["http://dev.perl.org/licenses/"],
                        repository   => {
                                          type => "git",
                                          url  => "git://github.com/tobyink/p5-type-tiny.git",
                                          web  => "https://github.com/tobyink/p5-type-tiny",
                                        },
                        x_identifier => "http://purl.org/NET/cpan-uri/dist/Type-Tiny/project",
                      },
  "version"        => 2.000001,
  "x_breaks"       => { "Kavorka" => "<= 0.013", "Types::ReadOnly" => "<= 0.001" },
  "x_contributors" => [
                        "Diab Jerius (DJERIUS) <djerius\@cpan.org>",
                        "Vyacheslav Matyukhin (MMCLERIC) <mmcleric\@cpan.org>",
                        "Peter Flanigan (PJFL) <pjfl\@cpan.org>",
                        "Pierre Masci",
                        "Mark Stosberg (MARKSTOS) <markstos\@cpan.org>",
                        "David Steinbrunner <dsteinbrunner\@pobox.com>",
                        "Samuel Kaufman (SKAUFMAN) <skaufman\@cpan.org>",
                        "Graham Knop (HAARG) <haarg\@cpan.org>",
                        "Peter Karman (KARMAN) <karman\@cpan.org>",
                        "Alexander Hartmaier (ABRAXXA) <abraxxa\@cpan.org>",
                        "Dagfinn Ilmari Manns\xE5ker (ILMARI) <ilmari\@cpan.org>",
                        "Gianni Ceccarelli (DAKKAR) <dakkar\@cpan.org>",
                        "Karen Etheridge (ETHER) <ether\@cpan.org>",
                        "Thomas Sibley (TSIBLEY) <tsibley\@cpan.org>",
                        "Peter Valdemar M\xF8rch <peter\@morch.com>",
                        "Zoffix Znet <cpan\@zoffix.com>",
                        "Denis Ibaev <dionys\@gmail.com>",
                        "Lucas Buchala (LSBUCHALA) <lsbuchala\@cpan.org>",
                        "Alexandr Ciornii <alexchorny\@gmail.com>",
                        "Philippe Bruhat (BOOK) <book\@cpan.org>",
                        "Robert Rothenberg (RRWO) <rrwo\@cpan.org>",
                        "Nelo Onyiah",
                        "Jonas B Nielsen (JONASBN) <jonasbn\@cpan.org>",
                        "Benct Philip Jonsson <bpj\@melroch.se>",
                        "Hauke D (HAUKEX) <haukex\@cpan.org>",
                        "Meredith Howard (MHOWARD) <mhoward\@cpan.org>",
                        "Andrew Ruder (AERUDER) <aeruder\@cpan.org>",
                        "Sandor Patocs (SPATOCS) <spatocs\@cpan.org>",
                        "Windymelt",
                        "Lucas Tiago de Moraes (LUCAS) <lucas\@cpan.org>",
                        "Florian Schlichting",
                      ],
};

my %dynamic_config;
do {
	use strict;
	use warnings;
	no warnings 'uninitialized';
	
	# Old versions of Perl come with old versions of Exporter.
	# Not that we use Exporter a whole lot anyway.
	if ( $] lt 5.009001 ) {
		$meta->{prereqs}{runtime}{requires}{'Exporter'} = '5.57';
	}
	
	my $extended_testing = 0;
	if ( $ENV{EXTENDED_TESTING} and $] ge '5.008009' ) {
		++$extended_testing if $meta->{version} =~ /_/;
		++$extended_testing if $ENV{TRAVIS};
	}
	
	if ( $ENV{MINIMAL_INSTALL} ) {
		$extended_testing = 0;
		for my $stage ( qw( runtime test ) ) {
			delete $meta->{prereqs}{$stage}{recommends};
			delete $meta->{prereqs}{$stage}{suggests};
		}
	}
	
	if ( $extended_testing ) {
		$meta->{prereqs}{test}{requires}{'Moose'} = '2.0600';
		$meta->{prereqs}{test}{requires}{$_} = '0'
			for qw(
				bareword::filehandles
				Class::InsideOut
				Class::XSAccessor
				Devel::LexAlias
				Devel::Refcount
				indirect
				match::simple
				Moo
				MooseX::Getopt
				MooseX::Types::Common
				Mouse
				MouseX::Types::Common
				multidimensional
				Object::Accessor
				PadWalker
				Return::Type
				strictures
				Test::Fatal
				Test::LeakTrace
				Test::Requires
				Test::Tester
				Test::Warnings
			);
		if ( $] ge '5.028' ) {
			$meta->{prereqs}{test}{requires}{$_} = '0'
				for qw(
					Validation::Class::Simple
				);
		}
	}
	
	if ( $ENV{AUTOMATED_TESTING} and "$^V" =~ /c$/ ) {
		print "cperl unsupported by test suite (the vast majority of the distribution should still work)\n";
		exit(0);
	}

};
for my $stage (keys %{$meta->{prereqs}})
{
	my $conflicts = $meta->{prereqs}{$stage}{conflicts} or next;
	eval { require CPAN::Meta::Requirements } or last;
	$conflicts = 'CPAN::Meta::Requirements'->from_string_hash($conflicts);
	
	for my $module ($conflicts->required_modules)
	{
		eval "require $module" or next;
		my $installed = eval(sprintf('$%s::VERSION', $module));
		$conflicts->accepts_module($module, $installed) or next;
		
		my $message = "\n".
			"** This version of $meta->{name} conflicts with the version of\n".
			"** module $module ($installed) you have installed.\n";
		die($message . "\n" . "Bailing out")
			if $stage eq 'build' || $stage eq 'configure';
		
		$message .= "**\n".
			"** It's strongly recommended that you update it after\n".
			"** installing this version of $meta->{name}.\n";
		warn("$message\n");
	}
}

my %WriteMakefileArgs = (
	ABSTRACT   => $meta->{abstract},
	AUTHOR     => ($EUMM >= 6.5702 ? $meta->{author} : $meta->{author}[0]),
	DISTNAME   => $meta->{name},
	VERSION    => $meta->{version},
	EXE_FILES  => [ map $_->{file}, values %{ $meta->{x_provides_scripts} || {} } ],
	NAME       => do { my $n = $meta->{name}; $n =~ s/-/::/g; $n },
	test       => { TESTS => "t/*.t t/20-modules/Devel-TypeTiny-Perl58Compat/*.t t/20-modules/Error-TypeTiny-Assertion/*.t t/20-modules/Error-TypeTiny-Compilation/*.t t/20-modules/Error-TypeTiny-WrongNumberOfParameters/*.t t/20-modules/Error-TypeTiny/*.t t/20-modules/Eval-TypeTiny-CodeAccumulator/*.t t/20-modules/Eval-TypeTiny/*.t t/20-modules/Test-TypeTiny/*.t t/20-modules/Type-Coercion-FromMoose/*.t t/20-modules/Type-Coercion-Union/*.t t/20-modules/Type-Coercion/*.t t/20-modules/Type-Library/*.t t/20-modules/Type-Params-Signature/*.t t/20-modules/Type-Params/*.t t/20-modules/Type-Parser/*.t t/20-modules/Type-Registry/*.t t/20-modules/Type-Tie/*.t t/20-modules/Type-Tiny-Class/*.t t/20-modules/Type-Tiny-ConstrainedObject/*.t t/20-modules/Type-Tiny-Duck/*.t t/20-modules/Type-Tiny-Enum/*.t t/20-modules/Type-Tiny-Intersection/*.t t/20-modules/Type-Tiny-Role/*.t t/20-modules/Type-Tiny-Union/*.t t/20-modules/Type-Tiny-_HalfOp/*.t t/20-modules/Type-Tiny/*.t t/20-modules/Type-Utils/*.t t/20-modules/Types-Common-Numeric/*.t t/20-modules/Types-Common-String/*.t t/20-modules/Types-Common/*.t t/20-modules/Types-Standard/*.t t/20-modules/Types-TypeTiny/*.t t/21-types/*.t t/30-external/Class-InsideOut/*.t t/30-external/Class-Plain/*.t t/30-external/Data-Constraint/*.t t/30-external/Exporter-Tiny/*.t t/30-external/Function-Parameters/*.t t/30-external/Kavorka/*.t t/30-external/Moo/*.t t/30-external/Moops/*.t t/30-external/Moose/*.t t/30-external/MooseX-Getopt/*.t t/30-external/MooseX-Types/*.t t/30-external/Mouse/*.t t/30-external/MouseX-Types/*.t t/30-external/Object-Accessor/*.t t/30-external/Return-Type/*.t t/30-external/Specio/*.t t/30-external/Sub-Quote/*.t t/30-external/Switcheroo/*.t t/30-external/Type-Library-Compiler/*.t t/30-external/Types-ReadOnly/*.t t/30-external/Validation-Class-Simple/*.t t/30-external/match-simple/*.t t/40-bugs/*.t" },
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

FixMakefile($mm->{FIRST_MAKEFILE} || 'Makefile');

exit(0);

