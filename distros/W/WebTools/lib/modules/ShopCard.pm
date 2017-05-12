package ShopCard;

################################################
# Base ShopCard Module (Object Model)
# written by Julian Lishev
# 
# Module purposes:
# To create and manage ShopCard within MySQL DB
################################################
# Available methods:
# new(), is_tables_exists(), create_tables(),
# add(), del(), clear(), remove_expired(),
# modify(), find(), update_expire(), error()
################################################

################################################
# SQL structure for MySQL DB support:
# Please edit this array only if you know what
# you doing!
# If DB structure is not available module
# will attempt to create one for you using
# structure below!
# Supported "templates" for elements of arrays:
# %%database%%, %%name%%, %%user%%, %%pass%%
################################################

@ShopCard::structure_tables = 
  (
    '_shopcard',      # First row must correspondence to first row of array below and so on.. !!!
  );
@ShopCard::structure =
 (
   "CREATE TABLE %%name%%$ShopCard::structure_tables[0]
    (
     UID          BIGINT(1) AUTO_INCREMENT PRIMARY KEY,
     ID           CHAR(50)  NOT NULL,
     CARD_NAME    CHAR(20)  DEFAULT 'default',
     PRODUCT_ID   BIGINT(1),
     QUANTITY     INT(1)    DEFAULT 1,
     PRICE        CHAR(15)  DEFAULT '0',
     DISCOUNT     CHAR(15)  DEFAULT '0',
     TOTAL        CHAR(20)  DEFAULT '0',
     CURRENCY     CHAR(20)  DEFAULT 'US',
     EXPIRE       DATETIME,
     INDEX   index_1 (PRODUCT_ID),
     INDEX   index_2 (EXPIRE),
     KEY     index_3 (CARD_NAME(5))
    )
   ",
 );
################################################
# PLEASE DO NOT EDIT BELOW!
################################################

use strict;

# ----- Global members for all objects -----
$ShopCard::debugging = 0;
$ShopCard::error     = '';

BEGIN
 {
  use vars qw($VERSION @ISA @EXPORT);
  $VERSION = "1.0";
  @ISA = qw(Exporter);
  @EXPORT = qw();
 }

sub AUTOLOAD
{
 my $self = shift;
 my $type = ref($self) or die "$self is not an object";
 my $name = $ShopCard::AUTOLOAD;
 $name =~ s/.*://;   # Strip fully-qualified portion
 $name = lc($name);
 unless (exists $self->{__subs}->{$name})
   {
    print "Can't access '$name' field in class $type";
    exit;
   }
my $ref =  $self->{__subs}->{$name};
&$ref($self,@_);
}

sub new
{ 
 my $proto = shift;
 my $class = ref($proto) || $proto;
 my $self = {};
 
 my %inp = @_;

 $self->{'create'}    = $inp{'create'}    || 'Y';
 $self->{'checkdb'}   = $inp{'checkdb'}   || 'Y';
 $self->{'name'}      = $inp{'name'}      || 'shop';
 $self->{'card_name'} = $inp{'card_name'} || 'default';
 $self->{'id'}        = $inp{'id'}        || undef;
 $self->{'database'}  = $inp{'database'}  || undef;
 $self->{'user'}      = $inp{'user'}      || '';
 $self->{'pass'}      = $inp{'pass'}      || '';
 $self->{'host'}      = $inp{'host'}      || 'localhost';
 $self->{'port'}      = abs(int($inp{'port'})) || '3306';
 $self->{'structure'} = $inp{'structure'} || \@ShopCard::structure;
 $self->{'structure_tables'} = $inp{'structure_tables'} || \@ShopCard::structure_tables;
 $self->{'dbh'}       = $inp{'dbh'}       || undef;
 
 $self->{'error'} = '';

 $self->{'__subs'} = {};
 $self->{'__subs'}->{'init'}    = $inp{'init'}      || \&__shopcard_init;

 if(($self->{'id'} eq undef) or ($self->{'id'} eq ''))
  {
   $ShopCard::error = "CARD ID is empty (supply your unique session (or card) id)!";
   return(undef);
  }

 bless($self,$class);
 if($self->init() eq undef)
  {
   return(undef);
  }
 
 return($self);
}

sub _set_val_ShopCard
{
 my $self = shift(@_);
 my $name = shift(@_);
 my @params = @_;
 if(defined($_[0]))
  {
   my $code = '$self->{'."'$name'".'} = $_[0];';
   eval $code;
   return($_[0]);
  }
 else
  {
   my $code = '$code = $self->{'."'$name'".'};';
   eval $code;
   return($code);
  }
}

sub error      { shift->_set_val_ShopCard('error', @_); $ShopCard::error = $_[0];}
sub create     { shift->_set_val_ShopCard('create', @_); }
sub checkdb    { shift->_set_val_ShopCard('checkdb', @_); }
sub card_name  { shift->_set_val_ShopCard('card_name', @_); }
sub id         { shift->_set_val_ShopCard('id', @_); }
sub database   { shift->_set_val_ShopCard('database', @_); }
sub name       { shift->_set_val_ShopCard('name', @_); }
sub user       { shift->_set_val_ShopCard('user', @_); }
sub pass       { shift->_set_val_ShopCard('pass', @_); }
sub host       { shift->_set_val_ShopCard('host', @_); }
sub port       { shift->_set_val_ShopCard('port', abs(int($_[0]))); }
sub structure  { shift->_set_val_ShopCard('structure', @_); }
sub structure_tables  { shift->_set_val_ShopCard('structure_tables', @_); }
sub dbh        { shift->_set_val_ShopCard('dbh', @_); }


sub __shopcard_init
{
 my ($self) = @_;
 my $code = << 'CODE_TERM';
 if($self->{'dbh'} eq undef)
  {
   use DBI;
  }
CODE_TERM
 eval $code;
 if($@ ne '')
   { 
    $self->error("Can't load module DBI.pm");
    return(undef);
   }
 
 # Check database (try connect) if db handler is empty
 if($self->{'dbh'} eq undef)
   {
    my $port = $self->{'port'} eq '' ? '' : ';port='.$self->{'port'};
    my $dbh = DBI->connect("DBI:mysql:".$self->{'database'}.":".$self->{'host'}.$port,$self->{'user'},$self->{'pass'});
    if($dbh)
     {
      $self->{'dbh'} = $dbh;
     }
    else
     {
      if($self->{'checkdb'} =~ m/^(Y|YES|1)$/si)
        {
         if($DBI::err == 1049) # 1049 Unknown database
          {
           if($self->{'create'} =~ m/^(Y|YES|1)$/si)
            {
             my $drh = DBI->install_driver("mysql");
             my $rc = $drh->func('createdb', $self->{'database'}, $self->{'host'}, $self->{'user'}, $self->{'pass'}, 'admin');
             if($rc)
              {
               my $port = $self->{'port'} eq '' ? '' : ';port='.$self->{'port'};
               my $dbh = DBI->connect("DBI:mysql:".$self->{'database'}.":".$self->{'host'}.$port,$self->{'user'},$self->{'pass'});
               if($dbh)
                 {
                  $self->{'dbh'} = $dbh;
                 }
               else
                 {
                  $self->error("Can't connect to database '".$self->{'database'}."'(database is just created)! Error message: ".$DBI::errstr);
                  return(undef);
                 }
              }
             else
              {
               $self->error("Error message: ".$DBI::errstr);
               return(undef);
              }
            }
           else
            {
             $self->error("Can't connect to database '".$self->{'database'}."'! Error message: ".$DBI::errstr);
             return(undef);
            }
          }
         elsif($DBI::err == 1045) # Access denied
          {
           $self->error("Can't connect to database '".$self->{'database'}."'! Access denied!");
           return(undef);
          }
         else
          {
           $self->error("Can't connect to database '".$self->{'database'}."'! Error message: ".$DBI::errstr);
           return(undef);
          }
        }
      else
       {
       	$self->error("Can't connect to database '".$self->{'database'}."'!");
        return(undef);
       }
     }
   }
 my $shops_ref = $self->{'structure_tables'};
 my @shops_s_table = @$shops_ref;
 my $shops_ref = $self->{'structure'};
 my @shops_table = @$shops_ref;
 # Check tables
 if($self->{'checkdb'} =~ m/^(Y|YES|1)$/si)
  {
   if($self->{'dbh'})
    {
     my $dbh = $self->{'dbh'};
     my $sth = $dbh->prepare("SHOW TABLES");
     $sth->execute;
     my $numRows = $sth->rows;
     my ($i,$l,$ind);
     my @rows;
     for($i=0; $i < $numRows; $i++)
      {
       my $aref = $sth->fetchrow_arrayref();
       push(@rows,$$aref[0]);
      }
     $sth->finish();
     $ind = 0;
     foreach $l (@shops_s_table)
      {
       $l =~ s/\%\%name\%\%/$self->{'name'}/sgi;
       $l =~ s/\%\%database\%\%/$self->{'database'}/sgi;
       $l =~ s/\%\%user\%\%/$self->{'user'}/sgi;
       $l =~ s/\%\%pass\%\%/$self->{'pass'}/sgi;
         
       my $counter = 0;
       foreach $i (@rows)
        {
         if(lc($self->{'name'}.$l) eq lc($i))
          {
           $counter++;
          }
        }
       if((!$counter) and ($self->{'create'} =~ m/^(Y|YES|1)$/si))
        {
         my $sqlq = $shops_table[$ind];
         $sqlq =~ s/\%\%name\%\%/$self->{'name'}/sgi;
         $sqlq =~ s/\%\%database\%\%/$self->{'database'}/sgi;
         $sqlq =~ s/\%\%user\%\%/$self->{'user'}/sgi;
         $sqlq =~ s/\%\%pass\%\%/$self->{'pass'}/sgi;
         if(!$dbh->do($sqlq))
          {
       	   $self->error("Can't create table '".$self->{'name'}.$l."'! Error message: ".$DBI::errstr);
           return(undef);
          }
        }
       $ind++;
      }
    }
   }
 return(1);
}

sub is_tables_exists
{
  my $self = shift;
  my $name = shift || $self->{'name'};
  my $counter = 0;
  
  my $shops_ref = $self->{'structure_tables'};
  my @shops_s_table = @$shops_ref;
  my $shops_ref = $self->{'structure'};
  my @shops_table = @$shops_ref;
  
  if($self->{'dbh'})
    {
     my $dbh = $self->{'dbh'};
     my $sth = $dbh->prepare("SHOW TABLES");
     $sth->execute;
     my $numRows = $sth->rows;
     my ($i,$l,$ind);
     my @rows;
     for($i=0; $i < $numRows; $i++)
      {
       my $aref = $sth->fetchrow_arrayref();
       push(@rows,$$aref[0]);
      }
     $sth->finish();
     $ind = 0;
     foreach $l (@shops_s_table)
      {
       $l =~ s/\%\%name\%\%/$name/sgi;
       $l =~ s/\%\%database\%\%/$self->{'database'}/sgi;
       $l =~ s/\%\%user\%\%/$self->{'user'}/sgi;
       $l =~ s/\%\%pass\%\%/$self->{'pass'}/sgi;
         
       foreach $i (@rows)
        {
         if(lc($name.$l) eq lc($i))
          {
           $counter++;
          }
        }
       $ind++;
      }
    }
  else
    {
     $self->error("Database handler is 'undef'! Please connect to DB fisrt!");
     return(undef);
    }
  if($counter != scalar(@shops_s_table)) {return(0);}
  return(1);
}

sub create_tables
{
  my $self = shift;
  my $name = shift || $self->{'name'};
  my $counter = 0;
  my $matched = 0;
  my $t_counter = 0;
  
  my $shops_ref = $self->{'structure_tables'};
  my @shops_s_table = @$shops_ref;
  my $shops_ref = $self->{'structure'};
  my @shops_table = @$shops_ref;
  
  if($self->{'dbh'})
    {
     my $dbh = $self->{'dbh'};
     my $sth = $dbh->prepare("SHOW TABLES");
     $sth->execute;
     my $numRows = $sth->rows;
     my ($i,$l,$ind);
     my @rows;
     for($i=0; $i < $numRows; $i++)
      {
       my $aref = $sth->fetchrow_arrayref();
       push(@rows,$$aref[0]);
      }
     $sth->finish();
     $ind = 0;
     foreach $l (@shops_s_table)
      {
       $l =~ s/\%\%name\%\%/$name/sgi;
       $l =~ s/\%\%database\%\%/$self->{'database'}/sgi;
       $l =~ s/\%\%user\%\%/$self->{'user'}/sgi;
       $l =~ s/\%\%pass\%\%/$self->{'pass'}/sgi;
       $counter = 0;
       foreach $i (@rows)
        {
         if(lc($name.$l) eq lc($i))
          {
           $counter++;
          }
        }
       if(!$counter)
        {
         my $sqlq = $shops_table[$ind];
         $sqlq =~ s/\%\%name\%\%/$name/sgi;
         $sqlq =~ s/\%\%database\%\%/$self->{'database'}/sgi;
         $sqlq =~ s/\%\%user\%\%/$self->{'user'}/sgi;
         $sqlq =~ s/\%\%pass\%\%/$self->{'pass'}/sgi;
         if(!$dbh->do($sqlq))
          {
       	   $self->error("Can't create table '".$name.$l."'! Error message: ".$DBI::errstr);
          }
         else
          {
           $t_counter++;
          }
        }
       else
        {
         $matched++;
        }
       $ind++;
      }
    }
  else
    {
     $self->error("Database handler is 'undef'! Please connect to DB fisrt!");
     return(undef);
    }
  if(($t_counter+$matched) != scalar(@shops_s_table)) {return(0);}
  return(1);
}

sub add
{
 my $self = shift;
 my %inp  = @_;
 my $id              = $inp{'id'}           || $self->{'id'}; # session(card) id
 my $card_name       = $inp{'card_name'}    || 'default';     # Card name
 my $name            = $inp{'name'}         || $self->{'name'};
 my $product_id      = $inp{'product_id'};                    # Product ID
 my $quantity        = exists($inp{'quantity'}) ? $inp{'quantity'} : '1';    # Count
 my $price           = exists($inp{'price'})    ? $inp{'price'} :    '0';    # Product price
 my $discount        = exists($inp{'discount'}) ? $inp{'discount'} : '0';    # Discount
 my $total           = exists($inp{'total'})    ? $inp{'total'} :    '0';    # Total amount
 my $currency        = exists($inp{'currency'}) ? $inp{'currency'} : 'US';   # Product currency (US)
 my $expire          = exists($inp{'expire'})   ? $inp{'expire'} :   '3h';   # Expire time(3 hours)
 
 my $shops_ref = $self->{'structure_tables'};
 my @shops_s_table = @$shops_ref;
 my $shops_ref = $self->{'structure'};
 my @shops_table = @$shops_ref;
 
 my $q;
 my $dbh = $self->{'dbh'};
 
 if(($id eq undef) or ($id eq ''))
  {
   $self->error("Can't add: CARD ID is empty (supply your unique session (or card) id)!");
   return(undef);
  }
 
 my $qid           = $dbh->quote($id);
 my $qcard_name    = $dbh->quote($card_name);
 my $qproduct_name = $dbh->quote($product_id);
 my $qquantity     = $dbh->quote($quantity);
 my $qprice        = $dbh->quote($price);
 my $qdiscount     = $dbh->quote($discount);
 my $qtotal        = $dbh->quote($total);
 my $qcurrency     = $dbh->quote($currency);
 $expire           = $self->__shopcard_parse_date($expire);
 
 $q = "INSERT INTO ".$name.$shops_s_table[0]." SET ID=$qid, CARD_NAME=$qcard_name, ".
      "PRODUCT_ID=$qproduct_name, QUANTITY=$qquantity, PRICE=$qprice, DISCOUNT=$qdiscount, ".
      "TOTAL=$qtotal, CURRENCY=$qcurrency, EXPIRE=$expire";

 my $sth = $dbh->prepare($q);
 $sth->execute();
 my $rowid = $dbh->{'mysql_insertid'};
 $sth->finish();
 return($rowid);
}

sub del
{
 my $self = shift;
 my %inp  = @_;
 my $uid             = $inp{'uid'};                           # unique shopcard item's id
 my $name            = $inp{'name'}         || $self->{'name'};
 
 my $shops_ref = $self->{'structure_tables'};
 my @shops_s_table = @$shops_ref;
 my $shops_ref = $self->{'structure'};
 my @shops_table = @$shops_ref;
 
 my $q;
 my $dbh = $self->{'dbh'};
  
 my $quid           = $dbh->quote($uid);
 
 $q = "DELETE FROM ".$name.$shops_s_table[0]." WHERE UID=$quid";
 my $sth = $dbh->prepare($q);
 $sth->execute();
 my $rows = $sth->rows;
 $sth->finish();
 return($rows);
}

sub clear
{
 my $self = shift;
 my %inp  = @_;
 my $id              = $inp{'id'}           || $self->{'id'}; # session(card) id
 my $card_name       = $inp{'card_name'}    || 'default';     # Card name
 my $name            = $inp{'name'}         || $self->{'name'};
 
 my $shops_ref = $self->{'structure_tables'};
 my @shops_s_table = @$shops_ref;
 my $shops_ref = $self->{'structure'};
 my @shops_table = @$shops_ref;
 
 my $q;
 my $dbh = $self->{'dbh'};
 
 if(($id eq undef) or ($id eq ''))
  {
   $self->error("Can't clear: CARD ID is empty (supply your unique session (or card) id)!");
   return(undef);
  }
 
 my $qid           = $dbh->quote($id);
 my $qcard_name    = $dbh->quote($card_name);
 
 $q = "DELETE FROM ".$name.$shops_s_table[0]." WHERE ID=$qid AND CARD_NAME=$qcard_name";
 my $sth = $dbh->prepare($q);
 $sth->execute();
 my $rows = $sth->rows;
 $sth->finish();
 return($rows);
}

sub remove_expired
{
 my $self = shift;
 my %inp  = @_;
 my $card_name       = $inp{'card_name'}    || undef;          # Card name
 my $name            = $inp{'name'}         || $self->{'name'};
 
 my $shops_ref = $self->{'structure_tables'};
 my @shops_s_table = @$shops_ref;
 my $shops_ref = $self->{'structure'};
 my @shops_table = @$shops_ref;
 
 my $q;
 my $dbh = $self->{'dbh'};
 
 my $qcard_name    = ($card_name eq undef) ? '' : ' AND CARD_NAME='.$dbh->quote($card_name);
 
 $q = "DELETE FROM ".$name.$shops_s_table[0]."WHERE EXPIRE <= NOW()".$qcard_name;
 my $sth = $dbh->prepare($q);
 $sth->execute();
 my $rows = $sth->rows;
 $sth->finish();
 return($rows);
}

sub modify
{
 my $self = shift;
 my %inp  = @_;
 my $uid             = $inp{'uid'};  # unique shopcard item's id
 my $card_name       = exists($inp{'card_name'}) ? $inp{'card_name'} :   undef;  # Card name
 my $name            = $inp{'name'}         || $self->{'name'};
 my $product_id      = exists($inp{'product_id'}) ? $inp{'product_id'} : undef;  # Product ID
 my $quantity        = exists($inp{'quantity'})   ? $inp{'quantity'} :   undef;  # Count
 my $price           = exists($inp{'price'})      ? $inp{'price'} :      undef;  # Product price
 my $discount        = exists($inp{'discount'})   ? $inp{'discount'} :   undef;  # Discount
 my $total           = exists($inp{'total'})      ? $inp{'total'} :      undef;  # Total amount
 my $currency        = exists($inp{'currency'})   ? $inp{'currency'} :   undef;  # Product currency
 my $expire          = exists($inp{'expire'})     ? $inp{'expire'} :     undef;  # Expire time
 my $act             = exists($inp{'expire'})     ? $inp{'expire'} :     undef;  # Move confirm
 
 my $shops_ref = $self->{'structure_tables'};
 my @shops_s_table = @$shops_ref;
 my $shops_ref = $self->{'structure'};
 my @shops_table = @$shops_ref;
 
 my $q;
 my $set = '';
 my $dbh = $self->{'dbh'};
 my $result = undef;
 
 if(($act =~ m/^MOVE$/si) and ($card_name ne ''))
  {
   my $quid = $dbh->quote($uid);
   $q = "SELECT * FROM ".$name.$shops_s_table[0]." WHERE UID=$quid";
   my $sth = $dbh->prepare($q);
   $sth->execute();
   my $rows = $sth->rows;
   if($rows)
    {
     my $aref = $sth->fetchrow_arrayref();
     my @data = @$aref;
     my ($old_uid,$id,$old_card_name,$product_id,$quantity,$price,$discount,$total,$expire) = @data;
     $sth->finish();
     if($old_card_name ne $card_name)
      {
       $uid = $self->add('id'=>$id,'card_name'=>$card_name,'product_id'=>$product_id,'quantity'=>$quantity,
                        'price'=>$price,'discount'=>$discount,'total'=>$total,'expire'=>$expire);
       if($uid)
        {
         $self->del('uid'=>$old_uid,'card_name'=>$old_card_name,'name'=>$name);
         $result = $uid;
        }
       else
        {
         $self->error("Can't add (when modify card_name)!");
         return(undef);
        }
      }
    }
   else
    {
     $sth->finish();
    }
  }
 my @setw = ();
 if($product_id ne undef)
   {
    push(@setw,'PRODUCT_ID',$product_id);
   }
 if($quantity ne undef)
   {
    push(@setw,'QUANTITY',$quantity);
   }
 if($price ne undef)
   {
    push(@setw,'PRICE',$price);
   }
 if($discount ne undef)
   {
    push(@setw,'DISCOUNT',$discount);
   }
 if($total ne undef)
   {
    push(@setw,'TOTAL',$total);
   }
 if($currency ne undef)
   {
    push(@setw,'CURRENCY',$currency);
   }
 if($expire ne undef)
   {
    push(@setw,'EXPIRE',$expire);
   }
 if(scalar(@setw))
  {
   $set = $self->__shopcard_make_set(', ',@setw);
   my $quid = $dbh->quote($uid);
   $q = "UPDATE ".$name.$shops_s_table[0]." SET ".$set." WHERE UID=".$quid;
   my $sth = $dbh->prepare($q);
   $sth->execute();
   my $rows = $sth->rows;
   $sth->finish();
   if($result eq undef) {$result = $rows;}
  }
 else
  {
   if($result eq undef) {$result = 1;}
  }
 return($result);    # On success: '1' if row updated or new UID of moved item. On error, returns undef!
}

sub find
{
 my $self = shift;
 my %inp  = @_;
 my $caseinsensitive = $inp{'caseinsensitive'}    || 'Y';
 my $multiple        = $inp{'multiple'}           || 'Y';       # Return many rows of results.
 my $by              = $inp{'by'}                 || 'UID';     # Search by 'UID', applicables are: 
 								# 'UID','ID','CARD_NAME','PRODUCT_ID','EXPIRE'
 my $sort            = $inp{'sort'}               || 'NAME';    # Sort by 'UID', applicables are: 
 								# 'UID','ID','CARD_NAME','PRODUCT_ID','EXPIRE'
 my $reverse         = $inp{'reverse'}            || undef;     # Reverse selected Categories
 my $partial         = $inp{'partial'}            || undef;     # Allows search on partial keyword
 my $search          = $inp{'search'}             || undef;
 my $check           = $inp{'check'}              || undef;     # Check mode

 my $shops_ref = $self->{'structure_tables'};
 my @shops_s_table = @$shops_ref;
 my $shops_ref = $self->{'structure'};
 my @shops_table = @$shops_ref;
 
 my @res = ();
 my $dbh = $self->{'dbh'};
 my $limits = '';
 my $order = '';
 my $where = '';
 my $srch = '';
 my $case = '';
 
 if($search eq undef) 
   {
    $self->error("'Search' text is empty!");
    return(undef);
   }

 if($check ne undef)
  {
   if(!$self->is_tables_exists())
     {
      $self->error("Database(table) structure is not available!");
      return(undef);
     }
  }
 if($partial =~ m/^(Y|YES|1)$/si)
  {
   $search = '%'.$search.'%';
   $case   = ' LIKE ';
  }
 else
  {
   $case = ' = ';
  }
 if($dbh)
  {
   if($caseinsensitive =~ m/^(Y|YES|1)$/si)
    {
     $search = uc($search);
     $where = " WHERE UPPER(".$by.")".$case;
    }
   else
    {
     $where = " WHERE ".$by.$case;
    }
   if($multiple =~ m/^(Y|YES|1)$/si)
    {
     $limits = '';
    }
   else
    {
     $limits = ' LIMIT 0,1';
    }
   $order = " ORDER BY $sort";
   my $rev = '';
   if($reverse =~ m/^(Y|YES|1)$/si){$rev = ' DESC';}
   $srch  = $dbh->quote($search);

   my $q = "SELECT * FROM ".$self->name().$shops_s_table[0].$where.$srch.$order.$limits.$rev;
   my $sth = $dbh->prepare($q);
   $sth->execute();
   my $ref;
   while ($ref = $sth->fetchrow_arrayref())
     {
      my @row = @$ref;
      push(@res,\@row);
     }
   $sth->finish();
   return(@res);
  }
 else
  {
   $self->error("Database handler is 'undef'! Please connect to DB fisrt!");
   return(undef);
  }
 return(undef);
}

sub update_expire
{
 my $self = shift;
 my %inp  = @_;
 my $uid             = exists($inp{'uid'}) ? $inp{'uid'} :                 undef; # unique shopcard item's id
 my $id              = exists($inp{'id'})  ? $inp{' id'} :                 undef; # unique shopcard item's id
 my $card_name       = exists($inp{'card_name'}) ? $inp{'card_name'} : 'default'; # Card name
 my $expire          = exists($inp{'expire'})   ? $inp{'expire'}     : '3h';      # Expire time(3 hours)
 my $name            = $inp{'name'}         || $self->{'name'};
 
 my $shops_ref = $self->{'structure_tables'};
 my @shops_s_table = @$shops_ref;
 my $shops_ref = $self->{'structure'};
 my @shops_table = @$shops_ref;
 
 my $result = undef;
 my $dbh  = $self->{'dbh'};
 my $where  = '';
 my @setw = ();
 
 if($uid ne undef)
   {
    push(@setw,'UID',$uid);
   }
 if($id ne undef)
   {
    push(@setw,'ID',$id);
   }
 if($card_name ne undef)
   {
    push(@setw,'CARD_NAME',$card_name);
   }
 if(scalar(@setw))
  {
   $where = $self->__shopcard_make_set(' AND ',@setw);
   my $quid = $dbh->quote($uid);
   $expire  = $self->__shopcard_parse_date($expire);
   my $q = "UPDATE ".$name.$shops_s_table[0]." SET EXPIRE=".$expire." WHERE ".$where;
   my $sth = $dbh->prepare($q);
   $sth->execute();
   my $rows = $sth->rows;
   $sth->finish();
   if($result eq undef) {$result = $rows;}
  }
 else
  {
   if($result eq undef) {$result = 1;}
  }
 return($result);
}

sub __shopcard_parse_date
{
 my $self   = shift;
 my $expire = shift;
 my ($a,$t);
 
 if($expire =~ m/^([0-9]+?)\ {0,}([a-zA-Z]+)$/s)
  {
   $a = $1;
   $t = $2;
   if($t =~ m/^y$/si) {$t = 'year';}
   if($t =~ m/^M$/s)  {$t = 'month';}
   if($t =~ m/^d$/si) {$t = 'day';}
   if($t =~ m/^h$/si) {$t = 'hour';}
   if($t =~ m/^m$/s)  {$t = 'minute';}
   if($t =~ m/^s$/si) {$t = 'second';}
   return("DATE_ADD(NOW(),INTERVAL $a $t)");
  }
 else
  {
   if($expire =~ m/NOW\ {0,}\(\)/si)
    {
     return($expire);
    }
   my $dbh = $self->{'dbh'};
   my $qe  = $dbh->quote($expire);
   return($qe);
  }
}

sub __shopcard_make_set
{
 my $self   = shift;
 my $sep    = shift;
 my %h      = @_;
 my $set    = '';
 my $key;
 my $dbh    = $self->{'dbh'};
 foreach $key (keys %h)
  {
   if($key ne '')
    {
     my $val = $h{$key};
     if(length($set))
      {
       $set .= $sep;
      }
     $set .= $key."=".$dbh->quote($val);
    }
  }
 return($set);
}

sub DESTROY
{
  my $self = shift;
  if($self->{'dbh'})
    {
      my $dbh = $self->{'dbh'};
      $dbh->disconnect();
    }
  1;
}

1;
__END__

=head1 NAME

ShopCard - Create and process ShopCard within MySQL DB

=head1 VERSION

ShopCard.pm ver.1.0

=head1 DESCRIPTION

=over 4

ShopCard allows you to create and process ShopCards

=back

=head1 SYNOPSIS

 There is an example that you may use in your own CGI scripts:

 # --- Script begin here ---
 use ShopCard;

 # NOTE: new() method will create needed DB structure in MySQL (database & tables) if they not exist!
 #       Please create database before execute this script or DB USER must have privilege to create DBs!
 
 $sid = '54929429823023450234';

 $obj = ShopCard->new(database => 'shopdb', user => 'db_user', pass => 'db_pass',
                      host => 'localhost', id=>$sid);
      # OR
      # $obj = ShopCard->new(dbh => $mysql_dbh_handler, id=>$sid);
 
 if($obj)
   {
    $id = $obj->add(product_id=>'8',quantity=>'2',price=>'19',discount=>'0',total=>'38',expire=>'40m','id'=>$sid);
    $obj->update_expire('id'=>$sid,'expire'=>'2h');
    print "<HR>";
    my @res = $obj->find('search'=>'8','sort'=>'EXPIRE','by'=>'PRODUCT_ID','multiple'=>YES,
                         'partial'=>NO,'reverse'=>NO);
   if(scalar(@res))
     {
      foreach $l (@res)
       {
         my ($uid,$id,$card_name,$product_id,$quantity,$price,$discount,$total,$currency,$expire) = @$l;
         print "UID:     $uid<BR>\n";
         print "ID:      $id<BR>\n";
         print "CARD:    $card_name<BR>\n";
         print "PRODUCT: $product_id<BR>\n";
         print "QNT:     $quantity<BR>\n";
         print "PRICE:   $price<BR>\n";
         print "DISC:    $discount<BR>\n";
         print "TOTAL:   $total<BR>\n";
         print "CURR:    $currency<BR>\n";
         print "EXPIRE:  $expire<BR>\n";
         print "<HR>";
       }
     }
   }
  else
   {
    print $ShopCard::error;
   }

 # --- Script ends here ---

=head1 SYNTAX

 That is simple function reference:
 
 $object = ShopCard->new(database=>'shopdb', user=>'db_user', pass=>'db_pass', host=>'localhost', 
                         port=>'3306', create=>'Y', checkdb=>'Y', name=>'shop', card_name=>'default',
                         dbh=>$connect_db_handler, id=>'session_card_id);
    Where:
    database  - is your DB where ShopCard (tables) will be placed. If database not exist module
                will try to create one for you, using supplied user and password. [REQUIRED if $dbh empty]
    user/pass - is your DB user and password [REQUIRED if $dbh empty]
    host      - MySQL DB host
    port      - your MySQL port
    create    - module will attempt to create DB and/or tables
    checkdb   - module will try to check DB structure
    name      - name of shop object
    dbh       - you can supply already connected database handler instead of database/user/pass/host/port!
    card_name - name of shopcard (multilevel name)
    id        - session/card id [REQUIRED]


=head1 AUTHOR

 Julian Lishev - Bulgaria, Sofia, 
 e-mail: julian@proscriptum.com, 
 www.proscriptum.com

=cut
