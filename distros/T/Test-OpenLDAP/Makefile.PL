use strict;
use warnings;
use ExtUtils::MakeMaker;
use Config;

unless (   ( exists $Config{'d_fork'} )
    && ( defined $Config{'d_fork'} )
    && ( $Config{'d_fork'} eq 'define' ) )
{
    die "'$^O' does not use the fork call for process control\n";
}
my $path_sep = $Config{'path_sep'};
my @slapd_directories = split /$path_sep/smx, "$ENV{'PATH'}$path_sep/usr/lib/openldap";
my $slapd_path;
foreach my $directory (@slapd_directories) {
    my $possible =
      File::Spec->catfile( $directory, 'slapd' );
    if ( -x $possible ) {
	$slapd_path = $possible;
    }
}
if ( !defined $slapd_path ) {
    die 'No slapd binary found in '
      . ( join ',', @slapd_directories );
}
WriteMakefile(
    NAME                => 'Test::OpenLDAP',
    AUTHOR              => q{David Dick <ddick@cpan.org>},
    VERSION_FROM        => 'lib/Test/OpenLDAP.pm',
    ABSTRACT_FROM       => 'lib/Test/OpenLDAP.pm',
    ( $ExtUtils::MakeMaker::VERSION >= 6.3002
        ? ( 'LICENSE' => 'perl' )
        : () ),
    (
        $ExtUtils::MakeMaker::VERSION >= 6.48
        ? ( 'MIN_PERL_VERSION' => '5.006' )
        : ()
    ),
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources   => {
            repository => {
                url  => 'https://github.com/david-dick/test-openldap',
                web  => 'https://github.com/david-dick/test-openldap',
                type => 'git',
            },
            bugtracker => {
                web => 'https://github.com/david-dick/test-openldap/issues'
            },
        },
    },
    PL_FILES            => {},
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    TEST_REQUIRES => {
        'Test::More'  => 0,
    },
    PREREQ_PM => {
	'Config' => 0,
	'POSIX' => 0,
	'Data::UUID' => 0,
	'FileHandle' => 0,
	'DirHandle' => 0,
	'File::Temp' => 0,
	'URI::Escape' => 0,
	'English' => 0,
	'Net::LDAP' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Test-OpenLDAP-*' },
);
