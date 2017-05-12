package URI::PathAbstract;

use strict;
use warnings;

=head1 NAME

URI::PathAbstract - A URI-like object with Path::Abstract capabilities

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

    my $uri = URI::PathAbstract->new("http://example.com?a=b")

    $uri->down("apple")
    # http://example.com/apple?a=b

    $uri->query("c=d&e=f")
    # http://example.com/apple?c=d&e=f

    $uri->path("grape/blueberry/pineapple")
    # http://example.com/grape/blueberry/pineapple?c=d&e=f

    $uri = $uri->parent
    # http://example.com/grape/blueberry?c=d&e=f

    $uri = $uri->child("xyzzy")
    # http://example.com/grape/blueberry/xyzzy?c=d&e=f

=head1 DESCRIPTION

URI::PathAbstract is a combination of the L<URI::WithBase> and L<Path::Abstract> classes. It is essentially a URI
class that delegates path-handling methods to Path::Abstract

Unfortunately, this is not true:

    URI::PathAbstract->new( http://example.com )->isa( URI )

URI::PathAbstract supports the L<URI> generic and common methods

=cut

use URI;
use Path::Abstract;
use Scalar::Util qw/blessed/;
use Carp;

use overload
    '""' => sub { $_[0]->{uri}->as_string },
    '==' => sub { overload::StrVal($_[0]) eq overload::StrVal($_[1]) },
    fallback => 1,
;

=head1 METHODS

=head2 URI::PathAbstract->new( <uri>, ... )

Create a new URI::PathAbstract object based on <uri>

<uri> should be of the L<URI> class or some sort of URI-like string

=head2 URI::PathAbstract->new( <uri>, path => <path>, ... )

Create a new URI::PathAbstract object based on <uri> but overriding the path with <path>

    URI::PathAbstract->new("http://example.com/cherry?a=b", path => "grape/lemon")
    # http://example.com/grape/lemon?a=b"

=head2 URI::PathAbstract->new( <uri>, child => <child>, ... )

Create a new URI::PathAbstract object based on <uri> but modifying the path by <child>

    URI::PathAbstract->new("http://example.com/cherry?a=b", child => "grape/lemon")
    # http://example.com/cherry/grape/lemon?a=b"

=head2 URI::PathAbstract->new( ... )

Create a new URI::PathAbstract object based on the following:

    uri         The URI you want to represent

    base        A base URI for use with ->abs and ->rel

    path        A path that will override the path of the given uri
                (although the scheme, host, ... will remain the same)

    child       A path that will be appended to the path of the given uri

=cut

sub new {
    my $self = bless {}, shift;

    my %given;
    if (@_ == 1 ) {
        $self->uri(shift);
    }
    elsif (@_ % 2) {
        $self->uri(shift);
        %given = @_;
    }
    elsif (@_) {
        %given = @_;
        $self->uri(delete $given{uri});
    }
    else {
        $self->uri(URI->new);
    }

    if (%given) {
        $self->path($given{path}) if defined $given{path};
        $self->down($given{child}) if defined $given{child};
        $self->base($given{base}) if defined $given{base};
    }

    return $self;
}

=head2 $uri->uri

Returns a L<URI> object that is a copy (not a reference) of the URI object inside $uri

=cut

sub uri {
    my $self = shift;
    if (@_) {
        my $uri = shift;
        $uri = URI->new($uri) unless blessed $uri;
        $self->_path($uri->path);
        $self->{uri} = $uri->clone;
    }
    return unless defined wantarray;
    return $self->{uri}->clone unless @_;
}

=head2 $uri->path

Returns a L<Path::Abstract> object that is a copy (not a reference) of the Path::Abstract object inside $uri

=head2 $uri->path( <path> )

Sets the path of $uri, completely overwriting what was there before

The rest of $uri (host, port, scheme, query, ...) does not change

=cut

sub path {
    my $self = shift;
    if (@_) {
        my $path = $self->_path(@_);
        $self->{uri}->path($path->get);
    }
    return unless defined wantarray;
    return $self->{path}->clone;
}

sub _path {
    my $self = shift;
    my @path = @_;
    @path = @{ $path[0] } if ref $path[0] eq "ARRAY";
    my $path = Path::Abstract->new(@path);
    $self->{path} = $path;
}

=head2 $uri->clone

Returns a URI::PathAbstract that is an exact clone of $uri

=cut

sub clone {
    my $self = shift;
    my $class = ref $self;
    return $class->new($self->uri);
}

=head2 $uri->base

Returns a L<URI::PathAbstract> object that is a copy (not a reference) of the base for $uri

Returns undef if $uri does not have a base uri

=head2 $uri->base( <base> )

Sets the base of $uri to <base>

=cut

sub base {
    my $self = shift;
    if (@_) {
        my $base = shift;
        if (defined $base) {
            my $class = ref $self;
            $base = $base->abs if blessed $base && ($base->isa(__PACKAGE__) || $base->isa('URI::WithBase'));
            $base = $class->new(uri => "$base") unless $base->isa(__PACKAGE__);
        }
        $self->{base} = $base;
    }
    return unless defined wantarray;
    return undef unless defined $self->{base};
    return $self->{base}->clone;
}

=head2 $uri->abs

=head2 $uri->abs( [ <base> ] )

Returns a L<URI::PathAbstract> object that is the absolute URI formed by combining $uri and <base>

If <base> is not given, then $uri->base is used as the base

If <base> is not given and $uri->base does not exist, then a clone of $uri is returned

See L<URI> and L<URI::WithBase> for more C<abs> information

=cut

sub abs {
    my $self = shift;
    my $class = ref $self;
    my $base = shift || $self->base || return $self->clone;
    return $class->new(uri => $self->uri->abs("$base", @_), base => $base);
}

=head2 $uri->rel

=head2 $uri->rel( [ <base> ] )

Returns a L<URI::PathAbstract> object that is the relative URI formed by comparing $uri and <base>

If <base> is not given, then $uri->base is used as the base

If <base> is not given and $uri->base does not exist, then a clone of $uri is returned

See L<URI> and L<URI::WithBase> for more C<rel> information

=cut

sub rel {
    my $self = shift;
    my $class = ref $self;
    my $base = shift || $self->base || return $self->clone;
    return $class->new(uri => $self->uri->rel("$base", @_), base => $base);
}

{

=head2 URI

See L<URI> for more information

=head2 ->scheme

=head2 ->fragment

=head2 ->as_string

=head2 ->canonical

=head2 ->eq

=head2 ->authority

=head2 ->query

=head2 ->query_form

=head2 ->query_keywords

=head2 ->userinfo

=head2 ->host

=head2 ->port

=head2 ->host_port

=head2 ->default_port

=cut

    no strict 'refs';

    for my $method (grep { ! /^\s*#/ } split m/\n/, <<_END_) {
scheme
fragment
as_string
canonical
eq
authority
query
query_form
query_keywords
userinfo
host
port
host_port
default_port
_END_
        *$method = sub {
            my $self = shift;
            return $self->{uri}->$method(@_);
        }
    }

#=head2 abs

#Returns a L<URI::PathAbstract> object

#=head2 rel

#Returns a L<URI::PathAbstract> object

#=cut

=head2 ->opaque

=head2 ->path_query

=head2 ->path_segments

=head2 Path::Abstract

See L<Path::Abstract> for more information

=head2 ->child

=head2 ->parent

=cut

    for my $method (grep { ! /^\s*#/ } split m/\n/, <<_END_) {
child
parent
_END_
        *$method = sub {
            my $self = shift;
            my $path = $self->{path}->$method(@_);
            my $clone = $self->clone;
            $clone->path($path);
            return $clone;
        }
    }

=head2 ->up

=head2 ->pop

=head2 ->down

=head2 ->push

=head2 ->to_tree

=head2 ->to_branch

=cut

    for my $method (grep { ! /^\s*#/ } split m/\n/, <<_END_) {
up
pop
down
push
to_tree
to_branch
#set
_END_
        *$method = sub {
            my $self = shift;
            my $path = $self->{path};
            my @result;
            if (wantarray) {
                my @result = $path->$method(@_);
            }
            else {
                $result[0] = $path->$method(@_);
            }
            $self->path($$path);
            return wantarray ? @result : $result[0];
        }
    }
    
=head2 ->list

=head2 ->first

=head2 ->last

=head2 ->is_empty

=head2 ->is_nil

=head2 ->is_root

=head2 ->is_tree

=head2 ->is_branch

=cut

    for my $method (grep { ! /^\s*#/ } split m/\n/, <<_END_) {
#get
list
first
last
is_empty
is_nil
is_root
is_tree
is_branch
_END_
        *$method = sub {
            my $self = shift;
            return $self->{path}->$method(@_);
        }
    }
}

=head1 SEE ALSO

L<URI>

L<URI::WithBase>

L<Path::Abstract>

L<Path::Resource>

L<URI::SmartURI>

=head1 AUTHOR

Robert Krimen, C<< <rkrimen at cpan.org> >>

=head1 SOURCE

You can contribute or fork this project via GitHub:

L<http://github.com/robertkrimen/uri-pathabstract/tree/master>

    git clone git://github.com/robertkrimen/uri-pathabstract.git URI-PathAbstract

=head1 BUGS

Please report any bugs or feature requests to C<bug-uri-pathabstract at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=URI-PathAbstract>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc URI::PathAbstract


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=URI-PathAbstract>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/URI-PathAbstract>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/URI-PathAbstract>

=item * Search CPAN

L<http://search.cpan.org/dist/URI-PathAbstract>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2008 Robert Krimen, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of URI::PathAbstract
