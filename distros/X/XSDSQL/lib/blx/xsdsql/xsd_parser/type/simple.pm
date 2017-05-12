package blx::xsdsql::xsd_parser::type::simple;
use strict;  # use strict is for PBP
use Filter::Include;
include blx::xsdsql::include;
#line 6

use blx::xsdsql::ut::ut qw(nvl);
use blx::xsdsql::schema_repository::sql::generic::limits qw(get_xsd_based_types get_normalized_type);

use base qw(blx::xsdsql::xsd_parser::type::base);


sub  _minus {
	my ($n1,$n2)=@_;
	return $n2 unless defined $n1;
	return $n1 < $n2 ? $n1 : $n2;
}

sub _merge {
	my ($h1,$h2)=@_;
	for my $k(keys %$h2) { $h1->{$k}=$h2->{$k} }
	undef;
}

sub new {
	my ($class,%params)=@_;
	affirm { defined $params{NAME} != defined $params{XSD_TYPE} } 'param NAME or XSD_TYPE must be set';
	affirm { ref($params{NAME}) eq '' || ref($params{NAME}) eq 'HASH' } 'param NAME must be scalar or HASH'; 
	affirm { defined $params{NAME} && !defined $params{LIMITS} || defined $params{XSD_TYPE}} 'param LIMITS is valid with param XSD_TYPE';
	affirm { ref($params{XSD_TYPE}) eq '' } 'param XSD_TYPE must be a scalar';
	affirm { !defined $params{LIMITS} || ref($params{LIMITS}) eq 'HASH' } 'param LIMITS must be HASH';
	bless \%params,$class;
}



sub get_sql_type  {
	my ($self,%params)=@_;
	return $self->{SQL_T_} if defined $self->{SQL_T_};
	if (defined (my $xsd_type=$self->{XSD_TYPE})) {
			affirm { exists get_xsd_based_types(FORMAT => 'HASH')->{$xsd_type} } "$xsd_type: is not a simple base type"; 
			return $self->{SQL_T_}={
						%{nvl($self->{LIMITS},{})}
						,BASE 		=> $xsd_type
						,SQL_TYPE 	=> $xsd_type
			}
	}
	$self->{NAME}={ base => $self->{NAME}} unless ref($self->{NAME});	
	my $name=$self->{NAME};
	my $base=$name->{base};
	affirm { defined $base } "base not set";
	$self->{SQL_T_}={ BASE => $base };	
	
	my $normalized_type=get_normalized_type($base);
	affirm { defined $normalized_type } "$base: not normalized";
	if ($normalized_type eq 'string') {
		if (defined (my $l=$name->{length})) { 
			$l+=0;
			_merge($self->{SQL_T_},{ SQL_TYPE  => $base,FIXSIZE => $l  });
		}					
		elsif (defined (my $l1=$name->{maxLength})) {
			$l1+= 0; 
			_merge($self->{SQL_T_},{ SQL_TYPE  => $base,SIZE => $l1  });
		}
		else {
			_merge($self->{SQL_T_},{ SQL_TYPE  => $base });
		}
		if (defined (my $e=$name->{enumeration})) {
			affirm { ref($e) eq 'ARRAY' } ref($e).": not an ARRAY";
			my $n=nvl($self->{SQL_T_}->{SIZE},nvl($self->{SQL_T_}->{FIXSIZE},0));
			for my $v(@$e) {
				my $lv=length($v);
				$n=$lv if $lv > $n;
			}
			if (defined $self->{SQL_T_}->{FIXSIZE}) {
				$self->{SQL_T_}->{FIXSIZE}=$n;
			}
			else {
				$self->{SQL_T_}->{SIZE}=$n;
			}
		}
	}
	elsif ($normalized_type eq 'decimal') {
		_merge($self->{SQL_T_},{ SQL_TYPE => 'decimal' });
		if (defined (my $l=$name->{totalDigits})) {
			$l+=0;
			$self->{SQL_T_}->{INT}=$l;
		}
		if (defined (my $l=$name->{fractionDigits})) {
			$l+=0;
			$self->{SQL_T_}->{DEC}=$l;
		}
		if (defined (my $l=$name->{maxInclusive})) {
			delete $self->{SQL_T_}->{INT}; #unlimited
			delete $self->{SQL_T_}->{DEC}; #unlimited
		}
	}
	elsif ($normalized_type eq 'integer') {
		_merge($self->{SQL_T_},{ SQL_TYPE => $base });		
		if (defined (my $l=$name->{totalDigits})) {
			$l+=0;
			$self->{SQL_T_}->{INT}=$l;
		}					
		if (defined (my $l=$name->{maxInclusive})) {
			$l=~s/^0+//;
			$self->{SQL_T_}->{INT}=_minus($self->{SQL_T_}->{INT},length($l.''));	
		}
	}
	elsif ($normalized_type eq 'boolean') {
		_merge($self->{SQL_T_},{ SQL_TYPE => 'boolean' });
	}
	else {
		affirm {0} "$normalized_type: not manipulated";
	}
	return $self->{SQL_T_};
}

sub resolve_type {  return $_[0]; }

sub link_to_column {
	my ($self,$c,%params)=@_;
	if ($c->get_max_occurs > 1) {
		return $self if defined $c->get_table_reference;
		my $parent_table=$params{TABLE};
		my $schema=$params{SCHEMA};
		my $table = $schema->get_attrs_value(qw(TABLE_CLASS))->new(
			PATH		    		=> $c->get_path
			,INTERNAL_REFERENCE 	=> 1
			,DEBUG 					=> $self->get_attrs_value(qw(DEBUG))
		);
		$schema->set_table_names($table);

		$table->add_columns(
			$schema->get_attrs_value(qw(EXTRA_TABLES))->factory_column(qw(ID))
			,$schema->get_attrs_value(qw(EXTRA_TABLES))->factory_column(qw(SEQ))
			,$schema->get_attrs_value(qw(EXTRA_TABLES))->factory_column(qw(VALUE_COL))
									->set_attrs_value(TYPE => $self,PATH => $c->get_path)
		);
		$c->set_attrs_value(
			PATH_REFERENCE 			=> $table->get_path
			,INTERNAL_REFERENCE 		=> 1
			,TYPE 					=> $schema->get_attrs_value(qw(ID_SQL_TYPE))
			,TABLE_REFERENCE 		=> $table
		);
		$parent_table->add_child_tables($table);
	}
	else {
		$c->set_attrs_value(TYPE => $self);
	}
	return $self;
}	

1;


__END__


=head1  NAME

blx::xsdsql::xsd_parser::type::simple - internal class for parsing schema

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
