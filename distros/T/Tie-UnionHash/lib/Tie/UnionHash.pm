package Tie::UnionHash;

=head1 NAME

Tie::UnionHash -  Union hashes. Make changes to the last hash in arguments ( depend on option <freeze_keys>).

=head1 SYNOPSIS

   use Tie::UnionHash;
    
   tie %uhash, 'Tie::UnionHash', \%hash1ro, \%hash2rw;
   
   tie %hashu, 'Tie::UnionHash', \%hash1, \%hash2, 'freeze_keys' ;

=head1 DESCRIPTION

Tie::UnionHash - Merge multiple hashes into a one hash. Make changes only to the last hash in arguments, unless used option I<freeze_keys>.

Tie::UnionHash can handle anything that looks like a hash; just give it a reference as one of the additional arguments to tie(). This includes other tied hashes, so you can include DB and DBM files as data sources for a union hash. If given a plain name instead of a reference, it will use as option.

UnionHash correctly distinguish deleted keys.

    my %hash1 = ( 1 => 1, 3 => 3 );
    my %hash2 = ( 2 => 2, 3 => 3 );
    my %hashu;
    tie %hashu, 'Tie::UnionHash', \%hash1, \%hash2;
    # keys %hashu  is [ '1', '2', '3' ]
    $hashu{3} = 4 #change %hash2;
    delete $hashu{3} #change %hash2 and track deleted keys
    exist $hashu{3} # false, but exists in read only hashes

Option I<freeze_keys> will change mode to readonly keys in hashes, except last hash in arguments.

    my %hash1 = ( 1 => 1, 3 => 3 );
    my %hash2 = ( 2 => 2, 3 => 3 );
    my %hashu;
    tie %hashu, 'Tie::UnionHash', \%hash1, \%hash2, 'freeze_keys' ;
    $hashu{3} = 4 #make changes to   %hash1 :  ( 1 => 1, 3 => 4 );
    $hashu{NEW_KEY} = 1 # make changes to   %hash2 :
                        #( 2 => 2, 3 => 3,  NEW_KEY =>1 );;
 
 
=cut

use strict;
use warnings;
use strict;
use Carp;
use Data::Dumper;
require Tie::Hash;
@Tie::UnionHash::ISA     = qw(Tie::StdHash);
$Tie::UnionHash::VERSION = '0.02';

### install get/set accessors for this object.
for my $key (qw( _orig_hashes _for_write __temp_array _opt _deleted_keys)) {
    no strict 'refs';
    *{ __PACKAGE__ . "::$key" } = sub {
        my $self = shift;
        $self->{$key} = $_[0] if @_;
        return $self->{$key};
      }
}

sub new {
    my $class = shift;
    $class = ref $class if ref $class;
    my $self   = bless( {}, $class );
    my %opt    = ();
    my @hashes = ();
    foreach my $par (@_) {
        if ( ref($par) ) {
            push @hashes, $par;
            next;
        }
        $opt{$par} = 1;
    }
    $self->_for_write( $hashes[-1] );
    $self->_orig_hashes( \@hashes );
    $self->_opt( \%opt );
    $self->_deleted_keys( {} );
    $self;
}

#delete keys only from _for_write hashe!
sub DELETE {
    my ( $self, $key ) = @_;
    delete $self->_for_write->{$key};
    $self->_deleted_keys->{$key}++ unless $self->_opt->{freeze_keys};
}

sub STORE {
    my ( $self, $key, $val ) = @_;
    my $hashes = $self->_orig_hashes;

    #restore key from deleted
    delete $self->_deleted_keys->{$key};

    #set changes only in rw hash
    return $self->_for_write->{$key} = $val unless $self->_opt->{freeze_keys};
    foreach my $hash (@$hashes) {
        next unless exists $hash->{$key};
        return $hash->{$key} = $val;
    }
    $self->_for_write->{$key} = $val;
}

sub FETCH {
    my ( $self, $key ) = @_;
    my $hashes = $self->_orig_hashes;
    unless ( $self->_opt->{freeze_keys} ) {

        #skip deleted keys
        return                           if exists $self->_deleted_keys->{$key};
        return $self->_for_write->{$key} if exists $self->_for_write->{$key};
    }
    foreach my $hash (@$hashes) {
        next unless exists $hash->{$key};
        return $hash->{$key};
    }
    return;
}

sub GetKeys {
    my $self   = shift;
    my $hashes = $self->_orig_hashes;
    my %uniq;
    foreach my $hash (@$hashes) {
        $uniq{$_}++ for keys %$hash;
    }

    #skip deleted keys
    unless ( $self->_opt->{freeze_keys} ) {
        my $del_keys_map = $self->_deleted_keys;
        for ( keys %uniq ) {
            delete $uniq{$_}
              if exists $del_keys_map->{$_};
        }
    }
    return [ keys %uniq ];
}

sub TIEHASH { shift; return __PACKAGE__->new(@_) }

sub FIRSTKEY {
    my ($self) = @_;
    $self->__temp_array( [ sort { $a cmp $b } @{ $self->GetKeys() } ] );
    shift( @{ $self->__temp_array() } );
}

sub NEXTKEY {
    my ( $self, $key ) = @_;
    shift( @{ $self->__temp_array() } );
}

sub EXISTS {
    my ( $self, $key ) = @_;
    my $hashes = $self->_orig_hashes;
    my %tmp;
    @tmp{ @{ $self->GetKeys } } = ();
    return exists $tmp{$key};
}

sub CLEAR {
    my $self = shift;
    $self->DELETE($_) for @{ $self->GetKeys };
}

1;
__END__


=head1 SEE ALSO

Tie::StdHash

=head1 AUTHOR

Zahatski Aliaksandr, <zag@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005-2007 by Zahatski Aliaksandr

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut

