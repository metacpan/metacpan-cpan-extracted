package URI::Nested;

use strict;
use 5.8.1;
our $VERSION = '0.10';
use overload '""' => 'as_string', fallback => 1;

sub prefix {
    my $class = ref $_[0] || shift;
    return (split /::/ => $class)[-1];
}

sub nested_class { undef }

sub new {
    my ($class, $str, $base) = @_;
    my $prefix = $class->prefix;
    my $scheme;
    if ($base) {
        # Remove prefix and grab the scheme to use for the nested URI.
        $base =~ s/^\Q$prefix://;
        ($scheme) = $base =~ /^($URI::scheme_re):/;
    }
    my $uri = URI->new($str, $base);
    return $uri if $uri->isa(__PACKAGE__);

    # Convert to a nested URI and assign the scheme, if needed.
    $uri->scheme($scheme) if $scheme && !$uri->scheme;
    if ( my $nested_class = $class->nested_class ) {
        bless $uri => $nested_class unless $uri->isa($nested_class);
    }

    bless [ $prefix => $uri ] => $class;
}

sub new_abs {
    my ($class, $uri, $base) = @_;
    $uri = URI->new($uri);
    # No change if already have a scheme.
    return $uri if $uri->scheme;
    $base = URI->new($base);
    # Return non-nested absolute.
    return $uri->abs($base) unless $base->isa(__PACKAGE__);
    # Return nested absolute.
    $uri = $uri->abs( $base->[1] ) if $base->[1];
    $base->[1] = $uri;
    return $base;
}

sub _init {
    my ($class, $str, $scheme) = @_;
    my $prefix = quotemeta $class->prefix;

    if ($str =~ s/^($prefix)://i) {
        $scheme = $1;
    }
    return $class->_nested_init($scheme, $str);
}

sub _nested_init {
    my ($class, $scheme, $str) = @_;
    my $uri = URI->new($str);
    if ( my $nested_class = $class->nested_class ) {
        bless $uri => $nested_class unless $uri->isa($nested_class);
    }
    bless [ $scheme, $uri ] => $class;
}

sub nested_uri { shift->[1] }

sub scheme {
    my $self = shift;
    return lc $self->[0] unless @_;
    my $new = shift;
    my $old = $self->[0];
    # Cannot change $self from array ref to scalar ref, so reject other schemes.
    Carp::croak('Cannot change ', ref $self, ' scheme' )
        if lc $new ne $self->prefix;
    $self->[0] = $new;
    return $old;
}

sub as_string {
    return join ':', @{ +shift };
}

sub clone {
    my $self = shift;
    bless [$self->[0], $self->[1]->clone], ref $self;
}

sub abs { shift }
sub rel { shift }

sub eq {
    my ($self, $other) = @_;
    $other = URI->new($other) unless ref $other;
    return ref $self eq ref $other && $self->[1]->eq($other->[1]);
}

sub _init_implementor {}

# Hard-code common accessors and methods.
sub opaque        { shift->[1]->opaque(@_)        }
sub path          { shift->[1]->path(@_)          }
sub fragment      { shift->[1]->fragment(@_)      }
sub host          { shift->[1]->host(@_)          }
sub port          { shift->[1]->port(@_)          }
sub _port         { shift->[1]->_port(@_)         }
sub authority     { shift->[1]->authority(@_)     }
sub path_query    { shift->[1]->path_query(@_)    }
sub path_segments { shift->[1]->path_segments(@_) }
sub query         { shift->[1]->query(@_)         }
sub userinfo      { shift->[1]->userinfo(@_)      }

# Catch any missing methods.
our $AUTOLOAD;
sub AUTOLOAD {
    my $self = shift;
    my $method = substr($AUTOLOAD, rindex($AUTOLOAD, '::')+2);
    return if $method eq 'DESTROY';
    $self->[1]->$method(@_);
}

sub can {                                  # override UNIVERSAL::can
    my $self = shift;
    $self->SUPER::can(@_) || (
        ref($self) ? $self->[1]->can(@_) : undef
    );
}

1;
__END__

=head1 Name

URI::Nested - Nested URIs

=head1 Synopsis

  package URI::jdbc;
  use parent 'URI::Nested';
  sub prefix       { 'jdbc' }
  sub nested_class { undef  }
  sub subprotocol  { shift->nested_uri->scheme(@_) }

  package main;
  my $jdbc_uri = URI->new('jdbc:oracle:scott/tiger@//myhost:1521/myservicename');
  my $nested_uri = $jdbc_uri->nested_uri;

=head1 Description

This class provides support for nested URIs, where the scheme is a prefix, and
the remainder of the URI is another URI. Examples include L<JDBC
URIs|http://docs.oracle.com/cd/B14117_01/java.101/b10979/urls.htm#BEIJFHHB>
and L<database URIs|https://github.com/theory/uri-db>.

=head1 Interface

The following differences exist compared to the C<URI> class interface:

=head2 Class Method

=head3 C<prefix>

Returns the prefix to be used, which corresponds to the URI's scheme. Defaults
to the last part of class name.

=head3 C<nested_class>

Returns the URI subclass to use for the nested URI. If defined, the nested URI
will always be coerced into this class if it is not naturally an instance of
this class or one of its subclasses.

=head2 Constructors

=head3 C<new>

  my $uri = URI::Nested->new($string);
  my $uri = URI::Nested->new($string, $base);

Always returns a URI::Nested object. C<$base> may be another URI object or
string. Unlike in L<URI>'s C<new()>, schemes will always be applied to the URI
and the nested URI if they does not already schemes. And if C<nested_class> is
defined, the nested URI will be coerced into that class.

=head2 Accessors

=head3 C<scheme>

  my $scheme = $uri->scheme;
  $uri->scheme( $new_scheme );

Gets or sets the scheme part of the URI. When setting the scheme, it must
always be the same as the value returned by C<prefix> or an exception will be
thrown -- although the letter casing may vary. The returned value is always
lowercase.

=head3 C<nested_uri>

  my $nested_uri = $uri->nested_uri;

Returns the nested URI.

=head2 Instance Methods

=head3 C<abs>

  my $abs = $uri->abs( $base_uri );

Returns the URI::Nested object itself. Unlike L<URI>'s C<abs()>,
C<$URI::ABS_ALLOW_RELATIVE_SCHEME> is ignored.

=head3 C<rel>

  my $rel = $uri->rel( $base_uri );

Returns the URI::Nested object itself.

=head1 Support

This module is stored in an open
L<GitHub repository|http://github.com/theory/uri-db/>. Feel free to fork and
contribute!

Please file bug reports via
L<GitHub Issues|http://github.com/theory/uri-db/issues/> or by sending mail to
L<bug-URI-db@rt.cpan.org|mailto:bug-URI-db@rt.cpan.org>.

=head1 Author

David E. Wheeler <david@justatheory.com>

=head1 Copyright and License

Copyright (c) 2013 David E. Wheeler. Some Rights Reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
