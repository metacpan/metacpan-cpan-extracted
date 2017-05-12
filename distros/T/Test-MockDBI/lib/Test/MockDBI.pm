package Test::MockDBI;

use 5.008;                              # minimum Perl is V5.8.0
use strict;
use warnings;
use Carp;
use Clone;
use Test::MockObject::Extends;
use Scalar::Util;

our $VERSION = '0.70';

my $instance = undef;

=head1 NAME
  
Test::MockDBI - Mocked DBI interface for testing purposes

=head1 SYNOPSIS

  use Test::MockDBI;
  
  my $mi = Test::MockDBI::get_instance();
  
  Sets a fake return value for the rows statementhandler
  $mi->set_retval( method => rows, retval => sub{ return scalar( @somearray ); });
  
  $mi->set_retval( method => 'bind_param', retval => undef);
  Same as:
  $mi->bad_method('bind_param');
  
  You can also specify return values for specific sqls
  $mi->set_retval( method => rows, retval => sub{ return scalar( @somearray ); }, sql => 'select id from names');
  
  $mi->set_retval( method => 'bind_param', retval => undef, sql => 'select id from names where id < ?');
  Same as:
  $mi->bad_method('bind_param', 'select id from names where id < ?');
  
  
  
=cut


sub import{
  
  require Test::MockDBI::Db;
  require Test::MockDBI::St;
  
  
  $instance = bless {
    methods => {
    },
    _regexes => {}
  }, __PACKAGE__;  
  
  Test::MockDBI::Db->import($instance);
  Test::MockDBI::St->import($instance);
  
  my $mock = Test::MockObject::Extends->new();
  
  $mock->fake_module("DBI",
   connect =>  \&_dbi_connect,
   _concat_hash_sorted => \&_dbi__concat_hash_sorted,
   _get_sorted_hash_keys => \&_dbi__get_sorted_hash_keys,
   looks_like_number => \&_dbi__looks_like_number
  );
  
  my %dbi_methods = (
    "DBI::db" => ['clone', 'data_sources', 'do', 'last_inserted_id', 'selectrow_array', 'selectrow_hashref', 'selectall_arrayref',
                  'selectall_hashref', 'selectcol_arrayref', 'prepare', 'prepare_cached', 'commit', 'rollback', 'begin_work', 'disconnect',
                  'ping', 'get_info', 'table_info', 'column_info', 'primary_key_info', 'primary_key', 'foreign_key_info', 'statistics_info',
                  'tables', 'type_info_all', 'type_info', 'quote', 'quote_identifier', 'take_imp_data', 'err', 'errstr'],
    "DBI::st" => ['bind_param', 'bind_param_inout', 'bind_param_array', 'execute', 'execute_array', 'execute_array_fetch',
                  'fetchrow_arrayref', 'fetchrow_array', 'fetchrow_hashref', 'fetchall_arrayref', 'fetchall_hashref', 'finish',
                  'rows', 'bind_col', 'bind_columns', 'dump_results', 'err', 'errstr', 'fetch']
  );
  
  my %packages = ( "Test::MockDBI::Db" => "DBI::db", "Test::MockDBI::St" => "DBI::st" );
  
  foreach my $mock_package ( keys %packages ){
    my %available_methods = ();
    
    #Takes the package as a parameter
    my $map_subs = sub{
      no strict 'refs';
      my $p = shift;
      return map{ s/^_dbi_//; $_ => $p . '::_dbi_' . $_ } grep { m/^_dbi_/ } grep { defined &{"$p\::$_"} } keys %{"$p\::"};
    };

    %available_methods = $map_subs->($mock_package);
    #Also find methods inherited by the package
    my @isalist = eval( '@' . $mock_package . '::ISA');
    die('Could not eval @' . $mock_package .'::ISA') if $@;
    foreach my $isa_package ( @isalist ){
      #Pray for no duplicates
      my %isamethods = $map_subs->($isa_package);
      @available_methods{keys %isamethods} = values %isamethods;
    }

    my %args = ();
    foreach my $method ( @{ $dbi_methods{ $packages{$mock_package} } } ){
      if(grep { m/^$method$/} keys %available_methods){
        $args{$method} = eval( '\&' . $available_methods{$method});
        die("Error during fake module setup. " . $@) if($@);
      }else{
        #Need to check if the method is inherited from a parent package
        $args{$method} = eval('sub{ die \'Test::MockDBI-ERROR : Unsupported method ' . $method . '\'; } ');
      }
    }    
    $mock->fake_module( $packages{ $mock_package }, %args );  
  }
  $mock->fake_new( "DBI" );  
  return 1;
}
##################################
#
# OO - Test MockDBI API
#
###################################

=head1 PUBLIC INTERFACE

  Methods available on the Test::MockDBI instance.

=over 4

=item reset()

  Method for reseting all mock returnvalues \ bad_params etc
  
=cut

sub reset{
  my ($self) = @_;
  $self->{methods} = {};
}

=item bad_method()

  This method is basically a alias for calling set_retval with the return value undef.
  
  Args:
    $method_name              - The name of the method which should return undef
    $matching_sql (Optional)  - The sql matching condition
    
  Returns:
    On success: 1
    On failure: undef
  
  The method also supports calling the method with the following arguments:
  $method_name, $dbi_testing_type, $matching_sql
  This will issue a warning as it is deprecated.

=cut

sub bad_method{
  my $self = shift;
  my %args = ();
  
  if(scalar(@_) == 3 && $_[0] =~ m/^[a-z_]+$/ && $_[1] =~ m/^\d+$/){
    warn "You have called bad_method in an deprecated way. Please consult the documentation\n";
    $args{method} = shift;
    
    #Throw away $dbi_testing_type
    shift;    
    my $matchingsql = shift;
    if($matchingsql && $matchingsql ne ''){
      my $regex = qr/$matchingsql/;
      $args{sql} = $regex;
    }
  }else{
    %args = @_;
  }
  
  $args{retval} = undef;

  return $self->set_retval( %args );  
}

=item bad_param()
  
  Args:
    $p_value        - The value that will cause bind_param to return undef
    $sql (Optional) - The sql matching condition
    
  Returns:
    On success: 1
    On failure: undef
  
  The method also supports calling the method with the following arguments:
  $dbi_testing_type, $p_num, $p_value
  This will issue a warning as it is deprecated.

=cut

sub bad_param{
  my $self = shift;
  my %args;
  
  #We assume its a legacy call if its length is 3 and arg 1 && 2 is numeric
  if(scalar(@_) == 3 && $_[0] =~ m/^\d+$/ && $_[1] =~ m/^\d+$/){
    warn "You have called bad_param in an deprecated way. Please consult the documentation\n";
    #Throw away $dbi_testing_type as we dont use it anymoer
    shift;
    #Throw away $p_num as we dont use it anymore
    shift;
    $args{p_value} = shift;
  }else{
    %args = @_;
  }
  
  if($args{sql}){
    push( @{ $self->{methods}->{bind_param}->{sqls}->{$args{sql}}->{bad_params}}, $args{p_value});
    $self->{_regexes}->{$args{sql}} = (ref($args{sql}) eq 'Regexp') ? $args{sql} : qr/\Q$args{sql}\E/;
  }else{
    push( @{ $self->{methods}->{bind_param}->{global_bad_params} }, $args{p_value});
  }
  
  return 1;
}

=item set_retval()

  Method for setting a return value for the specific method.
  
  Args:(Keys in a hash)
    method             - The method that should return the provided value
    retval             - The data which should be returned
    sql    (Optional)  - Matching sql. The return value will only be
                          returned for the provided method if the sql matches
                          a regex compiled by using this string

  Returnvalues:
    On success: 1
    On failure: undef
  
  Example usage:
  
    #fetchrow_hashref will shift one hashref from the list each time its called if the sql matches the sql provided, this will happend
    #until the return list is empty.
    $inst->set_retval( method => 'fetchrow_hashref',
                      retval => [ { letter => 'a' }, { letter => 'b' }, { letter => 'c' }  ],
                      sql => 'select * from letters' )
    
    #execute will default return undef
    $inst->set_retval( method => 'execute', retval => undef)
    
    #Execute will return 10 for sql 'select * from cars'
    $inst->set_retval( method => 'execute', retval => undef);
    $inst->set_retval( method => 'execute', retval => 10, sql => 'select * from cars');
    
=cut

sub set_retval{
  my ($self, %args) = @_;
  
  my $method = $args{method};
  my $sql = $args{sql} if $args{sql};
  
  unless($method){
    warn "No method provided\n";
    return;
  }
  
  if(ref($method)){
    warn "Parameter method must be a scalar string\n";
    return;
  } 

  if($sql && (ref($sql) && ref($sql) ne 'Regexp')){
    warn "Parameter SQL must be a scalar string or a precompiled regex\n";
    return;
  }
  
  unless( exists $args{retval} ){
    warn "No retval provided\n";
    return;
  }
    
  $self->{methods}->{$method} = {} if !$self->{methods}->{$method};
  
  if($sql){
    $self->{methods}->{$method}->{sqls}->{$sql}->{retval} = Clone::clone($args{retval});
    $self->{methods}->{$method}->{sqls}->{$sql}->{errstr} = $args{errstr} if $args{errstr};
    $self->{methods}->{$method}->{sqls}->{$sql}->{err} = $args{err} if $args{err};
    $self->{_regexes}->{$sql} = (ref($sql) eq 'Regexp') ? $sql : qr/\Q$sql\E/;
  }else{
    $self->{methods}->{$method}->{default}->{retval} = Clone::clone($args{retval});
    $self->{methods}->{$method}->{default}->{errstr} = $args{errstr} if $args{errstr};
    $self->{methods}->{$method}->{default}->{err} = $args{err} if $args{err};
  }
  return 1;
}

=item set_inout_value()

  Special method for handling inout params.
  In this method you can provided the value that the inout param should have
  after execute is called.
  
  Args:
    $sql    - The sql that this rule should apply for
    $p_num  - The parameter number of the inout parameter
    $value  - The value that the inout parameter should have after execute
    
  Returns:
    On success: 1
    On failure: undef
    
  Example:
  
  

=cut

sub set_inout_value{
  my ($self, $sql, $p_num, $value) = @_;
  
  if(!$sql || ref($sql)){
    warn "Parameter SQL must be a scalar string\n";
    return;
  }
  if($p_num !~ m/^\d+$/){
    warn "Parameter p_num must be numeric\n";
    return;
  }
  
  $self->{inoutvalues}->{$sql}->{$p_num} = $value;
  return 1;
}

=back

=head1 PRIVATE INTERFACE

  Methods used by the package internally. Should not be called from an external package.

=over 4

=item _clear_dbi_err_errstr()

  Helper method used by the fake DBI::st and DBI::db to clear out
  the $obj->{err} and $obj->{errstr} on each method call.
  
  Should not be called from an external script\package.

=cut

sub _clear_dbi_err_errstr{
  my ($self, $obj) = @_;
  
  $obj->{errstr} = undef;
  $obj->{err} = undef;
  $DBI::errstr = undef;
  $DBI::err = undef;
  return 1;
}

=item _set_dbi_err_errstr()

  Helper method used by the fake DBI::st and DBI::db to set the
  $obj->{err}, $obj->{errstr}, $DBI::err and $DBI::errstr.
  This method also handles RaiseError and PrintError attributes.
  
  Args:
    $obj - Instance of DBI::st or DBI::db
    %args - A hash with the following keys:
      err     - The numeric error code to be set
      errstr  - The user friendly DBI error message.
      
  Returns:
    On success : 1
    On failure : undef

=cut

sub _set_dbi_err_errstr{
  my ($self, $obj, %args) = @_;
  if($args{err}){
    $DBI::err = $args{err};
    $obj->{err} = $args{err};
  }
  
  if($args{errstr}){
    $DBI::errstr = $args{errstr};
    $obj->{errstr} = $args{errstr};
  }
  
  print $obj->{errstr} . "\n" if $obj->{PrintError} && $obj->{errstr};
  die( (($obj->{errstr}) ? $obj->{errstr} : '') ) if $obj->{RaiseError};
  return 1;
}

=item _set_fake_dbi_err_errstr

=cut

sub _set_fake_dbi_err_errstr{
  my ($self, $obj) = @_;
  my $sql = $obj->{Statement};

  #This should be refactored out in a helper method
  my @caller = caller(1);
  my $method = $caller[3];
  
  $method =~ s/Test::MockDBI::(St|Db)::_dbi_//;

  #No special return value is set for this method
  return if !exists($self->{methods}->{$method});
  
  
  #Search to see if the sql has a specific
  if($sql){
    foreach my $key (keys %{$self->{methods}->{$method}->{sqls}}){
      #This introduces the bug that the first hit will be the one used.
      #This is done to be complient with the regex functionality in the earlier versions
      #of Test::MockDBI
      if( $sql =~ $self->{_regexes}->{$key}){
        $self->_set_dbi_err_errstr($obj,
          err => $self->{methods}->{$method}->{sqls}->{$key}->{err},
          errstr => $self->{methods}->{$method}->{sqls}->{$key}->{errstr}
        );
        return 1;
      }
    }    
  }
  #If $sql is not or we have no matching sql we return the default if it is set
  if(exists $self->{methods}->{$method}->{default}->{err} && exists $self->{methods}->{$method}->{default}->{errstr}){
    $self->_set_dbi_err_errstr($obj,
      err => $self->{methods}->{$method}->{default}->{err},
      errstr => $self->{methods}->{$method}->{default}->{errstr});
    return 1;
  }  

  return ;
}

=item _has_inout_value()

  Helper method used by the DBI::db and DBI::st packages.
  The method searches to see if there is specified a value for a
  inout variable.
  
  If called in SCALAR context it return 1/undef based on if the
  parameter bound as $p_num has a predefined return value set.
  
  If called in LIST context the method returns and array with
  1/undef in position 0 which indicates the same as when the method
  is called in SCALAR context. The second element of the list is the
  value that should be applied to the inout parameter.

=cut

sub _has_inout_value{
  my ($self, $sql, $p_num) = @_;
  
  foreach my $key (keys %{ $self->{inoutvalues} }){
    if( $sql =~ m/\Q$key\E/ms){
      if($self->{inoutvalues}->{$key}->{$p_num}){
        return (wantarray) ? (1, $self->{inoutvalues}->{$key}->{$p_num}) : 1;
      }
    } 
  }
  return;
}

=item _has_fake_retval()
  
  Method for identifing if a method has a predefined return value set.
  If the SQL parameter is provided
  this will have precedence over the default value.
  
  If the method is called in SCALAR context it will return 1\undef based on
  if the method has a predefined return value set.
  
  If the method is called in LIST context it will return a list with 1/undef at
  index 0 which indicates the same as when called in SCALAR context. index 1 will
  contain a reference to the actual return value that should be returned by the method.
  This value may be undef.
  
=cut

sub _has_fake_retval{
  my ($self, $sql) = @_;
  my @caller = caller(1);
  my $method = $caller[3];
  
  $method =~ s/Test::MockDBI(::(St|Db))?::_dbi_//;
  
  #No special return value is set for this method
  return if !exists($self->{methods}->{$method});
  
  
  #Search to see if the sql has a specific
  if($sql){
    foreach my $key (keys %{$self->{methods}->{$method}->{sqls}}){
      #This introduces the bug that the first hit will be the one used.
      #This is done to be complient with the regex functionality in the earlier versions
      #of Test::MockDBI
     # if( ( ($key =~ m/^\(\?\^:/ && $sql =~ $instance->{legacy_regex}->{$key}) || $sql =~ m/\Q$key\E/ms ) &&
      #   exists $self->{methods}->{$method}->{sqls}->{$key}->{retval}){
	
	# to handle old and new versions of PERL
         my $modifiers = ($key =~ /\Q(?^/) ? "^" : "-xism";
      
       if( $sql =~ $self->{_regexes}->{$key} &&
         exists $self->{methods}->{$method}->{sqls}->{$key}->{retval}){  
        
		if(wantarray()){
	          return (1, $self->{methods}->{$method}->{sqls}->{$key}->{retval});
        	}else{
	          return 1;
       		 }
      }      
    }    
  }
  #If $sql is not or we have no matching sql we return the default if it is set
  if(exists $self->{methods}->{$method}->{default}->{retval}){
    return (wantarray()) ? (1, $self->{methods}->{$method}->{default}->{retval}) : undef;
  }
  
  return;
}

=item _is_bad_bind_param()
  
  Method for identifing if a bind parameters value is predefined as unwanted.
  The configuration for the provided SQL will have precedence over the default configured behaviour.
  
  When called it will return 1\undef based on
  if the provided value should make the bind_param method fail.
  
=cut

sub _is_bad_bind_param{
  my ($self, $sql, $param) = @_;
  my @caller = caller(1);
  my $method = $caller[3];
  
  $method =~ s/Test::MockDBI::(St|Db)::_dbi_//;
  
  foreach my $key (keys %{ $self->{methods}->{$method}->{sqls} }){
    #This introduces the bug that the first hit will be the one used.
    #This is done to be complient with the regex functionality in the earlier versions
    #of Test::MockDBI
    
    if( $sql =~ $self->{_regexes}->{$key} ){
      #If no bad params is set for this sql do nothing and continue the loop.
      if($self->{methods}->{$method}->{sqls}->{$key}->{bad_params} &&
         ref($self->{methods}->{$method}->{sqls}->{$key}->{bad_params}) eq 'ARRAY'){
        
        foreach my $bad_param ( @{ $self->{methods}->{$method}->{sqls}->{$key}->{bad_params} }){
          if(Scalar::Util::looks_like_number($param) && Scalar::Util::looks_like_number($bad_param)){
            return 1 if $param == $bad_param;
          }
          return 1 if $param eq $bad_param;
        }
      }
    }
  }
  
  if(exists $self->{methods}->{$method}->{global_bad_params} && ref($self->{methods}->{$method}->{global_bad_params}) eq 'ARRAY'){
    foreach my $bad_param ( @{ $self->{methods}->{$method}->{global_bad_params} }){
      if(Scalar::Util::looks_like_number($param) && Scalar::Util::looks_like_number($bad_param)){
        return 1 if $param == $bad_param;
      }
      return 1 if $param eq $bad_param;
    }    
  }  
  return;
}

=back

=head1 CLASS INTERFACE

=over 4

=item get_instance()

  Method for retrieving the current Test::MockDBI instance
  
=cut

sub get_instance{
  return $instance;
}

=back

=cut

####################################
#
# Mocked DBI API
# (Method used to mock the DBI package's methods)
#
####################################

=pod _dbi__concat_hash_sorted

  This is basically a copy\paste from the DBI package itself.
  The method is used inside the prepare_cached method

=cut

sub _dbi__concat_hash_sorted {
  my ( $hash_ref, $kv_separator, $pair_separator, $use_neat, $num_sort ) = @_;
  # $num_sort: 0=lexical, 1=numeric, undef=try to guess

  return undef unless defined $hash_ref;
  die "hash is not a hash reference" unless ref $hash_ref eq 'HASH';
  my $keys = DBI::_get_sorted_hash_keys($hash_ref, $num_sort);
  my $string = '';
  for my $key (@$keys) {
    $string .= $pair_separator if length $string > 0;
    my $value = $hash_ref->{$key};
    if ($use_neat) {
      $value = DBI::neat($value, 0);
    }
    else {
      $value = (defined $value) ? "'$value'" : 'undef';
    }
    $string .= $key . $kv_separator . $value;
  }
  return $string;
}

=pod _dbi__get_sorted_hash_keys

  This is basically a copy\paste from the DBI package itself.
  The method is used inside the prepare_cached method

=cut

sub _dbi__get_sorted_hash_keys {
  my ($hash_ref, $num_sort) = @_;
  if (not defined $num_sort) {
    my $sort_guess = 1;
    $sort_guess = (not DBI::looks_like_number($_)) ? 0 : $sort_guess
        for keys %$hash_ref;
    $num_sort = $sort_guess;
  }
  
  my @keys = keys %$hash_ref;
  no warnings 'numeric';
  my @sorted = ($num_sort)
      ? sort { $a <=> $b or $a cmp $b } @keys
      : sort    @keys;
  return \@sorted;
}

=pod _dbi_looks_like_number

  This is basically a copy\paste from the DBI package itself.
  The method is used inside the prepare_cached method

=cut

sub _dbi_looks_like_number {
  my @new = ();
  for my $thing(@_) {
    if (!defined $thing or $thing eq '') {
        push @new, undef;
    }
    else {
        push @new, ($thing =~ /^([+-]?)(?=\d|\.\d)\d*(\.\d*)?([Ee]([+-]?\d+))?$/) ? 1 : 0;
    }
  }
  return (@_ >1) ? @new : $new[0];
}

=pod _dbi_connect

  Mocked DBI->connect method.
  
  The method takes the same arguments as the usual DBI->connect method.
  It returns a $dbh which has ref DBI::db
  
=cut

sub _dbi_connect{
  my ($self, $dsn, $user, $pass, $attr) = @_;
  
  my $statement = 'CONNECT TO $dsn AS $user WITH $pass';
  
  my ($status, $retval) = $instance->_has_fake_retval($statement);
  if($status){
    if(ref($retval) eq 'CODE'){
      return $retval->();
    }
    return $retval;
  }
  
  my $object = bless({
    AutoCommit => 1,
    Driver => undef,
    Name => undef,
    Statement => $statement,
    RowCacheSize => undef,
    Username => undef,
    
    #Common
    Warn => undef,
    Active => undef,
    Executed => undef,
    Kids => 0,
    ActiveKids => undef,
    CachedKids => undef,
    Type => 'db',
    ChildHandles => [],
    CompatMode => undef,
    InactiveDestroy => undef,
    AutoInactiveDestroy => undef,
    PrintWarn => undef,
    PrintError => undef,
    RaiseError => undef,
    HandleError => undef,
    HandleSetErr => undef,
    ErrCount => undef,
    ShowErrorStatement => undef,
    TraceLevel => undef,
    FetchHashKeyName => undef,
    ChopBlanks => undef,
    LongReadLen => undef,
    LongTruncOk => undef,
    TaintIn => undef,
    TaintOut => undef,
    Taint => undef,
    Profile => undef,
    ReadOnly => undef,
    Callbacks => undef,
  }, "DBI::db");
  
  foreach my $key (keys %{ $attr }){
    $object->{$key} = $attr->{$key} if(exists($object->{$key}));
  }
  
  return $object;
  
}

##########################################################
#
# DEPRECATED OLD INTERFACE
#
###########################################################
sub set_retval_array{
  warn 'set_retval_array is deprecated. Please use $instance->set_retval instead' . "\n";
  my ($self, $dbi_testing_type, $matching_sql, @retval) = @_;
  
  my $regex = qr/$matching_sql/;
  
  if(ref($retval[0]) eq 'CODE'){
    return $instance->set_retval( method => 'fetchrow_arrayref', sql => $regex, retval => $retval[0]);
  }else{
    return $instance->set_retval( method => 'fetchrow_arrayref', sql => $regex, retval => [ \@retval ]);
  } 
}
sub set_retval_scalar{
  warn 'set_retval_scalar is deprecated. Please use $instance->set_retval instead' . "\n";
  my ($self, $dbi_testing_type, $matching_sql, $retval) = @_;
  
  my @methods = qw(fetchall_arrayref fetchrow_arrayref fetchall_hashref fetchrow_hashref);

  my $regex = qr/$matching_sql/;

  #try to find out if the $retval is an arrayref only, or an arrayref of arrayref
  # or arrayref of hashrefs
  if(ref($retval) eq 'ARRAY'){
    my $item = $retval->[0];
    
    if(ref($item) eq 'ARRAY'){
      #We most likely have an arrayref of arrayrefs
      #it should be applied to fetchall_arrayref and fetchrow_arrayref
      $instance->set_retval( method => 'fetchall_arrayref', sql => $regex, retval => $retval);
      $instance->set_retval( method => 'fetchrow_arrayref', sql => $regex, retval => $retval);
    }elsif(ref($item) eq 'HASH'){
      #We most likely have an arrayref of hashrefs
      #it should be applied to fetchall_hashrefref and fetchrow_hashref
      $instance->set_retval( method => 'fetchall_hashref', sql => $regex, retval => $retval);
      $instance->set_retval( method => 'fetchrow_hashref', sql => $regex, retval => $retval);
    }elsif(!ref($item)){
      #We only have 1 arrayref with values. This was used in the old Test::MockDBI tests
      #It was passed because you only called for instance fetchrow_arrayref once
      #We will wrap it in an array and hope for the best
      $instance->set_retval( method => 'fetchrow_arrayref', sql => $regex, retval => [$retval]);
    }else{
      #We dont know, set the same retval for EVERYONE!
      foreach my $method ( @methods ){
        $instance->set_retval( method => $method, sql => $regex, retval => $retval);
      }      
    }
    
  }elsif(ref($retval) eq 'HASH'){
    $instance->set_retval( method => 'fetchrow_hashref', sql => $regex, retval => [$retval]);
  }else{
    #We dont know, set the same retval for EVERYONE!
    foreach my $method ( @methods ){
      $instance->set_retval( method => $method, sql => $regex, retval => $retval);
    }          
  }
  return 1;
}
sub set_rows{
  warn 'set_rows is deprecated. Please use $instance->set_retval instead' . "\n";
  my ($self, $dbi_testing_type, $matching_sql, $rows) = @_;
  
  my $regex = qr/$matching_sql/;
  
  return $instance->set_retval( method => 'rows', sql => $regex, retval => $rows );
}

sub set_errstr{
  warn "set_errstr is deprecated. Please use $instance->set_retval instead \n";
  return;
}
sub _is_bad_param{
  warn "_is_bad_param is deprecated and no longer functional. It allways returns 1\n";
  return 1;
}
sub set_dbi_test_type{
  warn "set_dbi_test_type is deprecated. Does nothing!\n";
  return 1;
}
sub get_dbi_test_type{
  warn "get_dbi_test_type is deprecated. Does nothing!\n";
  return 1;
}

=head1 AUTHOR

Mark Leighton Fisher,
E<lt>mark-fisher@fisherscreek.comE<gt>

Minor modifications (version 0.62 onwards) by
Andreas Faafeng
E<lt>aff@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2004, Fisher's Creek Consulting, LLC.  Copyright
2004, DeepData, Inc.

=head1 LICENSE

This code is released under the same licenses as Perl
itself.

=cut

1;
