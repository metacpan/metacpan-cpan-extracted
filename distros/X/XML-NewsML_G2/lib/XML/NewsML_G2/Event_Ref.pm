package XML::NewsML_G2::Event_Ref;

use Moose;
use namespace::autoclean;

has 'event_id', is => 'ro', isa => 'Str', required => 1;
has 'name',     is => 'ro', isa => 'Str', required => 1;

__PACKAGE__->meta->make_immutable;

1;
__END__

=head1 NAME

XML::NewsML_G2::Event_Ref - a reference to an event

=head1 SYNOPSIS

    my $news_item;
    my $evref = XML::NewsML_G2::Event_Ref->new
        (event_id => '1234', name => 'Monthly beer summit');
    $news_item->add_event_ref($evref);

=head1 ATTRIBUTES

=over 4

=item event_id

The unique id of the referenced event

=item name

The name of the referenced event

=back

=head1 AUTHOR

Christian Eder  C<< <christian.eder@apa.at> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2019, APA-IT. All rights reserved.

See L<XML::NewsML_G2> for the license.
