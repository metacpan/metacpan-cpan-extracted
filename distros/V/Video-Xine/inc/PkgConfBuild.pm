package
PkgConfBuild;

use strict;
use warnings;

use Module::Build;

use base 'Module::Build';

use Config;
use Devel::CheckLib;
use ExtUtils::PkgConfig;

sub new {
	my $type = shift;
	my %opts = @_;
	
	check_lib_or_exit(
	    lib => [qw(xine)]
    );
    
	if ( !$Config{'usethreads'} ) {
		warn "Unable to install. The Xine module requires multithread support.\n";
		exit(0);
	}

	# We need to find xine-config
	my %xine_config = ExtUtils::PkgConfig->find('libxine')
		or die "Couldn't find package for libxine";

    $opts{'extra_linker_flags'} = $xine_config{'libs'};
    $opts{'extra_compiler_flags'} = $xine_config{'cflags'};

	return $type->SUPER::new(%opts);
}

1;