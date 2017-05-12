package XML::NewsML_G2::Topic;

use Moose;
use namespace::autoclean;

with 'XML::NewsML_G2::Role::HasQCode';

__PACKAGE__->meta->make_immutable;

1;
__END__

=head1 NAME

XML::NewsML_G2::Topic - a temporary topic covered in the news item,
used to group related stories

=head1 SYNOPSIS

    my $topic = XML::NewsML_G2::Topic->new(name => 'Swine Flu', qcode => 'h1n1');

=head1 AUTHOR

Philipp Gortan  C<< <philipp.gortan@apa.at> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2013-2014, APA-IT. All rights reserved.

See L<XML::NewsML_G2> for the license.
