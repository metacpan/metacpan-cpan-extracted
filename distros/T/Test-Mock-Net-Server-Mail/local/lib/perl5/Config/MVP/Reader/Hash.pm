package Config::MVP::Reader::Hash;
# ABSTRACT: a reader that tries to cope with a plain old hashref
$Config::MVP::Reader::Hash::VERSION = '2.200011';
use Moose;
extends 'Config::MVP::Reader';

#pod =head1 SYNOPSIS
#pod
#pod   my $sequence = Config::MVP::Reader::Hash->new->read_config( \%config );
#pod
#pod =head1 DESCRIPTION
#pod
#pod In some ways, this is the L<Config::MVP::Reader> of last resort.  Given a
#pod hashref, it attempts to interpret it as a Config::MVP::Sequence.  Because
#pod hashes are generally unordered, order can't be relied upon unless the hash tied
#pod to have order (presumably with L<Tie::IxHash>).  The hash keys are assumed to
#pod be section names and will be used as the section package moniker unless a
#pod L<__package> entry is found.
#pod
#pod =cut

sub read_into_assembler {
  my ($self, $location, $assembler) = @_;

  confess "no hash given to $self" unless my $hash = $location;

  for my $name (keys %$hash) {
    my $payload = { %{ $hash->{ $name } } };
    my $package = delete($payload->{__package}) || $name;

    $assembler->begin_section($package, $name);

    for my $key (%$payload) {
      my $val = $payload->{ $key };
      my @values = ref $val ? @$val : $val;
      $assembler->add_value($key => $_) for @values;
    }

    $assembler->end_section;
  }

  return $assembler->sequence;
}

no Moose;
__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Config::MVP::Reader::Hash - a reader that tries to cope with a plain old hashref

=head1 VERSION

version 2.200011

=head1 SYNOPSIS

  my $sequence = Config::MVP::Reader::Hash->new->read_config( \%config );

=head1 DESCRIPTION

In some ways, this is the L<Config::MVP::Reader> of last resort.  Given a
hashref, it attempts to interpret it as a Config::MVP::Sequence.  Because
hashes are generally unordered, order can't be relied upon unless the hash tied
to have order (presumably with L<Tie::IxHash>).  The hash keys are assumed to
be section names and will be used as the section package moniker unless a
L<__package> entry is found.

=head1 AUTHOR

Ricardo Signes <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Ricardo Signes.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
