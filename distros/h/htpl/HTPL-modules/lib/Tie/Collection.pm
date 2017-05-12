package Tie::Collection;
use Tie::Cache;
use strict;
use vars qw(@ISA);

@ISA = qw(Tie::Cache);

sub TIEHASH {
    my ($class, $storage, $ref, $bless) = @_;
    my $this = Tie::Cache::TIEHASH($class, $ref);
    bless $this, $class;
    $this->{'Storage'} = $storage;
    $this->{'Bless'} = $bless;
    $this;
}

sub read {
    my ($self, $key) = @_;
    my $s = $self->{'Storage'};
    my $el = $s->EXISTS($key) ? $s->FETCH($key) : undef;
    my $bless = $self->{'Bless'};
    if ($bless && $el) {
        bless $el, $bless;
        eval '$el->postload;';
    }
    $el;
}

sub write {
    my ($self, $key, $value) = @_;
    my $bless = $self->{'Bless'};
    eval '$value->prestore;' if ($bless && ref($value) =~ /$bless/);
    $self->{'Storage'}->STORE($key, $value);
}

1;

__END__

=head1 NAME

Tie::Collection - A trivial implementaion of Tie::Cache by using a tied
handle of a hash for storage.

=head1 SYNOPSIS

use Tie::Collection;
use DB_File;
use Fcntl;

$dbm = tie %hash2, DB_File, 'file.db', O_RDWR | O_CREAT, 0644;
tie %hash, Tie::Collection, $dbm, {MaxBytes => $cache_size};

=head1 DESCRIPTION

Tie::Collection implements a trivial implementation of B<Tie::Cache> by 
Joshua Chamas, that gets a tied hash handle to store the data. Assumption
was that most common use will be disk storage, therfore the storage hash
will probably be tied.

Tie::Collection is useful with B<DB_File> or B<MLDBM>, as will as with
B<Tie::DBI>. It was designed to be used with B<HTML::HTPL> in order to
cache objects accesses via a key, so they don't have to be read from disk
again and again.

Tie::Collection needs two parameters: The handled of the tied hash, and a
hashref with parameters to pass to B<Tie::Cache>. (See manpage).

=head1 AUTHOR

Ariel Brosh, schop@cpan.org.
B<Tie::Cache> was written by Joshua Chamas, chamas@alumni.stanford.org

=head1 SEE ALSO

perl(1), L<Tie::Cache>.

=head1 COPYRIGHT

Tie::Collection is part of the HTPL package. See L<HTML::HTPL>

=cut
