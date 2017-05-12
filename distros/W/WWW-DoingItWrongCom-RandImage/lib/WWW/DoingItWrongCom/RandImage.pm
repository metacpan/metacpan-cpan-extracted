package WWW::DoingItWrongCom::RandImage;

use warnings;
use strict;

our $VERSION = '1.01';

use Carp;
use URI;
use LWP::UserAgent;
use HTML::TokeParser::Simple;

sub new {
    my $class = shift;
    croak "Must have event number of arguments to ->new()"
        if @_ & 1;

    my %args = @_;
    $args{ lc $_ } = delete $args{ $_ } for keys %args;

    unless ( exists $args{ua_args}{timeout} ) {
        $args{ua_args}{timeout} = 30;
    }

    my $self = bless \%args, $class;

    $self->{site_uri} = 'http://www.doingitwrong.com/';

    return $self;
}

sub fetch {
    my $self = shift;

    $self->err_msg( undef );

    my $ua = LWP::UserAgent->new( %{ $self->{ua_args} || {} } );

    my $response = $ua->get( $self->{site_uri} );

    if ( $response->is_success ) {
        return $self->_parse_response( $response->content );
    }
    else {
        $self->err_msg( $response->status_line );
        return undef;
    }

    undef;
}

sub _parse_response {
    my $self = shift;
    my $content = shift;

    my $parser = HTML::TokeParser::Simple->new( \$content );
    while ( my $token = $parser->get_token ) {
        if ( $token->is_start_tag('img') ) {
            my $return_uri = URI->new( $self->{site_uri} );
            $return_uri->path( $token->get_attr('src') );

            return $return_uri;
        }
    }
    $self->err_msg('Parser could not find the image');
    return undef;
}

sub err_msg {
    my $self = shift;
    if ( @_ ) {
        $self->{ ERR_MSG } = shift;
    }
    return $self->{ ERR_MSG };
}

1;
__END__

=encoding utf8

=head1 NAME

WWW::DoingItWrongCom::RandImage - fetch random image from
L<http://www.doingitwrong.com>

=head1 SYNOPSIS

    use strict;
    use warnings;
    use WWW::DoingItWrongCom::RandImage;

    my $wrong = WWW::DoingItWrongCom::RandImage->new;

    my $wrong_pic = $wrong->fetch
        or die "Failed to get the picture: " . $wrong->err_msg;

    print "You are doing it wrong: $wrong_pic\n";

=head1 DESCRIPTION

The module is basic and simple. All it does is access
L<http://www.doingitwrong.com> and return a URI to a random image.

=head1 CONSTRUCTOR

=head2 new

    my $wrong = WWW::DoingItWrongCom::RandImage->new;

    my $wrong = WWW::DoingItWrongCom::RandImage->new(
        ua_args => {
            timeout => 20,
            agent   => 'WrongAgent',
        },
    );

The C<new()> method I<returns a WWW::DoingItWrongCom::RandImage object>.
It takes one I<optional> argument:

=head3 ua_args

    my $wrong = WWW::DoingItWrongCom::RandImage->new(
        ua_args => {
            timeout => 20,
            agent   => 'WrongAgent',
        },
    );

B<Optional>. The C<ua_args> argument takes a hashref as a value which
will be passed to L<LWP::UserAgent> object constructor. See
L<LWP::UseAgent> documentation for possible keys/values. B<By default>
the default L<LWP::UserAgent>'s constructor will be used I<except> for
C<timeout> which, unless specified by you, will default to C<30> seconds.

=head1 METHODS

=head2 fetch

    my $wrong_pic = $wrong->fetch
        or die "Failed to get the picture: " . $wrong->err_msg;

The C<fetch()> method instructs WWW::DoingItWrongCom::RandImage to fetch
a random image from L<http://www.doingitwrong.com> and I<returns a>
L<URI> object (which is overloaded, thus can be treated as a string) which
will point to the random image from L<http://www.doingitwrong.com>.
If an error occured during the process, C<fetch()> will return C<undef>
and the error explanation will be accessible via C<err_msg()> method
(see below).

=head2 err_msg

    my $wrong_pic = $wrong->fetch
        or die "Failed to get the picture: " . $wrong->err_msg;

If an error occured during the fetching of the URI of the image,
the C<fetch()> method will return C<undef>. The explanation of the error
will be avalable via C<err_msg()> method.

=head1 PREREQUISITES

For healthy operation module requires the following modules/versions:

    'Carp'                     => 1.04,
    'URI'                      => 1.35,
    'LWP::UserAgent'           => 2.036,
    'HTML::TokeParser::Simple' => 3.15,

It might work well with earlier versions of the above modules, but it
wasn't tested with those.

=head1 AUTHOR

Zoffix Znet, C<< <zoffix at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-www-doingitwrongcom-randimage at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WWW-DoingItWrongCom-RandImage>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WWW::DoingItWrongCom::RandImage

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WWW-DoingItWrongCom-RandImage>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WWW-DoingItWrongCom-RandImage>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WWW-DoingItWrongCom-RandImage>

=item * Search CPAN

L<http://search.cpan.org/dist/WWW-DoingItWrongCom-RandImage>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2008 Zoffix Znet, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut
