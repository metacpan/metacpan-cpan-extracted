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
    add_to_cleanup	=> $meta->add_to_cleanup(),
    build_requires	=> $meta->build_requires(),
    configure_requires	=> $meta->configure_requires(),
    dist_abstract	=> $meta->abstract(),
    dist_author	=> $meta->author(),
    dist_name	=> $meta->dist_name(),
    license	=> $meta->license(),
    module_name	=> $meta->module_name(),
    requires	=> $meta->requires(
	perl	=> $meta->requires_perl(),
    ),
    script_files	=> $meta->script_files(),
);

if ( $mbv >= 0.28 ) {
    $args{meta_merge} = $meta->meta_merge();
    $args{meta_add} = {
	no_index	=> $meta->no_index(),
    };
}

$mbv >= 0.34
    and $args{auto_configure_requires} = 0;	# Don't require Module::Build

my $bldr = My::Module::Build->new( %args );

$bldr->create_build_script();

# ex: set textwidth=72 :
