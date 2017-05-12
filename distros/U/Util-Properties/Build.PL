use strict;
use warnings;
use Module::Build;

my @scripts;
open (fd, "<MANIFEST") or die "cannot open MANIFEST: $!";
while(<fd>){
  chomp;
  push @scripts, $_ if /^(scripts)\//;
}

my %cgi_scripts;
open (fd, "<MANIFEST") or die "cannot open MANIFEST: $!";
while(<fd>){
  chomp;
  $cgi_scripts{$_}=$_ if /^(cgi)\//;
}

my $build = Module::Build->new(
    module_name         => 'Util::Properties',
    license             => 'lgpl',
    create_makefile_pl => 'traditional',
    create_readme => 'README',
    dist_author         => 'Alexandre Masselot <alexandre.masselot@genebio.com>',
    dist_version_from   => 'lib/Util/Properties.pm',
    requires => {
#		 'Test::More' => 0,
		 'IO::All' => 0,
		 'LockFile::Simple' => 0,
		 'Object::InsideOut' => 0,
		 'Digest::MD5::File' => 0,
		},
    script_files=>\@scripts,
    cgi_files=>\%cgi_scripts,
    install_path => { cgi =>"blib/cgi/" },
    add_to_cleanup      => [ 'Util-Properties-*' ],
);
$build->add_build_element('cgi') || die "cannot add build element [cgi]";
$build->prereq_failures() && $build->prereq_failures()->{requires}  && die "conflicts (missing requirem\ents?)";
$build->create_build_script;
