=head1 NAME

perfSONAR_PS::DB::SQL::Base  - A class that provides  data access for SQL databases 

=head1 DESCRIPTION

This module provides access to the relevant DBI wrapped methods given the relevant
contact points for the database. Any service specific SQL DB handler should ingerit from this class.

=head1 SYNOPSIS
  
  package  perfSONAR_PS::DB::SQL::PingER;

  # extend from this class
  
  use  perfSONAR_PS::DB::SQL::Base;
  use base  perfSONAR_PS::DB::SQL::Base;
  
  
  1;
  

=head1 METHODS
  
=cut



package perfSONAR_PS::DB::SQL::Base;
use warnings;
use strict; 
use DBI;
use Data::Dumper;
use version; our $VERSION = 0.09; 
use English '-no_match_vars';
use Scalar::Util qw(blessed);
use Log::Log4perl qw( get_logger ); 
 
use perfSONAR_PS::DB::SQL::QueryBuilder qw(build_select build_where_clause);

use constant  CLASSPATH  => 'perfSONAR_PS::DB::SQL::Base';
use constant  PARAMS =>  qw(driver database handle ERRORMSG LOGGER host port username password attributes);
 
use fields  (PARAMS);


no strict 'refs';
foreach my $key  (PARAMS)  { 
       *{__PACKAGE__ . "::$key"} = sub {  my $obj = shift; my $a = shift;
                          if($a) {
			     ($key  eq 'ERRORMSG')?$obj->{"$key"} .= " \n $a":$obj->{"$key"} = $a;
			  }  
			  return $obj->{"$key"}}; 
} 
use strict;

=head2  new

    constructor accepts hashref as parameter
    returns object

=cut 

sub new { 
    my $that = shift;
    my $param = shift;
    my $logger  = get_logger( __PACKAGE__ ); 
    my $class = ref($that) || $that;
    my $self =  fields::new($class );
    ## injecting accessor/mutator for each field
    $self->LOGGER($logger);
    $self->attributes(  {RaiseError => 1} ); 
    if($param) {
        if( $self->init($param) == -1 ) {
           $self->LOGGER()->error($self->ERRORMSG); 
           return;
        }
    }
    return   $self;
}


sub DESTROY {
    my $self = shift;
     $self->closeDB;
    $self->SUPER::DESTROY  if $self->can("SUPER::DESTROY");
    return;
}
 
=head2 init 

   accepts hashref as single parameter and initializes object
  returns  
 
    0 = if everything is okay
   -1 = somethign went wrong 

=cut


sub init {
  my ($self, $param) = @_;
  if($param) {
      if(ref($param) ne 'HASH')   {
            $self->ERRORMSG("ONLY hash ref accepted as param " . $param );         
            return -1;
      } 
   
      $self->{LOGGER}->debug("Parsing parameters: " . (join " : ", keys %{$param}));    
      foreach my $key (PARAMS) {
            $self->{$key} = $param->{$key} if exists  $param->{$key}; ###  
      } 
      return 0;
   } else {
      $self->ERRORMSG(" Undefined parameter "); 
      return -1;
   }
   
}

=head2 connect

opens a connection to the database or reuses the cached one

Returns 
     0 = if everything is okay
   -1 = somethign went wrong
  
=cut

sub  openDB {
    my ($self, $param) = @_;       
    if($param && $self->init($param) == -1 ) {
         return -1;
    } 
    eval {
        $self->handle(DBI->connect_cached("DBI:" .  $self->driver . ":dbname=" .  $self->database  . 
	                      ($self->host?";host=" . $self->host:'') .
			      ($self->port?";port=" . $self->port:'') , $self->username, $self->password, $self->attributes)) 
			      or  die $DBI::errstr; 
    };
    if ($EVAL_ERROR) {
        $self->ERRORMSG("Connect DB error \"" . $EVAL_ERROR . "\"." );
        return -1;
    }
    return 0;
}

=head2 closeDB

closes the connection to the database
Returns 
     0 = if everything is okay
   -1 = somethign went wrong
   
=cut

sub closeDB {
    my $self = shift;
    # close database connection
    # destroy objects classes in memory
    eval {
        $self->handle->disconnect if $self->handle && ref($self->handle) =~ /DBI/;
    };
    if ($EVAL_ERROR) {
        $self->ERRORMSG("Close DB error \"" . $EVAL_ERROR . "\"." );
        return -1;
    }
    return 0;	    
}

=head2 alive

   checks if db handle is alive
   Returns 
     0 = if everything is okay
   -1 = somethign went wrong

=cut

sub alive {
    my $self = shift;
    # close database connection
    # destroy objects classes in memory
    my $ping = -1;
    eval {
    	$ping = 0 if($self->handle && ref($self->handle) =~ /DBI/ && $self->handle->ping);
    };
    if ($EVAL_ERROR) {
        $self->ERRORMSG("Ping  DB error \"" . $EVAL_ERROR . "\"." );
        return -1;
    }
    return $ping;	    
}


=head2   getFromTable

      accepts single hash param with keys:
      query => Rose::DB::Object::QueryBuilder type of query,
      table =>  table name
      validate => table validation HASHref constant
      index =>   name of the indexing key  for result 
      
      returns result as hashref keyd by $index
      or undef and sets ERRORMSG 

=cut

 
sub  getFromTable {
     my ($self, $param) = @_;    
   
     unless( $param && ref($param) eq 'HASH' && $param->{table} && 
               ( ($param->{query}  && ref($param->{query}) eq 'ARRAY') ||
	         ($param->{validate}  && ref($param->{validate}) eq 'HASH') 
	       ) 
	   )  {
    	 $self->ERRORMSG("getFromTable  requires single HASH ref parameter with required query  key as ARRAY ref ");
    	 return -1;
     }   
     my $results = -1;
     my @array_of_names = ();
     #
     # if validation hash is not provided then we should use query  itself for the list of columns
     #
     if(defined $param->{validate} && ref($param->{validate}) eq 'HASH') {
         @array_of_names = keys %{$param->{validate}}; 
     } else {
         my $param_sz = scalar @{$param->{query}};
         for(my $i=0;$i<$param_sz;$i+=2) {
             push @array_of_names ,$param->{query}->[$i] if  $param->{query}->[$i];
	 }
     }
     unless(   @array_of_names ) {
        $self->ERRORMSG(" getFromTable  failed, someting misssing  for  " . Dumper $param);
        return -1;
     }
     my  $stringified_names  = join ", ",  @array_of_names;
      
     eval {
         my $sql_query =  build_select({ dbh => $self->handle, 
	                                 select =>   $stringified_names,
                                         tables => [$param->{table}], 
				         query =>  $param->{query}, 
					 query_is_sql => 1, 
				         columns => {   $param->{table}  => \@array_of_names},
					 limit => ($param->{limit}?$param->{limit}:'1000000'), ## i am pretty sure that 1 mil of records is more than enough
				      });
	 $self->LOGGER->debug("  SQL:: $sql_query ");			      
	 $self->openDB  if !($self->alive == 0);
	 my $sth = $self->handle->prepare($sql_query);	      
	 $results = $self->handle->selectall_hashref($sth,  $param->{index});
	  $self->LOGGER->debug("  RESULTS dump:: " . Dumper $results);	
	 die $DBI::errstr if  $DBI::err;
     };
     if ($EVAL_ERROR) {
        $self->ERRORMSG("getFromTable  failed with error \"" . $EVAL_ERROR . "\"." );
     } 
     return $results;
}
 

 

=head2   updateTable

      accepts singel hashref param with keys:
      set => hashref { for example  'ip_name' => $ip_name, 'ip_number' => $ip_number },
      table =>  table_name
      where => where clause ( formatted as Rose::DB::Object query )
  
      returns  
      
    0  if OK
   -1 = somethign went wrong 


=cut


sub updateTable{
     my ($self, $param) = @_;    
     unless($param && ref($param) eq 'HASH' && $param->{table}  && 
                  ($param->{set}  && ref($param->{set}) eq 'HASH') &&
	         ($param->{validate}  && ref($param->{validate}) eq 'HASH')    
             && $param->{where}  && ref($param->{where}) eq 'ARRAY')  {
    	 $self->ERRORMSG("updateTable  requires single HASH ref parameter with required set,validate and where keys ");
    	 return -1;
     }  
     my $stringified_names  = ''; 
     my @array_of_names =  keys %{$param->{validate}}; 
     foreach my $key (@array_of_names ) {
         $stringified_names  .=  " $key='" .  $param->{set}->{$key} ."'," if defined  $param->{set}->{$key};
     } 
       
     my $query_sql = build_where_clause({ 
                                         dbh => $self->handle, 
	                                 tables => [$param->{table}], 
				         query =>  $param->{where}, 
					 query_is_sql => 1, 
					 table_aliases => 0,
				         columns => { $param->{table}  => \@array_of_names},
				      });
 
     chop $stringified_names if $stringified_names;
     $self->LOGGER->debug("  SQL::  $query_sql ");	
     eval {
           $self->openDB  if !($self->alive == 0);
	    my $sth = $self->handle->prepare("update  " .$param->{table} . "  set  $stringified_names where $query_sql ");	
            $sth->execute() or die $DBI::errstr; 	  
      };
      if ($EVAL_ERROR) {
          $self->ERRORMSG("updateTable failed with error \"" . $EVAL_ERROR . "\"." );
	  return -1;
      } 
      return   0;
}

=head2   insertTable

      accepts single hashref with keys:
      insert => {  'ip_name' => $ip_name, 'ip_number' => $ip_number },
      table =>  table_name 
      returns  
      
    0  or last inserted id number 
   -1 = somethign went wrong 


=cut


sub insertTable{
    my ($self, $param ) = @_;
    unless( $param && ref($param) eq 'HASH' && $param->{table}  && $param->{insert}  && ref($param->{insert}) eq 'HASH')  {
    	 $self->ERRORMSG("uinsertTable  requires single HASH ref parameter with required insert key as HASH ref ");
    	 return -1;
    } 
    my $stringified_names  = ''; 
    my $stringified_values  = ''; 
    my $rv = 0; 
    
    foreach my $key (keys %{$param->{insert}}) {
        if(defined  $param->{insert}->{$key}) {
	      $stringified_names   .=  "$key,";
	      $stringified_values  .=  "'". $param->{insert}->{$key}."',";
	}
    } 
    if($stringified_names &&  $stringified_values) {
         chop $stringified_names;
         chop $stringified_values; 
         eval {
            $self->openDB  if !($self->alive == 0);
	    my $query_sql  = "insert into ". $param->{table} ."  ($stringified_names) values ($stringified_values)";
	    $self->LOGGER->debug("  SQL::  $query_sql ");	
            $self->handle->do($query_sql); 
	    # return last serial number of the newly inserted row or integer primary key
	    $rv =  ($self->driver =~ /mysql/i)?$self->handle->{q{mysql_insertid}}:
	               ($self->driver =~ /sqlite/i)?$self->handle->func("last_insert_rowid"):
		            $self->handle->last_insert_id(undef, undef,  $param->{table}, undef);
        };
        if ($EVAL_ERROR) {
            $self->ERRORMSG("insertTable failed with error \"" . $EVAL_ERROR . "\"." );
	    return -1;
        }
    } else {
        $self->ERRORMSG("insertTable failed  because of empty list of parameters" );
	return -1;
    }
    return   $rv;
}

=head2 createTable

     create  table from template - second parameter is the name of the template table ( must exist )
    
    returns 
    
    0 - evrything is OK
    -1 - something is wrong

=cut


sub createTable {
    my ($self,  $table, $template) = @_;
    eval {
	$self->LOGGER->debug( "creating new data table   $table from template table=$template");
        # create the database table if necessary 
        $self->openDB  if !($self->alive == 0); 			
        $self->handle->do( "CREATE TABLE $table AS SELECT * FROM  $template" );		
    };
    if ( $EVAL_ERROR ) {
        $self->ERRORMSG(" Failed to create   $table ");
     	return -1; 
    }
    return 0;

}
 
=head2 validateQuery

   vlaidated supplied query parameters against defined  fields for particular table
   optional arg $required is a hash of the required  table fields
   returns 
         
    0 = if everything is okay
   -1 = somethign went wrong 


=cut

sub validateQuery {
   my ($self, $params, $valid_const, $required) = @_;
   foreach my $key (keys %{$params}) {
       unless(defined  $valid_const->{$key}) {
         $self->ERRORMSG(" Field $key is unknown for DB schema");
         return -1;
       }
       delete $required->{$key}  if $required  && $required->{$key} &&  defined $params->{$key}; 
   }
   return -1 if $required && scalar %{$required};
   return 0;
}

 
=head2  fixTimestamp 
 
  fix timestamp 
  
  returns
  
  fixed timestamp or undef if its not parseable
  
=cut


sub  fixTimestamp {
    my ($self, $timestamp) = @_;
# remap the timestamp if it's not valid
    if ($timestamp) {
        if( $timestamp  =~ m/^\d+$/) {
            return  $timestamp; 
        } elsif ($timestamp =~ s/^(\d+)\.\d+$/$1/ ) {
            return   $timestamp;
        } 
     }	 
     $self->ERRORMSG( "Timestamp $timestamp format unparseable or its undef");
     return;
     
}

=head2  booleanToInt

    converts any boolean arg  to 0/1 int

=cut

sub booleanToInt {
    my ($self, $param) = @_;
    if ( defined $param) {
        if ( $param  eq 'false'  || !$param) {
	   return 0;
	 } else {
	   return 1;
	 }
    }
    return;
}
 
 
=head2 tableExists

     check presence of the table

Returns

   
   0 = no table
   1 = table exists

=cut

sub  tableExists {
    my  ($self, $table) = @_; 
    my $result = undef;
    eval {
     	  $self->LOGGER->debug( "...testing presence of the table $table");
     	  # create the database table if necessary 
	  $self->openDB  if !($self->alive == 0);	
	  # next line will fail if table does not exist	  
     	  ($result)  =  $self->handle->selectrow_array("select * from  $table where 1=0 " );  
    }; 
    $EVAL_ERROR?return 0:return 1;
}


1;
