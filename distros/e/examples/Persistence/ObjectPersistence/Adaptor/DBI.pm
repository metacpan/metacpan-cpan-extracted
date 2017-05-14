package Adaptor::DBI; 
use Carp;
use DBI;
use strict;

#---- Global variables
use vars qw(%map_info);
my %global_config = ();
my $debugging = 0;
sub new { # $db = Adaptor::DBI->new('db_name', '<username>', '<password>',
          #                       'db driver name', '<config file>');
    @_ == 6 ||
        croak "Usage: Adaptor::DBI->new ('<dbname>', '<username>', " .
              " '<password>', 'db driver name', '<config file>')";
    my ($pkg, $dbname, $user, $pass, $dbd, $config_file) = @_;
    my (@cl_info) = _load_config_file($config_file);

    my $db = DBI->connect($dbname, $user, $pass, $dbd) ||
       croak "DBI Error : $DBI::errstr\n";
    $db->{AutoCommit} = 1;
    my $obj = bless {"d" => $db}, $pkg;
    $obj;
}

sub begin_transaction {
    my $this = shift;
    my $db = $this->{d};
    $db->{AutoCommit} = 0;
}

sub commit_transaction {
    my $this = shift;
    my $db = $this->{d};
    $db->do ("commit");
    check_error();
    $db->{AutoCommit} = 1;
}

sub rollback_transaction {
    my $this = shift;
    my $db = $this->{d};
    $db->do("rollback");
    check_error();
    $db->{AutoCommit} = 1;
}


my %mapping_loaded = ();
sub _load_config_file {
    my ($file) = @_;
    return if (exists $mapping_loaded{$file});
    $mapping_loaded{$file}++;
    require $file; # for now.
}

sub delete {
    (@_ == 2) || (@_ == 3) ||
         croak  "Error: adaptor->delete (obj), or \n" .
                '       adaptor->delete (class, id)';
    my ($this, $class, $id);
    $this = shift;
    if (@_ == 1) {
        my $obj = $_[0];
        $class = ref($obj);
        ($id) = $obj->get_attributes('_id');
    } else {
         ($class, $id) = @_;
    }
    my $table = $map_info{$class}{"table"};
    return unless defined($id);
    $this->{"d"}->do("delete from $table where id = $id");
    check_error();
}

sub store {    # adaptor->store($obj)
    (@_ == 2) || croak  'Usage adaptor->store ($obj)';
    my $sql_cmd;
    my ($this, $obj) = @_;

    my $class = ref($obj);
    my $rh_class_info = $map_info{$class};

    my $table = $rh_class_info->{"table"};
    croak "No mapping defined for package $class" unless defined($table);
    my $rl_attr_names = $rh_class_info->{"attributes"};
    my $rl_column_names = $rh_class_info->{"columns"};
    my ($id)                  = $obj->get_attributes('_id');
    my ($attr);
    if (!defined ($id )) {
        $id = $this->_get_next_id($table);
        $obj->set_attributes('_id'=> $id);
        $sql_cmd               = "insert into $table (";
        my ($col_name, $type, $attr);
	my (@attrs) = $obj->get_attributes(@$rl_attr_names);
        $sql_cmd .= join(",",@$rl_column_names) . ") values (";
        my $val_cmd = "";
        foreach $attr (@attrs) {
            my $quote = ($attr =~ /\D/)
                           ? "'"
                           : "";
            $val_cmd .= "${quote}${attr}${quote},";
        }
        chop ($val_cmd);
        $sql_cmd .= $val_cmd . ")" ;
    } else {
        $sql_cmd = "update $table set ";
        my ($name, $quote);
        my @attrs = $obj->get_attributes(@$rl_attr_names);
	my $i = -1;
	my $id_col_name;
        foreach $name (@$rl_attr_names) {
	    $i++;
            if ($name eq '_id') {
		$id_col_name = $rl_column_names->[$i];
                shift @attrs;
                next;
            }
            $attr = shift @attrs;
            $quote = ($attr =~ /\D/)
                           ? "'"
                           : "";
            $sql_cmd .= "$name=${quote}${attr}${quote},";
        }
        chop($sql_cmd); # remove trailing comma
        $sql_cmd .= " where $id_col_name = $id";
    }
    $this->{d}->do($sql_cmd);
    check_error();
    $id;
}

sub flush {    # adaptor->flush();
    # noop
    1;
}

my $counter = 0;
my $counter_reset_time = time();

sub _get_next_id {  # adaptor->_get_next_id()
    if (++$counter > 99999) {
        # Assuming you can't create 99999 Perl objects in one second
        $counter_reset_time = time();
        $counter = 0;
    }
    sprintf("%09d%05d", $counter_reset_time, ++$counter);
}

sub retrieve {
    @_ == 3 or die 'Usage: $adaptor->retrieve(<class>, <id>)';
    my ($this,$class, $id) = @_;
    my @objs = $this->retrieve_where ($class, "id = $id");
    if (@objs) {
        $objs[0]; # assuming id is unique
    } else {
        undef;
    }
}

my $ANY_OP = '<=|>=|<|>|!=|==';      # Any comparison operator

sub retrieve_where {
    my ($this, $class, $query) = @_;
    my $where;
    $where = ($query =~ /\S/)
                   ? "where $query"
                   : "";

    my $rh_class_info = $map_info{$class};

    my $table = $rh_class_info->{"table"};
    croak "No mapping defined for package $class" unless defined($table);
    my $rl_attr_names = $rh_class_info->{"attributes"};
    my $rl_col_names  = $rh_class_info->{"columns"};
    my $rh_map_attr_col;
    unless (defined ($rh_map_attr_col = $rh_class_info->{"map_attr_col"})) {
	my %map = ();
	my @col_names = @$rl_col_names;
	foreach my $attr_name (@$rl_attr_names) {
	    $map{$attr_name} = shift @col_names;
	}
	$rh_map_attr_col = $rh_class_info->{"map_attr_col"} = \%map;
    }

    $where =~ s/(\w+)\s*($ANY_OP)/$rh_map_attr_col->{$1} . " " . $2/eg;

    my $sql_cmd      = "select " 
                       . join(",", @{$rl_col_names}) 
                       . " from $table $where";
    my $dbh  = $this->{d};
    print $sql_cmd if $debugging;
    my $sth = $dbh->prepare($sql_cmd);
    die "Adaptor::DBI error:\n\t$DBI::err : $DBI::errstr" if $DBI::err;
    $sth->execute();
    die "Adaptor::DBI error:\n\t$DBI::err : $DBI::errstr" if $DBI::err;
    my @retval;
    my $size = @$rl_attr_names - 1;
    my @list;
    while (@list = $sth->fetchrow) {
	my $obj = $class->new;
	$obj->set_attributes(map {
	                            $rl_attr_names->[$_] => $list[$_]
                                 } (0 .. $size));
	push (@retval, $obj);
    }
    @retval;
}

sub retrieve_all {
    my ($this) = @_;
    $this->retrieve_where(); # null query => get all
}

sub  check_error {
    die "DBI error: $DBI::err : $DBI::errstr\n" if $DBI::err;
}


1;




=head1 SERIOUS BUGS

1. attribute names must be mapped to column names in retrieve_where
   (cannot hard-code _id in classes either)

2. If object supplies a unique id, store() does an update, which is
   wrong the first time.

3. Retrieve queries return equivalent objects.

4. For performance, retrieve_where must take a callback

5. For performance, DBI::do should not be used.


