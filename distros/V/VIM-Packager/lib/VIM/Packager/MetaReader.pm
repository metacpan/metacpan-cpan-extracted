package VIM::Packager::MetaReader;
use warnings;
use strict;

use YAML;

sub trim_comment {
    my $c = shift;
    $c =~ s/#.*$//; # skip comment
    return $c;
}

sub trim {
    my $c = shift;
    $c =~ s/^\s*//;
    $c =~ s/\s*$//;
    return $c;
}



=head1 Synopsis

=head2 Generic VIM Meta file format

    =name            new_plugin

    =abstract        vim plugin blah blah blah

    =author          Cornelius (cornelius.howl@gmail.com)

    =version_from    plugin/new_plugin.vim   # extract version infomation from this file

    =type            syntax

    =script_id       [script id on vim.org]    # for uploading script to vim.org

    =dependency

        autocomplpop.vim > 0.3
        rainbow.vim      >= 1.2

        libperl.vim
            | autoload/libperl.vim | http://....../..././.../libperl.vim
            | autoload/std.vim | http://....../..././.../std.vim

        cpan.vim > 0
            git://github.com/c9s/cpan.vim.git  # install from git repository

    =libpath .

    =script

        bin/parser
        bin/template_generator

    =repository git://....../

=head1 Description

=head1 Constant

=head2 META_FILES

available metafile names: F<VIMMETA>, F<META>, F<VIMMETA.yml>

=cut

use constant META_FILES => [ 'VIMMETA','META','VIMMETA.yml'];

=head1 Functions

=head2 new

=cut

sub new { bless {} , shift }

=head2 meta



=cut

sub meta { my $self = shift; return $self->{meta} ||= {}; }

=head2 read_metafile

read_metafile function tries to find available vim meta file 
and parse meta file into hashref.

return meta information in hashref.

=cut

sub read_metafile {
    my $self = shift;
    # read meta_reader file

    my $file = $self->find_meta_file();
    die 'Can not found META file' unless -e $file;

    open my $fh , "<" , $file ;
    $self->read( $fh );
    close $fh;

    return $self->meta;
}

=head2 find_meta_file

find_meta_file function tries to find available vim meta file 

return the filename of vim meta file (string)

=cut

sub find_meta_file {
    my $files = META_FILES;
    for ( @$files ) {
        return $_ if -e $_;
    }
}



sub read {
    my $self = shift;

    my $fh = shift;

    my @lines = <$fh>;

    my $cur_section;
    my %sections = ();
    for ( @lines ) {
        chomp;
        $_ = trim trim_comment($_);
        next if blank($_);

        if( /^=(\w+)(?:\s+(.*?))?$/ ) {
            $cur_section = $1;
            $sections{$cur_section} = $2 if $2;
            next;
        }

        push @{ $sections{ $cur_section } } , $_;
    }


    for my $sec ( keys %sections ) {
        my $lines = $sections{ $sec };
        my $dispatch = '__' . $sec;
        if( $self->can( $dispatch ) )  {
            $self->$dispatch( $lines );
        }
        else {
            # print "Meta tag $sec is not supported. but we will still save to Makefile\n";
            $self->{meta}->{ $sec } = $lines;
        }

    }
=pod

    # XXX: check for mandatory meta info
    my $fall;
    my $meta = $class->meta;
    for ( qw(name author version type vim_version) ) {
        if( ! defined $meta->{ $_ } ) {
            print STDOUT "META: column '$_' is required. ";
            $fall = 1;
        }
    }
    die if $fall;
=cut

}

my $package_re = '[0-9a-zA-Z._-]+';


sub blank {
    my $c = shift;
    return $c =~ /^\s*$/;
}


sub _get_value {
    my $cur = shift;
    my ($v) = ( $cur =~ /^=\w+\s+(.*)$/ ) ;
    return $v;
}

sub __name {
    my ($self,$value) = @_;
    $self->meta->{name} =$value;
}

sub __email {
    my ($self,$value) = @_;
    $self->meta->{email} =$value;
}

sub __author {
    my ($self,$value) = @_;
    $self->meta->{author} =$value;
}

sub __version {
    my ($self,$value) = @_;
    $self->meta->{version} = $value;
}

sub __abstract {
    my ($self,$value) = @_;
    $self->meta->{abstract} =$value;
}

sub __type {
    my ($self,$value) = @_;
    $self->meta->{type} =$value;
}

sub __libpath {
    my ($self,$value) = @_;
    $self->meta->{libpath} =$value;
}

sub __version_from {
    my ($self,$version_file) = @_;

    $self->meta->{version_from} = $version_file;

    open FH, "<" , $version_file;
    my @lines = <FH>;
    close FH;
    
    for ( @lines ) {
        if( /^"=VERSION ([0-9.]+)$/ or /^"\s*Version:\s*([0-9.]+)$/i ) {
            $self->meta->{version} = $1;
            return;
        }
    }
    print "Warning: Can not found version, you should declare your version in your vim script.\n";
    print "For example \n";
    print " \" Version: 0.3 \n";
}

=head2 __install_dirs

if you don't like F<vimlib/>

=cut

sub __install_dirs {
    my ($self,$lines) = @_;
    $self->meta->{install_dirs} = [];
    for ( @$lines ) {
        $_ = trim $_;
        push @{  $self->meta->{install_dirs} },$_ if $_;
    }
}

sub __dependency {
    my ( $self, $lines ) = @_;
    $self->meta->{dependency} = [];

    my %pkgs = ();
    my $cur_name;
    for ( @$lines ) {

        # for lines like:
        #       plugin.vim  > 1.0
        if( m{^ ($package_re) \s+ ([=<>]{1,2}) \s+ ([0-9.]+) }x ) {
            my ( $name, $op, $version ) = ( $1, $2, $3 );
            $cur_name = $name;
            $pkgs{ $name } = {
                name => $name,
                op => $op,
                version => $version,
            };
            next;
        }

        # for lines like:
        #       plugin.vim
        #           | plugin/plugin.vim | http://...../.../plugin.vim
        elsif( m{^($package_re)$} ) {
            $cur_name = $1;
            $pkgs{ $cur_name } = [];
            next;
        }
        elsif( m{^\|\s*(.*?)\s*\|\s*(\S+)} ) {
            my ( $target, $from ) = ( $1, $2 );
            push @{ $pkgs{ $cur_name } } , {  from => $from , target => $target  };
        }
        
        # from git repository
        elsif( m{^git://} )  {
            my $git_repo = $_;
            $pkgs{ $cur_name }->{git_repo} = $git_repo;
        }
    }

    $self->meta->{dependency} = [
        map( { { name => $_, required_files => $pkgs{$_} } } grep { ref( $pkgs{$_} ) eq 'ARRAY' } keys %pkgs ),
        map( { $pkgs{$_} } grep { ref( $pkgs{$_} ) ne 'ARRAY' } keys %pkgs ),
    ];

}

sub __script {
    my ( $self, $lines ) = @_;
    $self->meta->{script} = $lines;
}

sub __repository {
    my ( $self, $value ) = @_;
    $self->meta->{repository} = $value;
}

sub __vim_version {
    my ( $self , $v ) = @_;
    my ( $op , $version ) = $v =~ m/^([<=>]{1,2})\s+([0-9.-a-z]+)/;
    $self->meta->{vim_version} = {
        op => $op,
        version => $version,
    };
}

# some alias
# ....


1;
