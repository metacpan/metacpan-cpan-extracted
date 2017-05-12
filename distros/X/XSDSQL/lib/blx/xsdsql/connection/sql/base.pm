package blx::xsdsql::connection::sql::base;
use strict;  # use strict is for PBP
use Filter::Include;
include blx::xsdsql::include;
#line 6

use base qw(blx::xsdsql::ut::common_interfaces);

our %_ATTRS_R:Constant(
	CONNECTION_LIST	=> sub {
		my $self=$_[0]; 
		if (defined (my $conn=$self->{CONNECTION_LIST})) {
			return [ @{$conn} ] 
		};
		undef;
	}
	,map { my $a=$_;($a,sub { $_[0]->{$a}})} (qw(ERR))
);

our %_ATTRS_W:Constant(
	map { my $a=$_;($a,sub { croak "$a: this attribute is not writeble" })} keys %_ATTRS_R
);

sub _get_attrs_w { return \%_ATTRS_W; }
sub _get_attrs_r { return \%_ATTRS_R; }

sub new {
	my ($class,%params)=@_;
	bless \%params,$class;
}

sub get_attribute_names {
	my ($self,%params)=@_;
	my @k=keys %_ATTRS_R;
	return wantarray ? @k : \@k;
}

sub _get_connection_list {
	croak "abstract method";
}

sub do_connection_list {
	my ($self,$h,%params)=@_;
	affirm { ref($h) eq 'HASH'} "1^ param is not HASH";
	for my $k($self->get_attribute_names) { delete $self->{$k}; }
	my ($err,@args)=$self->_get_connection_list($h,%params);
	$self->{ERR}=$err;
	$self->{CONNECTION_LIST}=\@args;
	$self;
}

1;


__END__

=head1  NAME

blx::xsdsql::connection::sql::base -  base class blx::xsdsql::connection::sql classes

=cut



=head1 SEE ALSO

blx::xsdsql::connection - this is the main class for generate connection

=cut


=head1 VERSION

0.10.0

=cut



=head1 BUGS

Please report any bugs or feature requests to https://rt.cpan.org/Public/Bug/Report.html?Queue=XSDSQL

=cut



=head1 AUTHOR

lorenzo.bellotti, E<lt>pauseblx@gmail.comE<gt>


=cut


=head1 COPYRIGHT

Copyright (C) 2010 by lorenzo.bellotti

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut
