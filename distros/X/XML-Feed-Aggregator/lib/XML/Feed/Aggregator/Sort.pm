package XML::Feed::Aggregator::Sort;
BEGIN {
  $XML::Feed::Aggregator::Sort::VERSION = '0.0401';
}
use Moose::Role;
requires 'sort_entries';

sub sort_by_date {
   my ($self) = @_;

   $self->sort_entries(sub {
            my $adt = $_[0]->issued || $_[0]->modified;
            my $bdt = $_[1]->issued || $_[1]->modified;
            return $adt->compare($bdt);
        });

    return $self;
}

sub sort_by_date_ascending {
    my ($self) = @_;
    
    $self->sort_entries(sub {
            my $adt = $_[0]->issued || $_[0]->modified;
            my $bdt = $_[1]->issued || $_[1]->modified;
            return $bdt->compare($adt);
        });

    return $self;
}

sub sort {
    my ($self, $order) = @_;

    warn "Called deprecated method ->sort";

    if ($order eq 'desc') {
        $self->sort_by_date;
    }
    else {
        $self->sort_by_date_ascending;
    }

    return $self;
}

1;


=pod

=head1 NAME

XML::Feed::Aggregator::Sort

=head1 VERSION

version 0.0401

=head1 SYNOPSIS

  # builtin sort methods:

  $aggregator->sort_by_date_ascending;
  $aggregator->sort_by_date;

  # custom sort routine

  $aggregator->sort_entries(sub {
    $_[0]->title cmp $_[1]->title
  });

=head1 NAME

XML::Feed::Aggregator::Sort - Role for sorting feed entries

=head1 METHODS

=head2 sort_entries

Provide your own sorting routine via a CodeRef, two entries provided as arguments.

=head2 sort_by_date

Sort entries with date in descending order.

=head2 sort_by_date_ascending

Sort entries with date in ascending order.

=head1 SEE ALSO

L<XML::Feed::Aggregator>

L<XML::Feed::Aggregator::Deduper>

=head1 AUTHOR

Robin Edwards <robin.ge@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Robin Edwards.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

