use 5.8.8;
use strict;
use warnings FATAL => 'all';
use Module::Build;

# Installation paths

my $sysconfig = ( -e '/etc/default' ) ? '/etc/default' : '/etc/sysconfig';
my $install_path = {
    etc           => '/etc/xas',
    sbin          => '/usr/sbin',
    script        => '/usr/bin',
    sysconfig     => $sysconfig,
    'init.d'      => '/etc/init.d',
    'profile.d'   => '/etc/profile.d',
    'logrotate.d' => '/etc/logrotate.d',
};

# Required modules

my $requires = {
    'perl'                        => 5.008_08,
    'Badger'                      => 0.09,
    'POE'                         => 1.294,
    'Data::Dumper'                => 0.0,
    'Data::Hexdumper'             => 0.0,
    'Data::UUID'                  => 0.0,
    'DateTime'                    => 0.53,
    'DateTime::Span'              => 0.0,
    'DateTime::Format::Pg'        => 0.0,
    'DateTime::Format::Strptime'  => 1.10,
    'Getopt::Long'                => 0.0,
    'Config::IniFiles'            => 2.65,
    'Hash::Merge'                 => 0.12,
    'JSON::XS'                    => 2.27,
    'KeyedMutex'                  => 0.06,
    'MIME::Lite'                  => 3.027,
    'Params::Validate'            => 0.92,
    'Pod::Usage'                  => 1.35,
    'Try::Tiny'                   => 0.11,
    'Try::Tiny::Retry'            => 0.003,
    'Set::Light'                  => 0.04,
    'Sys::Syslog'                 => 0.0,
    'Net::SSH2'                   => 0.44,
    'WWW::Curl'                   => 0.0,
    'HTTP::Response'              => 0.0,
    'HTTP::Request'               => 0.0,
    'XML::LibXML'                 => 0.0,
};

# Needed for Win32 installations

if ($^O eq 'MSWin32') {

    $requires->{'Win32'}          = 0.45;
    $requires->{'Win32::IPC'}     = 0.0;
    $requires->{'Win32::OLE'}     = 0.1709;
    $requires->{'Win32::Daemon'}  = 20110117;
    $requires->{'Win32::Service'} = 0.06;

    my $path = defined($ENV{'XAS_ROOT'}) ? $ENV{'XAS_ROOT'} : 'C:\\xas';

    $install_path = {
        script        => $path . '\\bin',
        sbin          => $path . '\\sbin',
        etc           => $path . '\\etc',
        sysconfig     => $path . '\\etc\\sysconifg',
        'init.d'      => $path . '\\etc\\init.d',
        'profile.d'   => $path . '\\etc\\profile.d',
        'logrotate.d' => $path . '\\etc\\logrotate.d',
    };

}

my $class = Module::Build->subclass(code => <<'EOC');

    use strict;
    use warnings;
    use IO::File;
    use File::Find;
    use File::Basename;
    use File::Spec::Functions qw( catfile catdir rel2abs );

    # override and add a few things

    sub new {
        my $class = shift;

        my $self = $class->SUPER::new(@_);

        my $blib = $self->{properties}{blib};
        my $sbin = catfile($blib, 'sbin');
        $self->{properties}{sbindoc_dirs} = [ $sbin ];

        return $self;

    }

    # create man pages for files within sbin

    sub manify_sbin_pods {
        my $self    = shift;

        my $files  = $self->_find_pods( 
            $self->{properties}{sbindoc_dirs},
            exclude => [ $self->file_qr('\.bat$') ] 
        );

        return unless keys %$files;

        my $mandir = File::Spec->catdir( $self->blib, 'bindoc' );
        File::Path::mkpath( $mandir, 0, oct(777) );

        require Pod::Man;

        foreach my $file (keys %$files) {

            # Pod::Simple based parsers only support one document per instance.
            # This is expected to change in a future version 
            # (Pod::Simple > 3.03).

            # binaries go in section 1p

            my $parser  = Pod::Man->new( section => '1p' ); 
            my $manpage = $self->man1page_name( $file ) . '.' .
                $self->config( 'man1ext' );

            my $outfile = File::Spec->catfile($mandir, $manpage);

            next if $self->up_to_date( $file, $outfile );

            $self->log_verbose("Manifying $file -> $outfile\n");

            eval { $parser->parse_from_file( $file, $outfile ); 1 }
                 or $self->log_warn("Error creating '$outfile': $@\n");
          
            $files->{$file} = $outfile;

        }

    }

    # set up directory structure and user/group accounts

    sub ACTION_post_install {
        my $self = shift;

        # create xas owner/group

        unless ($^O eq 'MSWin32') {

            unless (getpwnam('xas')) {

                system("groupadd -f -r xas");
                system("useradd -r -g xas -d /var/lib/xas -s /sbin/nologin -c \"XAS\" xas");

            }

            # using the standard filesystem layout

            system("mkdir /etc/xas")       unless ( -e '/etc/xas');
            system("mkdir /var/lock/xas")  unless ( -e '/var/lock/xas');
            system("mkdir /var/log/xas")   unless ( -e '/var/log/xas');
            system("mkdir /var/lib/xas")   unless ( -e '/var/lib/xas');
            system("mkdir /var/run/xas")   unless ( -e '/var/run/xas');
            system("mkdir /var/spool/xas") unless ( -e '/var/spool/xas');

            # create some spool directories

            system("mkdir /var/spool/xas/alerts") unless ( -e '/var/spool/xas/alerts');
            system("mkdir /var/spool/xas/logs")   unless ( -e '/var/spool/xas/logs');

            # set ownership/permissions on the files/directories

            system("chown -R xas:xas  /var/log/xas");
            system("chown -R xas:xas  /var/lib/xas");
            system("chown -R xas:xas  /var/run/xas");
            system("chown -R xas:xas  /var/spool/xas");
            system("chown -R xas:xas  /var/lock/xas");

            system("chmod 0775 /var/log/xas");
            system("chmod 0775 /var/lib/xas");
            system("chmod 0775 /var/run/xas");
            system("chmod 0775 /var/spool/xas");
            system("chmod 0775 /var/lock/xas");
            system("chmod 0775 /var/spool/xas/alerts");
            system("chmod 0775 /var/spool/xas/logs");

            system("chmod g+s /var/log/xas");
            system("chmod g+s /var/lib/xas");
            system("chmod g+s /var/run/xas");
            system("chmod g+s /var/lock/xas");
            system("chmod g+s /var/spool/xas");
            system("chmod g+s /var/spool/xas/alerts");
            system("chmod g+s /var/spool/xas/logs");

        } else {

            my $dir;
            my $base = defined($ENV{'XAS_ROOT'}) ? $ENV{'XAS_ROOT'} : 'C:\\xas';

            $dir = catdir($base, 'tmp');
            system("mkdir $dir") unless ( -e $dir);

            $dir = catdir($base, 'var');
            system("mkdir $dir") unless ( -e $dir);

            $dir = catdir($base, 'var', 'log');
            system("mkdir $dir") unless ( -e $dir);

            $dir = catdir($base, 'var', 'lock');
            system("mkdir $dir") unless ( -e $dir);

            $dir = catdir($base, 'var', 'run');
            system("mkdir $dir") unless ( -e $dir);

            $dir = catdir($base, 'var', 'lib');
            system("mkdir $dir") unless ( -e $dir);

            $dir = catdir($base, 'var', 'spool');
            system("mkdir $dir") unless ( -e $dir);

            $dir = catdir($base, 'var', 'spool', 'alerts');
            system("mkdir $dir") unless ( -e $dir);

            $dir = catdir($base, 'var', 'spool', 'logs');
            system("mkdir $dir") unless ( -e $dir);

        }

        return $self;

    }

    # remove redhat stuff when installing to debian

    sub ACTION_debian {
        my $self = shift;

        # cleanup the profile.d directory

        my $destdir = $self->destdir;
        my @files = ('xas.bat'); 
        my @names = map { catfile($destdir, 'etc', 'profile.d', $_) } @files;

        foreach my $file (@names) {

            unlink $file if (-e $file);

        }

    }

    # remove debian stuff when installing to redhat

    sub ACTION_redhat {
        my $self = shift;

        # cleanup the profile.d directory

        my $destdir = $self->destdir;
        my @files = ('xas.bat'); 
        my @names = map { catfile($destdir, 'etc', 'profile.d', $_) } @files;

        foreach my $file (@names) {

            unlink $file if (-e $file);

        }

    }

    # correctly process additional directories

    sub process_etc_files {
        my $self = shift;

        my $result;
        my $dir = catfile('blib', 'etc');
        my $files = $self->find_etc_files;

        mkdir $dir unless (-e $dir);

        while (my ($from, $to) = each %$files) {

            $to = catfile('blib', $to);
            $result = $self->copy_if_modified(from => $from, to => $to);

        }

        return $self;

    }

    # correctly process additional directories

    sub process_sbin_files {
        my $self = shift;

        my $result;
        my $dir = catfile('blib', 'sbin');
        my $files = $self->find_sbin_files;

        mkdir $dir unless (-e $dir);

        while (my ($from, $to) = each %$files) {

            $to = catfile('blib', $to);
            $result = $self->copy_if_modified(from => $from, to => $to) or next;
            $self->fix_shebang_line($result) unless $self->is_vmsish;
            $self->make_executable($result);

        }

        $self->manify_sbin_pods();

        return $self;

    }

    sub process_initd_files {
        my $self = shift;

        my $result;
        my $dir = catfile('blib', 'init.d');
        my $files = $self->find_initd_files;

        mkdir $dir unless (-e $dir);

        while (my ($from, $to) = each %$files) {

            $to = catfile('blib', $to);
            $result = $self->copy_if_modified(from => $from, to => $to) or next;
            $self->make_executable($from);

        }

        return $self;

    }

    sub process_sysconf_files {
        my $self = shift;

        my $result;
        my $dir = catfile('blib', 'sysconfig');
        my $files = $self->find_sysconf_files;

        mkdir $dir unless (-e $dir);

        while (my ($from, $to) = each %$files) {

            $to = catfile('blib', $to);
            $result = $self->copy_if_modified(from => $from, to => $to);

        }

        return $self;

    }

    sub process_profiled_files {
        my $self = shift;

        my $result;
        my $dir = catfile('blib', 'profile.d');
        my $files = $self->find_profiled_files;

        mkdir $dir unless (-e $dir);

        while (my ($from, $to) = each %$files) {

            $to = catfile('blib', $to);
            $result = $self->copy_if_modified(from => $from, to => $to) or next;
            $self->make_executable($result);

        }

        return $self;

    }

    sub process_logrotated_files {
        my $self = shift;

        my $result;
        my $dir = catfile('blib', 'logrotate.d');
        my $files = $self->find_logrotated_files;

        mkdir $dir unless (-e $dir);

        while (my ($from, $to) = each %$files) {

            $to = catfile('blib', $to);
            $result = $self->copy_if_modified(from => $from, to => $to);

        }

        return $self;

    }

    sub find_etc_files { shift->find_all_files_no_svn('etc'); }
    sub find_sbin_files { shift->find_all_files_no_svn('sbin'); }
    sub find_initd_files { shift->find_all_files_no_svn('init.d'); }
    sub find_sysconf_files { shift->find_all_files_no_svn('sysconfig'); }
    sub find_profiled_files { shift->find_all_files_no_svn('profile.d'); }
    sub find_logrotated_files { shift->find_all_files_no_svn('logrotate.d'); }

    sub find_all_files_no_svn {
        my ($self, $dir) = @_;

        my $sub = sub {
            return 1 if (($File::Find::dir !~ /SVN/i or 
                          $File::Find::Dir !~ /GIT/i) and 
                         -f $File::Find::name);
        };

        return { map {$_, $_} @{ $self->rscan_dir($dir, $sub) } };

    }

    # fix for when scm files are in the script directory

    sub _files_in {
        my ($self, $dir) = @_;
        return unless -d $dir;

        local *DH;
        opendir DH, $dir or die "Can't read directory $dir: $!";

        my @files;
        while (defined (my $file = readdir DH)) {
           my $full_path = File::Spec->catfile($dir, $file);
           next if -d $full_path;
           next if (($file =~ /SVN/i) or ($file =~ /GIT/i));
           push @files, $full_path;
       }
       return @files;
    }
EOC

my $builder = $class->new(
    module_name         => 'XAS',
    license             => 'artistic_2',
    dist_author         => q{Kevin L. Esteb <kevin@kesteb.us>},
    dist_version_from   => 'lib/XAS.pm',
    release_status      => 'stable',
    configure_requires => {
        'Module::Build' => 0,
    },
    build_requires => {
        'Test::More' => 0,
    },
    meta_add => {
        resources => {
            homepage   => 'http://scm.kesteb.us/trac',
            repository => 'http://scm.kesteb.us/git/XAS',
        },
    },
    requires           => $requires,
    add_to_cleanup     => [ 'XAS-*' ],
    create_makefile_pl => 'traditional',
    install_path       => $install_path,
);

$builder->add_build_element('profiled');
$builder->add_build_element('msg');
$builder->add_build_element('etc');

$builder->create_build_script();

