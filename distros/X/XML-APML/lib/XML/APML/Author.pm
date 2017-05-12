package XML::APML::Author;

use strict;
use warnings;

use base 'XML::APML::Node';

__PACKAGE__->tag_name('Author');

1;

__END__

=head1 NAME

XML::APML::Author - author markup

=head1 SYNOPSIS

    my $explicit_author = XML::APML::Author->new();
    $explicit_author->key();
    $explicit_author->value();

    my $implicit_author = XML::APML::Author->new(
        key     => 'Sample',
        value   => 0.5,
        from    => 'GatheringTool.com',
        updated => '2007-03-11T01:55:00Z',
    );

    print $implicit_author->key;
    print $implicit_author->value;
    print $implicit_author->from;
    print $implicit_author->updated;

    $source->add_author($explicit_author);

=head1 DESCRIPTION

Class that represents Author mark-up for APML.

=head1 METHODS

=head2 new

=head2 key

=head2 value

=head2 from

=head2 updated

=cut

