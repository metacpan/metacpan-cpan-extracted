package Win32::TieRegistry::Dump;
our $VERSION = 0.031;	# Bug fix by sb@engelschall.com &


use 5.006;
use strict;
use Carp;
use Win32::TieRegistry ( Delimiter=>"/", ArrayValues=>0 );
no strict 'refs';

=head1 NAME

Win32::TieRegistry::Dump - dump Win32 registry tree

=head1 SYNOPSIS

	use Win32::TieRegistry::Dump
	$_ = Win32::TieRegistry::Dump::toArray ("LMachine/Software/LittleBits/");
	while (my ($key, $value) = each %{$_} ){
		warn "$key = $value\n";
	}
	exit;

=head1 FUNCTION toArray

Returns a reference to a hash of values in a Win32 registry tree,
keyed by registry entry.

=cut

sub toHash {
	my $literal = shift or carp __PACKAGE__."::toArray requires an argument" and return undef;
	my $rkey = $Registry->{$literal}
		or  warn "* Can't read the registry key for $literal:\n $^E\n" and return undef;
	return &_iterate ($rkey,$literal);
}

=head1 FUNCTION toArray

Returns an array of keys and values in a Win32 registry tree.

=cut

sub toArray {
	my $literal = shift or carp __PACKAGE__."::toArray requires an argument" and return undef;
	my $rkey = $Registry->{$literal}
		or  warn "* Can't read the registry key for $literal:\n $^E\n" and return undef;
	$_ = &_iterate ($rkey,$literal);
	@_ = ();
	foreach my $i (keys %$_){
		push @_, "$i/$_->{$i}";
	}
	return @_;
}

sub _iterate { my ($key,$root) = (shift,shift);
	my $info = shift  || {};
	foreach my $entry (  keys(%$key)  ) {
		if ($key->SubKeyNames){
			&_iterate( $key->{$entry}, $root.$entry, $info );
		} else {
			$info->{$root.$entry} = $key->{$entry};
		}
	}
	return $info;
}



1; # Return cleanly from module

=head1 DEPENDENCIES

	Win32::TieRegistry

=head1 EXPORTS

None.

=head1 AUTHOR

Lee Goddard <http://www.leegoddard.com/>
Mailto: <lgoddard -at- cpan -dot- org>

=head1 LICENCE AND COPYRIGHT

Copyrigh (C) 2001-2003 Lee Goddard

This is free software made available under the same terms as Perl itself;

=head1 SEE ALSO

See L<Win32::TieRegistry>;
L<Win32::TieRegistry::PMVersionInfo>;
