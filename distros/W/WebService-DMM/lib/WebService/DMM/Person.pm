package WebService::DMM::Person;
use strict;
use warnings;

use Class::Accessor::Lite (
    ro => [qw/id name ruby/],
);

1;

__END__

=encoding utf-8

=for stopwords

=head1 NAME

WebService::DMM::Person - Base class for DMM person classes.

=head1 AUTHOR

Syohei YOSHIDA E<lt>syohex@gmail.comE<gt>

=head1 COPYRIGHT

Copyright 2013 - Syohei YOSHIDA

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
