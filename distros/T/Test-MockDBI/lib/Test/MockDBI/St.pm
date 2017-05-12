package Test::MockDBI::St;

use strict;
use warnings;
use Test::MockDBI::Constants;
use Test::MockDBI::Db;
use Test::MockDBI::Base;

use base qw(Test::MockDBI::Base);

my $mockdbi = undef;

sub import{ $mockdbi = $_[1]; }


sub _dbi_bind_param{
  my ($self, $p_num, $bind_value, $attr) = @_;
  
  #Clearing the dbi err/errstr
  $mockdbi->_clear_dbi_err_errstr($self);
  
  my ($status, $retval) = $mockdbi->_has_fake_retval($self->{Statement});
  if($status){
    $mockdbi->_set_fake_dbi_err_errstr($self);
    
    if(ref($retval) eq 'CODE'){
      return $retval->($self);
    }
    
    return $retval;
  }
  return if($mockdbi->_is_bad_bind_param($self->{Statement}, $bind_value));
  
  #Check that the $p_num is a valid number
  if($p_num !~ m/^\d+$/){
    $mockdbi->_set_dbi_err_errstr($self,  err => 16, errstr => 'Illegal parameter number');
    return;
  }
  if($p_num < 1 || $p_num > $self->{NUM_OF_PARAMS}){
    $mockdbi->_set_dbi_err_errstr($self,  err => 16, errstr => 'Illegal parameter number');
    return;
  }
  
  #Verify that the bind_param attribute is a valid one

  
  #Rewrite this to resemble the DBI behaviour
  if($attr && $attr =~ m/^\d+$/){
    $self->{ParamTypes}->{$p_num} = { TYPE => $attr};
  }elsif($attr){
    #Assume its a hash
    #Throw a warning as DBI does
    if( $attr->{TYPE} !~ m/^\d+$/){
      my @caller = caller(1);
      warn 'Argument "' . $attr->{TYPE} .'" isn\'t numeric in subroutine entry at ' . $caller[1] . ' line ' . $caller[2] . '.' . "\n";
    }else{
      $self->{ParamTypes}->{$p_num} = $attr;
    }
    
  }else{
    $self->{ParamTypes}->{$p_num} = { TYPE => SQL_VARCHAR };
  }
    
  $self->{ParamValues}->{$p_num} = $bind_value;
  
  return 1;
}

sub _dbi_bind_param_inout{
  my($self, $p_num, $bind_value, $max_length, $attr) = @_;
  
  $mockdbi->_clear_dbi_err_errstr($self);
  
  my ($status, $retval) = $mockdbi->_has_fake_retval($self->{Statement});
  if($status){
    $mockdbi->_set_fake_dbi_err_errstr($self);
    
    if( ref($retval) eq 'CODE'){
      return $retval->($self);
    }
    
    return $retval;
  }
  return if($mockdbi->_is_bad_bind_param($self->{Statement}, $bind_value));
  
  if(!$self || !$p_num || !$bind_value || $max_length ){
    #DBI just dies if it has to few parameters
    die('DBI bind_param_inout: invalid number of arguments: got handle + 2, expected handle + between 3 and 4
        Usage: $h->bind_param_inout($parameter, \$var, $maxlen, [, \%attr])');
  }

  #Check that the $p_num is a valid number
  if($p_num !~ m/^\d+$/){
    $mockdbi->_set_dbi_err_errstr($self,  err => 16, errstr => 'Illegal parameter number');
    return;
  }
  if($p_num < 1 || $p_num > $self->{NUM_OF_PARAMS}){
    $mockdbi->_set_dbi_err_errstr($self,  err => 16, errstr => 'Illegal parameter number');
    return;
  }
  
  #Verify that the bind_param attribute is a valid one
  if($attr && $attr =~ m/^\d+$/){
    $self->{ParamTypes}->{$p_num} = { TYPE => $attr};
  }elsif($attr){
    #Assume its a hash
    #Throw a warning as DBI does
    if( $attr->{TYPE} !~ m/^\d+$/){
      my @caller = caller(1);
      warn 'Argument "' . $attr->{TYPE} .'" isn\'t numeric in subroutine entry at ' . $caller[1] . ' line ' . $caller[2] . '.' . "\n";
    }else{
      $self->{ParamTypes}->{$p_num} = $attr;
    }
    
  }else{
    $self->{ParamTypes}->{$p_num} = { TYPE => SQL_VARCHAR };
  }
  
  if ( ref($bind_value) ne 'SCALAR' ) {
    #DBI just dies if $bind_value is not a SCALAR reference
    die('bind_param_inout needs a reference to a scalar value');
    return;
  }  
  
  $self->{ParamValues}->{$p_num} = $bind_value;
  
  push( @{ $self->{_fake}->{InoutParams} }, $p_num );
  
  return 1;  
}

sub _dbi_execute{
  my ($self, @bind_values) = @_;
  
  $mockdbi->_clear_dbi_err_errstr($self);
  
  my ($status, $retval) = $mockdbi->_has_fake_retval($self->{Statement});
  if($status){
    $mockdbi->_set_fake_dbi_err_errstr($self);
    
    if(ref($retval) eq 'CODE'){
      return $retval->($self);
    }
    return $retval;
  }    
  
  #Copied from the DBI documentation:
  # Active
  # Type: boolean, read-only
  # The Active attribute is true if the handle object is "active". This is rarely used in applications.
  # The exact meaning of active is somewhat vague at the moment.
  # For a database handle it typically means that the handle is connected to a database ($dbh->disconnect sets Active off).
  # For a statement handle it typically means that the handle is a SELECT that may have more data to fetch.
  # (Fetching all the data or calling $sth->finish sets Active off.)
  #
  # Due to the vague definition of the Active attribute i have taken the freedom to interpeter the attribute in the following way:
  #   - The Active attribute is set to true on a statementhandler when the execute method is called on an already prepared select statement
  #   - The Active attribute is set to false either if finish is called on the statementhandler or disconnect is called on the dbh
  #
  
  #Updating attributes
  $self->{Active} = 1 if $self->{Statement} =~ m/^select/i;
  $self->{Executed} = 1;
  #Update the parent activekids flag
  Test::MockDBI::Db::_update_active_kids($self->{Database});
  
  if(ref($self->{_fake}->{InoutParams}) eq 'ARRAY' && scalar( @{ $self->{_fake}->{InoutParams} } ) > 0 ){
    foreach my $p_num ( @{ $self->{_fake}->{InoutParams} } ){
      my ($status, $retval) = $mockdbi->_has_inout_value($self->{Statement}, $p_num);
      ${ $self->{ParamValues}->{$p_num} } = $retval if $status;
    }
    
  }

  #Not enough parameters bound
  if( $self->{NUM_OF_PARAMS} != scalar(keys %{ $self->{ParamValues} })){
    return '0E0';
  }
  
  #Number of affected rows is not known
  return -1;
}

sub _dbi_fetchrow_arrayref{
  my ($self) = @_;
  
  $mockdbi->_clear_dbi_err_errstr($self);
  
  #return if we are not executed
  return if( !$self->{Executed} );  
  
  my ($status, $retval) = $mockdbi->_has_fake_retval($self->{Statement});
  if($status){
    $mockdbi->_set_fake_dbi_err_errstr($self);
    
    if(ref($retval) eq 'CODE'){
      my @caller = caller(1);
      if($caller[3] && $caller[3] =~ m/fetchrow_array$/){
        return $retval;
      }
      return $retval->($self);
    }
  }  
  
  #The resultset should be an array of hashes
  if(ref($retval) ne 'ARRAY'){
    #Should implement support for RaiseError and PrintError
    return;
  }
  
  if(scalar( @{$retval} ) > 0){
    my $row = shift @{ $retval };
    if(ref($row) ne 'ARRAY'){
      #Should implement support for RaiseError and PrintError
      return;
    }
    return $row;
  }
  #fetchrow_arrayref returns undef if no more rows are available, or an error has occured
  return;
}

sub _dbi_fetch{
  return $_[0]->fetchrow_arrayref();
}

sub _dbi_fetchrow_array{
  my ($self) = @_;
  my $row = $self->fetchrow_arrayref();
  return if !$row;
  return @{$row} if ref($row) eq 'ARRAY';
  return $row->($self) if ref($row) eq 'CODE';
  return $row;
}

sub _dbi_fetchrow_hashref{
  my ($self) = @_;
  
  $mockdbi->_clear_dbi_err_errstr($self);
  
  #return if we are not executed
  return if( !$self->{Executed} );  
  
  my ($status, $retval) = $mockdbi->_has_fake_retval($self->{Statement});
  if($status){
    $mockdbi->_set_fake_dbi_err_errstr($self);
    
    if(ref($retval) eq 'CODE'){
      return $retval->($self);
    }
  }  
  
  #The resultset should be an array of hashes
  if(ref($retval) ne 'ARRAY'){
    #Should implement support for RaiseError and PrintError
    return;
  }
  
  if(scalar( @{$retval} ) > 0){
    my $row = shift @{ $retval };
    if(ref($row) ne 'HASH'){
      #Should implement support for RaiseError and PrintError
      return;
    }
    return $row;
  }

  #fetchrow_hashref returns undef if no more rows are available, or an error has occured
  return;
}

sub _dbi_fetchall_arrayref{
  my ($self) = @_;
  
  $mockdbi->_clear_dbi_err_errstr($self);
  
  #return if we are not executed
  return if( !$self->{Executed} );  
  
  my ($status, $retval) = $mockdbi->_has_fake_retval($self->{Statement});
  if($status){
    $mockdbi->_set_fake_dbi_err_errstr($self);
    
    if(ref($retval) eq 'CODE'){
      return $retval->($self);
    }
  }  

  #The resultset should be an array of hashes
  if(ref($retval) ne 'ARRAY'){
    #Should implement support for RaiseError and PrintError
    return;
  }
  
  return $retval;
}


sub _dbi_finish{
  my ($self) = @_;
  
  $mockdbi->_clear_dbi_err_errstr($self);
  
  my ($status, $retval) = $mockdbi->_has_fake_retval($self->{Statement});
  if($status){
    $mockdbi->_set_fake_dbi_err_errstr($self);
    
    if(ref($retval) eq 'CODE'){
      return $retval->($self);
    }
    return $retval;
  }  
  
  $self->{Active} = undef;
  #Update the parent activekids flag
  Test::MockDBI::Db::_update_active_kids($self->{Database});
  
  return 1;
}

sub _dbi_rows{
  my ($self) = @_;
  
  $mockdbi->_clear_dbi_err_errstr($self);
  
  my ($status, $retval) = $mockdbi->_has_fake_retval($self->{Statement});
  if($status){
    $mockdbi->_set_fake_dbi_err_errstr($self);
    
    if(ref($retval) eq 'CODE'){
      return $retval->($self);
    }
    return $retval;
  }  
  
  return -1;
}
1;