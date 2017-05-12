use 5.006;

use strict;
use warnings;

use lib qw{inc};

use Module::Build;
use My::Module::Build;
use My::Module::Meta;
use Config;

(my $mbv = Module::Build->VERSION) =~ s/_//g;

my $meta = My::Module::Meta->new();

my %args = (
    dist_author => 'Tom Wyant (wyant at cpan dot org)',
    dist_abstract => 'Get information on arbitrary processes in Windows NT',
    module_name => 'Win32::Process::Info',
    configure_requires => { 'Module::Build' => 0.42 },
    build_requires => $meta->build_requires(),
    requires => $meta->requires(
	perl => $meta->requires_perl(),
    ),
    license => 'perl',
);

$mbv >= 0.28 and $args{meta_merge} = {
    no_index => {
	directory => [qw{ inc t xt }],
    },
    resources => {
	bugtracker => 'https://rt.cpan.org/Public/Dist/Display.html?Name=Win32-Process-Info',
    },
};


# Don't require Module::Build when building distribution, because user
# can use ExtUtils::MakeMaker.
$mbv >= 0.34
    and $args{auto_configure_requires} = !$meta->distribution();

my $bldr = My::Module::Build->new(%args);

$bldr->create_build_script ();
