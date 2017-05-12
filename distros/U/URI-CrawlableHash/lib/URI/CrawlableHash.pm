package URI::CrawlableHash;

use strict;
use warnings;
our $VERSION = '0.02';

use URI;
use URI::Escape;
use Guard;

sub convert_always {
    my ( $class, $option ) = @_;
    no warnings 'redefine';

    $option ||= "query";

    my $orig = URI->can('new');
    my $conv  = $class->can("convert_to_" . $option);
    unless ($conv) { die "unknown option: " . $option }
    
    no strict "refs";

    *{'URI::new'} = sub { 
        my $self = $orig->(@_);
        if ($self) {
           $conv->($self); 
        }
    };

    if ( defined wantarray ) {
        return guard { 
            *{"URI::new"} = $orig;
        };
    }
}

sub convert_to_query {
    my $self = shift;
    if ($self->has_crawlable_hash) {
        $self->fragment_to_query
    } else {
        $self 
    }
}

sub convert_to_hash {
    my $self = shift;
    if ($self->has_escaped_fragment) {
        $self->query_to_fragment
    } else {
        $self
    }
}

sub URI::has_crawlable_hash {
    my ($uri) = @_;
    ($uri->fragment || "") =~/^!/
}

sub URI::has_escaped_fragment {
    my ($uri) = @_;
    my %hash = $uri->query_form;
    $hash{_escaped_fragment_} ? 1 : undef;
}

sub URI::fragment_to_query {
    my $self = shift;
    return $self unless $self->has_crawlable_hash;

    my $fragment = $self->fragment;
    $fragment =~s/^!//;
    my $q = "_escaped_fragment_=" . uri_escape($fragment, "\x00-\x20\x23\x25\x26\x2b\x7f-\xff");
    if ($self->query) {
        my $old = $self->query;
        $old =~s/_escaped_fragment_=[^\&]*$//;
        my $delimiter = $old ? "&" : "";
        $self->query( $old . $delimiter . $q );
    } else {
        $self->query($q);
    }
    $self->fragment(undef);
    $self;
}

sub URI::query_to_fragment {
    my $self = shift;
    return $self unless $self->has_escaped_fragment;

    my %query = $self->query_form;
    my $escaped = delete $query{_escaped_fragment_};

    my $old = $self->query;
    $old =~s/\&?_escaped_fragment_=[^\&]*$//;

    if ($old) {
        $self->query($old)
    } else {
        $self->query(undef);
    } 

    $self->fragment('!' . uri_unescape($escaped));
    $self;
}

1;
__END__

=head1 NAME

URI::CrawlableHash - convert ajax uri to crawlable

=head1 SYNOPSIS

  use URI::CrawlableHash;

  my $uri = URI->new("http://example.com/#!key1=value1&key2=value2");

  # uri for crawler
  $uri->fragment_to_query; # http://example.com/?_escaped_fragment_=key1=value1%26key2=value2

  # uri for browser
  $uri->query_to_fragment; # http://example.com/#!key1=value1&key2=value2

  # always convert to #! (Google says pretty url)
  $guard = URI::CrawlableHash->convert_always("hash");
  
  # always convert to ?_escaped_fragment_ (Google says ugly url)
  $guard = URI::CrawlableAjax->convert_always("query");

=head1 DESCRIPTION

URI::CrawlableHash is URL transformer for AJAX URLs.

See http://code.google.com/web/ajaxcrawling/docs/specification.html

It adds some method to the C<URI> namespace. I hate this approach but I need it.

See also HTML5's history.pushState or history.replaceState http://www.w3.org/TR/html5/author/history.html#history

=head1 METHODS

=head2 has_crawlable_hash

  $uri->has_crawlable_hash; # return true if contain #!

=head2 has_escaped_fragment
 
  $uri->has_escaped_fragment; # return true if contain _escaped_fragment_

=head2  fragment_to_query

This method return ugly URI. Note that this is destructive method.

If you want new object, call $uri->clone before call this method.

=head2  query_to_fragment

This method return pretty URI. This method is destructive itself too.

=head2 convert_always

This method will make you happy or crash everything. please read source.
 
=head1 AUTHOR

mala E<lt>cpan@ma.laE<gt>

=head1 SEE ALSO

L<URI>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
