package Tie::Concurrent;

use strict;
use vars qw($VERSION);
use Carp;
use POSIX qw(:errno_h);
$VERSION = '0.05';

sub DEBUG () {0}

#######################################################
sub TIEHASH
{
    my($package, $self)=@_;
    
    unless($self->{READER} and $self->{WRITER}) {
        croak __PACKAGE__, "::TIEHASH needs READER and WRITER params";
    }
    my $p;

    foreach my $type (qw(READER WRITER)) {
        ($self->{$type.'_MODULE'}, @{$self->{$type}})=@{$self->{$type}};
    }
    return bless $self, $package;
}

#######################################################
sub _tie
{
    my($self, $type)=@_;
    my $data;
    my $tries=10;
    do {
        $data=eval {$self->{$type."_MODULE"}->TIEHASH(@{$self->{$type}})};
        if(not $data) {
            if($! != EAGAIN) {
                warn qq($self->{$type."_MODULE"}->TIEHASH(@{$self->{$type}}) failed: $!\n$@);
                return;
            }
            warn "$$: $tries attemps";
            $tries--;
            sleep 1;
        }
    } while(not $data and $tries > 0);
    return $data;
}

#######################################################
sub FETCH
{
    my $self=shift;
    
    my $data=$self->_tie('READER');
    croak "$$: Unable to tie data: $! ($@)" unless $data;
    return $data->FETCH(@_);
}

#######################################################
sub EXISTS
{
    my $self=shift;

    my $data=$self->_tie('READER');
    croak "$$: Unable to tie data: $! ($@)" unless $data;
    return $data->EXISTS(@_);
}





#######################################################
sub STORE
{
    my $self=shift;

    DEBUG and warn "Storing ", join ', ', @_;

    my $data=$self->_tie('WRITER');
    croak "$$: Unable to tie data: $! ($@)" unless $data;
    return $data->STORE(@_);
}

#######################################################
sub CLEAR
{
    my $self=shift;

    my $data=$self->_tie('WRITER');
    croak "$$: Unable to tie data: $! ($@)" unless $data;
    return $data->CLEAR(@_);
}

#######################################################
sub DELETE
{
    my $self=shift;

    my $data=$self->_tie('WRITER');
    croak "$$: Unable to tie data: $! ($@)" unless $data;
    my $rv=$data->FETCH(@_);        # work around a bug in MLDBM
    $data->DELETE(@_);
    return $rv;
}

#######################################################
sub FIRSTKEY
{
    my($self)=shift;
    my $data=$self->_tie('READER');
    croak "$$: Unable to tie data: $! ($@)" unless $data;

    $self->{_keys}=[];
    my $q=$data->FIRSTKEY;
    DEBUG and warn "first key=$q";
    while(defined $q) {
        push @{$self->{_keys}}, $q;
        $q=$data->NEXTKEY($q);
        DEBUG and warn "next key=$q" if defined $q;
    }
    return $self->NEXTKEY;
}

#######################################################
sub NEXTKEY
{
    my($self)=shift;
    return unless $self->{_keys};
    my $rv=shift @{$self->{_keys}};
    delete $self->{_keys} if 0==@{$self->{_keys}};
    return $rv;
}



1;
__END__
# Below is the stub of documentation for your module. You better edit it!

=head1 NAME

Tie::Concurrent - Paranoid tie for concurrent access

=head1 SYNOPSIS

    use Tie::Concurrent;
    tie %data, 'Tie::Concurrent', {READER=>[....], WRITER=>[....]};

=head1 DESCRIPTION

Modules like GDBM_File are fraught when you have potentialy many
readers/writers (like say in a long running forking daemon).  While they
might handle file locking properly, if any program holds the lock for too
long, others will not be able to write to the file.

This module solves the problem by doing a tie/operation/untie for each and
every operation.  NOTE THAT THIS IS ONE HUGE PERFORMANCE HIT.  Only use this
where all other methods fail.

The params to tie are :

=over 4

=item READER
    
Array ref that is used to tie the underlying hash when only reading is
desired.

=item WRITER

Array ref that is used to tie the underlying hash when writing is needed.


=back

=head1 EXAMPLE

    use Tie::Concurrent;
    use GDBM_File;
    use Storable;
    use MLDBM qw(GDBM_File Storable);

    my $file="search-cache.gdbm";

    my %cache;
    tie %cache, 'Tie::Concurrent', {
            READER=>['MLDBM', $file, GDBM_READER, 0660], 
            WRITER=>['MLDBM', $file, GDBM_WRCREAT, 0660]
    };

    
    my $res=$cache{$key};
    unless($res) {
        $res=very_long_search($key);
        $cache{$key}=$res;
    }
    print "\n", @$res;
            

=head1 NOTES

Please note that there are many problems with this aproach.  For instance,
in the above example, another process might have created $cache{$key} while
we did our search and those values would be lost.

If a process tries to lock the file whist another already has the lock, we
wait one second before trying again.  This is not very friendly if to things
like POE.

In fact, the truth is that Tie::Concurrent does locking only if the
underlying object does locking.  If you an AnyDBM_File which doesn't lock,
Tie::Concurrent isn't safe.  All it will gain you is that results are
automatically flushed each fetch/store.

=head1 BUGS

FIRSTKEY/NEXTKEY not implemented yet.

MLDBM spits out warnings if it can't tie the file.

MLDBM::DELETE is broken.  It does not return the deleted value.

=head1 AUTHOR

Philip Gwyn, E<lt>gwyn-at-cpan.orgE<gt>


=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Philip Gwyn

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=head1 SEE ALSO

perl(1).  perltie(1)

=cut
