package YYZ;

use strict;
use warnings;

use XXX;

use Carp;
use Exporter qw(import);

our $VERSION = '2112.1001001';
our @EXPORT = qw(YYZ);


=head1 NAME

YYZ - Like XXX but dump arguments in a stack

=head1 SYNOPSIS

    use YYZ;

    my $song = YYZ Song->new(
        band    => "Rush",
        name    => "YYZ",
        length  => "7:47",
        albumn  => "Exit... Stage Left",
        type    => ["Instrumental", "Drum Solo"]
    );

=head1 DESCRIPTION

Similar to XXX, but this supplies the critically overlooked obvious Rush reference.

=head1 FUNCTIONS

=head3 YYZ

Like YYY + ZZZ, it will Carp::Confess a dump of its arguments and then
return the original.

=cut

sub YYZ {
    my $dump = Carp::longmess(XXX::_xxx_dump(@_));

    if (defined &main::note and
        defined &Test::More::note and
        \&main::note eq \&Test::More::note
    ) {
        main::note($dump);
    }
    else {
        warn $dump;
    }

    return wantarray ? @_ : $_[0];
}

=head1 COPYRIGHT and LICENSE

Copyright 2011 by Michael G Schwern E<lt>schwernE<0x40>pobox.comE<gt>.

This program is free software; you can redistribute it and/or 
modify it under the same terms as Perl itself.

See L<http://dev.perl.org/licenses/artistic.html>


=head1 SEE ALSO

L<XXX>,
L<http://www.youtube.com/watch?v=jKBLSkN2sRk>,
L<https://secure.wikimedia.org/wikipedia/en/wiki/Yyz>

=cut

"Neil Peart taught Chuck Norris how to play the drums";
