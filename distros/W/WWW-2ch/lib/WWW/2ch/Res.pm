package WWW::2ch::Res;
use strict;

use base qw( Class::Accessor::Fast );
__PACKAGE__->mk_accessors( qw( c key resid num name mail date time id be body ) );

sub new {
    my $class = shift;
    my $c = shift;
    my $opt = shift;
    my $self = bless $opt, $class;
    $self->c($c);
    $self;
}

sub body_text {
    my $self = shift;
    my $body = $self->body;
    $body =~ s/<br>/\n/ig;
    $body =~ s/<[^>]*>//g;
    $body =~ s/&lt;/</g;
    $body =~ s/&gt;/>/g;
    $body;
}

sub permalink {
    my ($self) = @_;
    $self->c->worker->permalink($self->key, $self->resid);
}

1;

__END__

=head1 NAME

WWW::2ch::Res - remark of BBS is treated. 


=head1 Method

=over 4

=item key

=item resid

=item num

=item name

=item mail

=item date

=item time

=item body

=item body_text

=item id

=item be


=back

=head1 SEE ALSO

L<WWW::2ch::Dat>

=head1 AUTHOR

Kazuhiro Osawa

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Kazuhiro Osawa

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.5 or,
at your option, any later version of Perl 5 you may have available.

=cut
