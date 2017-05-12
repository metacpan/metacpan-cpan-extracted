package WWW::Yahoo::Smushit;

use strict;
use warnings;
use Moose;
use LWP::UserAgent;
use JSON;

our $VERSION = '0.03';

has _ua => (
    is       => 'rw',
    lazy     => 1,
    required => 1,
    default  => sub { LWP::UserAgent->new; }
);

has _service_url => (
    is       => 'ro',
    isa      => 'Str',
    default  => 'http://www.smushit.com/ysmush.it/ws.php?img=',
    required => 1
);

sub upload_by_url {
    my ($self, $img_url) = @_;

    my $req  = $self->_ua->get($self->_service_url . $img_url);

    my $json = JSON->new->allow_nonref;
    my $resp = $json->decode($req->content);
    return 1
      if($self->_create_attrs_from_json($resp));

    return 0;
}

sub _create_attrs_from_json {
    my ($self, $json) = @_;

    for (keys %{$json}) {
        $self->meta->add_attribute($_, is => 'rw');
        $self->$_($json->{$_});
    }

    $self->meta->make_immutable;

    return 0
      if not keys %{$json}
          or defined $json->{error};
    return 1;
}

1;

__END__

=encoding utf8

=head1 NAME

WWW::Yahoo::Smushit - Perl interface to Yahoo Smushit image optimizer

=head1 SYNOPSIS

    my $st = new WWW::Yahoo::Smushit;

    if($st->upload_by_url('http://img3.imageshack.us/img3/562/synyrt2.jpg')) {
        printf("Image url:\t%s\nNew image:\t%s\nNew size:\t%s\nOld size:\t%s\nPercent:\t%s%%\n",
            $st->src, $st->dest, $st->dest_size, $st->src_size, $st->percent);
    }
    else {
        printf("Oops! Something is wrong...\n\nError:\t%s\n", $st->error);
    }

=head1 DESCRIPTION

Smush.it is a service to optimize images, removing some unnecessary data.

=head1 METHODS

=head2 upload_by_url($img_url)

Send a request to the Smushit via http and retrieves the JSON object.

=head1 INTERNALS

=head2 _create_attrs_from_json

Get the JSON and create the attributes.

=head2 SEE ALSO

L<Smushit|http://smush.it/>.

=head1 AUTHOR

Junior Moraes <fvox@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 by Junior Moraes

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself, either Perl version 5.8.4 or, at your option, any later version of Perl 5 you may have available.

=cut
