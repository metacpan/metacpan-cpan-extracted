package Tie::Func;

use strict;
use warnings;
use vars qw($VERSION);

$VERSION = '1.10';

sub TIEHASH {
    my ($class, $fetch, $store, $del, %const) = @_;
    foreach (qw($fetch $store $del)) {
        eval "$_ = &$_ if ($_ && ref($_) !~ /CODE/);";
    }
    bless {'data' => \%const, '__fetch' => $fetch, '__store' => $store,
              '__del' => $del }, $class;
}

sub TIESCALAR {
    TIEHASH(shift, shift, shift, shift, 'this' => $_[3]);
}

sub FETCH {
    my ($this, $key) = @_;
    $key ||= 'this';
    my $code = $this->{'__fetch'};
    my $val = $this->{'data'}->{$key};
    $val = &$code($this, $key, $val) if ($code);
    $val;
}

sub STORE {
    my ($this, $key, $value) = @_;
    if (!defined($value)) {
        $value = $key;
        $key = 'this';
    }
    my $code = $this->{'__store'};
    $this->{'data'}->{$key} = $value if ($code && &$code($this, 
          $key, $value));
    return 1;
}

sub DELETE {
    my ($this, $key) = @_;
    my $code = $this->{'__del'};
    my $value = $this->{'data'}->{$key};
    return undef if ($code && !&$code($this, $key, $value));
    delete $this->{'data'}->{$key};
    1;
}

sub EXISTS {
    my ($this, $key) = @_;
    exists $this->{'data'}->{$key};
}

sub FIRSTKEY {
    my $this = shift;
    keys %{$this->{'data'}};
    each %{$this->{'data'}};
}

sub NEXTKEY {
    my $this = shift;
    each %{$this->{'data'}};
}

1;

__END__

=head1 NAME

Tie::Func

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 SUBROUTINES/METHODS

=head2 TIEHASH

=head2 TIESCALAR

=head2 FETCH

=head2 STORE

=head2 DELETE

=head2 EXISTS

=head2 FIRSTKEY

=head2 NEXTKEY

=head1 AUTHOR

Ariel Brosh, schop@cpan.org.
B<Tie::Cache> was written by Joshua Chamas, chamas@alumni.stanford.org

=head1 SEE ALSO

perl(1), L<Tie::Cache>.

=head1 COPYRIGHT

Tie::Collection is part of the HTPL package. See L<HTML::HTPL>

=cut

