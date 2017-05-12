package Tie::Parent;

use strict;
use warnings;
use vars qw($VERSION);

$VERSION = '1.10';

sub TIESCALAR {
    my $class = shift;
    my ($obj, $field) = @_;
    my $this = {'obj' => $obj, 'field' => $field};
    bless $this, $class;
}

sub FETCH {
    my $this = shift;
    return $this->{'obj'}->{$this->{'field'}} ||
             $this->{'obj'}->{uc($this->{'field'})} ||
             $this->{'obj'}->{lc($this->{'field'})};
}

sub STORE {
    my ($this, $value) = @_;
    $this->{'obj'}->{$this->{'field'}} = $value;
}

1;

__END__

=head1 NAME

Tie::Parent

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 SUBROUTINES/METHODS

=head2 TIESCALAR

=head2 FETCH

=head1 STORE

=head1 AUTHOR

Ariel Brosh, schop@cpan.org.
B<Tie::Cache> was written by Joshua Chamas, chamas@alumni.stanford.org

=head1 SEE ALSO

perl(1), L<Tie::Cache>.

=head1 COPYRIGHT

Tie::Collection is part of the HTPL package. See L<HTML::HTPL>

=cut
