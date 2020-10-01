use Module::Build;
use File::Copy qw(copy);

my $lang = defined($ENV{'LANG'}) ? $ENV{'LANG'} : 'en';
my $target_pod = File::Spec->catfile('lib','Unicode','MapUTF8.pod');
if ($lang =~ m/^(ja|ja_JP|ja_JP.utf-8|ja_JP.utf8|ja.utf8|ja.utf-8)$/i) {
    $source_pod = File::Spec->catfile('pod','MapUTF8.ja_JP.utf8.pod');
    copy ($source_pod, $target_pod);
    
} elsif ($lang =~ m/^(ja_JP.eucjp|ja_JP.euc|ja_euc|ja_eucjp)$/i) {
    $source_pod = File::Spec->catfile('pod','MapUTF8.ja_JP.eucjp.pod');
    copy ($source_pod, $target_pod);
} else {
    $source_pod = File::Spec->catfile('pod','MapUTF8.en.pod');
    copy ($source_pod, $target_pod);
}

my $build = Module::Build->new
      ( module_name    => 'Unicode::MapUTF8',
        dist_author    => 'Jerilyn Franz <cpan@jerilyn.info>',
        dist_abstract  => 'Conversions to and from arbitrary character sets and UTF8',
        license        => 'mit',
        requires       => {
            'perl'             => '5.006',
            'warnings'         => 0,
	    'Carp'             => 0,
            'File::Copy'       => 0,
            'Unicode::Map'     => 0,
            'Unicode::String'  => 0,
            'Unicode::Map8'    => 0,
            'Jcode'            => 0,
        },
        build_requires => { },
        test_requires => {
            'perl'             => '5.006',
            'warnings'         => 0,
	    'Carp'             => 0,
            'File::Copy'       => 0,
            'Unicode::Map'     => 0,
            'Unicode::String'  => 0,
            'Unicode::Map8'    => 0,
            'Jcode'            => 0,
        },
        meta_merge => {
          'meta-spec' => { version => 2 },
           resources => {
              bugtracker => {
                   web  => 'https://github.com/JerilynFranz/perl-Unicode-MapUTF8/issues',
               },
               homepage => 'https://github.com/JerilynFranz/perl-Unicode-MapUTF8',
               repository => {
                   type => 'git',
                   url  => 'https://github.com/JerilynFranz/perl-Unicode-MapUTF8.git',
                   web  => 'https://github.com/JerilynFranz/perl-Unicode-MapUTF8',
               },
            },
        },
      )->create_build_script;
