package VIM::Packager::MakeMaker;
use warnings;
use strict;

use VIM::Packager;
use VIM::Packager::MetaReader;
use VIM::Packager::Utils qw(vim_rtp_home vim_inst_record_dir findbin);
use DateTime::Format::DateParse;
use YAML;
use File::Spec;
use File::Path;
use File::Find;
use VIM::Packager::Record;

our $VERSION = 0.0.1;
my  $VERBOSE = 1;

=head1 SYNOPSIS

    $ vim-packager build 
    $ make -f Makefile.vimp

        # auto install dependency 
    $ make install -f Makefile.vimp

=head1 Constants

LIBPATH: F<vimlib/>

=cut

use constant {
    LIBPATH  => 'vimlib',
};

=head1 Makefile Helper Functions

=head2 multi_line Array:Lines

=head2 add_macro  ArrayRef:Makefile Lines , String: Macro Name , String: Macro 

=head2 new_section ArrayRef:Makefile Lines , String: Section Name , Array: Depended macro names

=head2 add_st ArrayRef:Makefile Lines , String: Statement , Array: Statement Arguments

Statement Arguments is for Statement string, which is in sprintf format.

=head2 add_noop_st ArrayRef:Makefile Lines

=cut

sub multi_line {
    my @items = @_;
    return join " \\\n\t", @items ;
}

sub add_macro  {
    my $ref = shift;
    my ( $name, $content ) = @_;
    push @{ $ref } , qq|$name = $content|;
}

sub new_section {
    my $ref = shift;
    my ( $name , @deps ) = @_;
    push @{ $ref } , qq|| , qq|$name : | . join( " ", @deps );
}

sub add_st {
    my ($ref, $st , @args ) = @_;
    push @{ $ref } , qq|\t\t| . sprintf($st , @args);
}

sub add_noop_st {
	add_st $_[0] => q|$(NOECHO) $(NOOP)|;
}

=head1 Main Functions

=head2 new

=cut

sub new { 
    my $class = shift;
    my $cmd = shift;  # command object

    my $self = bless {}, $class;
    my $meta = VIM::Packager::MetaReader->new->read_metafile();

    $self->{cmd} = $cmd;

    YAML::DumpFile( "VIMMETA.yml" , $meta );

    $self->meta( $meta ); # save meta object

    my $makefile = {};
    $makefile->{meta} = $meta;

    {
        my $info = vim_version_info();

        my $op = $meta->{vim_version}->{op} ;
        my $version = $meta->{vim_version}->{version} ;

        my $installed_vim_version = $info->{version};

        print STDOUT "Found installed VIM, version $installed_vim_version\n";

        unless( eval "$installed_vim_version $op $version" ) {
            print STDOUT "This distrubution needs a newer vim ( $version )\n";
            die;
        }
    }

    print STDOUT "VIM::Packager::MakeMaker (v$VERSION)\n" if $VERBOSE;
    if (-f "MANIFEST" && ! -f "Makefile"){
        check_manifest();
    }

    my $main = [ ];

    push @$main, q|.PHONY: all install clean uninstall help upload link|;
    
    my $filelist = $self->make_filelist( $meta->{libpath} || LIBPATH );

    $makefile->{filelist} = $filelist;

    my @meta_section   = $self->meta_section( $meta );
    my @config_section = $self->config_section();
    my @file_section   = $self->file_section( $filelist );

    $self->section_all( $main );
    $self->section_install( $main );

    # main install section
    $self->section_pure_install( $main , $makefile );

    # dependency section
    $self->section_deps( $main );
    $self->section_link( $main , $filelist );

    new_section $main => 'manifest';
    add_st $main => q|$(NOECHO) $(ECHO) ".git" > MANIFEST.SKIP|;
    add_st $main => q|$(NOECHO) $(ECHO) ".svn" >> MANIFEST.SKIP|;
    add_st $main => q|$(NOECHO) $(ECHO) ".*.tar.gz" >> MANIFEST.SKIP|;
    add_st $main => q|$(FULLPERL) $(PERLFLAGS) -MVIM::Packager::Manifest=mkmanifest -e 'mkmanifest'|;

    new_section $main => 'dist' , qw(manifest);
    add_st $main => q|$(TAR) $(TARFLAGS) $(DISTNAME).tar.gz $(TO_INST_VIMS) $(META_FILE) $(README) `cat MANIFEST`|;
	add_noop_st $main;

    new_section $main => 'help';
    add_st $main => q|perldoc VIM::Packager|;

    new_section $main => 'uninstall';
    add_st $main => q|$(NOECHO) $(FULLPERL) $(PERLFLAGS) -MVIM::Packager::Installer=uninstall  |
            . q| -e 'uninstall()' $(NAME)|;

    # XXX: prompt user to uninstall depedencies
    new_section $main => 'reinstall' , qw(uninstall install);
    add_noop_st $main;

    new_section $main => 'upload' , qw(dist);
    add_st $main => q|$(FULLPERL) $(PERLFLAGS) -MVIM::Packager::Uploader=upload -e 'upload()' |
                . multi_line qw|$(PWD)/$(DISTNAME).tar.gz $(VIM_VERSION) $(VERSION) $(SCRIPT_ID)|;

    new_section $main => 'clean';
    add_st $main      => q|$(MV) $(FIRST_MAKEFILE) $(MAKEFILE_OLD)|;
    add_st $main      => q|$(RM) *.tar.gz|;

    new_section $main => 'bump';
    add_st $main => q|$(NOECHO) $(FULLPERL) $(PERLFLAGS) -MVIM::Packager::Installer=bump_version -e 'bump_version()' |;
    add_st $main => q|sh -c 'vim-packager build'|;  # rebuild
    add_st $main => q|sh -c 'make upload -f Makefile.vimp'|;

    new_section $main => 'release' , qw(bump);
    add_noop_st $main;

    $self->generate_makefile( [
            { meta   => \@meta_section },
            { config => \@config_section },
            { file   => \@file_section },
            { main   => $main } ] );
}

=head2 meta

return current meta object.

=cut

sub meta {
    my $self = shift;
    $self->{meta} = shift if @_;
    return $self->{meta};
}





=head2 section_all



=cut

sub section_all {
    my $self = shift;
    my $main = shift;
    new_section $main => "all" => qw(install-deps);
	add_noop_st $main;
}

=head2 section_install



=cut

sub section_install {
    my $self = shift;
    my $main = shift;
    new_section $main => "install" => qw(pure_install install-deps) ;
	add_noop_st $main;
}

=head2 section_pure_install



=cut

sub section_pure_install {
    my ($self,$main,$makefile) = @_;

    new_section $main => "pure_install";

    # pure makefile option let 
    # makefile doesnt depend on perl module.
    if ( $self->{cmd}->{pure} ) {
        print "Making pure makefile (not to depend on perl module)\n";

        my %files = %{ $makefile->{filelist} };
        
        while ( my ($from,$to) = each %files ) {
            add_st $main => sprintf( q|$(CP) %s %s| , $from , $to );
        }
    }
    else {
        add_st $main =>
            q|$(NOECHO) $(FULLPERL) $(PERLFLAGS) -MVIM::Packager::Installer=install|
            . q| -e 'install()' $(NAME) $(VIMS_TO_RUNT) $(BIN_TO_RUNT)|;
    }
}

=head2 section_deps



=cut

sub section_deps {
    my $self = shift;
    my $main = shift;

    new_section $main => "install-deps";

    if( $self->{cmd}->{pure} ) {
        print "You are making a pure makefile that doesn't depend on perl module.\n";
        print "We are going to skip dependency section.\n";
        add_noop_st $main;
        return;
    }

    my $requires = $self->check_dependency( $self->meta );
    my %unsatisfied      = %{ $requires->{unsat} };
    my %nonversion_unsat = %{ $requires->{nonversion_unsat} };

    # grep out the non-version package requires from those unsatisfied infomation
    # which is an array ref because it's a file list.
    my @pkgs_nonversion = keys %nonversion_unsat;
    for my $pkgname ( @pkgs_nonversion ) {
        my @nonversion_params = map {  ( $_->{target} , $_->{from} ) } 
            map { @{ $nonversion_unsat{ $_ } } } $pkgname ;

        add_st $main => multi_line q|$(NOECHO) $(FULLPERL) $(PERLFLAGS)|
                    . qq| -MVIM::Packager::Installer=install_deps_remote |
                    . qq| -e 'install_deps_remote()' $pkgname | 
                    , @nonversion_params ;

    }

    # XXX: grep git repo deps from upstream ... zzz
    # packages with version specified.
    my @pkgs_version = keys %unsatisfied;
    if( @pkgs_version > 0 ) {
        my @pkgs_git_repo = grep { $unsatisfied{ $_ }->{git_repo} } @pkgs_version;
        for my $pkg ( @pkgs_git_repo ) {
            my $dep = $unsatisfied{ $pkg };
            
            my $v = $dep->{version};
            add_st $main => q|$(NOECHO) $(FULLPERL) $(PERLFLAGS) -MVIM::Packager::Installer=install_deps_from_git |
                . qq| -e 'install_deps_from_git()' @{[ $dep->{git_repo} ]} $v|;
        }

        my @pkgs_version = grep { ! $unsatisfied{ $_ }->{git_repo} } @pkgs_version;
        
        add_st $main => q|$(NOECHO) $(FULLPERL) $(PERLFLAGS) -MVIM::Packager::Installer=install_deps  |
                . qq| -e 'install_deps()' '@{[ join ",",@pkgs_version ]}' |
                        if @pkgs_version > 0;
    }
}

=head2 section_link


=cut

sub section_link {
    my ($self,$main , $filelist) = @_;
    new_section $main => 'link';
    while( my ($src,$target) = each %$filelist ) {
        add_st $main => q|$(NOECHO) $(LN_S) | . File::Spec->join( '$(PWD)' , $src )  . " " .  $target;
    }
    new_section $main => 'link-force';
    while( my ($src,$target) = each %$filelist ) {
        add_st $main => q|$(NOECHO) $(LN_SF) | . File::Spec->join( '$(PWD)' , $src ) . " " .  $target;
    }

    new_section $main => 'unlink';
    while( my ($src,$target) = each %$filelist ) {
        add_st $main => q|$(NOECHO) $(RM) | . $target;
    }
}


sub generate_makefile {
    my $self = shift;
    my $sections = shift;
    

    print "Write to Makefile.vimp\n";

    open my $fh , ">" , 'Makefile.vimp';
    print $fh <<'END';
# VIM::Packager::MakeMaker
#
# This Makefile is generated by VIM::Packager::MakeMaker version $VERSION from
# the contents of META . don't edit this file, edit META file instead.
#
# Author: Cornelius
# Email : cornelius.howl@gmail.com
# 

END
    for my $s ( @$sections ) {
        my $n = (keys %$s)[0];
        my $list = $s->{$n};
        print $fh "\n" for ( 1 .. 3 );
        print $fh sprintf("# -------- %s section ------\n" , $n );
        print $fh join("\n", @$list );
        print $fh "\n" for ( 1 .. 2 );
    }
    close $fh;
    print "DONE\n";
}

sub meta_section {
    my $self = shift;
    my $meta = shift;
    my @section = ();
    map { add_macro \@section, uc($_) => $meta->{$_} } grep { ! ref $meta->{$_} } keys %$meta;

    my $distname = $meta->{name};
    $distname =~ tr/._/--/;
    $distname .= '-' . $meta->{version};
    add_macro \@section , DISTNAME => $distname;

    # XXX: op skipeed
    add_macro \@section , VIM_VERSION => $meta->{vim_version}->{version};

    return @section;
}

sub config_section {
    my $self = shift;

    my @section = ();

    my %configs = ();
    my %dir_configs = $self->init_vim_dir_macro();

    my $perl = find_perl();
    die "Can not found perl." unless $perl;

    $configs{FULLPERL}  ||= $perl;
    $configs{NOECHO}    ||= '@';
    $configs{TOUCH}     ||= 'touch';
    $configs{ECHO}      ||= 'echo';
    $configs{ECHO_N}    ||= 'echo -n';
    $configs{RM_F}      ||= "rm -vf";
    $configs{RM_RF}     ||= "rm -rf";
    $configs{TEST_F}    ||= "test -f";
    $configs{CP}        ||= "cp";
    $configs{MV}        ||= "mv";
    $configs{CHMOD}     ||= "chmod";
    $configs{FALSE}     ||= 'false';
    $configs{TRUE}      ||= 'true';
    $configs{NOOP}      ||= '$(TRUE)';
    $configs{LN_S}      ||= 'ln -sv';
    $configs{LN_SF}     ||= 'ln -svf';
    $configs{PWD}       ||= '`pwd`';
    $configs{CP}        ||= 'cp -v';

    $configs{README} ||= '';
    $configs{README} .= ' README'     if -e 'README';
    $configs{README} .= ' README.mkd' if -e 'README.mkd';

    $configs{META_FILE} ||= VIM::Packager::MetaReader->find_meta_file();

    $configs{FIRST_MAKEFILE} ||= 'Makefile';
    $configs{MAKEFILE_OLD}   ||= 'Makefile.old';

    $configs{TAR} ||= 'COPY_EXTENDED_ATTRIBUTES_DISABLE=1 COPYFILE_DISABLE=1 tar';
    $configs{TARFLAGS} ||= 'cvzf';

    $configs{PERLFLAGS} ||= ' -Ilib ';

    map { add_macro \@section, $_ => $configs{$_} } sort keys %configs;
    map { add_macro \@section, $_ => $dir_configs{$_} } sort keys %dir_configs;
    return @section;
}

sub file_section {
    my $self = shift;
    my $filelist = shift;
    my $meta = $self->meta;

    my @section  = ();

    my @to_install = keys %$filelist;

    add_macro \@section , VIMLIB => $meta->{libpath} || LIBPATH;

    add_macro \@section , VIMMETA => VIM::Packager::MetaReader::find_meta_file();

    add_macro \@section , TO_INST_VIMS => multi_line @to_install ;

    my @vims_to_runtime = %$filelist;
    add_macro \@section , VIMS_TO_RUNT => multi_line @vims_to_runtime ;

    my %bin_to_runtime = ();

    if( $meta->{script} ) {
        my @bin = @{ $meta->{script} };
        for (@bin) {
            my ( $v, $d, $f ) = File::Spec->splitpath($_);
            # $bin_to_runtime{ $_ } =  File::Spec->join( vim_rtp_home() , 'bin' , $f );
            $bin_to_runtime{$_} = File::Spec->join( '$(VIM_BASEDIR)', 'bin', $f );
        }
        add_macro \@section , TO_INST_BIN => multi_line keys %bin_to_runtime ;
        add_macro \@section , BIN_TO_RUNT => multi_line %bin_to_runtime ;
    }
    return @section;
}

=head2 get_installed_pkgs

=cut

sub get_installed_pkgs {
    my ($self, $dir ) = @_;

    unless( -e $dir ) {
        File::Path::mkpath [ $dir ];
        return ();
    }

    my @pkg_record_files = ();
    my $closure = sub { 
        my $file = $_;
        my $dir  = $File::Find::dir;

        return unless -f $file;

        my $path = File::Spec->join($dir , $file );
        push @pkg_record_files , $path;
    };

    File::Find::find( \&$closure ,$dir );
    return @pkg_record_files;
}



=head2 check_dependency

pass meta object and check dependency.

=cut

sub check_dependency {
    my $self = shift;
    my $meta = shift;

    my $record_dir  = $self->vim_inst_record_dir();
    my @pkg_records = $self->get_installed_pkgs($record_dir);

    my %unsatisfied = ();
    my %nonversion_unsat = ();

    for my $dep ( @{ $meta->{dependency} } ) {

        if ( defined $dep->{version} ) {
            my ( $prereq, $required_version, $version_op , $git_repo ) 
                        = @$dep{qw(name version op git_repo)};

            # XXX: check if prerequire plugin is installed. 
            #      try to get installed package record 
            #      or just look into file and parse the version
            my $pr_version = undef ;

            my $found = VIM::Packager::Record->find( $prereq );
            if( $found ) {
                my $r = VIM::Packager::Record->read( $found );
                $pr_version = $r->{meta}->{version};
                print "Found Installed Package: $prereq \n";
                print "Version: $pr_version\n";
            }
            else {
                my $installed_files; # get installed files here
                $pr_version = parse_version( $installed_files ) if( $installed_files );
            }

            if( ! $pr_version ) {
                warn sprintf "Warning: prerequisite %s - %s not found.\n", 
                    $prereq, $required_version;
                $unsatisfied{ $prereq } = $dep;
            }
            elsif ( eval "$pr_version $version_op $required_version"  ) {
                warn sprintf "Warning: prerequisite %s - %s not found. We have %s.\n",
                    $prereq, $required_version, $pr_version;

                $unsatisfied{ $prereq } = $dep;
            }

        }
        else {
            # if we can not detect installed package version
            # here is the other way to install dependencies.
            my ( $prereq , $require_files ) = ( $dep->{name}  , $dep->{required_files} );
            $nonversion_unsat{ $prereq } = $require_files; 

            # XXX: grep out ?
            for ( @$require_files ) {
                # XXX: expand Makefile variable to support such things like:
                #    $(VIM_BASEDIR)/path/to/
                my $target_path =  File::Spec->join( vim_rtp_home() , $_->{target} ) ;

                unless( -e $target_path ) {
                    warn sprintf "Warning: prerequisite %s - %s not found.\n\tWill be retreived from %s\n", 
                            $prereq , $target_path , $_->{from} ;
                }
                else {
                    printf "[ %s : %s ] ....  OK\n" , $prereq , $_->{target} ;
                }
            }
        }

    }

    return {
        unsat => \%unsatisfied,
        nonversion_unsat => \%nonversion_unsat,
    };
}

sub possible_runtime_dir { qw(autoload after syntax ftplugin ftdetect compiler plugin macros colors doc) }

=head2 init_vim_dir_macro

init vim dir macro

=cut

sub init_vim_dir_macro {
    my $self = shift;
    my %dir_configs = ();
    $dir_configs{ VIM_BASEDIR } = $ENV{VIM_BASEDIR} || vim_rtp_home();
    $dir_configs{ VIM_AFTERBASE_DIR} = $ENV{VIM_AFTERBASE_DIR}  || File::Spec->join( $dir_configs{VIM_BASEDIR} , 'after' );

    for my $sub ( possible_runtime_dir() ) {
        my $path_name = 'VIM_' . uc($sub) . '_DIR';
        my $after_path_name = 'VIM_AFTER_' . uc($sub) . '_DIR';
        $dir_configs{$path_name} = $ENV{$path_name}
            || File::Spec->join( $dir_configs{VIM_BASEDIR}, $sub );

        $dir_configs{$after_path_name} = $ENV{$after_path_name}
            || File::Spec->join( $dir_configs{VIM_BASEDIR}, $sub );
    }
    return %dir_configs;
}


=head2 make_filelist

if install_dirs is given , then we should record:

    autoload/zzz.vim
    plugin/xxx.vim

if not , then we should find files from F<vimlib/>

    TO_INSTALL=$(VIM_BASEDIR)/plugin/xxx.vim
        \ $(VIM_BASEDIR)/autoload/zzz.vim

=cut

sub make_filelist {
    my ( $self, $base_prefix ) = @_;

    my %install = ();

    # my $prefix = File::Spec->join($ENV{HOME} , '.vim');
    my $prefix = '$(VIM_BASEDIR)';

    my @search_dir = ( ( $base_prefix eq '.' or $base_prefix eq './' ) 
                ?  possible_runtime_dir()
                :  $base_prefix );
    

    File::Find::find( sub {
        return unless -f $_;
        return if /\#/;
        return if /~$/;             # emacs temp files
        return if /,v$/;            # RCS files
        return if /\.(git|svn)/;          # skip .git
        return if m{\.swp$};        # vim swap files

        my $src = File::Spec->catfile( $File::Find::dir , $_ );

        my $target;
        ( $target = $src ) =~ s{^$base_prefix/}{};
        $target = File::Spec->catfile( $prefix , $target );

        $install{ $src } = $target;
        print "Added $src to file list\n";
    } , grep { -e $_ } @search_dir );
    return \%install;
}


# XXX:
# parse version from vim runtime path files
# neeed to find a way to do it
sub parse_version {

}

sub vim_version_info {

    # check_vim_version 
    my $where_is_vim = findbin('vim');
    unless( $where_is_vim ) {
        print STDOUT "It seems you dont have vim installed.";
        die;
    }

    my $version_output = qx{$where_is_vim --version};
    my @lines = split /\n/, $version_output;

    my ( $version, $date_string )
        = $lines[ 0 ] =~ /^VIM - Vi IMproved ([0-9.]+) \((.*?)\)/;

    my ( $revision_date, $compiled_time ) = split /,/, $date_string;

    $compiled_time =~ s/\s*compiled\s*//;
    $compiled_time = DateTime::Format::DateParse->parse_datetime($compiled_time);

    my ($platform) = $lines[ 1 ] =~ /^(.*?) version/;

    # Included patches: 1-264
    my ( $patch_from, $patch_to )
        = $lines[ 2 ] =~ /^Included patches: (\d+)-(\d+)$/;

    # Compiled by [who]
    my ($compiled_by) = $lines[ 3 ] =~ /^Compiled by (.*?)$/;

    return {
        version     => $version,
        platform    => $platform,
        compiled_on => $compiled_time,
        patch_from  => $patch_from,
        patch_to    => $patch_to,
        compiled_by => $compiled_by
    };
}

sub check_manifest {
    print STDOUT "Checking if your kit is complete...\n";
    require ExtUtils::Manifest;
    # avoid warning
    $ExtUtils::Manifest::Quiet = $ExtUtils::Manifest::Quiet = 1;
    my(@missed) = ExtUtils::Manifest::manicheck();
    if (@missed) {
        print STDOUT "Warning: the following files are missing in your kit:\n";
        print "\t", join "\n\t", @missed;
        print STDOUT "\n";
        print STDOUT "Please inform the author.\n";
    } else {
        print STDOUT "Looks good\n";
    }
}

sub prompt ($;$) {  ## no critic
    my($mess, $def) = @_;
    Carp::confess("prompt function called without an argument") 
        unless defined $mess;

    my $isa_tty = -t STDIN && (-t STDOUT || !(-f STDOUT || -c STDOUT)) ;

    my $dispdef = defined $def ? "[$def] " : " ";
    $def = defined $def ? $def : "";

    local $|=1;
    local $\;
    print "$mess $dispdef";

    my $ans;
    if ($ENV{PERL_MM_USE_DEFAULT} || (!$isa_tty && eof STDIN)) {
        print "$def\n";
    }
    else {
        $ans = <STDIN>;
        if( defined $ans ) {
            chomp $ans;
        }
        else { # user hit ctrl-D
            print "\n";
        }
    }

    return (!defined $ans || $ans eq '') ? $def : $ans;
}

use File::Spec;
sub find_perl {
    my @paths = split /:/,$ENV{PATH};
    my @names = qw(perl);
    for my $path ( @paths ) {
        for my $name ( @names ) {
            my $abspath = File::Spec->join( $path , $name );
            return $abspath if -e $abspath;
        }
    }
    return undef;
}


1;
