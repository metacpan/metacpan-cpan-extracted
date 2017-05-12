package blx::xsdsql::connection;
use strict;  # use strict is for PBP
use Filter::Include;
include blx::xsdsql::include;
#line 6

use base qw(blx::xsdsql::ut::common_interfaces);

our %_ATTRS_R:Constant(
	OUTPUT_NAMESPACE_INSTANCE  => sub { 
		my $self=$_[0];
		if (defined (my $output_namespace=$self->{OUTPUT_NAMESPACE})) {
			if (defined (my $inst=$self->{OUTPUT_NAMESPACE_INSTANCE}->{$output_namespace})) {
				return $inst;
			}
		}
		undef
	}
	,CONNECTION_LIST  => sub {
		my $self=$_[0];
		if (defined (my $output_namespace=$self->{OUTPUT_NAMESPACE})) {
			if (defined (my $inst=$self->{OUTPUT_NAMESPACE_INSTANCE}->{$output_namespace})) {
				return $inst->get_attrs_value(qw(CONNECTION_LIST));
			}
		}
		undef;
	}
	,DB_NAMESPACE	=> sub {
		my $self=$_[0];
		if (defined (my $output_namespace=$self->{OUTPUT_NAMESPACE})) {
			if (defined (my $inst=$self->{OUTPUT_NAMESPACE_INSTANCE}->{$output_namespace})) {
				return $inst->get_attrs_value(qw(DB_NAMESPACE));
			}
		}
		undef;		
	}
	,ERR => sub   {
		my $self=$_[0];
		return $self->{ERR} if defined $self->{ERR};
		if (defined (my $output_namespace=$self->{OUTPUT_NAMESPACE})) {
			if (defined (my $inst=$self->{OUTPUT_NAMESPACE_INSTANCE}->{$output_namespace})) {
				return $inst->get_attrs_value(qw(ERR));
			}
		}
		undef;
	}
);

our %_ATTRS_W:Constant(
	map { my $a=$_;($a,sub {  croak $a.": this attribute is not writeable"}) } keys %_ATTRS_R
);


sub _get_attrs_w { return \%_ATTRS_W; }
sub _get_attrs_r { return \%_ATTRS_R; }

sub new {
	my ($class,%params)=@_;
	my $s=delete $params{CONNECTION_STRING};
	my $self=bless {},$class;
	$self->set_attrs_value(%params);
	$self->do_connection_list($s,%params) if defined $s;
	$self;
}

sub do_connection_list {
	my ($self,$connection_string,%params)=@_;
	for my $k(grep($_ ne 'OUTPUT_NAMESPACE_INSTANCE',keys %_ATTRS_R)) { delete $self->{$k}; }
	unless (defined $connection_string) {
		$self->{ERR}="no connection string specify";
		return;
	}
	$self->{CONNECTION_STRING}=$connection_string;
	my $output_namespace=$connection_string=~s/^(\w+):://  ? $1 : undef;
	$output_namespace='sql' unless defined $output_namespace;
	$self->{OUTPUT_NAMESPACE}=$output_namespace;
	unless (defined $self->{OUTPUT_NAMESPACE_INSTANCE}->{$output_namespace}) {
		my $class='blx::xsdsql::connection::'.$output_namespace.'::connection';
		local $@;
		eval "use $class"; ## no critic
		if (my $s=$@) {
			if ($s=~/^\s*Can't locate/) {
				$self->{ERR}="$output_namespace: unknow output_namespace";
				return;
			}
			else {
				croak $s;
			}
		}
		$self->{OUTPUT_NAMESPACE_INSTANCE}->{$output_namespace}=$class->new;
	}
	my $inst=$self->{OUTPUT_NAMESPACE_INSTANCE}->{$output_namespace};
	my $r=$inst->do_connection_list(
							$connection_string
							,%params
							,CONNECTION_STRING => $self->{CONNECTION_STRING}
							,OUTPUT_NAMESPACE  => $self->{OUTPUT_NAMESPACE}
	);
	return  unless $r;
	$self->{CONNECTION_LIST}=$inst->get_attrs_value(qw(CONNECTION_LIST));
	$self;
}

sub get_output_namespace { $_[0]->get_attrs_value(qw(OUTPUT_NAMESPACE))}

sub get_db_namespace { $_[0]->get_attrs_value(qw(DB_NAMESPACE))}

sub get_last_error { $_[0]->get_attrs_value(qw(ERR)) }

sub get_connection_list {
	my ($self,%params)=@_;
	my $connection_list=$self->get_attrs_value(qw(CONNECTION_LIST));
	if (defined $connection_list) {
		return wantarray ? @$connection_list : $connection_list;
	}
	wantarray ? () : undef; 
}

sub get_output_namespace_instance { return $_[0]->get_attrs_value(qw(OUTPUT_NAMESPACE_INSTANCE))}

sub get_attribute_names {
	my ($self,%params)=@_;
	my @k=keys %_ATTRS_R;
	wantarray ? @k : \@k;
}

1;

__END__

=head1  NAME

blx::xsdsql::connection -  generate connection list to a database from standard format

=head1 SYNOPSIS

use blx::xsdsql::connection


=head1 VERSION

0.10.0

=cut

=head1 FUNCTIONS

new - constructor

   PARAMS:
         CONNECTION_STRING  - see on botton of this doc for examples of connection string
         the format is:
            [<output_namespace>::]<dbtype>:<user>/<password>@<dbname>[:hostname[:port]][;<attribute>[,<attribute>...]]

                    <output_namespace>::=  sql  (this is the default)
                    <dbtype>::= pg|mysql|oracle|DBM
                    <user>::=  username
                    <pwd>::=   password
                    <dbname> ::= database name
                    <hostname>:: socket remote hostname or ipaddress - the default is 127.0.0.1
                    <port>    :: socket remote port - the default is the database port default
                    <attribute> :: extra attribute - see the manual of DBI, section connect



do_connection_list

    ARGS:
        connection_string - equal to param CONNECTION_STRING of the constructor


get_connection_list - return a list for input to a database connection (for example DBI)

get_output_namespace - return  output namespace

get_dbnamespace - return the database namespace

get_last_error - return a message error relative to wrong connection string

get_attribute_names - return a list of know attributes

get_attrs_value  - return the value of one or many attributes

    ARGS:
             <attribute_name>[,<attribute_name>...]

=head1 connection string examples:

=head2 postgres

    'sql::pg:myuser/mypwd@mydb:127.0.0.1:5432;RaiseError => 1,AutoCommit => 0,pg_enable_utf8 => 1'

=head2 mysql

    'sql::mysql:myuser/mypwd@mydb:127.0.0.1:3306;RaiseError => 1,AutoCommit => 0,mysql_enable_utf8 => 1'

=head2 dbm

    'sql::DBM:dbm_mldbm=Storable;RaiseError => 1,f_dir=> q(/tmp)'

=head2 oracle

    'sql::oracle:myuser/mypwd@orcl:127.0.0.1:1522;RaiseError => 1,AutoCommit => 0'

=head1 BUGS

Please report any bugs or feature requests to https://rt.cpan.org/Public/Bug/Report.html?Queue=XSDSQL


=head1 AUTHOR

lorenzo.bellotti, E<lt>pauseblx@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by lorenzo.bellotti

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut






