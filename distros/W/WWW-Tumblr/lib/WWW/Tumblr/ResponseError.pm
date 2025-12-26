package WWW::Tumblr::ResponseError;

use Moose;
use Data::Dumper;
use JSON 'decode_json';

has 'response', is => 'rw', isa => 'HTTP::Response';

sub code    { $_[0]->response->code }

sub is_rate_limited {
    my $self = shift;
    # Check for HTTP 429 (Too Many Requests) or 400 with rate limit error code
    return 1 if $self->code == 429;
    
    if ($self->code == 400) {
        my $content = $self->response->decoded_content;
        my $j;
        eval { $j = JSON::decode_json($content); };
        return 0 if $@;
        
        # Check for Tumblr's rate limit error code 8004
        if (ref $j eq 'HASH' && ref $j->{response} eq 'HASH' &&
            ref $j->{response}{errors} eq 'ARRAY') {
            for my $err (@{$j->{response}{errors}}) {
                return 1 if ref $err eq 'HASH' && ($err->{code} || 0) == 8004;
            }
        }
    }
    return 0;
}
sub reasons  {
    my $self = $_[0];
    my $content = $_[0]->response->decoded_content;
    my $j;
    eval { $j = decode_json($content); };
    if ($@) {
        # Response is not valid JSON, return HTTP message
        return [ $self->response->message || 'Unknown error' ];
    }
    if ( ref $j && ref $j eq 'HASH' ) {
        if ( ref $j->{response} && ref $j->{response} eq 'ARRAY' ) {
            unless ( scalar @{ $j->{response} }) {
                return [ $self->response->message ]
            }
            return $j->{response};
        } elsif ( ref $j->{response} && ref $j->{response} eq 'HASH' &&
            defined $j->{response}->{errors}  
        ) {
            if ( ref $j->{response}->{errors} eq 'HASH' &&
                defined $j->{response}->{errors}->{state} ) {
                return [ 
                    $j->{response}->{errors}->{0},
                    $j->{response}->{errors}->{state}
                ];
            } elsif ( ref $j->{response}->{errors} eq 'ARRAY' ) {
                return $j->{response}->{errors};
            } else {
                Carp::croak "Unimplemented";
            }
        } else {
            Carp::croak "Unimplemented";
        }
    } else {
        Carp::croak "Unimplemented";
    }
}

1;

=pod

=head1 NAME

WWW::Tumblr::ResponseError

=head1 SYNOPSIS

  my $posts = $tumblr->blog('stupidshit.tumblr.com')->posts;

  die "Couldn't get posts! " . Dumper( $tumblr->error->reasons ) unless $posts;

=head1 DESCRIPTION

This a class representing L<WWW::Tumblr>'s C<error> method. It contains the
response from upstream Tumblr API.

=head1 METHODS

=head2 error

Callable from a model context, usually L<WWW::Tumblr>.

  print Dumper $tumblr->error unless $post;

=head2 code

HTTP response code for the error:

  my $info = $blog->info;
  print $blog->error->code . ' nono :(' unless $info;

=head2 reasons

Commodity method to display reasons why the error ocurred. It returns an array
reference:

  unless ( $some_tumblr_action ) {
    print "Errors! \n";
    print $_, "\n" for @{ $tumblr->error->reasons || [] };
  }

=head1 BUGS

Please refer to L<WWW::Tumblr>.

=head1 AUTHOR(S)

The same folks as L<WWW::Tumblr>.

=head1 SEE ALSO

L<WWW::Tumblr>, L<WWW::Tumblr::ResponseError>.

=head1 COPYRIGHT and LICENSE

Same as L<WWW::Tumblr>.

=cut

