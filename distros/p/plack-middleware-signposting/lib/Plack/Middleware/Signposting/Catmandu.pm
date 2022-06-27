package Plack::Middleware::Signposting::Catmandu;

our $VERSION = '0.06';

use Catmandu::Sane;
use Catmandu;
use Catmandu::Fix;
use Plack::Request;
use Plack::Util::Accessor;
use Moo;

extends 'Plack::Middleware::Signposting';

has store => (is => 'ro');
has bag => (is => 'ro');
has _bag => (is => 'lazy');
has fix => (is => 'ro');
has match_paths => (is => 'ro');
has _fixer => (is => 'lazy');

sub _build__bag {
    my ($self) = @_;
    Catmandu->store($self->store)->bag($self->bag);
}

sub _build__fixer {
    my ($self) = @_;
    Catmandu::Fix->new(fixes => [$self->fix]);
}

sub call {
    my ($self, $env) = @_;

    my $request = Plack::Request->new($env);
    my $res = $self->app->($env);

    my $bag = $self->_bag;
    my $fixer = $self->_fixer;

    # only get/head requests
    return $res unless $request->method =~ m{^get|head$}i;

    my $id;
    my $match_paths = $self->match_paths;
    foreach my $p (@$match_paths) {
        if ($request->path =~ /$p/) {
            $id = $1;
            last;
        }
    }

    return $res unless $id;

    # see http://search.cpan.org/~miyagawa/Plack-1.0044/lib/Plack/Middleware.pm#RESPONSE_CALLBACK
    return $self->response_cb($res, sub {
        my $res = shift;

        # ignore streaming response for now
        return unless ref $res->[2] eq 'ARRAY';

        my $data = $bag->get($id) || return;

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

Plack::Middleware::Signposting::Catmandu - A Signposting implementation from a Catmandu store

=head1 SYNOPSIS

    builder {
        enable "Plack::Middleware::Signposting::Catmandu",
            store => 'library',
            bag => 'books',
            fix => 'signs.fix', #optional
            match_paths => ['publication/(\w+)/*', 'record/(\w+)/*'],
            ;

        # ...
    };

=head1 SEE ALSO

L<Plack::Middleware>, L<Catmandu>

=cut
