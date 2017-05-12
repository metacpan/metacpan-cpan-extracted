package WWW::GoKGS::Scraper;
use strict;
use warnings;
use Carp qw/croak/;
use URI;

sub base_uri {
    croak 'call to abstract method ', __PACKAGE__, '::base_uri';
}

sub build_uri {
    my ( $class, @query ) = @_;
    my $uri = URI->new( $class->base_uri );
    $uri->query_form( @query ) if @query;
    $uri;
}

sub new {
    my $class = shift;
    my %args = @_ == 1 ? %{$_[0]} : @_;
    my $self = bless {}, $class;

    $self->init( \%args );

    $self;
}

sub init {
    my ( $self, $args ) = @_;

    for my $method (qw/user_agent _tree_builder_class/) {
        $self->$method( $args->{$method} ) if exists $args->{$method};
    }

    return;
}

sub _scraper {
    my $self = shift;
    $self->{_scraper} ||= $self->__build_scraper;
}

sub __build_scraper {
    croak 'call to abstract method ', __PACKAGE__, '::__build_scraper';
}

sub _tree_builder_class {
    my ( $self, @args ) = @_;
    $self->_scraper->_tree_builder_class( @args );
}

sub user_agent {
    my ( $self, @args ) = @_;
    $self->_scraper->user_agent( @args );
}

sub scrape {
    my ( $self, @args ) = @_;
    $self->_scraper->scrape( @args );
}

sub query {
    my ( $self, @query ) = @_;
    $self->scrape( ref($self)->build_uri(@query) );
}

1;

__END__

=head1 NAME

WWW::GoKGS::Scraper - Abstract base class for KGS scrapers

=head1 SYNOPSIS

  use parent 'WWW::GoKGS::Scraper';
  use WWW::GoKGS::Scraper::Declare;

  sub base_uri { 'http://www.gokgs.com/...' }

  sub __build_scraper {
      my $self = shift;

      scraper {
          ...
      };
  }

=head1 DESCRIPTION

This module is an abstract base class for KGS scrapers. KGS scrapers must
inherit from this class, and also implement the following methods:

=over 4

=item base_uri

Must return a URI string which represents a resource on KGS.
This method is called as a method on the class.

=item __build_scraper

Must return an L<Web::Scraper> object which can C<scrape> the resource.
This method is called as a method on the object.

=back

=head2 CLASS METHODS

=over 4

=item $URI = $class->build_uri( $k1 => $v1, $k2 => $v2, ... )

=item $URI = $class->build_uri({ $k1 => $v1, $k2 => $v2, ... })

=item $URI = $class->build_uri([ $k1 => $v1, $k2 => $v2, ... ])

Given key-value pairs of query parameters, constructs a L<URI> object
which consists of C<base_uri> and the paramters.

=back

=head2 INSTANCE METHODS

=over 4

=item $UserAgent = $scraper->user_agent

=item $scraper->user_agent( LWP::UserAgent->new(...) )

Can be used to get or set an L<LWP::UserAgent> object which is used to
C<GET> the requested resource. Defaults to the C<LWP::UserAgent> object
shared by L<Web::Scraper> users (C<$Web::Scraper::UserAgent>).

=item $scraper->scrape( URI->new(...) )

=item $scraper->scrape( HTTP::Response->new(...) )

=item $scraper->scrape( $html[, $base_uri] )

=item $scraper->scrape( \$html[, $base_uri] )

Given arguments are passed to the C<scrape> method of
an L<Web::Scraper> object built by the C<__build_scraper> method.

=item $scraper->query( $k1 => $v1, $k2 => $v2, ... )

Given key-value pairs of query parameters, constructs a L<URI> object
which consists of C<base_uri> and the parameters, then pass the C<URI>
to the C<scrape> method.

=back

=head2 INTERNAL METHODS

=over 4

=item $class_name = $scraper->_tree_builder_class

=item $scraper->_tree_builder_class( 'HTTP::TreeBuilder::XPath' )

Can be used to get or set a class name which is used to C<build_tree>.
Defaults to L<HTML::TreeBuilder::XPath>.
You shouldn't modify this attribute unless you understand what you're doing.

  use HTML::TreeBuilder::LibXML;
  $scraper->_tree_builder_class( 'HTML::TreeBuilder::LibXML' );

=back

=head1 SEE ALSO

L<WWW::GoKGS>

=head1 AUTHOR

Ryo Anazawa (anazawa@cpan.org)

=head1 LICENSE

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=cut
