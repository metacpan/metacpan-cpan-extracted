package oEdtk::Restitution;
use base qw( Exporter );
use warnings;
use strict;
use feature 'say';
use Carp qw( carp croak );
use Readonly;
use Data::Dumper qw( Dumper );

our @EXPORT_OK = qw( follow_path restitution_value );

# follows a 'path' in a hash:
# in case h = { a => b => { "value" } } then follow_path(h, [ "a", "b" ]) returns "value"
# value returned: '' if list undef; execution on current value if code ref
sub follow_path {
	my ( $h, $l, $flag_quiet ) = @_;
	$flag_quiet = 0 unless defined $flag_quiet;
	my $res = $h;
	foreach my $key ( @{$l} ) {
		my $ref = ref $key;
		if ( $ref eq '' ) {
			if ( exists $res->{$key} ) {
				$res = $res->{$key};
			}
			else {
				say STDERR "INFO: no key '$key' found." unless $flag_quiet;
				return '';
			}
		}
		elsif ( $ref eq 'CODE' ) {
			return &{$key}($res);
		}
		else { croak "Unexpected key (ref='$ref'): " . Dumper($key); }
	}
	my $ref = ref $res;
	return ( $ref eq 'ARRAY' )
		? join( "\n", @{$res} )    # adresse_payeur
		: ($ref) ? croak "Unexpected result: " . Dumper($res)
		:          $res;
}

sub restitution_value {
	my ( $h, $obj, $flag_quiet ) = @_;
	return '' if !defined $obj;
	my $ref = ref $obj;
	if ( $ref eq 'ARRAY' ) { return follow_path( $h, $obj, $flag_quiet ) }
	else                   { croak "Unexpected restitution rule: " . Dumper($obj); }
}

1;

=head1 NAME

oEdtk::Restitution - read a value out of nested data with a key path

=head1 SYNOPSIS

    use oEdtk::Restitution qw(follow_path restitution_value);

    my $h = { a => { b => { c => 'value' } } };
    follow_path($h, [ 'a', 'b', 'c' ]);          # 'value'
    restitution_value($h, [ 'a', 'b' ], 1);      # 'value', quiet

=head1 DESCRIPTION

A small path walker used by the templates to pull a value out of a nested
structure described by a list of keys. Ported from the 0.8032 fork at S20 of the
fork-merge plan.

=head1 FUNCTIONS

=head2 follow_path

    my $value = follow_path($h, $list, $flag_quiet);

Walk C<$list> over C<$h>. A plain (non-reference) key descends into a hash. A
code reference is called with the value gathered so far and its result is
returned immediately. A missing key returns C<''> (and prints an INFO line on
STDERR unless C<$flag_quiet> is true); a key of any other kind is an error. At
the end, an array value is joined with newlines, any other reference is an
error, and a plain scalar is returned as is.

=head2 restitution_value

    my $value = restitution_value($h, $rule, $flag_quiet);

Wrapper for a restitution rule: an undefined rule yields C<''>, a list rule is
passed to L</follow_path>, and anything else is an error.

=head1 AUTHOR

The oEdtk team.

=cut
