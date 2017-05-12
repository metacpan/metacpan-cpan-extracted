package Tie::DeepTied;

use strict qw(vars subs);
use warnings;
use vars qw(@ISA $VERSION);

require Tie::Hash;

$VERSION = '1.10';
@ISA = qw(Tie::Hash);

sub TIEHASH {
    my ($class, $obj, $ind) = @_;
    my $this = {};
    bless $this, $class;
    $this->{'__obj'} = $obj;
    $this->{'__index'} = $ind;
    my $cell = $obj->FETCH($ind);
    $this->{'__storage'} = {%$cell};
    $this;
}

sub STORE {
    my ($this, $key, $value) = @_;
    $this->{'__last'} = time;
    $this->{'__storage'}->{$key} = $value;
    $this->{'__obj'}->STORE($this->{'__index'}, $this->{'__storage'});
    if (UNIVERSAL::isa($value, 'HASH')) {
        unless (tied(%$value)) {
            my %hash = %$value;
            tie %$value, 'Tie::StdHash', $this, $key; # Prevent infinite loop!
            %$value = %hash;
            tie %$value, 'Tie::DeepTied', $this, $key;
        }
    }
}

sub FETCH {
    my ($this, $key) = @_;
    my $value = $this->{'__storage'}->{$key};
    if (UNIVERSAL::isa($value, 'HASH')) {
        unless (tied(%$value)) {
            my %hash = %$value;
            tie %$value, 'Tie::StdHash', $this, $key; # Prevent infinite loop!
            %$value = %hash;
            tie %$value, 'Tie::DeepTied', $this, $key;
        }
    }
    $value;
}

sub DELETE {
    my ($this, $key) = @_;
    delete $this->{'__storage'}->{$key};
}

sub EXISTS {
    my ($this, $key) = @_;
    exists($this->{'__storage'}->{$key});
}

sub CLEAR {
    my $this = shift;
    $this->{'__storage'} = {};
}

sub FIRSTKEY { 
    my $this = shift;
    my $a = scalar keys %{$this->{'__storage'}}; 
    each %{$this->{'__storage'}};
}

sub NEXTKEY { 
    my $this = shift;
    each %{$this->{'__storage'}};
}

1;

__END__

=head1 NAME

Tie::DeepTied

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 SUBROUTINES/METHODS

=head2 TIEHASH

=head2 STORE

=head2 FETCH

=head2 DELETE

=head2 EXISTS

=head2 CLEAR

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
