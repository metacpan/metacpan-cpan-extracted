package XML::Feed::Deduper;
use strict;
use warnings;
use 5.008008;

our $VERSION = '0.06';

use XML::Feed;

use Mouse;

no Mouse;

sub BUILD {
    my ($self, $args) = @_;
    my $engine = delete $args->{engine} || 'DB_File';
    $engine = $engine =~ s/^\+// ? $engine : "@{[ __PACKAGE__ ]}::${engine}";
    Mouse::Util::load_class($engine);
    my $instance = $engine->new($args) or die 'wtf?';
    $self->{engine} = $instance;
}

sub dedup {
    my ($self, @entries) = @_;
    my $engine = $self->{engine} or die 'wtf?';

    my @res;
    for my $entry (@entries) {
        next unless $engine->is_new($entry);
        push @res, $entry;
        $engine->add($entry);
    }
    return @res;
}

__END__

=encoding utf-8

=for stopwords deduper

=head1 NAME

XML::Feed::Deduper - remove duplicated entries from feed

=head1 SYNOPSIS

    use XML::Feed;
    use XML::Feed::Deduper;
    my $feed = XML::Feed->parse($content);
    my $deduper = XML::Feed::Deduper->new(
        path => '/tmp/foo.db',
    );
    for my $entry ($deduper->dedup($feed->entries)) {
        # only new entries come here!
    }

=head1 DESCRIPTION

XML::Feed::Deduper is deduper for XML::Feed.

You can write the aggregator more easily :)

The concept is stolen from L<Plagger::Rule::Deduper>.

Enjoy!

=head1 CAUTION

This module is still in its beta quality.

your base are belongs to us!

=head1 AUTHOR

Tokuhiro Matsuno E<lt>tokuhirom@gmail.comE<gt>

=head1 SEE ALSO

L<Plagger::Rule::Deduper>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
