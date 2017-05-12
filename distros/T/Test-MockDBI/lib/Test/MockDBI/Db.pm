package Test::MockDBI::Db;

use strict;
use warnings;
use Test::MockDBI::Base;

use base qw(Test::MockDBI::Base);

my $mockdbi = undef;

sub import{ $mockdbi = $_[1]; }

sub _dbi_prepare{
  my ($self, $statement, $attr) = @_;
  
  # Reset both errors as per DBI Rule
  $mockdbi->_clear_dbi_err_errstr($self);
  
  my ($status, $retval) = $mockdbi->_has_fake_retval($statement);
  if($status){
    $mockdbi->_set_fake_dbi_err_errstr($self);
    
    if(ref($retval) eq 'CODE'){
      return $retval->($self);
    }
    return $retval;
  }
  
  #Seems like DBI dies if nothing is passed as a statement
  #We replicate the same behaviour, but is this wrong?
  #Doesnt DBI->prepare honor RaiseError \ PrintError ?
  unless( $statement ){
    die('DBI prepare: invalid number of arguments: got handle + 0, expected handle + between 1 and 2
    Usage: $h->prepare($statement [, \%attr])');
  }

  #dbh->{Statment} should contain the most recent string
  #passed to prepare or do event if that call failed
  $self->{Statement} = $statement;

  my $num_of_params = ($statement =~ tr/?//);
  
  my $o_retval = bless {
    NUM_OF_FIELDS => undef,
    NUM_OF_PARAMS => $num_of_params,
    NAME => undef,
    NAME_lc => undef,
    NAME_uc => undef,
    NAME_hash => undef,
    NAME_lc_hash => undef,
    NAME_uc_hash => undef,
    TYPE => undef,
    PRECISION =>  undef,
    SCALE => undef,
    NULLABLE => undef,
    CursorName => undef,
    Database => $self,
    Statement => $statement,
    ParamValues => {},
    ParamTypes => {},
    ParamArray => undef,
    RowsInCache =>  undef,
    _fake => {
      InoutParams => []
    },
    
    #Common
    Warn => undef,
    Active => undef,
    Executed => undef,
    Kids => 0, #Should always be zero for a statementhandler see DBI documentation
    ActiveKids => undef,
    CachedKids => undef,
    Type => 'st',
    ChildHandles => undef,
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
  }, 'DBI::st';
  
  push( @{ $self->{ChildHandles} }, $o_retval);
  $self->{Kids} = scalar( @{ $self->{ChildHandles} } );
  $self->{ActiveKids} = Test::MockDBI::Db::_update_active_kids($self);
  return $o_retval;
}

sub _dbi_prepare_cached{
  my ($self, $statement, $attr, $if_active) = @_;
  
  $attr = {} if !$attr;
  # Reset both errors as per DBI Rule
  $mockdbi->_clear_dbi_err_errstr($self);
  
  my ($status, $retval) = $mockdbi->_has_fake_retval($statement);
  if($status){
    $mockdbi->_set_fake_dbi_err_errstr($self);
    
    if(ref($retval) eq 'CODE'){
      return $retval->($self);
    }
    return $retval;
  }  
  
	my $cache = $self->{CachedKids} ||= {};
	my $key = do { local $^W;
	    join "!\001", $statement, DBI::_concat_hash_sorted($attr, "=\001", ",\001", 0, 0)
	};
	my $sth = $cache->{$key};
  
  if($sth){
    return $sth unless ($sth->{Active});
    Carp::carp("prepare_cached($statement) statement handle $sth still Active")
      unless ($if_active ||= 0);
    $sth->finish if $if_active <= 1;
    return $sth  if $if_active <= 2;    
  }
	$sth = $self->prepare($statement, $attr);
	$cache->{$key} = $sth if $sth;

	return $sth;  
}

sub _dbi_do{
  my($self, $statement, $attr, @bind_values) = @_;

  # Reset both errors as per DBI Rule
  $mockdbi->_clear_dbi_err_errstr($self);
  
  my ($status, $retval) = $mockdbi->_has_fake_retval($statement);
  if($status){
    $mockdbi->_set_fake_dbi_err_errstr($self);
    
    if(ref($retval) eq 'CODE'){
      return $retval->($self);
    }
    return $retval;
  }  
  
  my $sth = $self->prepare($statement, $attr) or return;
  $sth->execute(@bind_values) or return;

  #Updating dbh attributes
  $self->{Executed} = 1;

  
  my $rows = $sth->rows;
  ($rows == 0) ? "0E0" : $rows; # always return true if no error  
}

sub _dbi_commit{
  my ($self) = @_;

  # Reset both errors as per DBI Rule
  $mockdbi->_clear_dbi_err_errstr($self);
  
  
  
  #The executed attribute is updated even if the
  #call fails
  $self->{Executed} = undef;
  
  #Warning is displayed even if the method fails
  warn "commit ineffective with AutoCommit enabled" if $self->{AutoCommit};
  
  my ($status, $retval) = $mockdbi->_has_fake_retval($self->{Statement});
  if($status){
    $mockdbi->_set_fake_dbi_err_errstr($self);
    
    if(ref($retval) eq 'CODE'){
      return $retval->($self);
    }
    return $retval;
  }
  
  #Updating dbh attributes
  $self->{AutoCommit} = 1;

  return 1;
}

sub _dbi_rollback{
  my ($self) = @_;
  # Reset both errors as per DBI Rule
  $mockdbi->_clear_dbi_err_errstr($self);
  
  #The executed attribute is updated even if the
  #call fails
  $self->{Executed} = undef;
  
  #Warning is displayed even if the method fails
  warn "rollback ineffective with AutoCommit enabled" if $self->{AutoCommit};
  
  my ($status, $retval) = $mockdbi->_has_fake_retval($self->{Statement});
  if($status){
    $mockdbi->_set_fake_dbi_err_errstr($self);
    
    if(ref($retval) eq 'CODE'){
      return $retval->($self);
    }
    return $retval;
  }
  
  $self->{AutoCommit} = 1;
  return 1;  
}

sub _dbi_begin_work{
  my ($self) = @_;
  
  # Reset both errors as per DBI Rule
  $mockdbi->_clear_dbi_err_errstr($self);
  
  my ($status, $retval) = $mockdbi->_has_fake_retval($self->{Statement});
  if($status){
    $mockdbi->_set_fake_dbi_err_errstr($self);
    
    if(ref($retval) eq 'CODE'){
      return $retval->($self);
    }
    return $retval;
  }
  
  $self->{AutoCommit} = 0;
  return 1;
}

sub _dbi_ping{
  my ($self) = @_;
  
  # Reset both errors as per DBI Rule
  $mockdbi->_clear_dbi_err_errstr($self);
  
  my ($status, $retval) = $mockdbi->_has_fake_retval();
  if($status){
    $mockdbi->_set_fake_dbi_err_errstr($self);
    
    if(ref($retval) eq 'CODE'){
      return $retval->($self);
    }
    return $retval;
  }  

  return 1;
}

sub _dbi_disconnect{
  my ($self) = @_;

  # Reset both errors as per DBI Rule
  $mockdbi->_clear_dbi_err_errstr($self);
  
  my ($status, $retval) = $mockdbi->_has_fake_retval();
  if($status){
    $mockdbi->_set_fake_dbi_err_errstr($self);
    
    if(ref($retval) eq 'CODE'){
      return $retval->($self);
    }
    return $retval;
  }   

  #Set the Active flag to false for all childhandlers
  foreach my $ch ( @{ $self->{ChildHandlers} } ){
    $ch->{Active} = undef;
  }
  Test::MockDBI::Db::_update_active_kids($self);

  return 1;  
}


#This is a helper method, and not a part of the DBI specification
sub _update_active_kids{
  my ($self) = @_;
  my $cnt = scalar(grep{ $_->{Active} } @{$self->{ChildHandles}});
  $self->{ActiveKids} = $cnt;
  return 1;
}
1;