package XML::API::Cache;
use strict;
use warnings;
use Carp qw(croak);
use overload '""' => \&content;

our $VERSION = '0.30';

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $x     = shift || croak 'XML::API::Cache->new($x)';
    $x->isa('XML::API') || croak 'argument must be XML::API derived object';

    my $self = {
        content => $x->_fast_string,
        langs   => [ $x->_langs ],
    };

    bless( $self, $class );
    return $self;
}

sub langs {
    my $self = shift;
    return @{ $self->{langs} };
}

sub content {
    my $self = shift;
    return $self->{content};
}

1;
__END__


=head1 NAME

XML::API::Cache - Cached version of an XML::API object

=head1 VERSION

0.30 (2016-04-11)

=head1 SYNOPSIS

  use XML::API::Cache;
  my $cache = XML::API::Cache->new($xml_api_object);

  # store and then retrieve $cache somewhere
  # later:
  
  use XML::API;
  my $x = XML::API->new();
  $x->tag_open();
  $x->_add($cache);
  $x->tag_close();

=head1 DESCRIPTION

B<XML::API::Cache> is a class for storing L<XML::API> objects in a
cache. L<XML::API> objects are flattened, but their language attributes
are kept, so that they can be efficiently stored and retrieved from
somewhere but will still allow the caller to use them in the creation
of XML.

=head1 METHODS

=head2 new

Create a new L<XML::API::Cache> object. The first and only argument
must be an L<XML::API> object.

=head2 langs

Returns the values of the _langs() method from the original L<XML::API>
object. This is used by L<XML::API> when _adding() the $cache to
another L<XML::API> object.

=head2 content

Returns the (fast) string value of the original L<XML::API> object.
'""' is overloaded so you can also just print $cache.

=head1 SEE ALSO

L<XML::API>

=head1 AUTHOR

Mark Lawrence E<lt>nomad@null.net<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008,2015,2016 Mark Lawrence <nomad@null.net>

This program is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the
Free Software Foundation; either version 2 of the License, or (at your
option) any later version.

=cut

