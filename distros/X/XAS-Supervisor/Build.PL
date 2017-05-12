use strict;
use warnings FATAL => 'all';
use Module::Build;

my $requires = {
    'XAS' => '0.12',
};
    
my $sysconfig = ( -e '/etc/default' ) ? '/etc/default' : '/etc/sysconfig';
my $install_path = {
    etc           => '/etc/xas',
    sbin          => '/usr/sbin',
    script        => '/usr/bin',
    sysconfig     => $sysconfig,
    'init.d'      => '/etc/init.d',
    'profile.d'   => '/etc/profile.d',
    'logrotate.d' => '/etc/logrotate.d'
};

if ($^O eq 'MSWin32') {

    my $path = defined($ENV{XAS_ROOT}) ? $ENV{XAS_ROOT} : 'C:\\xas';

    my $install_path = {
        etc           => $path . '\\etc',
        sbin          => $path . '\\sbin',
        script        => $path . '\\bin',
        sysconfig     => $path . '\\etc\\sysconfig',
        'init.d'      => $path . '\\etc\\init.d',
        'profile.d'   => $path . '\\etc\\profile.d',
        'logrotate.d' => $path . '\\etc\\logrotate.d'
    };

}

my $class = Module::Build->subclass(code => <<'EOC');

    use strict;
    use warnings;

    use IO::File;
    use File::Copy;
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

    # remove redhat stuff when installing to debian

    sub ACTION_debian {
        my $self = shift;

        # cleanup the init.d directory

        my $destdir = $self->destdir;
        my @files = ('xas-spooler', 'xas-collector-alerts', 'xas-collector-logstash'); 
        my @names = map { catfile($destdir, 'etc', 'init.d', $_ . '.rhel') } @files;

        foreach my $file (@names) {

            unlink $file if (-e $file);

        }

        @names = map { catfile($destdir, 'etc', 'init.d', $_ . '.debian') } @files;

        foreach my $file (@names) {

            if ( -e $file) {

                my ($name, $path, $ext) = fileparse($file, qr/\.[^.]*/);
                my $new = catfile($path, $name);

                move($file, $new);

            }

        }

    }

    # remove debian stuff when installing to redhat

    sub ACTION_redhat {
        my $self = shift;

        # cleanup the init.d directory

        my $destdir = $self->destdir;
        my @files = ('xas-spooler', 'xas-collector-alerts', 'xas-collector-logstash'); 
        my @names = map { catfile($destdir, 'etc',  'init.d', $_ . '.debian') } @files;

        foreach my $file (@names) {

            unlink $file if (-e $file);

        }

        @names = map { catfile($destdir, 'etc', 'init.d', $_ . '.rhel') } @files;

        foreach my $file (@names) {

            if ( -e $file) {

                my ($name, $path, $ext) = fileparse($file, qr/\.[^.]*/);
                my $new = catfile($path, $name);

                move($file, $new);

            }

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
            $self->make_executable($result);

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

    sub find_etc_files { shift->find_all_files_no_scm('etc'); }
    sub find_sbin_files { shift->find_all_files_no_scm('sbin'); }
    sub find_initd_files { shift->find_all_files_no_scm('init.d'); }
    sub find_sysconf_files { shift->find_all_files_no_scm('sysconfig'); }
    sub find_profiled_files { shift->find_all_files_no_scm('profile.d'); }
    sub find_logrotated_files { shift->find_all_files_no_scm('logrotate.d'); }

    sub find_all_files_no_scm {
        my ($self, $dir) = @_;

        my $sub = sub {
            return ((($File::Find::name !~ /SVN/i)  and
                     ($File::Find::name !~ /GIT/i)) and
                    ( -f $File::Find::name));
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
    module_name         => 'XAS-Supervisor',
    license             => 'perl',
    dist_author         => q{Kevin L. Esteb <kevin@kesteb.us>},
    dist_version_from   => 'lib/XAS/Supervisor.pm',
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
            repository => 'http://scm.kesteb.us/git/XAS-Supervisor',
        },
    },
    add_to_cleanup     => [ 'XAS-Supervisor-*' ],
    create_makefile_pl => 'traditional',
    install_path       => $install_path,
    requires           => $requires
);

$builder->add_build_element('etc');
$builder->add_build_element('msg');
$builder->add_build_element('sbin');
$builder->add_build_element('initd');
$builder->add_build_element('sysconf');
$builder->add_build_element('logrotated');

$builder->create_build_script();

