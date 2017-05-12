
package WWW::CPAN;

use 5.006;
use strict;
use warnings;

our $VERSION = '0.013';

use Class::Lego::Constructor 0.004 ();
use parent qw( Class::Accessor Class::Lego::Constructor );

my $FIELDS = {
    host => 'search.cpan.org',
    ua   => sub {                # default useragent
        my %options = ( agent => 'www-cpan/' . $VERSION, );

        #                require LWP::UserAgent;
        #                return LWP::UserAgent->new( %options );
        require LWP::UserAgent::Determined;
        return LWP::UserAgent::Determined->new(%options);
    },
    j_loader => sub {    # json loader sub
        require JSON::MaybeXS;
        my $j = JSON::MaybeXS->new;
        return sub { $j->decode(shift); }
    },
    x_loader => sub {    # xml loader sub
        require XML::Simple;
        my %options = (
            ForceArray => [qw( module dist match )],
            KeyAttr    => [],
        );
        my $x = XML::Simple->new(%options);
        return sub { $x->XMLin(shift); }
    },
};

__PACKAGE__->mk_constructor0($FIELDS);
__PACKAGE__->mk_accessors( keys %$FIELDS );

use Class::Lego::Myself;
__PACKAGE__->give_my_self;

use Carp qw( carp );

sub _build_distmeta_uri {
    my $self   = shift;
    my $params = shift;

    if ( !ref $params ) {
        $params = { dist => $params };
    }
    require URI;
    my $uri = URI->new();
    $uri->scheme('http');
    $uri->authority( $self->host );
    my @path = qw( meta );
    if ( $params->{author} ) {
        push @path, $params->{author};
    }

    my $dist = $params->{dist};
    if ( $params->{version} ) {
        $dist .= '-' . $params->{version};
    }
    push @path, $dist;

    push @path, 'META.json';    # XXX support YAML as well
    $uri->path_segments(@path);

    return $uri;
}

sub fetch_distmeta {
    ( my $self, @_ ) = &find_my_self;
    my $uri = $self->_build_distmeta_uri(@_);
    my $r   = $self->ua->get($uri);
    if ( $r->is_success ) {

        my $content = $r->decoded_content;

        # Back to UTF8 (if needed)
        utf8::encode($content)
          unless utf8::is_utf8($content);

        return $self->j_loader->($content);
    }
    else {
        carp $r->status_line;    # FIXME needs more convincing error handling
        return;
    }
}

# http://search.cpan.org/search?query=Archive&mode=all&format=xml
sub _build_query_uri {
    my $self   = shift;
    my $params = shift;

    if ( !ref $params ) {
        $params = { query => $params, mode => 'all', format => 'xml', };
    }
    require URI;
    my $uri = URI->new();
    $uri->scheme('http');
    $uri->authority( $self->host );
    my @path = qw( search );
    $uri->path_segments(@path);

    $params->{mode}   ||= 'all';
    $params->{format} ||= 'xml';
    $uri->query_form($params);

    return $uri;
}

# other params: s (start), n (page size, should be <= 100)

sub _basic_query {
    my $self = shift;
    my $uri  = $self->_build_query_uri(@_);
    my $r    = $self->ua->get($uri);
    if ( $r->is_success ) {
        return $self->x_loader->( $r->content );
    }
    else {
        carp $r->status_line;    # FIXME needs more convincing error handling
        return;
    }
}

sub search {
    my $self = &find_my_self;
    return $self->_basic_query(@_);
}

# TODO fetch the entire result by default

# &query is an alias to &search (see Method::Alias for the rationale)
sub query {
    goto &{ $_[0]->can('search') };
}

"I didn't do it! -- Bart Simpson";
