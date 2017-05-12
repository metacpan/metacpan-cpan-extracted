package WWW::TarPipe;

use warnings;
use strict;
use Carp;
use LWP::UserAgent;

=head1 NAME

WWW::TarPipe - An interface to tarpipe.com's REST based web service.

=head1 VERSION

This document describes WWW::TarPipe version 0.01

=cut

our $VERSION = '0.01';

my @ATTR;

BEGIN {
    @ATTR = qw(
      base_uri body image key title
    );

    for my $attr ( @ATTR ) {
        no strict 'refs';
        *$attr = sub {
            my $self = shift;
            croak "$attr may not be set" if @_;
            return $self->{$attr};
        };
    }
}

=head1 SYNOPSIS

    use WWW::TarPipe;

    my $tp = WWW::TarPipe->new( 
        key => '77c38f56696963fa13f5b6cd97a2556c' 
    );

    $tp->upload( 
        title => 'The outside temperature is 27C' 
    );
  
=head1 DESCRIPTION

tarpipe.com is a publishing mediation and distribution platform that
simplifies regular upload activities:

=over

=item * Publishing content to multiple Web locations;

=item * Combining different media into a single blog post or article;

=item * Transforming documents on-the-fly;

=item * Managing repeatable upload actions.

=back

You can learn more by visiting L<http://tarpipe.com/>.

=head1 INTERFACE 

=head2 C<< new >>

Create a new WWW::TarPipe. Accepts a number of key, value pairs. The
following arguments are recognised:

=over

=item C<< base_uri >>

The base URI for the tarpit REST service. Defaults to

    http://rest.receptor.tarpipe.net:8000/

=item C<< title >>

The title of the data being posted.

=item C<< body >>

A larger chunk of text associated with this post such as a blog post.

=item C<< image >>

A chunk of binary data - perhaps an image - for this post.

=item C<< key >>

The token generated when you save a REST API workflow.

=back

Any options not passed to C<< new >> may be passed to a subsequent call
to C<< upload >>, for example:

    my $tp = WWW::TarPipe->new( 
        key => '77c38f56696963fa13f5b6cd97a2556c' 
    );

    $tp->upload( 
        title => 'The outside temperature is 27C' 
    );

is equivalent to

    my $tp = WWW::TarPipe->new;

    $tp->upload( 
        key   => '77c38f56696963fa13f5b6cd97a2556c', 
        title => 'The outside temperature is 27C' 
    );

When making multiple posts to the same workflow it is convenient to
supply unchanging options as arguments to C<< new >> and pass those that
change to C<< upload >>.

=cut

sub new {
    my $class = shift;
    return bless {
        base_uri => $class->default_base_uri,
        $class->_check_args( @_ )
    }, $class;
}

=head2 C<< upload >>

Send an upload request to the tarpit.com REST service. A number of key,
value argument pairs should be passed. See C<< new >> above for details
of the arguments that can be specified.

    $tp->upload( 
        key   => '77c38f56696963fa13f5b6cd97a2556c',
        title => 'Hello, World',
        body  => "First Post!\nYay me!\n"
    );

If the request fails an exception will be thrown.

=cut

sub upload {
    my $self = shift;
    my %args = ( %$self, $self->_check_args( @_ ) );
    my $ua   = LWP::UserAgent->new;

    my $uri = delete $args{base_uri}
      or croak "base_uri must be supplied";
    my $key = delete $args{key}
      or croak "key must be supplied";

    my $resp = $ua->post(
        "$uri?key=$key",
        Content_Type => 'form-data',
        Content      => \%args
    );

    croak $resp->status_line if $resp->is_error;
    return $resp->content;

}

sub _check_args {
    my $self = shift;
    croak "Please supply a number of key, value pairs"
      if @_ % 1;
    my %args = @_;
    my %got  = ();

    for my $attr ( @ATTR ) {
        $got{$attr} = delete $args{$attr}
          if exists $args{$attr};
    }

    croak "Invalid options: ", join ', ', sort keys %args if keys %args;
    return %got;
}

=head2 Accessors

Each of the options that may be supplied to C<< new >> and C<< upload >>
have a corresponding read only accessor.

=head3 C<< base_uri >>

The base URI for the tarput service.

=head3 C<< title >>

The title of the post.

=head3 C<< body >>

The body of the post.

=head3 C<< image >>

Arbitrary image data.

=head3 C<< key >>

The REST key for the workflow.

=head3 C<< default_base_uri >>

Returns the default URI for the tarpipe service. May be overridden in
subclasses or by supplying the C<< base_uri >> option to C<< new >> or
C<< upload >>.

=cut

sub default_base_uri { 'http://rest.receptor.tarpipe.net:8000/' }

1;

__END__

=head1 CONFIGURATION AND ENVIRONMENT
  
WWW::TarPipe requires no configuration files or environment variables.

=head1 DEPENDENCIES

None.

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-www-tarpipe@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 AUTHOR

Andy Armstrong  C<< <andy@hexten.net> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2008, Andy Armstrong C<< <andy@hexten.net> >>.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.
