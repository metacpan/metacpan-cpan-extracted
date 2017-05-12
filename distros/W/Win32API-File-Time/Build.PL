use 5.006002;

use strict;
use warnings;

use lib qw{ inc };

use My::Module::Build;
use My::Module::Meta;
use Module::Build;

( my $mbv = Module::Build->VERSION() ) =~ s/_//g;

my $meta = My::Module::Meta->new();

$meta->os_check();

my %args = (
    dist_author => 'Tom Wyant (wyant at cpan dot org)',
    dist_abstract => 'Get and set file times in Windows - including open files',
    module_name => 'Win32API::File::Time',
    requires => $meta->requires(
	perl	=> $meta->requires_perl(),
    ),
    build_requires => $meta->build_requires(),
    license => 'perl',
    add_to_cleanup	=> [ qw{ cover_db } ],
);

$mbv >= 0.28
    and $args{meta_merge} = $meta->meta_merge();

$mbv >= 0.34
    and $args{auto_configure_requires} = 0;	# Don't require Module::Build

my $bldr = My::Module::Build->new(%args);

$bldr->create_build_script ();

# ex: set textwidth=72 :
