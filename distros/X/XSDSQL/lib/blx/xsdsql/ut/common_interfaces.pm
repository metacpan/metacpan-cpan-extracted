package blx::xsdsql::ut::common_interfaces;
use strict;  # use strict is for PBP
use Filter::Include;
include blx::xsdsql::include;
#line 6
use Storable;

sub _fusion_params {
	my ($self,%params)=@_;
	my %p=%$self;
	for my $p(keys %params) {
		$p{$p}=$params{$p};
	}
	return \%p;
}

sub _get_attrs_w {
	croak "set the method _get_attrs_w for use set_attrs_value\n";
	return $_[0];
}

sub _get_attrs_r {
	croak "set the metod _get_attrs_r for use get_attrs_value\n";
	return $_[0];
}

sub _am {
	croak "abstract method called\n";
	return $_[0];
}

sub get_attrs_value {
	my $self=shift;
	my $h=$self->_get_attrs_r;
	my @out=();
	for my $attr(@_) {
		my $f=exists $h->{$attr} ? $h->{$attr} : undef; 
		if (!defined $f) {
			push @out,$self->{$attr};
		}
		elsif (ref($f) eq 'CODE') {
			push @out,$f->($self,$attr);
		}
		else {
			push @out,$f;
		}
	}
	return @out if wantarray;
	return \@out if scalar(@out) > 1;
	return $out[0] if scalar(@out) == 1;
	undef;
}

sub set_attrs_value {
	my $self=shift;
	affirm { scalar(@_) % 2 == 0 } "Odd elements"; 
	my $h=$self->_get_attrs_w;
	for (my $i=0; $i < scalar(@_); $i+=2) {
		my ($attr,$v)=($_[$i],$_[$i + 1]);
		my $f=exists $h->{$attr} ? $h->{$attr} : undef;
		if (!defined $f) {
			$self->{$attr}=$v;
		}
		else {
			affirm { ref($f) eq 'CODE' } "the handler must be a CODE";
			$self->{$attr}=$f->($self,$v);
		}
	}
	return $self;
}

sub shallow_clone {
	my ($self,%params)=@_;
	my %newtable=%$self;	
	return bless \%newtable,ref($self);
}

sub get_clone {
	my ($self,%params)=@_;
	return Storable::dclone($self);
}


sub _clone_from_attributes {
	my ($self,$k,%params)=@_;
	affirm { ref($k) eq 'ARRAY' } "1^ param must be ARRAY";
	my $values=$self->get_attrs_value(@$k);
	my %attrs=map { ($k->[$_],$values->[$_]) } (0..scalar(@$k) - 1);
	return bless \%attrs,ref($self);
}


1;

__END__

=head1  NAME

blx::xsdsql::ut::ut::common_interfaces - class for common methods

=cut

=head1 FUNCTIONS

get_attrs_value    -  generic method for  return value of  attribute

    the params is a list of attributes name
    the method return a list of values or a value if the params is one

set_attrs_value  - generic method for set a value of attribute
    the params are a pair of NAME => VALUE
    the method return a self object


shallow_clone - return a shallow clone of the self object


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
