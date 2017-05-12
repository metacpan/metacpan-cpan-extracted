use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/misc/cpan";
use MyBuilder;

my %pm_files = (
  map {my ($std) = $_; $std =~ s{^web/cgi-bin/yatt.lib/}{lib/}; $_ => $std}
  @{MyBuilder->rscan_dir('web/cgi-bin/yatt.lib', qr{\.pm})}
);

my $builder = MyBuilder->new(
    module_name         => 'YATT',
    license             => 'perl',
    dist_author         => '"KOBAYASI, Hiroaki" <hkoba@cpan.org>',
    dist_version_from   => 'web/cgi-bin/yatt.lib/YATT.pm',
    requires => {
        'perl'       => '5.7.2', # for sprintf reordering.
        'version'    => 0,
        'File::Remove' => 0, # Should be replaced to File::Path.
        'List::Util' => 0,
        'Test::More' => 0,
        'Test::Differences' => 0,
        'CGI' => 0,
    },
    configure_requires => {
        'Module::Build' => 0,
    },
    pm_files => \%pm_files,
    test_files => Module::Build->rscan_dir('web/cgi-bin/yatt.lib/t', qr{\.t}),
    script_files => {
      map(("scripts/$_" => "bin/$_")
	  , qw(
		yatt.genperl
		yatt.lint
		yatt.render
		yatt.server
	     ))
    },
    add_to_cleanup      => [ qw(YATT-* *.tmp
				web/cgi-bin/yatt.lib/t/cover_db
			      ) ],
);

$builder->create_build_script();
