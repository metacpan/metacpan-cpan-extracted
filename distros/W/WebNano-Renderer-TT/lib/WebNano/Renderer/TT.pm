package WebNano::Renderer::TT;
BEGIN {
  $WebNano::Renderer::TT::VERSION = '0.002';
}
use strict;
use warnings;

use Template;
use Object::Tiny::RW qw/ root _tt _global_path INCLUDE_PATH TEMPLATE_EXTENSION/;
use File::Spec;

sub new {
    my( $class, %args ) = @_;
    my $self = bless { 
        _global_path => [ _to_list( delete $args{INCLUDE_PATH} ) ],
        root => delete $args{root},
        TEMPLATE_EXTENSION => delete $args{TEMPLATE_EXTENSION},
    }, $class;
    # Use a weakend copy of self so we dont have loops preventing GC from working
    my $copy = $self;
    Scalar::Util::weaken($copy);
    $args{INCLUDE_PATH} = [ sub { $copy->INCLUDE_PATH } ];
    $self->_tt( Template->new( \%args ) );
    return $self;
}


sub _to_list {
    if( ref $_[0] ){
        return @{ $_[0] };
    }
    elsif( ! defined $_[0] ){
        return ();
    }
    else{
        return $_[0];
    }
}

sub render {
    my( $self, %params ) = @_;
    my $c = $params{c};
    my @input_path;
    if( $c ){
        my $path = ref $c;
        $path =~ s/.*::Controller(::)?//;
        $path =~ s{::}{/};
        @input_path = ( $path, @{ $c->template_search_path }); 
    }
    if( !@input_path ){
        @input_path = ( '' );
    }
    my @path = @{ $self->_global_path };
    for my $sub_path( @input_path ){
        for my $root( _to_list( $self->root ) ){
            if( File::Spec->file_name_is_absolute( $sub_path ) ){
                push @path, $sub_path;
            }
            else{
                push @path, File::Spec->catdir( $root, $sub_path );
            }
        }
    }
    $self->INCLUDE_PATH( \@path );
    my $template = $params{template};
    if( !$template ){
        my @caller = caller(2);
        $template =  $caller[3];
        $template =~ s/_action$//;
        $template =~ s/^.*:://;
        $template .= '.' . $self->TEMPLATE_EXTENSION if $self->TEMPLATE_EXTENSION;
    }
    my $tt = $self->_tt;
    my $output;
    if( ! $tt->process( $template, \%params, \$output ) ){
        warn "Current INCLUDE_PATH: @path\n"; 
        die $tt->error();
    }
    return $output;
}

1;



=pod

=head1 NAME

WebNano::Renderer::TT - A Template Toolkit renderer for WebNano with dynamic search paths

=head1 VERSION

version 0.002

=head1 SYNOPSIS

    use WebNano::Renderer::TT;
    $renderer = WebNano::Renderer::TT->new( root => [ 't/data/tt1', 't/data/tt2' ] );
    $out = '';
    $renderer->render( template => 'template.tt', search_path => [ 'subdir1', 'subdir2' ], output => \$out );

=head1 DESCRIPTION

This is experimental Template Tookit dynamic renderer for L<WebNano>.
Please note that you can use Template Tookit directly in WebNano without this module,
what this module adds is way to search for the templates that depends on the
controller.
When looking for
a template file it scans a cartesian product of static set of paths provided 
at instance creation time and stored in the C<root> attribute and a dynamic
set provided to the C<render> method in the C<search_path> attribute.  Additionally it 
also scans the C<INCLUDE_PATH> in a more traditional and non-dynamic way.

=head1 ATTRIBUTES

=head2 root

=head2 INCLUDE_PATH

A mechanism to provide the serach path directly sidestepping the dynamic calculations.

Templates that are to be found in C<INCLUDE_PATH> are universal - i.e. can be C<INCLUDE>d 
everywhere.

=head2 TEMPLATE_EXTENSION

Postfix added to action name to form the template name ( for example 'edit.tt'
from action 'edit' and TEMPLATE_EXTENSION 'tt' ).

=head1 METHODS

=head2 render

=head2 new

=head1 AUTHOR

Zbigniew Lukasiak <zby@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2010 by Zbigniew Lukasiak <zby@cpan.org>.

This is free software, licensed under:

  The Artistic License 2.0

=cut


__END__

# ABSTRACT: A Template Toolkit renderer for WebNano with dynamic search paths

