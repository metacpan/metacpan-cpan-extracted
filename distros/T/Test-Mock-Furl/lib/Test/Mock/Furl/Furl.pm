package Test::Mock::Furl::Furl;
use strict;
use warnings;
use Test::MockObject;
use parent 'Exporter';
our @EXPORT = qw/$Mock_furl/;

our $Mock_furl;

BEGIN {
    $Mock_furl = Test::MockObject->new;
    $Mock_furl->fake_module('Furl');
    $Mock_furl->fake_new('Furl');
}

package # hide from PAUSE
    Furl;
use strict;
use warnings;

our $VERSION = 'Mocked';

1;

__END__

=head1 NAME

Test::Mock::Furl::Furl - Mock Furl


=head1 SYNOPSIS

    use Test::Mock::Furl;


=head1 DESCRIPTION

See L<Test::Mock::Furl> page for more details.


=head1 AUTHOR

Dai Okabayashi E<lt>bayashi@cpan.orgE<gt>


=head1 SEE ALSO

L<Test::Mock::Furl>

The code of this module was almost copied from L<Test::Mock::LWP>.


=head1 LICENSE

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=cut
