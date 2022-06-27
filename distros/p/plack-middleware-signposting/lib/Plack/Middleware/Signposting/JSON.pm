package Plack::Middleware::Signposting::JSON;

our $VERSION = '0.06';

use Catmandu::Sane;
use Catmandu;
use Catmandu::Fix;
use JSON qw(decode_json);
use Plack::Request;
use Plack::Util::Accessor qw(fix);
use Moo;

extends 'Plack::Middleware::Signposting';

sub call {
    my ($self, $env) = @_;

    my $request = Plack::Request->new($env);
    my $res = $self->app->($env);

    # only get/head requests
    return $res unless $request->method =~ m{^get|head$}i;

    # see http://search.cpan.org/~miyagawa/Plack-1.0044/lib/Plack/Middleware.pm#RESPONSE_CALLBACK
    return $self->response_cb($res, sub {
        my $res = shift;

        my $content_type = Plack::Util::header_get($res->[1], 'Content-Type') || '';
        # only json responses
        return unless $content_type =~ m{^application/json|application\/vnd\.api\+json}i;
        # ignore streaming response for now
        return unless ref $res->[2] eq 'ARRAY';

        my $body = join('', @{$res->[2]});
        my $data = decode_json($body);

        if (ref $data && ref $data eq 'ARRAY') {
            $data = $data->[0];
        }

        my $fix = $self->fix ? $self->fix : 'nothing()';
        my $fixer = Catmandu::Fix->new(fixes => [$fix]);
        $fixer->fix($data);

        # add information to the 'Link' header
        if ($data->{signs}) {
            Plack::Util::header_push(
                $res->[1],
                'Link' => $self->to_link_format( @{$data->{signs}} )
            );
        }
    });
}

1;

__END__

=encoding utf-8

=head1 NAME

Plack::Middleware::Signposting::JSON - A Signposting implementation for JSON content

=head1 SYNOPSIS

    my $json_string = '{"hello":"world",....}';
    builder {
       enable "Plack::Middleware::Signposting::JSON";

       sub { 200, [ 'Content-Type' => 'text/plain' ], [ $json_string ] };
    };

=head1 SEE ALSO

L<Plack::Middleware>

=cut
