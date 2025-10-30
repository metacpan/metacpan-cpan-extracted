package YaraFFI::Event;

$YaraFFI::Event::VERSION   = '0.06';
$YaraFFI::Event::AUTHORITY = 'cpan:MANWAR';

=head1 NAME

YaraFFI::Event - Event class that stringifies to rule name but also works as a hash

=head1 VERSION

Version 0.06

=head1 SYNOPSIS

    use YaraFFI::Event;

    # Create a rule match event with metadata
    my $event = YaraFFI::Event->new(
        event    => 'rule_match',
        rule     => 'MalwareRule',
        metadata => {
            author      => 'Security Team',
            description => 'Detects malware',
            severity    => 5,
            active      => 1,
        },
    );

    print "Matched: $event\n";  # Stringifies to rule name
    print "Author: ", $event->metadata->{author}, "\n";
    print "Severity: ", $event->severity, "\n";

    # Create a string match event with offsets
    my $str_event = YaraFFI::Event->new(
        event     => 'string_match',
        rule      => 'MalwareRule',
        string_id => '$suspicious',
        offsets   => [0, 42, 128],
    );

    print "String: ", $str_event->string_id, "\n";
    print "Found at: ", join(", ", @{$str_event->offsets}), "\n";

=head1 DESCRIPTION

C<YaraFFI::Event> represents a scanning event from C<YARA>. It can be used as a string
(stringifies to the rule name) or as a hash/object to access event details.

Events are created during C<YARA> scans and passed to callback functions.

=head1 EVENT TYPES

=head2 rule_match

Emitted when a C<YARA> rule matches the scanned data.

    Fields:
        event    => 'rule_match'
        rule     => 'RuleName'
        metadata => { key => value, ... }  # Optional, rule metadata

=head2 string_match

Emitted when a string pattern within a rule matches.

    Fields:
        event     => 'string_match'
        rule      => 'RuleName'
        string_id => '$string_identifier'
        offsets   => [offset1, offset2, ...]  # Byte offsets where string matched

=head1 METHODS

=head2 new(%args)

Creates a new event object.

    my $event = YaraFFI::Event->new(
        event => 'rule_match',
        rule  => 'TestRule',
    );

=cut

use v5.14;
use strict;
use warnings;

use overload '""' => sub { $_[0]->{rule} }, fallback => 1;

sub new {
    my ($class, %args) = @_;
    return bless \%args, $class;
}

=head2 event

Returns the event type (C<rule_match> or C<string_match>).

    my $type = $event->event;

=cut

sub event {
    my ($self) = @_;
    return $self->{event};
}

=head2 rule

Returns the name of the matched rule.

    my $rule_name = $event->rule;

=cut

sub rule {
    my ($self) = @_;
    return $self->{rule};
}

=head2 metadata

Returns the rule metadata as a hash reference (rule_match events only).

    my $meta = $event->metadata;
    if ($meta) {
        print "Author: $meta->{author}\n";
        print "Severity: $meta->{severity}\n";
    }

=cut

sub metadata {
    my ($self) = @_;
    return $self->{metadata};
}

=head2 string_id

Returns the string identifier (C<string_match> events only).

    my $id = $event->string_id;  # e.g., '$suspicious'

=cut

sub string_id {
    my ($self) = @_;
    return $self->{string_id};
}

=head2 offsets

Returns an array reference of byte offsets where the string matched (C<string_match> events only).

    my $offsets = $event->offsets;
    for my $offset (@$offsets) {
        print "Match at byte $offset\n";
    }

=cut

sub offsets {
    my ($self) = @_;
    return $self->{offsets} || [];
}

=head2 Convenience Metadata Accessors

For common metadata fields, you can access them directly:

    my $author = $event->author;
    my $desc   = $event->description;
    my $sev    = $event->severity;

These return undef if the metadata doesn't exist or the field isn't present.

=cut

sub author {
    my ($self) = @_;
    return $self->{metadata} ? $self->{metadata}{author} : undef;
}

sub description {
    my ($self) = @_;
    return $self->{metadata} ? $self->{metadata}{description} : undef;
}

sub severity {
    my ($self) = @_;
    return $self->{metadata} ? $self->{metadata}{severity} : undef;
}

sub reference {
    my ($self) = @_;
    return $self->{metadata} ? $self->{metadata}{reference} : undef;
}

sub date {
    my ($self) = @_;
    return $self->{metadata} ? $self->{metadata}{date} : undef;
}

=head2 has_metadata

Returns true if the event has metadata.

    if ($event->has_metadata) {
        # Process metadata
    }

=cut

sub has_metadata {
    my ($self) = @_;
    return defined $self->{metadata} && ref $self->{metadata} eq 'HASH' && keys %{$self->{metadata}} > 0;
}

=head2 has_offsets

Returns true if the event has match offsets.

    if ($event->has_offsets) {
        print "Matches at: ", join(", ", @{$event->offsets}), "\n";
    }

=cut

sub has_offsets {
    my ($self) = @_;
    return defined $self->{offsets} && ref $self->{offsets} eq 'ARRAY' && @{$self->{offsets}} > 0;
}

=head2 match_count

Returns the number of times the string matched (for C<string_match> events).

    my $count = $event->match_count;

=cut

sub match_count {
    my ($self) = @_;
    return $self->{offsets} ? scalar(@{$self->{offsets}}) : 0;
}

=head2 is_rule_match

Returns true if this is a rule_match event.

    if ($event->is_rule_match) {
        # Handle rule match
    }

=cut

sub is_rule_match {
    my ($self) = @_;
    return $self->{event} && $self->{event} eq 'rule_match';
}

=head2 is_string_match

Returns true if this is a C<string_match> event.

    if ($event->is_string_match) {
        # Handle string match
    }

=cut

sub is_string_match {
    my ($self) = @_;
    return $self->{event} && $self->{event} eq 'string_match';
}

=head2 to_hash

Returns the event as a plain hash reference.

    my $hash = $event->to_hash;

=cut

sub to_hash {
    my ($self) = @_;
    return { %$self };
}

=head1 OVERLOADING

The event object overloads string concatenation, so it can be used directly
in print statements and will display the rule name:

    print "Matched: $event\n";  # Prints "Matched: RuleName"

=head1 AUTHOR

Mohammad Sajid Anwar, C<< <mohammad.anwar at yahoo.com> >>

=head1 REPOSITORY

L<https://github.com/manwar/YaraFFI>

=head1 BUGS

Please report any bugs or feature requests through the web interface at L<https://github.com/manwar/YaraFFI/issues>.
I will  be notified and then you'll automatically be notified of progress on your
bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc YaraFFI::Event

You can also look for information at:

=over 4

=item * BUG Report

L<https://github.com/manwar/YaraFFI/issues>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/YaraFFI>

=item * Search MetaCPAN

L<https://metacpan.org/dist/YaraFFI>

=back

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2025 Mohammad Sajid Anwar.

This program  is  free software; you can redistribute it and / or modify it under
the  terms  of the the Artistic License (2.0). You may obtain a  copy of the full
license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any  use,  modification, and distribution of the Standard or Modified Versions is
governed by this Artistic License.By using, modifying or distributing the Package,
you accept this license. Do not use, modify, or distribute the Package, if you do
not accept this license.

If your Modified Version has been derived from a Modified Version made by someone
other than you,you are nevertheless required to ensure that your Modified Version
 complies with the requirements of this license.

This  license  does  not grant you the right to use any trademark,  service mark,
tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge patent license
to make,  have made, use,  offer to sell, sell, import and otherwise transfer the
Package with respect to any patent claims licensable by the Copyright Holder that
are  necessarily  infringed  by  the  Package. If you institute patent litigation
(including  a  cross-claim  or  counterclaim) against any party alleging that the
Package constitutes direct or contributory patent infringement,then this Artistic
License to you shall terminate on the date that such litigation is filed.

Disclaimer  of  Warranty:  THE  PACKAGE  IS  PROVIDED BY THE COPYRIGHT HOLDER AND
CONTRIBUTORS  "AS IS'  AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES. THE IMPLIED
WARRANTIES    OF   MERCHANTABILITY,   FITNESS   FOR   A   PARTICULAR  PURPOSE, OR
NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY YOUR LOCAL LAW. UNLESS
REQUIRED BY LAW, NO COPYRIGHT HOLDER OR CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT,
INDIRECT, INCIDENTAL,  OR CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE
OF THE PACKAGE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut

1; # End of YaraFFI::Event
