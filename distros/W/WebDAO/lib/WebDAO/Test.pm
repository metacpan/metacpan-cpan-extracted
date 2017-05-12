package WebDAO::Test;

#$Id$

=head1 NAME

WebDAO::Test - Class for tests 

=head1 SYNOPSIS

    use WebDAO::Test;

    my $eng = WebDAO::Test::make_engine(
            class      => 'MyClass',
            config     => 't/tests.ini',
           index_file => 'contrib/www/index.xhtml'
          )
    
    my $tlib = new WebDAO::Test::(eng =>$eng);


=head1 DESCRIPTION

Class for tests

=cut

our $VERSION = '0.01';

require Exporter;
@WebDAO::Test::ISA = qw(Exporter );

#@WebDAO::Test::EXPORT = qw/ t_get_engine t_get_tlib/;
use strict;
use warnings;
use Data::Dumper;
use Test::More;
use Digest::MD5 qw(md5 md5_hex md5_base64);
use WebDAO::Lex;
use WebDAO::SessionSH;
use WebDAO::Engine;
our $default_engine_class = 'WebDAO::Engine';

=head1 FUNCTIONS

=head2 t_get_engine

Return Engine

 my $eng =  t_get_engine ('www/index.html', config=>'tests.ini');

=cut

sub main::t_get_engine {
    my $index_file = shift;
    my %eng_pars   = @_;
    if ( $index_file && -e $index_file ) {
        my $content = qq!<wD><include file="$index_file"/></wD>!;
        my $lex = new WebDAO::Lex:: content => $content;
        $eng_pars{lexer} = $lex;
    }
    else {
        $eng_pars{source} = '';
    }
    my $session = new WebDAO::SessionSH::;
    my $eng     = $__PACKAGE__::default_engine_class->new(
        session => $session,
        %eng_pars
    );
    return $eng;
}

sub t_get_engine {
    my $index_file = shift;
    warn "$index_file" unless -e $index_file;
    my %eng_pars = @_;
    if ( $index_file && -e $index_file ) {
        my $content = qq!<wD><include file="$index_file"/></wD>!;
        my $lex = new WebDAO::Lex:: content => $content;
        $eng_pars{lexer} = $lex;
    }
    else {
        $eng_pars{source} = '';
    }
    my $session = new WebDAO::SessionSH::;
    my $eng     = $__PACKAGE__::default_engine_class->new(
        session => $session,
        %eng_pars
    );
    return $eng;
}

=head2 make_eng [class=><CLASS>, index_file=><file_path>, %other_params_to_engine]

Return engine object. Used params:
    
  class - Class of engine (default -"WebDAO::Kernel"), 
  index_file - path to index file



=cut

sub make_engine {
    my %eng_pars = @_;
    my $class = delete $eng_pars{class} || 'WebDAO::Kernel';
    if ( my $index_file = delete $eng_pars{index_file} ) {
        warn "$index_file not found!!!" unless -e $index_file;
        if ( $index_file && -e $index_file ) {
        open FH, "<$index_file" or die $!;
        my $content ='';
        { local $/=undef;
            $content = <FH>;
        }
        close FH;
            my $lex = new WebDAO::Lex:: tmpl => $content;
            $eng_pars{lex} = $lex;
        }
    }
    my $session =  new WebDAO::SessionSH::;
    my $eng     = $class->new(
        session => $session,
        %eng_pars
    );
    return $eng;

}

=head2 make_test_lib <engine_object> [, <class_of_testlib>]

Return object of test class B<class_of_testlib> (default "WebDAO::Test")

=cut

sub make_test_lib {
    my ( $eng, $tclass ) = @_;
    $tclass ||= "WebDAO::Test";
    return $tclass->new( eng => $eng );
}

sub import {
    my $self = shift;
    my $engine_class = shift || $default_engine_class;
    $__PACKAGE__::default_engine_class = $engine_class;

    #    $self->export_to_level( 1, 't_get_engine' );
    $self->export_to_level( 1, 't_get_tlib' );
}

sub t_get_tlib {
    my $eng = shift || die "need \$eng";
    my $tlib = __PACKAGE__->new( eng => $eng );
    return $tlib;
}

=head1 METHODS

=cut

sub new {
    my $class = shift;
    $class = ref($class) || $class;
    my %args = @_;
    my $self = bless( \%args, $class );
    return $self;

}

=head2  tree [ $contaner ]

return tree of node  $contaner . default $engine

=cut

sub tree {
    my $self = shift;
    my $obj  = shift || $self->{eng};
    my @res  = ();
    foreach my $o ( @{ $obj->_get_childs_ } ) {
        push @res, $self->tree($o),;
    }
    return { $obj->__my_name . ":" . ref($obj) => \@res };
}

=head2 xget

get object by path (query)

     $tlib->xget('/page')

=cut

sub xget {
    my $self = shift;
    my $path = shift;
#    $path =~ s/^\///;
    my $eng = $self->{eng};

    #check if exists args
        my $pars;
        ( $path, $pars ) = split /\?/, $path;
        my %args = ();
        %args = map { split /\=/, $_ } split /\&/, $pars if $pars;
        $eng->_session->Params( \%args );
    return $self->resolve_path( $path, @_ );
#    return $eng->resolve_path( $eng->_session, $path );
}

=head2 resolve_path '/path/Path'

#[, arg1=>1, arg2=>2]

Query path

=cut

sub resolve_path {
    my $self = shift;
    my $path = shift;
    my $sess = $self->eng->_session();

    #    return $self if $path eq '/';

    #skip root objects
    my ( undef, @path ) = split( /\//, $path );
    my ( $src, $res ) = ( shift || $self->eng)->_traverse_( $sess, @path );
    $res;
}

=head2 get_by_path

get object by resolve_path query

     $tlib->get_by_path('/page')
     $tlib->get_by_path('/page', $root_object)
=cut

sub get_by_path {
    my $self = shift;
    my $path = shift;
    my $eng  = $self->{eng};
    my $root_obj  = shift || $eng;
    #skip root objects
    my ( undef, @path ) = split( /\//, $path );
    my ( $src, $res ) = $root_obj->_traverse_($self->eng->_session()
, @path );
    $res;
}

=head2 eng 

get root object

=cut

sub eng {
    return $_[0]->{eng};
}

=head2 get_session

Get curren Session object

=cut

sub get_session {
    return $_[0]->eng->_session;
}

1;

sub make_cv {
    my %args = @_;
    my $out;
    my $cv = WebDAO::CV->new(
        env    => $args{env},
        writer => sub {
            new Test::Writer::
              out     => \$out,
              status  => $_[0]->[0],
              headers => $_[0]->[1];
        }
    );

}

package Test::Writer;
our $VERSION = '0.01';
use warnings;
use strict;
sub new {
    my $class = shift;
    my $self = bless( ( $#_ == 0 ) ? shift : {@_}, ref($class) || $class );
}
sub write   {
    ${ $_[0]->{out} } .= $_[1] ;
    }
sub close   { }
sub headers { return $_[0]->{headers} }
sub output { ${ $_[0]->{out} } }

1;

package TestCV;
use strict;
use warnings;
use WebDAO::CV;
our $VERSION = '0.01';
use base 'WebDAO::CV';

sub new {
    my $self  = shift;
    my $buf_ref = shift;
    my $writer =  sub {
            new Test::Writer::
              out     => $buf_ref,
              status  => $_[0]->[0],
              headers => $_[0]->[1];
        };
    $self->SUPER::new(writer=>$writer, @_ )
}
# for skip headers
# $cv{SKIP_HEADERS} = 1
sub _init__ { 
    my $self = shift;
    my $buf_ref  = shift;
    return $self->SUPER::_init(@_);

}

sub response__ {
    my $self = shift;
    my $res = shift || return;
    unless ( exists( $self->{SKIP_HEADERS} ) ) {
      $self->SUPER::response($res)
    } else {
      $self->print( $res->{data} );
    }
}

sub print__ {
    my $self = shift;
     my $out_ref = $self->{ctr};
    if ( grep { ! defined $_} @_ ) {
        warn "NOT DEFINED IN PUT";

    }
    $$out_ref .=join "",grep {defined $_ } @_ if scalar(@_);
}


1;
__DATA__

=head1 SEE ALSO

http://webdao.sourceforge.net

=head1 AUTHOR

Zahatski Aliaksandr, E<lt>zag@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2002-2009 by Zahatski Aliaksandr

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut

