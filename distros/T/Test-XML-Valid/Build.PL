shift(@ARGV) if $ARGV[0] eq 'Build'; # accomodate with CPAN autoinstall
use Module::Build;

my $class = Module::Build->subclass(
	 class => 'Test::XML::Valid::Builder',
	 code => q{
	 	sub ACTION_dist {
			my $self = shift;
			`perldoc -t lib/Test/XML/Valid.pm>README`;
			$self->SUPER::ACTION_dist;
	 	}

        sub ACTION_cover {
            my $self = shift;
            $self->depends_on('build');

            system qw( cover -delete );

            # sometimes we get failing tests, which makes Test::Harness
            # die.  catch that
            eval {
                local $ENV{PERL5OPT} = "-MDevel::Cover=-summary,0";
                $self->ACTION_test(@_);
            };
            system qw( cover -report html );
        }
 	},
);


$class->new(
    create_makefile_pl  => 'traditional', 
    dist_author         => 'Mark Stosberg <mark@summersault.com>',
	module_name => 'Test::XML::Valid',
	license => 'perl',
	requires => {
        'XML::LibXML'           => 0,
        'Test::More'            => 0,
        'Test::Builder::Tester' => 0,
	},
)->create_build_script;

