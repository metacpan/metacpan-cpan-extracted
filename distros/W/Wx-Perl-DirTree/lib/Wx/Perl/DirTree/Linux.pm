package Wx::Perl::DirTree::Linux;

use strict;
use warnings;
use Cwd;
use Exporter;
use File::Spec;

our @ISA    = qw(Exporter);
our @EXPORT = qw(
    add_root
    AddChildren
);

our $VERSION = 0.02;

sub add_root {
    my ($self,$args) = @_;
    
    my $dir = [ '/', '/' ];
    
    if( exists $args->{dir} and -e $args->{dir} and 
        exists $args->{is_root} and $args->{is_root} ){
        my $path = Cwd::abs_path( $args->{dir} );
        my @dirs = File::Spec->splitdir( $path );
        $dir = [ $path, $dirs[-1] ];
    }
    
    my $root = $self->AddRoot( $dir->[1] );
    $self->SetPlData( $root, $dir->[0] );
    $self->SetItemHasChildren( $root, 1 );
    $self->Expand( $root );
    
    if( exists $args->{dir} and -e $args->{dir} and 
        ( ( exists $args->{is_root} and not $args->{is_root} ) or
            not exists $args->{is_root} )){
            
        my $path     = Cwd::abs_path( $args->{dir} );
        my @dirs     = File::Spec->splitdir( $path );
        my $tmp_item = _find_node( $self, $root, $dirs[0] );
        $self->Expand( $tmp_item );
        
        for my $i ( 1 .. $#dirs ){
            my $subdir = File::Spec->catdir( @dirs[0..$i] );
            
            my @data   = _get_content( $subdir );
            _insert_items( $self, $tmp_item, @data );
            
            $tmp_item  = _find_node( $self, $tmp_item, $subdir );
            $self->Expand( $tmp_item );
        }
    }
}

sub _find_node {
    my ($tree,$parent,$value) = @_;
    
    $value = File::Spec->catdir( $value ) unless $value =~ m!\\$!;
    
    my ($id,$cookie) = $tree->GetFirstChild( $parent );
    
    while( $id->IsOk ){
        if( $tree->GetPlData( $id ) eq $value ){
            return $id;
        }
        
        ($id,$cookie) = $tree->GetNextChild( $parent, $cookie );
    }
}

sub AddChildren {
    my ($self,$event) = @_;
    
    my $tree = $event->GetEventObject;
    my $item = $event->GetItem;
    my $data = $tree->GetPlData( $item );
    
    if( $tree->GetChildrenCount( $item, 0 ) ){
    }
    else{
        my @array = _get_content( $data );
        _insert_items( $tree, $item, @array );
    }
}

sub _insert_items {
    my ( $tree, $item, @data ) = @_;

    for my $child ( @data){
        my ($label,$value,$is_dir) = @$child;
        my $childobj = $tree->AppendItem( $item, $label );
        $tree->SetPlData( $childobj, $value );
        $tree->SetItemHasChildren( $childobj, 1 ) if $is_dir;
    }
}

sub _get_content {
    my ($dir) = @_;
    
    opendir my $dirh, $dir or die $!;
    my @files = sort grep{ !/^\.\.?$/ }readdir $dirh;
    closedir $dirh;
    
    return map{ [ $_, $dir . '/' . $_, -d $dir . '/' . $_ ] }(@files);
}

1;

# ABSTRACT: module for the directory tree on Linux


__END__
=pod

=head1 NAME

Wx::Perl::DirTree::Linux - module for the directory tree on Linux

=head1 VERSION

version 0.07

=head1 METHODS

=head2 add_root

=head2 AddChildren

=head1 AUTHOR

Renee Baecker <module@renee-baecker.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2010 by Renee Baecker.

This is free software, licensed under:

  The Artistic License 2.0

=cut

