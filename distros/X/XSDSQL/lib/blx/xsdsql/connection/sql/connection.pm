package blx::xsdsql::connection::sql::connection;
use strict;  # use strict is for PBP
use Filter::Include;
include blx::xsdsql::include;
#line 6

use base qw(blx::xsdsql::ut::common_interfaces);

our %_ATTRS_R:Constant(
	DB_NAMESPACE_INSTANCE => sub { croak "DB_NAMESPACE_INSTANCE: this attribute is not readable"}
	,ERR  => sub {
		my $self=$_[0];
		return $self->{ERR} if defined $self->{ERR};
		if (defined (my $db_namespace=$self->{DB_NAMESPACE})) {
			if (defined (my $inst=$self->{DB_NAMESPACE_INSTANCE}->{$db_namespace})) {
				return $inst->get_attrs_value(qw(ERR));
			}
		}
		undef;
	}
	,CONNECTION_LIST => sub { 
		my $self=$_[0]; 
		if (defined (my $conn=$self->{CONNECTION_LIST})) {
			return [ @{$conn} ] 
		};
		undef;
	}
	,map { my $a=$_;($a,sub { $_[0]->{$a}})}
		(qw(
			DB_NAMESPACE
			USER
			PWD
			DBNAME
			HOST
			PORT
			ATTRS
		))
);

our %_ATTRS_W:Constant(
	map { my $a=$_;($a,sub { croak "$a: this attribute is not writeble" })} keys %_ATTRS_R
);

sub _get_attrs_w { return \%_ATTRS_W; }
sub _get_attrs_r { return \%_ATTRS_R; }

sub _split {
	my ($self,$s,%params)=@_;
	my $attrs='';
	if ($s=~/^([^;]*);(.*)/) {
		$s=$1;
		$attrs=$2;
	}
	my ($user,$pwd,$dbname,$host,$port)=$s=~/^(\w+)\/(\w+)@(\w+):([^:]+):(\d*)$/;
	($user,$pwd,$dbname,$host)=$s=~/^(\w+)\/(\w+)@(\w+):([^:]+)$/ unless defined $user;
	($user,$pwd,$dbname)=$s=~/^(\w+)\/(\w+)@(\w+)$/ unless defined $user;
	$dbname=$s unless defined $user;
	if (length($attrs)) {
		my $a='{'.$attrs.'};';
		local $@;
		my $e=eval($a); ## no critic
		if ($@) {
			$self->{ERR}=$params{CONNECTION_STRING}.": invalid attributes in connect string ($attrs)";
			return;
		}
		if (ref($e) ne 'HASH' ) {
			$self->{ERR}=$params{CONNECTION_STRING}.": attributes in connect strict is not a HASH evaluable ($a)";
			return;
		} 
		$attrs=$e;
	}
	return {
				 USER			=> $user
				,PWD			=> $pwd
				,DBNAME			=> $dbname
				,HOST			=> $host
				,PORT			=> $port
				,ATTRS			=> $attrs
	};
}

sub new {
	my ($class,%params)=@_;
	bless \%params,$class;
}

sub do_connection_list {
	my ($self,$connection_string,%params)=@_;
	affirm { defined $connection_string} "1^ param not set";
	for my $k(grep($_ ne 'DB_NAMESPACE_INSTANCE',keys %_ATTRS_R)) { delete $self->{$k}; }
	my $db_namespace=$connection_string=~s/^(\w+)// ? $1 : undef;
	unless (defined $db_namespace) {
		$self->{ERR}=$params{CONNECTION_STRING}.": invalid connection string";
		return;
	}
	$self->{DB_NAMESPACE}=$db_namespace;
	$connection_string=~s/^://;
	my $p=$self->_split($connection_string,%params);
	return unless defined $p;
	for my $k(keys %$p) { $self->{$k}=$p->{$k}}
	unless (defined $self->{DB_NAMESPACE_INSTANCE}->{$db_namespace}) {
		my $class='blx::xsdsql::connection::'.$params{OUTPUT_NAMESPACE}.'::databases::'.$db_namespace;
		local $@;
		eval("use $class"); ## no critic
		if (my $s=$@) {
			if ($s=~/^\s*Can't locate/) {
				$self->{ERR}="$db_namespace: unknow db_namespace";
				return;
			}
			else {
				croak $s;
			}
		}
		$self->{DB_NAMESPACE_INSTANCE}->{$db_namespace}=$class->new;
	}
	my $r=$self->{DB_NAMESPACE_INSTANCE}->{$db_namespace}->do_connection_list($p,%params);
	return unless $r;
	my @a=@{$self->{DB_NAMESPACE_INSTANCE}->{$db_namespace}->get_attrs_value(qw(CONNECTION_LIST))};
	while(scalar(@a) < 3) { push @a,undef };
	if (ref(my $attrs=$p->{ATTRS})) {
		push @a,$attrs; 		
	}
	$self->{CONNECTION_LIST}=\@a;
	$self;
}

sub get_dbnamespace { $_[0]->get_attrs_value(qw(DB_NAMESPACE))}
sub get_dbname { $_[0]->get_attrs_value(qw(DBNAME))}
sub get_user { $_[0]->get_attrs_value(qw(USER))}
sub get_pwd { $_[0]->get_attrs_value(qw(PWD))}
sub get_host { $_[0]->get_attrs_value(qw(HOST))}
sub get_port { $_[0]->get_attrs_value(qw(PORT))}

sub get_attribute_names {
	my ($self,%params)=@_;
	my @k=grep($_ ne 'DB_NAMESPACE_INSTANCE',keys %_ATTRS_R);
	return wantarray ? @k : \@k;
}


1;

__END__

=head1  NAME

blx::xsdsql::connection::sql::connection -  internal class for namespace sql

=cut

=head1 SYNOPSIS

use blx::xsdsql::connection::sql::connection

=cut



=head1 SEE ALSO

blx::xsdsql::connection - this is the main class for generate connection



=head1 VERSION

0.10.0

=cut

=head1 FUNCTIONS


get_dbnamespace - return the database namespace (Ex: pg for postgresql)

get_dbname - return the database name (Ex: mydb)

get_user  - return the user

get_pwd - return the password

get_host - return the remote socket host name or ip addres

get_port - return the remote socket port


=head1 AUTHOR

lorenzo.bellotti, E<lt>pauseblx@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by lorenzo.bellotti

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut



