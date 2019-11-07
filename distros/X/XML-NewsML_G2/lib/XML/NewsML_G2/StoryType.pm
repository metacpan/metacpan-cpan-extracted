package XML::NewsML_G2::StoryType;

use Moose;
use namespace::autoclean;

with 'XML::NewsML_G2::Role::HasQCode';

__PACKAGE__->meta->make_immutable;

1;
__END__

=head1 NAME

XML::NewsML_G2::Story - the story type of the news item

=head1 SYNOPSIS

    my $story_type = XML::NewsML_G2::StoryType->new(name => 'Breaking news', qcode => 'Break');

=head1 AUTHOR

Christian Eder  C<< <christian.eder@apa.at> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2019, APA-IT. All rights reserved.

See L<XML::NewsML_G2> for the license.
