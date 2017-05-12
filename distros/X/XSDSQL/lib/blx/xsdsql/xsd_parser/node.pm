package blx::xsdsql::xsd_parser::node;

use strict;  # use strict is for PBP
use Filter::Include;
include blx::xsdsql::include;
#line 7

use blx::xsdsql::ut::ut qw(ev nvl);
use blx::xsdsql::ut::posix;

use base qw(blx::xsdsql::ios::debuglogger blx::xsdsql::ut::common_interfaces);

our %_ATTRS_W:Constant(());
our %_ATTRS_R:Constant(());

sub _get_attrs_w { return \%_ATTRS_W; }
sub _get_attrs_r { return \%_ATTRS_R; }


use constant {
	UNBOUNDED	=>  blx::xsdsql::ut::posix::get_int_max
};


sub  _resolve_maxOccurs {
	my ($self,%params)=@_;
	my $n=exists $params{VALUE} ? $params{VALUE} : $self->get_attrs_value(qw(maxOccurs)); 
	$n=nvl($n,1);
	$n=UNBOUNDED if $n eq 'unbounded';
	return $n;
}

sub _resolve_minOccurs {
	my ($self,%params)=@_;
	return 0 if $params{CHOICE};
	my $n=exists $params{VALUE} ? $params{VALUE} : $self->get_attrs_value(qw(minOccurs)); 
	return nvl($n,1);
}

sub _resolve_form {
	my ($self,%params)=@_;
	my $form=$self->get_attrs_value(qw(form));
	return $form unless defined $form;
	$form='Q' if $form eq 'qualified';
	$form='U' if $form eq 'unqualified';
	$form;
}

sub _split_tag_name  {  # split tag into namespace/name
	my ($name,%params)=@_;
	my @a=$name=~/^([^:]+):([^:]+)$/;
	@a=('',$name) unless scalar(@a);  # name without namespace prefix 
	return {
			FULLNAME		=> $name
			,NAMESPACE		=> $a[0]  #namespace abbr
			,NAME 			=> $a[1]
	};	
}


sub _resolve_boolean {
	my ($self,$value,%params)=@_;
	return 0 unless defined $value;
	return $value eq 'true' || $value eq '1' ? 1 : 0;
}

sub _is_into_a_mixed {
	my ($self,%params)=@_;
	my $stack=$self->get_attrs_value(qw(STACK));
	for my $s(reverse @$stack) {
		if (ref($s)=~/::complexType$/) {
			return $s->get_attrs_value(qw(MIXED));
		}
	}
	return 0;
}

sub _new {
	my ($class,%params)=@_;
	return bless \%params,$class;
}

sub _construct_path {
	my ($self,$name,%params)=@_;
	my $parent=nvl($params{PARENT},$self->get_attrs_value(qw(STACK))->[-1]);
	my $path=$parent->get_attrs_value(qw(PATH));
	return $path unless defined $path;
	if (defined $name) {
		$path.='/' unless $path eq '/';
		$path.=$name;
	}
	return $path;
}

sub _get_parent_table {
	my ($self,%params)=@_;
	my $i=-1;
	while(1) {
		my $parent=$self->get_attrs_value(qw(STACK))->[$i];
		last unless defined $parent;
		if (defined (my $parent_table=$parent->get_attrs_value(qw(TABLE)))) {
			return $parent_table; 
		}
		$i--;
	}
	affirm {  0 }  "no such parent table";
	undef;
}

sub _get_parent_path {
	my ($self,%params)=@_;
	my $i=-1;
	my $stack=$self->get_attrs_value(qw(STACK));
	while(1) {
		my $parent=$stack->[$i];
		last unless defined $parent;
		if (defined(my $path=$parent->get_attrs_value(qw(PATH)))) {
			return $path;
		}
		$i--;
	}
	affirm {  0 }  "no such parent path";
	undef;
}


sub _resolve_simple_type {
	my ($self,$t,$types,$out,%params)=@_;
	if (ref($t)=~/::union/) {
		$out->{base}='string';
		return $self;
	}
	if (defined (my $base=$t->get_attrs_value(qw(base)))) {
		my $t=blx::xsdsql::xsd_parser::type::factory($base,%params);
		if (ref($t)=~/::type::simple/) { 
			$out->{base}=$t->get_attrs_value(qw(NAME));
		}
		elsif (defined $types) {
			my $t=$types->{$base};
			unless (defined $t) {
				$self->_debug(undef,"$base: type not found");
				return;
			}
			$self->_resolve_simple_type($t,$types,$out,%params);
		}
		else {
			$out->{base}=$t;
		}
	}
	if (defined (my $v=$t->get_attrs_value(qw(value)))) {
		my $r=ref($t);
		my ($b)=$r=~/::([^:]+)$/;
		affirm { defined $b } "$r: is not a class";
		if ($b eq 'enumeration') {
			$out->{$b}=[] unless defined $out->{$b};
			$self->_debug(__LINE__,$v);
			push @{$out->{$b}},$v;
		}
		else {
			$out->{$b}=$v;
		}
	}

	if (defined (my $child=$t->get_attrs_value(qw(CHILD)))) {
		for my $c(@$child) {
			$self->_resolve_simple_type($c,$types,$out,%params);
		}
	}
	return $self;
}

sub _dynamic_create {
	my ($tag,%params)=@_;
	my $split=_split_tag_name($tag,%params);
	if (defined (my $name=$split->{NAME})) {
		my $class='blx::xsdsql::xsd_parser::node::'.$name;
		ev("use $class");
		my $attrs=delete $params{ATTRIBUTES};
		my $obj=$class->new(
					%params
					,%$attrs
					,%$split
					,DEBUG_NAME => undef
		);
		unless ($name eq 'schema') {
			if (defined (my $path=$obj->_get_parent_path(%params)))  {
				if (defined (my $name=$attrs->{name})) {
					$path.='/'  if $path ne '/';
					$path.=$name;
				}
				$obj->set_attrs_value(PATH => $path);
			}
			else {
				affirm {  0 }  "path not set";
			}
		}
		return $obj;
	}
	else {
		affirm { 0 } "$tag: NAME not set";
	}
	undef;
}

sub factory_object {
	my ($tag,%params)=@_;
	affirm { defined $params{STACK} } "STACK param not set";
	affirm { defined $params{ATTRIBUTES} } "ATTRIBUTES param not set";	
	affirm { defined $params{EXTRA_TABLES} } "EXTRA_TABLES param not set";
	affirm { !defined $params{CHILDS_SCHEMA_LIST} } "CHILDS_SCHEMA_LIST param is reserved";
	my $obj=_dynamic_create($tag,%params);
	return $obj;
}

sub trigger_at_start_node {
	my ($self,%params)=@_;
	undef;
}

sub trigger_at_end_node {
	my ($self,%params)=@_;
	undef;
}


1;

__END__

=head1  NAME

blx::xsdsql::xsd_parser::node - internal class for parsing schema

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
