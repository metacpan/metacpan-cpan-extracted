package Tie::Hash::Longest;

$VERSION='1.1';

use strict;

sub TIEHASH {
	my $class = shift;
	my $self = CLEAR({});
	return bless $self, $class;
}

sub longestkey {
    my $self = shift;
    rescan($self) if($self->{RESCAN_NEEDED});
    $self->{KEY};
}

sub longestvalue {
    my $self = shift;
    rescan($self) if($self->{RESCAN_NEEDED});
    $self->{VALUE};
}

# the no warnings here (and the one later) are so we can take length(undef)

sub rescan {
    no warnings;
    my $self = shift;
    $self->{KEY} = $self->{VALUE} = undef;
    foreach (keys %{$self->{CURRENT_STATE}}) {
        $self->{KEY} = $_ if(length($_) > length($self->{KEY}));
        $self->{VALUE} = $self->{CURRENT_STATE}->{$_}
            if(length($self->{CURRENT_STATE}->{$_}) > length($self->{VALUE}));
    }
    $self->{RESCAN_NEEDED} = 0;
}

sub CLEAR {
    my $self = shift;
    $self = {
        KEY           => undef,
        VALUE         => undef,
        CURRENT_STATE => {},
        RESCAN_NEEDED => 0
    };
}

sub STORE {
    no warnings;
    my($self, $key, $value)=@_;
    $self->{KEY} = $key unless(defined($self->{KEY}));
    $self->{VALUE} = $value unless(defined($self->{VALUE}));
    $self->{RESCAN_NEEDED} = 1 if(
        length($key) == length($self->{KEY}) ||
        length($self->{CURRENT_STATE}->{$key}) == length($self->{VALUE})
    );
    $self->{CURRENT_STATE}->{$key} = $value;
    $self->{KEY}   = $key   if(length($key)   > length($self->{KEY}));
    $self->{VALUE} = $value if(length($value) > length($self->{VALUE}));
}

sub FETCH {
    my($self, $key) = @_;
    $self->{CURRENT_STATE}->{$key};
}

sub FIRSTKEY {
    my $self = shift;
    scalar keys %{$self->{CURRENT_STATE}};
    scalar each %{$self->{CURRENT_STATE}};
}

sub DELETE {
    my($self, $key) = @_;
    $self->{RESCAN_NEEDED} = 1 if(
        $key eq $self->{KEY} ||
        $self->{CURRENT_STATE}->{$key} eq $self->{VALUE}
    );
    delete $self->{CURRENT_STATE}->{$key};
}

sub NEXTKEY { my $self = shift; scalar each %{$self->{CURRENT_STATE}}; }
sub EXISTS { my($self, $key) = @_; exists($self->{CURRENT_STATE}->{$key}); }

1;
__END__

=head1 NAME

Tie::Hash::Longest - A hash which knows its longest key and value

=head1 SYNOPSIS

  use Tie::Hash::Longest;

  tie my %hash, 'Tie::Hash::Longest';
  %hash = (
    a => 'ant',
    b => 'bear',
    elephant => 'e'
  );

  # prints elephant
  print tied(%hash)->longestkey();
  # prints bear 
  print tied(%hash)->longestvalue();

=head1 DESCRIPTION

This module implements a hash which remembers its longest key and value.
It avoids rescanning the entire hash whenever possible.

=head1 METHODS

The following methods are available.  Call them thus:

C<tied(%my_hash)-E<gt>methodname();>

=over 4

=item C<longestkey>

Return the longest key.

=item C<longestvalue>

Return the longest value.

=head1 AUTHOR

David Cantrell <david@cantrell.org.uk>.  I welcome feedback.

=head1 COPYRIGHT

Copyright 2001 David Cantrell.

This module is licensed under the same terms as perl itself.

=head1 SEE ALSO

Tie::Hash(3)

=cut
