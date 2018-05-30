=head1 Name

qbit::Hash - Functions to manipulate hashes.

=cut

package qbit::Hash;
$qbit::Hash::VERSION = '2.6';
use strict;
use warnings;
use utf8;
use base qw(Exporter);

BEGIN {
    our (@EXPORT, @EXPORT_OK);

    @EXPORT = qw(
      hash_transform push_hs
      );
    @EXPORT_OK = @EXPORT;
}



=head1 Functions

=head2 hash_transform

B<Arguments:>

=over

=item

B<$hs> - hash ref, original hash;

=item

B<$arr> - array ref, keys to copy;

=item

B<$transform_hs> - hash ref, new keys names.

=back

B<Return value:> hash with new keys names.

 my %new_hash = hash_transform(
     {
         a => 1,
         b => 2,
         c => 3,
         d => 4
     },
     [qw(a c)],
     {
         d => 'e'
     }
 );

 Result:
 %new_hash = (
     a => 1,
     c => 3,
     e => 4
 )

=cut

sub hash_transform($$;$) {
    my ($hs, $arr, $transform_hs) = @_;

    return map {$transform_hs ? $transform_hs->{$_} || $_ : $_ => $hs->{$_}}
      grep {exists $hs->{$_}} @$arr, keys %$transform_hs;
}



=head2 push_hs

B<Arguments:>

=over

=item

B<$h1|%h1> - hash or hash ref, first hash;

=item

B<$h2|%h2> - hash or hash ref, second hash.

=back

Merge second hash into first.

=cut

sub push_hs(\[$%]@) {
    my ($h1, @args) = @_;

    $h1 = $$h1 if ref($h1) eq 'REF';
    my $h2 = @args == 1 ? $args[0] : {@args};

    @$h1{keys(%$h2)} = values(%$h2);
}

1;
