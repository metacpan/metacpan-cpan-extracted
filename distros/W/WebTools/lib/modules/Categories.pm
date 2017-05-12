package Categories;

################################################
# Powerful Categories Module (Object Model)
# written by Julian Lishev
# 
# Module purposes:
# To create and manage categories within MySQL DB
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
# Available methods:
# new(), is_tables_exists(), create_tables(),
# clear_cache(), preload_categories(), find(),
# add(), del(), modify(), traverse(), error(),
# deep_traverse(), load_category(), read()
################################################

@Categories::structure_tables = 
  (
    '_categories',      # First row must correspondence to first row of array below and so on.. !!!
    '_items',
  );
@Categories::structure =
 (
   "CREATE TABLE %%name%%$Categories::structure_tables[0]
   (
     ID      BIGINT(1) AUTO_INCREMENT PRIMARY KEY,
     PARENT  BIGINT(1) DEFAULT 0,
     NAME    VARCHAR(100),
     INDEX   index_1 (PARENT),
     KEY     index_2 (NAME(3))
    )
   ",
   "CREATE TABLE %%name%%$Categories::structure_tables[1]
   (
     ID      BIGINT(1) AUTO_INCREMENT PRIMARY KEY,
     CID     BIGINT(1) DEFAULT 0,
     NAME    VARCHAR(100),
     VALUE   VARCHAR(255) binary,
     INDEX   index_1 (CID),
     KEY     index_2 (NAME(3)),
     KEY     index_3 (VALUE(3))
    )
   ",
 );
################################################
# PLEASE DO NOT EDIT BELOW!
################################################

use strict;

# ----- Global members for all objects -----
$Categories::debugging = 0;
$Categories::error     = '';

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
 my $name = $Categories::AUTOLOAD;
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
 $self->{'name'}      = $inp{'name'}       || 'catdb';
 $self->{'database'}  = $inp{'database'}  || undef;
 $self->{'user'}      = $inp{'user'}      || '';
 $self->{'pass'}      = $inp{'pass'}      || '';
 $self->{'host'}      = $inp{'host'}      || 'localhost';
 $self->{'port'}      = abs(int($inp{'port'})) || '3306';
 $self->{'structure'} = $inp{'structure'} || \@Categories::structure;
 $self->{'structure_tables'} = $inp{'structure_tables'} || \@Categories::structure_tables;
 $self->{'dbh'}       = $inp{'dbh'}       || undef;
 
 $self->{'error'} = '';

 $self->{'categories'} = '';

 $self->{'__subs'} = {};
 $self->{'__subs'}->{'init'}    = $inp{'init'}      || \&__category_init;

 bless($self,$class);
 if($self->init() eq undef)
  {
   return(undef);
  }
 
 return($self);
}

sub _set_val_Categories
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

sub error      { shift->_set_val_Categories('error', @_); $Categories::error = $_[0];}
sub create     { shift->_set_val_Categories('create', @_); }
sub checkdb    { shift->_set_val_Categories('checkdb', @_); }
sub database   { shift->_set_val_Categories('database', @_); }
sub name       { shift->_set_val_Categories('name', @_); }
sub user       { shift->_set_val_Categories('user', @_); }
sub pass       { shift->_set_val_Categories('pass', @_); }
sub host       { shift->_set_val_Categories('host', @_); }
sub port       { shift->_set_val_Categories('port', abs(int($_[0]))); }
sub structure  { shift->_set_val_Categories('structure', @_); }
sub structure_tables  { shift->_set_val_Categories('structure_tables', @_); }
sub categories { shift->_set_val_Categories('categories', @_); }
sub dbh        { shift->_set_val_Categories('dbh', @_); }


sub __category_init
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
 my $cats_ref = $self->{'structure_tables'};
 my @cats_s_table = @$cats_ref;
 my $cats_ref = $self->{'structure'};
 my @cats_table = @$cats_ref;
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
     foreach $l (@cats_s_table)
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
         my $sqlq = $cats_table[$ind];
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
  my $cats_ref = $self->{'structure_tables'};
  my @cats_s_table = @$cats_ref;
  my $cats_ref = $self->{'structure'};
  my @cats_table = @$cats_ref;
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
     foreach $l (@cats_s_table)
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
  if($counter != scalar(@cats_s_table)) {return(0);}
  return(1);
}

sub create_tables
{
  my $self = shift;
  my $name = shift || $self->{'name'};
  my $counter = 0;
  my $matched = 0;
  my $t_counter = 0;
  my $cats_ref = $self->{'structure_tables'};
  my @cats_s_table = @$cats_ref;
  my $cats_ref = $self->{'structure'};
  my @cats_table = @$cats_ref;
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
     foreach $l (@cats_s_table)
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
         my $sqlq = $cats_table[$ind];
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
  if(($t_counter+$matched) != scalar(@cats_s_table)) {return(0);}
  return(1);
}

sub clear_cache
{
  my $self = shift;
  
  $self->{'categories'} = '';
  return(1);
}
sub preload_categories
{
  my $self = shift;
  my %inp  = @_;
 
  my $name    = $inp{'name'}     || $self->name();
  my $sort    = $inp{'sort'}     || 'NAME';          # Sort Items/Categories by $sort
  my $reverse = $inp{'reverse'}  || undef;           # Reverse selected Categories
 
  my @cats = ();
  my $dbh = $self->{'dbh'};
  
  my $cats_ref = $self->{'structure_tables'};
  my @cats_s_table = @$cats_ref;
  my $cats_ref = $self->{'structure'};
  my @cats_table = @$cats_ref;
 
  if(ref($self->{'categories'}))
    {
     my $r = $self->{'categories'};
     @cats = @$r;
    }
  else
    {
     my $order = " ORDER BY $sort";
     my $rev = '';
     if($reverse =~ m/^(Y|YES|1)$/si){$rev = ' DESC';}
     
     my $q = "SELECT * FROM ".$name.$cats_s_table[0].$order.$rev;
     my $sth = $dbh->prepare($q);
     $sth->execute();
     my $ref;
     while ($ref = $sth->fetchrow_hashref())
      {
       my %row = %$ref;
       push(@cats,\%row);
      }
     $sth->finish();
     $self->{'categories'} = \@cats;
    }
  return(@cats);
}

sub find
{
 my $self = shift;
 my %inp  = @_;
 my $caseinsensitive = $inp{'caseinsensitive'}    || 'Y';
 my $filter          = $inp{'filter'}             || 'ITEMS';   # Items only, don't mutch categories,
 								# applicables are: 'ITEMS','ALL','CATEGORIES'
 my $multiple        = $inp{'multiple'}           || 'Y';       # Return many rows of results.
 my $by              = $inp{'by'}                 || 'ID';      # Search by 'ID', applicables are: 
 								# 'ID','NAME','CID','PARENT','VALUE'
 my $sort            = $inp{'sort'}               || 'NAME';    # Sort by 'NAME', applicables are: 
 								# 'ID','NAME','CID','PARENT','VALUE'
 my $reverse         = $inp{'reverse'}            || undef;     # Reverse selected Categories
 my $partial         = $inp{'partial'}            || undef;     # Allows search on partial keyword
 my $search          = $inp{'search'}             || undef;
 my $check           = $inp{'check'}              || undef;     # Check mode
 my $route           = $inp{'route'}              || 'N';
 my $separator       = $inp{'separator'}          || '//';
 my $preload         = $inp{'preload'}            || 'Y';       # Default load all categories in memmory before
 								# searching. This speed up process but for very
 								# large DBs this may crush!
 
 my @cats = ();
 my @res = ();
 my @tmp = ();
 my $dbh = $self->{'dbh'};
 my $limits = '';
 my $order = '';
 my $where = '';
 my $srch = '';
 my $case = '';
 
 my $cats_ref = $self->{'structure_tables'};
 my @cats_s_table = @$cats_ref;
 my $cats_ref = $self->{'structure'};
 my @cats_table = @$cats_ref;
 
 if($search eq undef) 
   {
    $self->error("'Search' text is empty!");
    return(undef);
   }
 if(($by =~ m/^PARENT$/i) and ($filter =~ m/^ITEMS$/i)) 
   {
    $self->error("Can't search by PARENT in ITEMS context!");
    return(undef);
   }
 if(($sort =~ m/^PARENT$/i) and ($filter =~ m/^ITEMS$/i)) 
   {
    $self->error("Can't sort(search) by PARENT in ITEMS context!");
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
   if(($preload =~ m/^(Y|YES|1)$/si) and ($route =~ m/^(Y|YES|1)$/si))
    {
     @cats = $self->preload_categories('sort'=>$sort,'reverse'=>$reverse);
    }
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

   if($filter =~ m/^(ITEMS|ALL)$/si)
     {
      my $q = "SELECT * FROM ".$self->name().$cats_s_table[1].$where.$srch.$order.$limits.$rev;
      my $sth = $dbh->prepare($q);
      $sth->execute();
      my $ref;
      while ($ref = $sth->fetchrow_arrayref())
       {
         my @row = @$ref;
         unshift(@row,'I');
         push(@res,\@row);
       }
      $sth->finish();
     }
   if($filter =~ m/^(CATEGORIES|ALL)$/si)
     {
      my $q = "SELECT * FROM ".$self->name().$cats_s_table[0].$where.$srch.$order.$limits.$rev;
      my $sth = $dbh->prepare($q);
      $sth->execute();
      my $ref;
      while ($ref = $sth->fetchrow_arrayref())
       {
         my @row = @$ref;
         unshift(@row,'C');
         push(@res,\@row);
       }
      $sth->finish();
     }
   if($route =~ m/^(Y|YES|1)$/si)
    {
     my $t;
     foreach $t (@res)
      {
       my $found = 0;
       my @row = @$t;
       my $CID = $row[2];    # Get PARENT or CID field.
       my $iname = '';
       my $path = $separator;
       while($CID != 0)
        {
         if($preload =~ m/^(Y|YES|1)$/si)
          {
            my $sc;
            foreach $sc (@cats)
             {
              my %rh = %$sc;
              my $id = $rh{'ID'};
              if($id eq $CID)
                {
                 $CID   = $rh{'PARENT'};
                 my $ID    = $rh{'ID'};
                 $iname = $rh{'NAME'};
                 $path = $separator.$ID."\x0".$iname.$path;
                 $found = 1; last;
                }
             }
            if(!$found) {$CID = 0;}
          } 
         else
          {
           my $qCID = $dbh->quote($CID);
           my $q = "SELECT ID,PARENT,NAME FROM ".$self->name().$cats_s_table[0]." WHERE ID=$qCID";
           my $sth = $dbh->prepare($q);
           $sth->execute();
           my $ref;
           $ref = $sth->fetchrow_arrayref();
           if(ref($ref))
            {
             my @row = @$ref;
             $CID    = $row[1];
             $iname  = $row[2];
             my $ID  = $row[0];
             $path = $separator.$ID."\x0".$iname.$path;
            }
           else
            {
             $CID = 0;
            }
           $sth->finish();
          }
        }
       push(@row,$path);
       push(@tmp,\@row);
      }
     @res = @tmp;
    }
   return(@res);
  }
 else
  {
   $self->error("Database handler is 'undef'! Please connect to DB fisrt!");
   return(undef);
  }
 return(undef);
}

sub add
{
 my $self = shift;
 my %inp  = @_;
 my $type              = $inp{'type'}       || 'ITEM';  # Type: 'ITEM' or 'CATEGORY'
 my $category          = $inp{'category'}   || undef;   # Category ID; 0 is root
 my $name              = $inp{'name'}       || undef;   # Item/Category name
 my $value             = $inp{'value'}      || undef;   # Item value (for type 'ITEM' only)
 my $check             = $inp{'check'}      || undef;   # Check mode
 my $q;
 my $dbh = $self->{'dbh'};
 
 my $cats_ref = $self->{'structure_tables'};
 my @cats_s_table = @$cats_ref;
 my $cats_ref = $self->{'structure'};
 my @cats_table = @$cats_ref;
 
 if($name eq undef)
  {
   $self->error("Can't ADD item/category with empty name!");
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
 if($category eq undef) {$category = 0;}
 
 my $q_category = $dbh->quote($category);
 my $q_name     = $dbh->quote($name);
 
 if($type =~ m/^ITEM/si)
  {
   my $q_value    = $dbh->quote($value);
   $q = "INSERT INTO ".$self->name().$cats_s_table[1]." SET CID=$q_category, NAME=$q_name, VALUE=$q_value";
  }
 elsif($type =~ m/^CATEGORY/si)
  {
   $q = "INSERT INTO ".$self->name().$cats_s_table[0]." SET PARENT=$q_category, NAME=$q_name";
   $self->{'categories'} = '';       # Category changes are made, we need to reload categiries!
  }
 else
  {
   $self->error("Unrecognized type!");
    return(undef);
  }
 my $sth = $dbh->prepare($q);
 $sth->execute();
 my $row = $dbh->{'mysql_insertid'};
 $sth->finish();
 return($row);
}

sub del
{
 my $self = shift;
 my %inp  = @_;
 my $type              = $inp{'type'}       || 'ITEM';  # Type: 'ITEM' or 'CATEGORY'
 my $id                = $inp{'id'};                    # Item/Category id
 my $check             = $inp{'check'}      || undef;   # Check mode
 my $preload           = $inp{'preload'}    || 'Y';     # Default load all categories in memmory before
 							# searching. This speed up process but for very
 							# large DBs this may crush!
 my $q;
 my $dbh = $self->{'dbh'};
 my $row;
 
 my $cats_ref = $self->{'structure_tables'};
 my @cats_s_table = @$cats_ref;
 my $cats_ref = $self->{'structure'};
 my @cats_table = @$cats_ref;
 
 if($id eq undef)
  {
   $self->error("Can't DEL item/category with empty id!");
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

 my $q_id = $dbh->quote($id);
 
 if($type =~ m/^ITEM/si)
  {
   $q = "DELETE FROM ".$self->name().$cats_s_table[1]." WHERE ID=$q_id";
   my $sth = $dbh->prepare($q);
   $sth->execute();
   $row = $sth->rows();
   $sth->finish();
  }
 elsif($type =~ m/^CATEGORY/si)
  {
   $row = $self->traverse('eval'=>\&__category_del,'cid'=>$id,'preload'=>$preload);
   $self->{'categories'} = '';       # Category changes are made, we need to reload categiries!
  }
 else
  {
   $self->error("Unrecognized type!");
   return(undef);
  }
 return($row);
}

sub __category_del
{
 my $self = shift;
 my %inp  = @_;
 
 my $id              = $inp{'id'};
 my $parent          = $inp{'parent'};
 
 my $dbh  = $self->{'dbh'};
 my $qCID = $dbh->quote($id);
 my $q;
 my $count = 0;
 
 my $cats_ref = $self->{'structure_tables'};
 my @cats_s_table = @$cats_ref;
 my $cats_ref = $self->{'structure'};
 my @cats_table = @$cats_ref;
 
 if($id != 0)
  {
   $q = "DELETE FROM ".$self->name().$cats_s_table[0]." WHERE ID=$qCID";
   my $sth = $dbh->prepare($q);
   $sth->execute();
   $count += $sth->rows;
   $sth->finish();
  }
 $q = "DELETE FROM ".$self->name().$cats_s_table[1]." WHERE CID=$qCID";
 my $sth = $dbh->prepare($q);
 $sth->execute();
 $count += $sth->rows;
 $sth->finish();
 
 return($count);
}

sub modify
{
 my $self = shift;
 my %inp  = @_;
 my $type              = $inp{'type'}       || 'ITEM';  # Type: 'ITEM' or 'CATEGORY'
 my $id                = $inp{'id'}         || undef;   # Item/Category id
 my $newcid            = $inp{'newcid'};                # New 'parent' ID (CID/PARENT)
 my $check             = $inp{'check'}      || undef;   # Check mode
 my $name              = $inp{'name'}       || undef;   # ITEM/CATEGORY name
 my $value             = exists($inp{'value'}) ? $inp{'value'} : undef;   # ITEM value
 
 my $q;
 my ($table_name,$set);
 my $aff = 0;
 my $dbh = $self->{'dbh'};
 
 my $cats_ref = $self->{'structure_tables'};
 my @cats_s_table = @$cats_ref;
 my $cats_ref = $self->{'structure'};
 my @cats_table = @$cats_ref;
 
 if($id eq undef)
  {
   $self->error("Can't MODIFY item/category with empty id!");
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
 if($type =~ m/^ITEM/si)
  {
   $table_name = $self->name().$cats_s_table[1];
   if($newcid ne undef)
    {
     my $qcid = $dbh->quote($newcid);
     $set     = "CID=$qcid";
    }
   if($value ne undef)
    {
     my $qvalue = $dbh->quote($value);
     if($set) {$set .= ",";}
     $set     .= "VALUE=$qvalue";
    }
  }
 elsif($type =~ m/^CATEGORY/si)
  {
   $table_name = $self->name().$cats_s_table[0];
   if($newcid ne undef)
    {
     my $qcid = $dbh->quote($newcid);
     $set     = "PARENT=$qcid";
    }
  }
 else
  {
   $self->error("Unrecognized type!");
   return(undef);
  }
 if($name ne undef)
  {
   my $qname = $dbh->quote($name);
   if($set ne '') {$set .= ",";}
   $set     .= "NAME=$qname";
  }
 if($set ne '')
  {
   my $q_id  = $dbh->quote($id);
   
   $q = "UPDATE $table_name SET $set WHERE ID=$q_id";
   my $sth = $dbh->prepare($q);
   $sth->execute();
   $aff = $sth->rows;
   $sth->finish();
  }
 if($aff)
  {
   $self->clear_cache();
  }
 return($aff);
}

sub traverse
{
 my $self = shift;
 my %inp  = @_;
 my $cid               = $inp{'cid'};                   # Category id
 my $evala             = $inp{'eval'}       || undef;   # Code that will be evaluated
 my $check             = $inp{'check'}      || undef;   # Check mode
 my $sort              = $inp{'sort'}       || 'NAME';  # Sort Items/Categories by $sort
 my $reverse           = $inp{'reverse'}    || undef;   # Reverse selected Categories
 my $preload           = $inp{'preload'}    || 'Y';     # Default load all categories in memmory before
 							# searching. This speed up process but for very
 							# large DBs this may crush!
 my $q;
 my $dbh = $self->{'dbh'};
 my @queue = ();
 my @cats = ();
 my $current = '';
 my $cnt = 0;
 
 my $cats_ref = $self->{'structure_tables'};
 my @cats_s_table = @$cats_ref;
 my $cats_ref = $self->{'structure'};
 my @cats_table = @$cats_ref;

 if($cid eq undef)
  {
   $self->error("Can't TRAVERSE item/category with empty cid!");
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
 
 if($preload =~ m/^(Y|YES|1)$/si)
  {
   @cats = $self->preload_categories('sort'=>$sort,'reverse'=>$reverse);
  }

 if($cid == 0)
  {
   my $qCID = $dbh->quote($cid);
   if(scalar(@cats))
    {
     my $sc;
     foreach $sc (@cats)
       {
        my %rh = %$sc;
        my $cid = $rh{'PARENT'};
        if($cid == 0)
          {
           my $id  = $rh{'ID'};
           unshift(@queue,$id);
          }
       }
    }
   else
    {
     $q = "SELECT ID FROM ".$self->name().$cats_s_table[0]." WHERE PARENT=$qCID";
     my $sth = $dbh->prepare($q);
     $sth->execute();
     my $ref;
     while($ref = $sth->fetchrow_arrayref())
      {
       my @row = @$ref;
       unshift(@queue,$row[0]);
      }
     $sth->finish();
    }
   $current = 0;
   my $qCID = $dbh->quote($current);
   $cnt++;
   if(ref($evala))
     {
      &$evala($self,'id'=>$current,'parent'=>$cid);
     }
    else
     {
      eval $evala;
     }
  }
 else
  {
   unshift(@queue,$cid);
  }
  
 while(scalar(@queue))
  {
   $current = pop(@queue);
   my $qCID = $dbh->quote($current);
   if(scalar(@cats))
    {
     my $sc;
     foreach $sc (@cats)
       {
        my %rh = %$sc;
        my $cid = $rh{'PARENT'};
        if($cid == $current)
          {
           my $id  = $rh{'ID'};
           unshift(@queue,$id);
          }
       }
    }
   else
    {
     $q = "SELECT ID FROM ".$self->name().$cats_s_table[0]." WHERE PARENT=$qCID";
     my $sth = $dbh->prepare($q);
     $sth->execute();
     my $ref;
     while($ref = $sth->fetchrow_arrayref())
      {
       my @row = @$ref;
       unshift(@queue,$row[0]);
      }
     $sth->finish();
    }
   $cnt++;
   if(ref($evala))
     {
      &$evala($self,'id'=>$current,'parent'=>$cid);
     }
    else
     {
      eval $evala;
     }
  }
 return($cnt);
}

sub deep_traverse
{
 my $self = shift;
 my %inp  = @_;
 my $id              = $inp{'id'};
 my $level           = $inp{'level'};
 my $separator       = $inp{'separator'}   || '//';
 my $path            = $inp{'path'};
 my $evala           = $inp{'eval'}        || undef;    # Code that will be evaluated
 my $sort            = $inp{'sort'}        || 'NAME';   # Sort Items/Categories by $sort
 my $reverse         = $inp{'reverse'}     || undef;    # Reverse selected Categories
 my $preload         = $inp{'preload'}     || 'Y';      # Default load all categories in memmory before
 							# searching. This speed up process but for very
 							# large DBs this may crush!
 my $dbh = $self->{'dbh'};
 my @cats = ();
 my $q;
 my ($i,$item,$item_name,$item_value);
 my $whereis = 'C';
 
 my $cats_ref = $self->{'structure_tables'};
 my @cats_s_table = @$cats_ref;
 
 if($preload =~ m/^(Y|YES|1)$/si)
  {
   @cats = $self->preload_categories('sort'=>$sort,'reverse'=>$reverse);
  }
 
 $level++;
 
 if(ref($evala))
  {
   &$evala($self,'id'=>$id,'level'=>$level,'type'=>$whereis,'path'=>$path,'separator'=>$separator);
  }
 else
  {
   eval $evala;
  }
 my @all_level_rows = ();
 my @all_level_rows_names = ();
 my @all_level_rows_values = ();
 my $current_index = 0;
 my $all_current_rows = 0;
 
 my $qCID = $dbh->quote($id);
 if(scalar(@cats))
    {
     my $sc;
     foreach $sc (@cats)
       {
        my %rh = %$sc;
        my $cid = $rh{'PARENT'};
        if($cid == $id)
          {
           my ($id,$name) = ($rh{'ID'},$rh{'NAME'});
           unshift(@all_level_rows,$id);
           unshift(@all_level_rows_names,$name);
          }
       }
    }
 else
  {
   my $order = " ORDER BY $sort";
   my $rev = '';
   if($reverse =~ m/^(Y|YES|1)$/si){$rev = ' DESC';}
   
   $q = "SELECT ID,NAME FROM ".$self->name().$cats_s_table[0]." WHERE PARENT=$qCID".$order.$rev;
   my $sth = $dbh->prepare($q);
   $sth->execute();
   my $ref;
   while($ref = $sth->fetchrow_arrayref())
     {
      my @row = @$ref;
      unshift(@all_level_rows,$row[0]);
      unshift(@all_level_rows_names,$row[1]);
     }
   $sth->finish();
  }
 $all_current_rows = scalar(@all_level_rows);
 foreach $i (1..$all_current_rows)
  {
    my $this = pop(@all_level_rows);
    my $this_name = pop(@all_level_rows_names);
    $self->deep_traverse(id=>$this,level=>$level,separator=>$separator,
                         path=>$path.$this."\x0".$this_name.$separator,eval=>$evala);
  }
 @all_level_rows = ();
 @all_level_rows_names = ();
 @all_level_rows_values = ();
 my $qCID = $dbh->quote($id);
 my $order = " ORDER BY $sort";
 my $rev = '';
 if($reverse =~ m/^(Y|YES|1)$/si){$rev = ' DESC';}
   
 $q = "SELECT ID,NAME,VALUE FROM ".$self->name().$cats_s_table[1]." WHERE CID=$qCID".$order.$rev;
 my $sth = $dbh->prepare($q);
 $sth->execute();
 my $ref;
 while($ref = $sth->fetchrow_arrayref())
   {
    my @row = @$ref;
    push(@all_level_rows,$row[0]);
    push(@all_level_rows_names,$row[1]);
    push(@all_level_rows_values,$row[2]);
   }
 $sth->finish();

 $whereis = 'I';
 foreach $item (@all_level_rows)
   {
    $item_name  = shift(@all_level_rows_names);
    $item_value = shift(@all_level_rows_values);
    if(ref($evala))
     {
      &$evala($self,'id'=>$id,'level'=>$level,'type'=>$whereis,'path'=>$path,'name'=>$item_name,
              'value'=>$item_value,'separator'=>$separator);
     }
    else
     {
      eval $evala;
     }
   }
 return(1);
}

sub load_category
{
 my $self = shift;
 my %inp  = @_;
 my $cid             = $inp{'cid'};                     # Category id
 my $sort            = $inp{'sort'}        || 'NAME';   # Sort Items/Categories by $sort
 my $reverse         = $inp{'reverse'}     || undef;    # Reverse selected Categories
 my $preload         = $inp{'preload'}     || 'Y';      # Default load all categories in memmory before
 							# searching. This speed up process but for very
 							# large DBs this may crush!
 my @res;
 my @cats;
 my $dbh = $self->{'dbh'};
 my $q;
 
 my $cats_ref = $self->{'structure_tables'};
 my @cats_s_table = @$cats_ref;
 
 if($preload =~ m/^(Y|YES|1)$/si)
  {
   @cats = $self->preload_categories('sort'=>$sort,'reverse'=>$reverse);
  }
 
 my $qCID = $dbh->quote($cid);
 if(scalar(@cats))
   {
     my $sc;
     foreach $sc (@cats)
       {
        my %rh = %$sc;
        my $parent = $rh{'PARENT'};
        if($parent == $cid)
          {
           my @mf  = ('C',$rh{'ID'},$rh{'NAME'},'');
           unshift(@res,\@mf);
          }
       }
   }
 else
   {
    $q = "SELECT ID,NAME FROM ".$self->name().$cats_s_table[0]." WHERE PARENT=$qCID";
    my $sth = $dbh->prepare($q);
    $sth->execute();
    my $ref;
    while($ref = $sth->fetchrow_arrayref())
      {
       my @row = @$ref;
       my @mf  = ('C',$row[0],$row[1],'');
       unshift(@res,\@mf);
      }
    $sth->finish();
   }
 $q = "SELECT ID,NAME,VALUE FROM ".$self->name().$cats_s_table[1]." WHERE CID=$qCID";
 my $sth = $dbh->prepare($q);
 $sth->execute();
 my $ref;
 while($ref = $sth->fetchrow_arrayref())
   {
    my @row = @$ref;
    my @mf  = ('I',$row[0],$row[1],$row[2]);
    push(@res,\@mf);
   }
 $sth->finish();
 
 return(@res);
}

sub read
{
 my $self = shift;
 my %inp  = @_;
 my $caseinsensitive = $inp{'caseinsensitive'}    || 'Y';
 my $sort            = $inp{'sort'}               || 'ID';      # Sort by 'NAME', applicables are: 
 								# 'ID','NAME','CID','PARENT','VALUE'
 my $reverse         = $inp{'reverse'}            || undef;     # Reverse selected Categories
 my $path            = $inp{'path'}               || undef;
 my $partial         = $inp{'partial'}            || undef;     # Allows search on partial keyword (ITEMS only)
 my $check           = $inp{'check'}              || undef;     # Check mode
 my $separator       = $inp{'separator'}          || '//';
 my $preload         = $inp{'preload'}            || 'Y';       # Default load all categories in memmory before
 								# searching. This speed up process but for very
 								# large DBs this may crush! 
 my @cats = ();
 my @res = ();
 my @parts = ();
 my $item = '';
 my $dbh = $self->{'dbh'};
 my $order = '';
 my $where = '';
 my ($l,$value,$mpar,$mpath) = ();
 my $parent = '0';
 my $result = '';
 my $case = '';
 
 my $cats_ref = $self->{'structure_tables'};
 my @cats_s_table = @$cats_ref;
 my $cats_ref = $self->{'structure'};
 my @cats_table = @$cats_ref;
 
 if($path eq undef) 
   {
    $self->error("'Path' is empty!");
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
 if($dbh)
  {
   if(($preload =~ m/^(Y|YES|1)$/si))
    {
     @cats = $self->preload_categories('sort'=>$sort,'reverse'=>$reverse);
    }
   $order = " ORDER BY $sort";
   my $rev = '';
   if($reverse =~ m/^(Y|YES|1)$/si){$rev = ' DESC';}
   
   my $qsep = quotemeta($separator);
   @parts = split(/$separator/s,$path);
   if($path =~ m/$separator$/s)
    {
     $item = '';
    }
   else
    {
     $item = pop(@parts);
    }
   foreach $l (@parts)
    {
     if($parent eq undef)
      {
       $self->error("Can't find part of category path! Please check you category tree!");
       return(undef);
      }
     $l =~ s/\ {1,}$//si;
     $l =~ s/^\ {1,}//si;
     if($l ne '')
       {
         if($preload =~ m/^(Y|YES|1)$/si)
          {
            my $sc;
            my $state = 0;
            foreach $sc (@cats)
             {
              my %rh   = %$sc;
              my $cid  = $rh{'PARENT'};
              my $name = $rh{'NAME'};
              if($caseinsensitive =~ m/^(Y|YES|1)$/si)
               {
                if((uc($name) eq uc($l)) and ($cid == $parent))
                 {
                  my $ID   = $rh{'ID'};
                  $result  = $ID;
                  $mpar    = $parent;
                  $mpath  .= $separator.$ID."\x0".$name;
                  $state = 1;
                  last;
                 }
                }
               else
                {
                 if(($name eq $l) and ($cid == $parent))
                  {
                   my $ID   = $rh{'ID'};
                   $result  = $ID;
                   $mpar    = $parent;
                   $mpath  .= $separator.$ID."\x0".$name;
                   $state = 1;
                   last;
                  }
                }
             }
            if(!$state) {$result = undef;}
            $parent = $result;
          } 
         else
          {
           if($caseinsensitive =~ m/^(Y|YES|1)$/si)
             {
              $l = uc($l);
              $where = " WHERE UPPER(NAME)=";
             }
           else
             {
              $where = " WHERE NAME=";
             }
           my $qCID  = $dbh->quote($parent);
           my $qname = $dbh->quote($l);
           my $q = "SELECT ID,PARENT,NAME FROM ".$self->name().$cats_s_table[0].$where."$qname AND PARENT=$qCID".$order;
           my $sth = $dbh->prepare($q);
           $sth->execute();
           my $ref;
           $ref = $sth->fetchrow_arrayref();
           if(ref($ref))
            {
             my @row = @$ref;
             my $ID  = $row[0];
             $result  = $ID;
             $mpar    = $parent;
             $mpath  .= $separator.$ID."\x0".$l;
            }
           else
            {
             $result = undef;
            }
           $sth->finish();
           $parent = $result;
          }
       }
      }
     if($item ne '')
      {
       if($item eq '*') {$item = '';}
       if($partial =~ m/^(Y|YES|1)$/si)
         {
          $item = '%'.$item.'%';
          $case   = ' LIKE ';
         }
       else
         {
          $case = ' = ';
         }
       if($caseinsensitive =~ m/^(Y|YES|1)$/si)
         {
          $l = uc($item);
          $where = " WHERE UPPER(NAME)$case";
         }
       else
         {
          $where = " WHERE NAME$case";
         }
       my $qCID  = $dbh->quote($result);
       my $qname = $dbh->quote($l);
       my $q = "SELECT ID,CID,NAME,VALUE FROM ".$self->name().$cats_s_table[1].$where."$qname AND CID=$qCID".$order;
       my $sth = $dbh->prepare($q);
       $sth->execute();
       my $ref;
       if($sth->rows())
        {
         while($ref = $sth->fetchrow_arrayref())
          {
           my @row = @$ref;
           push(@row,$mpath.$separator);
           push(@res,\@row);
          }
         $sth->finish();
        }
       else
        {
         $self->error("Can't find item specified by category path! Please check you category tree!");
         return(undef);
        }
      }
     else
      {
       my @row = ($result,$mpar,'','',$mpath);
       push(@res,\@row);
      }
   return(@res);
  }
 else
  {
   $self->error("Database handler is 'undef'! Please connect to DB fisrt!");
   return(undef);
  }
 return(undef);
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

Categories - Create and process categories within MySQL DB

=head1 VERSION

Categories.pm ver.1.0

=head1 DESCRIPTION

=over 4

Categories allows you to create and process categories (for products/directories/shops and etc...)

=back

=head1 SYNOPSIS

 There is an example that you may use in your own CGI scripts:

 # --- Script begin here ---
 use Categories;

 # NOTE: new() method will create needed DB structure in MySQL (database & tables) if they not exist!
 #       Please create database before execute this script or DB USER must have privilege to create DBs!
 
 $obj = Categories->new(database => 'catsdb', user => 'db_user', pass => 'db_pass', host => 'localhost');
      # OR
      # $obj = Categories->new(dbh => $mysql_dbh_handler);
 
 if($obj)
  {
   my $comp_id = $obj->add(type=>'category',name=>'Computers',category=>0);
   my $film_id = $obj->add(type=>'category',name=>'Films',category=>0);
   my $matr_id = $obj->add(type=>'item',name=>'The Matrix',category=>$film_id,value=>'');
   my $one_id  = $obj->add(type=>'item',name=>'The One',category=>$film_id,value=>'');
   my $cpu_id  = $obj->add(type=>'category',name=>'CPU',category=>$comp_id);
   my $hdd_id  = $obj->add(type=>'category',name=>'HDD',category=>$comp_id);
   my $xp18_id = $obj->add(type=>'item',name=>'Athlon XP 1800+',category=>$cpu_id,value=>'');
   my $xp20_id = $obj->add(type=>'item',name=>'Athlon XP 2000+',category=>$cpu_id,value=>'');
   my $xp21_id = $obj->add(type=>'item',name=>'Athlon XP 2100+',category=>$cpu_id,value=>'');
   my $hdd1_id = $obj->add(type=>'item',name=>'Maxtor 80 GB',category=>$hdd_id,value=>'30 months warranty');
   my $hdd2_id = $obj->add(type=>'item',name=>'Maxtor 120 GB',category=>$hdd_id,value=>'36 months warranty');
   
   my @res = $obj->read(path=>'//Computers//HDD//*',sort=>'ID',preload=>YES,reverse=>NO,partial=>'YES');
   print "<HR>";
   if(scalar(@res))
     {
      foreach $l (@res)
       {
         my ($id,$parent_category,$name,$value,$route_path) = @$l;
         print "ID:     $id<BR>\n";
         print "PARENT: $parent_category<BR>\n";
         print "NAME:   $name<BR>\n";
         print "VALUE:  $value<BR>\n";
         $route_path =~ s~//~\\~sgi;
         $route_path =~ s~\\(.*?)\x0~\\~sgi;
         print "PATH:   $route_path<BR>\n";
         print "<HR>";
       }
     }
   
   # Find categories and items (filter=>ALL) that has NAME (by=>NAME) 'The Matrix' order by ID (sort=>ID)
   # and return multiple results (multiple=>'YES') if available, also return rout path to this element 
   # (route=>'YES') using category cache (preload=>'YES') to speed up searching. However 'preload' option may be
   # worse if categories table is too long, because script load whole table and may crush if not enough memmory!
   
   my @res = $obj->find('search'=>'The Matrix','sort'=>'ID','by'=>'NAME','filter'=>'ALL','multiple'=>'YES',
                        'route'=>'YES','preload'=>'YES','partial'=>'NO','reverse'=>'NO');
   if(scalar(@res))
     {
      foreach $l (@res)
       {
         my ($type,$id,$parent_category,$name,$value,$route_path) = @$l;
         print "Type:   $type<BR>\n";
         print "ID:     $id<BR>\n";
         print "PARENT: $parent_category<BR>\n";
         print "NAME:   $name<BR>\n";
         print "VALUE:  $value<BR>\n";
         $route_path =~ s~//~\\~sgi;
         $route_path =~ s~\\(.*?)\x0~\\~sgi;
         print "PATH:   $route_path<BR>\n";
       }
     }
    print "<HR>";
    
    # Modify: Change PARENT/CID and/or NAME
    $obj->modify(id=>$xp21_id,type=>'item',name=>'Duron 1300 MHz',value=>'6 months warranty');
    $obj->modify(id=>$comp_id,type=>'category',name=>'PC');
    $obj->modify(id=>$cpu_id,type=>'category',newcid=>0);
    
    $obj->deep_traverse('preload'=>'YES','id'=>0,'level'=>0,'path'=>'//','eval'=>\&Walk,'sort'=>'NAME');
    
    # Delete ROOT category, so all items/categories are deleted!
    $obj->del(type=>'category',id=>0);
   }
  else
   {
    print $Categories::error;
   }
   
 sub Walk
 {
  my $self = shift;
  my %inp  = @_;
 
  my $id              = $inp{'id'};
  my $level           = $inp{'level'};
  my $separator       = $inp{'separator'};
  my $path            = $inp{'path'};
  my $name            = $inp{'name'};   # ITEM only ($type='I')!
  my $value           = $inp{'value'};  # ITEM only ($type='I')!
  my $type            = $inp{'type'};
 
  $path =~ s~$separator~\\~sgi;
  $path =~ s~\\(.*?)\x0~\\~sgi;
  print $path."$name"."[$value]<BR>";
 }
 # --- Script ends here ---

=head1 SYNTAX

 That is simple function reference:
 
 # Create object of Categories type
 $object = Categories->new(database=>'catsdb', user=>'db_user', pass=>'db_pass', host=>'localhost', 
                           port=>'3306', create=>'Y', checkdb=>'Y', name=>'catdb', dbh=>$connect_db_handler);
    Where:
    database  - is your DB where categories (tables) will be placed. If database not exist module
                will try to create one for you, using supplied user and password. [REQUIRED if $dbh empty]
    user/pass - is your DB user and password [REQUIRED if $dbh empty]
    host      - MySQL DB host
    port      - your MySQL port
    create    - module will attempt to create DB and/or tables
    checkdb   - module will try to check DB structure
    name      - name of category object
    dbh       - you can supply already connected database handler instead of database/user/pass/host/port!
    
 
 
 # Test database structure (tables only)
 $state = $object->is_tables_exists(name=>'name_of_category_object');
    
    
 
 # Create database structure (tables only - database must exist!)
 $state = $object->create_tables(name=>'name_of_category_object');
    Create table structure (database should exist!)
 
 
 
 # Clear categories cache
 $state = $object->clear_cache();
 
 
 
 # Reload/create categories cache and return array of all categories. @cats is array of references to hashes;
 @cats = $object->preload_categories(name=>'name_of_category_object', sort=>'NAME', reverse=>'N');
    Where:
           sort      - is name of column (order by),
           reverse   - reverse results (DESC)
    HINT: $ref = $cats[0]; %hash = %$ref; $name = $hash{'NAME'}; $id = $hash{'ID'}; $parent = $hash{'PARENT'};
    
 
 
 # Find category/item by 'by' column, searching by 'search' keyword (may be on part of word 'partial'=>'Y');
 # also it may return full path to located item/category (route=>'Y') using categories cache (preload=>'Y')
 @res = $object->find(caseinsensitive=>'Y', filter=>'ITEMS', multiple=>'Y', by=>'ID', sort=>'NAME',
                      reverse=>'N', partial=>'N', search=>'keyword', check=>'N', route=>'N',
                      separator=>'//', preload=>'Y');
    Where:
          caseinsensitive  - search is caseinsensitive,
          filter           - define where sub must search (ITEMS,CATEGORIES,ALL),
          multiple         - allows muliple results,
          by               - search BY column,
          sort             - 'order by' all results,
          reverse          - reverse all results,
          partial          - allows partial search ( LIKE %something%),
          search           - search keyword,
          check            - test tables structure,
          route            - find path to root,
          separator        - use follow separator to separate categories in route path,
          preload          - allows categories cache.
    Method returns array of references to arrays results in follow syntax:
          @res = ($ref_1[,$ref_2,...]), where $ref_n is reference to array with follow structure:
          @$ref_n = ([0],[1],[2],[3],[4],[5]);
          where:
          [0] - 'I' or 'C' (Item or Category),
          [1] - ID of Item/Category,
          [2] - PARENT (category ID),
          [3] - NAME of Item/Category,
          [4] - VALUE of Item (ONLY) or empty string if Category,
          [5] - If route=>'Y' this will has follow syntax:
                $separator.$ID."\x0".$CATEGORY_NAME[$separator...]
 


 # Add ITEM/CATEGORY to categories tree. If proceed ITEM you can set 'value' to it.
 $id = $object->add(type=>'ITEM', category=>'0', name=>'Name_Of_Element', check=>'N', value=>'Items only');
     Where:
           type      - is type of element ('ITEM' and 'CATEGORY'),
           category  - is ID of parent (0 is root),
           name      - name of new item/category,
           value     - value of item (only)
           check     - test tables structure.
           $id is ID of created element.



 # Delete ITEM/CATEGORY (recursive) by it's own ID
 $cnt = $object->del(type=>'ITEM', id=>'0', check=>'N', preload=>'Y');
      Where:
            type      - is type of element ('ITEM' and 'CATEGORY'),
            id        - is ID of Item/Category (0 is root),
            check     - test tables structure,
            preload   - allows categories cache.
            $cnt is number of affected(deleted) rows.



 # Modify(update/rename/move) given ITEM/CATEGORY. If some parameter missed method will not change
 # current ITEM value (name,parent,value)
 $cnt = $object->modify(type=>'ITEM', id=>'id_of_element', newcid=>'id_of_new_parent', check=>'N',
                        name=>'new_name_of_element', value=>'Items only', preload=>'Y');
      Where:
            type      - is type of element ('ITEM' and 'CATEGORY'),
            id        - is ID of Item/Category,
            check     - test tables structure,
            name      - new name of item/category (if you dismiss filed, NAME will not be affected!),
            value     - new value of item (if you dismiss filed, VALUE will not be affected!),
            newcid    - new Parent category ID (if you dismiss filed, PARENT will not be affected!),
            preload   - allows categories cache.
            $cnt is number of affected(deleted) rows.
 
 
 
 # Traverse category tree (in width) and calling 'eval' callback sub for any found category!
 $cnt = $object->traverse(cid=>'id_of_category', eval=>\&callback_sub', check=>'N',
                          sort=>'NAME', reverse=>'N', preload=>'Y');
      This sub traverse in width.
      Where:
            cid      - ID of category that should be traversed,
            eval     - reference to sub that will be called for every category,
                       it will be called as: &$eval($self,'id'=>$current,'parent'=>$cid);



 # Traverse category tree (in deep) and calling 'eval' callback sub for any found CATEGORY/ITEM!
 $object->deep_traverse(id=>'id_of_category', level=>'0', separator=>'//', path=>'//',
                        eval=>\&callback_sub', sort=>'NAME', reverse=>'N', check=>'N',
                        preload=>'Y');
      deep_traverse is recursive sub and it traverse in deep. At fist step level should be '0' and
      path '//' (like separator); eval is also reference to callback sub and it will be called as:
      
      &$evala($self,'id'=>$id,'level'=>$level,'type'=>$whereis,'path'=>$path,
              'name'=>$item_name,'value'=>$item_value,'separator'=>$separator);
      where 'name'/'value' will be available only for Items (type=>'I'), but not for categories (type=>'C')
      
      
 
 # Load found categories/items for 'cid' category only! (no recurse)
 @res = $object->load_category(cid=>'id_of_category', sort=>'NAME', reverse=>'N', preload=>'Y');
      This method will load only Items/Categories of 'cid' category (without recurse)!


 
 # Read category/item[s] properties(data) searching by registry-like path (only by 'NAME')!
 @res = $object->read(path=>'//path//to//category//item', sort=>'ID', reverse=>'N', preload=>'Y',
                      partial=>'N', caseinsensitive=>'Y', separator=>'//', preload=>'Y', check=>'N');
      This method try to locate category or item[s] only by 'NAME' starting by 'root' category(PARENT=0),
      Where:
            path      - is 'registry'-like path to category/item[s]. If path ends with '//' (separator)
                        then searching is proceed for category, other else for item. If name of item is
                        '*' then all items of this 'path' will be fetched!
            partial   - This allows searhing for partial items (not for path or categories)! Moreover to
                        use '*' feature you must set partial=>'YES'
      Method returns array of references to arrays results in follow syntax:
            @res = ($ref_1[,$ref_2,...]), where $ref_n is reference to array with follow structure:
            @$ref_n = ($ID,$PARENT_ID,$NAME,$VALUE,$PATH);
            $PATH has follow syntax:  $separator.$ID."\x0".$CATEGORY_NAME[$separator...]



=head1 AUTHOR

 Julian Lishev - Bulgaria, Sofia, 
 e-mail: julian@proscriptum.com, 
 www.proscriptum.com

=cut
