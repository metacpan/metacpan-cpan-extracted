package VIM::Packager::Installer;
use warnings;
use strict;
use File::Spec;
use File::Path;
use File::Copy;
use Exporter::Lite;
use YAML;
use VIM::Packager::Utils qw(vim_rtp_home vim_inst_record_dir findbin);
use LWP::UserAgent;
use VIM::Packager::Record;
use VIM::Packager::MetaReader;
use Carp;
use FileHandle;

our @EXPORT = ();
our @EXPORT_OK = qw(
        install_deps 
        install 
        install_deps_remote 
        install_deps_from_git 
        uninstall
        bump_version
        );


# FIXME:  install deps from vim script archive network.


=head2 install_deps_from_git

    install dependencies from repository. e.g. repositories on github.com 

=cut

sub install_deps_from_git {
    my $clone_path = shift @ARGV;
    my $version_required = shift @ARGV;

    require VIM::Packager::MakeMaker;
    require VIM::Packager::Git;
    my $g = VIM::Packager::Git->new;
    $g->clone( $clone_path );

    # convert meta to makefile
    my $maker = VIM::Packager::MakeMaker->new;

    my $system = "make";
    my $stderr = $^O eq "MSWin32" ? "" : " 2>&1 ";

    my $pipe = FileHandle->new("$system install $stderr |") 
        || Carp::croak("Can't execute $system: $!");

    my $makeout = "";
    while (<$pipe>) {
        print $_; # intentionally NOT use Frontend->myprint because it
                  # looks irritating when we markup in color what we
                  # just pass through from an external program
        $makeout .= $_;
    }  
    $pipe->close;

    $g->cleanup();
}

=head2 install_deps

    install dependencies from VSAN.

    XXX: implement me.

=cut

sub install_deps {
    my $deps = shift @ARGV;
    my @pkgs = split /,/,$deps;
    # use Data::Dumper;warn Dumper( \@pkgs );
    die 'please implement me!!!';

    # * foreach dependency

    # * retreive vimscript tarball

    # * untar to build directory

    # * change directory to build directory

    # * read package meta file

    # * check dependency

    # * install dependencies

    # * call VIM::Pacakger::Installer to install files

}

our $VERBOSE = $ENV{VERBOSE} ? 1 : 0;

=head2 install_deps_remote


=cut

# XXX: give all dependency pkgnames in one time
sub install_deps_remote {
    my $pkgname = shift @ARGV;
    my %install = @ARGV;

    print sprintf( "Installing dependencies: %s\n",  $pkgname);

    $|++;
    while( my ($target,$from) = each %install ) {

        # XXX: we might need to expand Makefile macro to support such things like:
        #    $(VIM_BASEDIR)/path/to/
        # see VIM::Packager::MakeMaker
        # XXX: we should compare the installed file and the downloaded file.
        $target = File::Spec->join( vim_rtp_home() , $target );

        print "Downloading $from " ;
        print " to " . $target if $VERBOSE;
        print "...";

        {
            my ($v,$dir,$file) = File::Spec->splitpath( $target );
            File::Path::mkpath [ $dir ] unless -e $dir;
        }

        my $ua = LWP::UserAgent->new;
        $ua->timeout( 10 );
        $ua->env_proxy();

        my $content;
        my $response = $ua->get( $from );
        if( $response->is_success ) {
            $content = $response->decoded_content;


            print "[ OK ]\n";
        }
        else {
            print "[ FAIL ]\n";
            print $response->status_line;
        }

        # XXX: try to get the last modified time

        # if target exists , then we should do a diff
        if ( $content and -e $target ) {
            my @src = split /\n/,$content;

            open FH_T , "<", $target;
            my @target = <FH_T>;
            close FH_T;

            chomp @target;
            chomp @src;

            my $diff = diff_base_install( \@src , \@target );
            if ( $diff ) {
                my $ans = prompt_for_different( $target );
                while( $ans =~ /d/i ) {
                    print "Diff:\n";
                    print $diff;
                    $ans = prompt_for_different( $target );
                }
                if( $ans =~ /r/i ) {
                    # do replace
                    open RH,">",$target;
                    print RH join("\n",@src);
                    close RH;
                    print "$target replaced\n";
                }
                elsif ( $ans =~ /s/i ) {
                    # do nothing
                    print "Skipped\n";
                }
            }
        }
        elsif ( $content and ! -e $target ) {
            open RH,">",$target;
            print RH $content;
            close RH;
            print "$target installed\n";
        }


    }
}


=head2 prompt_for_different

=cut

sub prompt_for_different {
    my $target = shift;
    print "Installed script version not found. instead , we found the installed script file.\n";
    print "The installed vim script file is different from which you just downloaded.\n";
    print "Which is: $target.\n";
    print "(Replace(r) / Diff(d) / Merge(m) / Skip(s) ) it with the remote one ? ";
    my $ans = <STDIN>;
    chomp $ans;
    return $ans;
}


=head2 diff_base_install ArrayRef:From , ArrayRef:To

diff text

=cut

sub diff_base_install {
    my ($src_lines,$to_lines) = @_;
    require Algorithm::Diff;

    my $diff = Algorithm::Diff->new( $src_lines , $to_lines );
    $diff->Base(1);
    
    my $result = "";
    while(  $diff->Next()  ) {
        next   if  $diff->Same();

        my $sep = '';

        if(  ! $diff->Items(2)  ) {
            $result .= sprintf "%d,%dd%d\n", $diff->Get(qw( Min1 Max1 Max2 ));
        } 
        elsif(  ! $diff->Items(1)  ) {
            $result .= sprintf "%da%d,%d\n", $diff->Get(qw( Max1 Min2 Max2 ));
        } 
        else {
            $sep = "---\n";
            $result .= sprintf "%d,%dc%d,%d\n", $diff->Get(qw( Min1 Max1 Min2 Max2 ));
        }  
        $result .= "< $_\n"   for  $diff->Items(1);
        $result .= $sep;
        $result .= "> $_\n"   for  $diff->Items(2);
    }

    return $result ? $result : undef;
}



=head2 install $pkgname %install_files

install package vimlib files

%install_file is a hash, which key is source file , value is target path of installation.

=cut

sub install {
    my $pkgname = shift @ARGV;
    my %install_to = @ARGV;

    my $meta = VIM::Packager::MetaReader->new->read_metafile();

    # we should check more details on those files which are going to be
    #      installed.
    my $found_record = VIM::Packager::Record::find( $pkgname );
    if( $found_record and -e $found_record ) {
        my $r = VIM::Packager::Record::read( $found_record );
        my $version = $r->{meta}->{version};
        printf "Found installed package: %s v%s\n" , $pkgname , $version ;

        # uninstall older version
        if( $version < $meta->{version} ) {
            print "We require version up to " . $meta->{version} . "\n";
            print "Uninstalling $pkgname v$version\n";
            for my $f ( @{ $r->{files} } ) {
                if( -e $f ) {
                    print "Removing $f\n";
                    unlink $f;
                }
                else {
                    print "Warning: Can not found file $f\n";
                }
            }
        }
        else {
            print "Package $pkgname has been installed. Skipped.\n";
            print "run \$ make uninstall before make install if you need to reinstall it\n";
            return;
        }
    }

    print "Installing $pkgname " . $meta->{version} . "\n";
    while( my ($from,$to) = each %install_to ){
        my ( $v, $dir, $file ) = File::Spec->splitpath($to);

        print("$from doesnt exist.\n"),next unless -e $from;

        File::Path::mkpath [ $dir ] unless -e $dir ;

        if( -e $to ) {
            my $mtime_to = (stat($to))[9];
            my $mtime_from = (stat($from))[9];

            if ( $mtime_from > $mtime_to ) {
                File::Copy::copy( $from , $to );
                print STDOUT "Installing $from => $to \n";
            }
            else {
                print STDOUT "Skip $from\n";
            }
        }
        else {
            File::Copy::copy( $from , $to );
            print STDOUT "Installing $from => $to \n";
        }
    }

    my @files = values %install_to;

    print STDERR "Making checksum...\n";
    my @e = Vimana::Record->mk_file_digests( @files );
    use Vimana::Record;
    Vimana::Record->add( {
            version => 0.2,    # record spec version
            generated_by => 'VIM-Packager' . $Vimana::VERSION,
            install_type => 'meta',    # auto , make , rake ... etc
            package => $pkgname,
            files => \@e,
            meta => $meta,
    } );

    print "Updating doc tags\n";
    system(qq|vim -c ':helptags \$VIMRUNTIME/doc'  -c q |);
    print "Done\n";
}


=head2 uninstall [pkgname]

=cut

sub uninstall {
    my $pkgname = shift @ARGV;
    my $f = VIM::Packager::Record::find( $pkgname );

    unless( $f and -e $f ) {
        print "Can not found record of $pkgname\n";
        return ;
    }

    my $r = YAML::LoadFile( $f );
    my @files = @{ $r->{files} };

    for ( @files ) {
        print "Removing $_\n";
        if( ! -e $_ ) {
            print "Warning: can not found file $_.\n";
            next;
        }
        unlink $_;
    }

    print "Removing record $pkgname\n";
    unlink $f;
}


=head2 bump_version

you can export VIMPACKAGE_AUTO_COMMIT to do auto commit after version bumpped.

    export VIMPACKAGE_AUTO_COMMIT=1

=cut

sub bump_version {
    my $meta = VIM::Packager::MetaReader->new->read_metafile();
    my $previous_ver = $meta->{version};
    my $version = $previous_ver + 0.01;

    my $file = $meta->{version_from};
    if( -e $file ) {
        open FH , "<" , $file;
        my @lines = <FH>;
        close FH;

        my $found;
        for ( @lines ) {
            if( /^"=?\s*Version:?\s+$previous_ver/i ) {
                $found++;
                print "Version tag found: $_";
                $_ = qq{" Version: $version\n};
            }
        }

        open FH , ">" , $file;
        print FH @lines;
        close FH;

        if( $ENV{VIMPACKAGE_AUTO_COMMIT} and -e '.git' and $found ) {
            # found git repository
            print "Found .git directory\n";
            print "Do auto-commit\n";
            my $git = qx{which git};
            chomp $git;
            qx{$git commit $file -m"Bump version to $version."};
        }

        print "Version bumped to $version\n";
        print "Done.\n";
    }
}

1;
