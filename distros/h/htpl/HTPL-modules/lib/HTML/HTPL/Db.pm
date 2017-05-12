package HTML::HTPL::Db;

use DBI;
use HTML::HTPL::SQL;
use HTML::HTPL::Result;
use HTML::HTPL::Sys qw(getvar gethash DEBUG);
use HTML::HTPL::Lib qw(htdie);
use strict;

###
# Handle DB Error

sub dbdie {
    my $par = shift;
    my $err = $DBI::errstr || $@;
    &HTML::HTPL::Lib::takebroadlog("$par failed: $err");
    &HTML::HTPL::Lib::htdie("Database error: $err. Please report administrator: "
      . $ENV{'SERVER_ADMIN'});
}

###
# Erase persistent database connections and queries

sub zap {
#    %HTML::HTPL::Sys::db_pool = ();
    %HTML::HTPL::Sys::query_pool = ();
}

###
# Construct an object

sub old_new {
    my ($class, $dsn, @extra) = @_;

    my $dbh = $HTML::HTPL::Sys::db_pool{$dsn, @extra};
# If connection is not caches, create it
    unless (ref($dbh) eq "DBI::db" && $dbh->{Active}) {
        eval '$dbh = DBI->connect($dsn, @extra);';
        &dbdie("Connection to $dsn") unless ($dbh);
# Save it
        $HTML::HTPL::Sys::db_pool{$dsn, @extra} = $dbh
               if ($HTML::HTPL::Config::htpl_db_save);
    }
    my $self = {'dbh' => $dbh};

    bless $self, $class;
}

sub new {
    my ($class, $dsn, @extra) = @_;

    my $meth = ($HTML::HTPL::Config::htpl_db_save ? 'connect_cached'
			: 'connect');

    my $dbh;

    eval '$dbh = DBI->$meth($dsn, @extra);';
        &dbdie("Connection to $dsn") unless ($dbh);

    my $self = {'dbh' => $dbh};

    DEBUG { print "New connection: $dsn\n"; };

    bless $self, $class;
}

####
# Execute a statement with parameters

sub dbgout {
    my ($script, @values) = @_;
    my $text = $script;
    my @v = @values;
    $text =~ s/\?/pop @v/ge;
    print "$text\n";
}

sub execsql {
    my ($self, $script, @values) = @_;
    my $dbh = $self->{'dbh'};

    DEBUG {
        print "Executing:\n";
        &dbgout($script, @values);
    };

    $dbh->do($script, undef, @values) || &dbdie(qq!SQL "$script"!);
}

sub insert {
    &add(@_);
}

####
# Insert a record

sub add {
    my ($self, $table, @fields) = @_;

    my $dbh = $self->{'dbh'};
    
    my @qs = ();
 
    my $key;
    my @values = ();

# Default field list is all the fields in the table

    @fields = &fieldnames($dbh, $table) unless (@fields);

# Fetch values

    foreach $key (@fields) {
        push(@qs, "?");
        push(@values, &getvar($key));
    }
    my $sql = "INSERT INTO $table (" . join(", ", @fields) .
         ") VALUES (" . join(", ", @qs) . ")";

    DEBUG {
        print "Inserting:\n";
        &dbgout($sql, @values);
    };
# Do it
    my $sth = $dbh->prepare($sql) || &dbdie(qq!SQL "$sql"!);
    $sth->execute(@values) || &dbdie(qq!SQL "$sql"!);
}

#####
## Update

sub update {
    my ($self, $table, @pars) = @_;

# Seperate field list from condition list

    my @parts = split(/\s+WHERE\s+/i, join(" ", @pars));
    my @fields = split(/\s+/, $parts[0]);
    my @conds = split(/\s+/, $parts[1]);

    my $dbh = $self->{'dbh'};

    my @qs = ();

    my @tokens = ();

    my ($ins, @values) = &makefilter(sub { $_[0] . " = ?";},
           ", ", @fields);

    my ($where, @vals2) = &makewhere(@conds);
    push(@values, @vals2);

    my $sql = "UPDATE $table SET $ins WHERE $where";

    DEBUG {
        print "Updating:\n";
        &dbgout($sql, @values);
    };

# Do it
    my $sth = $dbh->prepare($sql) || &dbdie(qq!SQL "$sql"!);

    $sth->execute(@values) || &dbdie(qq!SQL "$sql"!);

}

sub DESTROY {
    my $self = shift;

    my $dbh = $self->{'dbh'};

    $dbh->disconnect;
}

####
## Prepare a resultset

sub cursor {
    my ($self, $sql, @values) = @_;

    DEBUG {
        print "Querying:\n";
        &dbgout($sql, @values);
    };

    my $dbh = $self->{'dbh'};
    my $sth = $dbh->prepare($sql) || &dbdie(qq!SQL "$sql"!);

    return $sth && $sth->execute(@values) && &load($sth)
        || &dbdie(qq!SQL "$sql"!);

}

sub dumpfld {
    my ($txt, $len) = @_;
    print substr($txt . " " . " " x $len, 0, $len + 1);
}

####
## Load a query result into a result set

sub load {
    my ($sth) = @_;

    my $rows = $sth->rows;
## Check if there was anytihng returned
    my $hashref; # Do NOT check if rows == 0, will fail on INFORMIX

    my @fields =  @{$sth->{NAME}};

    return new HTML::HTPL::Result(undef, @fields) unless
		($hashref = $sth->fetchrow_hashref);


## Prepare a queue
    my $orig = HTML::HTPL::Db::Orig->new($sth, @fields);
## Create result set
    my $result = new HTML::HTPL::Result($orig, @fields);
    $result->add($hashref);

    DEBUG {
        print "Result:\n";
        my @tbl = $result->matrix;
        my (@max, @lens);
        foreach (@fields) {
            @lens = $result->project(sub {length($result->get($_));});
            push(@lens, length($_));
            push(@max, (sort @lens)[0] + 2);
            &dumpfld($_, $max[-1]);
        }
        print "\n";
        foreach (@max) {
            print "-" x $_ . " "; 
        }
        print "\n";
        foreach (@tbl) {
            my $i = 0;
            foreach (@$_) {
                &dumpfld($_, $max[$i++]);
            }
            print "\n";
        }
    };

    $result;
}

####
## Obsolete

#sub __add {
#    my ($result, $hashref, @fields) = @_;
#    my $key;
#    my @ary = ();

#    my %hash = %$hashref;

#    foreach $key (@fields) {
#        push(@ary, $hash{$key});
#    }

#    $result->addrow(@ary);
#}

####
## Obsolete

#sub addcgi {
#    my ($self, $table, $param) = @_;
#    my @fields;
#    if (!$param) {
#        @fields = keys (gethash('in'));
#    } else {
#        @fields = &seperate($param);
#    }
#
#    $self->add($table, @fields);
#}

####
## Obsolete

#sub ___updatecgi {
#    my ($self, $table, $param) = @_;
#    my @fields, @conds, $strw, $strf;

#    ($strf, $strw) = ($param =~ /^(.*)\s+WHERE\s+(.*)$/i);
#    @fields = &seperate($strf);
#    @conds = &seperate($strw);
    
#    $self->update($table, \@fields, \@conds);
#}

####
## Prepare a query by field list

sub query {
    my ($self, $table, @conds) = @_;

    my $dbh = $self->{'dbh'};

    my @tokens = ();

    my @values = ();

    my ($key, $where);

    my $sql = "";


## Convert field list to SQL

    if (@conds) {
        ($where, @values) = &makewhere(@conds);
        $sql = " WHERE $where"; 
    }

    my $code = "SELECT * FROM $table$sql";

    return $self->cursor($code, @values);
#    my $sth = $dbh->prepare($code) || &dbdie(qq!SQL "$sql"!);
#    return $sth->execute(@values) && &load($sth) || &dbdie(qq!SQL "$sql"!);

}

#sub ___querycgi {
#    my ($self, $table, $param) = @_;
#    my @conds;

#    @conds = &seperate($param);
    
#    return $self->query($table, @conds);
#}

####
## Search an SQL statement for :variable instances
## Return a modified statement with ?'s and var refs

sub parse_sql2 {
    my $sql = shift;
    my $tokens = &HTML::HTPL::SQL'tokenize_sql($sql);
    my @vars;
    my @result = map {if (/^:/) {
                s/^://; push(@vars, 
                          /^\d+$/ ? getvar($_, 1)
                              : $_);"?"; # Get references
                              # to variables, not values
            } else {
	        $_;
            } 
        } @$tokens;
    (join('', @result), @vars);
}

####
## Tokenize SQL statement, this time return values and not var refs

sub parse_sql {
    my @ary = &parse_sql2(@_);
    (shift @ary, map {getvar($_);} @ary);
}

sub delete {
    my ($self, $table, @conds) = @_;

    my $dbh = $self->{'dbh'};

    my @tokens = ();

    my @values = ();

    my ($key, $where);

    my $sql = "";



    if (@conds) {
        ($where, @values) = &makewhere(@conds);
        $sql = " WHERE $where";
    }

    my $script = "DELETE FROM $table$sql";
    my $sth = $dbh->prepare($script) || &dbdie(qq!SQL "$script"!);
    $sth->execute(@values) || &dbdie(qq!SQL "$script"!);
}


sub batch_insert {
    my ($self, $table, $src) = @_;
    my $dbh = $self->{'dbh'};
    my @fields = &fieldnames($dbh, $table);
    my $sql = "INSERT INTO $table (" . join(", ", @fields) . ") 
       VALUES (" . join(", ", ("?") x @fields) . ")";
    my $sth = $dbh->prepare($sql);
    &HTML::HTPL::Sys::pushvars(@fields);
    my $save = $src->index;
    $src->rewind;
    while ($src->fetch) {
        my @values = map {&getvar($_);} @fields;
        $sth->execute(@values);
    }
    $src->access($save);
    &HTML::HTPL::Sys::popvars;
}

sub prepare {
    my ($self, $sql) = @_;
    my ($code, @vars) = &parse_sql2($sql);
    my $dbh = $self->{'dbh'};
    HTML::HTPL::Db::Query->new($dbh, $sql, \@vars);
}

sub fieldnames {
    my ($dbh, $table) = @_;
    my $sth = $dbh->prepare("SELECT * FROM $table WHERE 2 = 3");
    $sth->execute;
    @{$sth->{NAME}};
}

sub makewhere {
    &makefilter(sub {
        my ($key, $val) = @_;
        my $eq = '=';
        $eq = 'LIKE' if ($val =~ /[\%\#\!\*\?]/);
        "$key $eq ?";
    }, ' AND ', @_);
}

sub makefilter {
    my ($code, $delim, @keys) = @_;
    my (@values, @ws);
    foreach my $key (@keys) {
        my $val = getvar($key);
        push(@values, $val);
        my $eq = '=';
        $eq = 'LIKE' if ($val =~ /[\%\#\!\*\?]/);
        push(@ws, &$code($key, $val));
    };

    (join($delim, @ws), @values);
}

package HTML::HTPL::Db::Orig;

use HTML::HTPL::Orig;

@HTML::HTPL::Db::Orig::ISA = qw(HTML::HTPL::Orig);

use DBI;

sub new {
    my ($class, $sth, @fields) = @_;

    my $self = {'sth' => $sth,
             'fields' => \@fields};
    bless $self, $class;
}

sub realfetch {
    my $self = shift;
    $self->{'sth'}->fetchrow_hashref;
}

package HTML::HTPL::Db::Query;

sub new {
    my ($class, $dbh, $sql, $vars) = @_;
#    $sql =~ s/\$(\$|\d+)/$1 eq '$' ? '$' : ':__' . $1/ge;
#    my ($code, @vars) = &HTML::HTPL::Db::parse_sql($sql);
    bless {'dbh' => $dbh, 'sql' => $sql, 'vars' => $vars}, $class;
}

sub load {
    my $self = shift;
    my $sth = $self->{'sth'};
    my @ary = @{$self->{'vars'}};
    unless ($sth) {
        my $dbh = $self->{'dbh'};
        my $sql = $self->{'sql'};
        $sth = $dbh->prepare($sql) || &HTML::HTPL::Db::dbdie(qq!SQL "$sql"!);
        $self->{'sth'} = $sth;
    } 

####
## We need to trick perl so $1 .. $n will contain $_[0] .. $_[n]
## So we can handle queries with val = :1 etc

    my ($i, $boundary, $re);

####
## Produce a delimiter - a random string that is
    while (1) {
        $boundary = pack("C*", map {int(rand(256));} (0 .. 10));
        $re = quotemeta($boundary);
        last unless grep /^$re$/, @_;
    }
## Build a string of all the parameters delmited by the boundary

    my $str = join($boundary, @_);

## Build a regexp that will match it exactly
    $re = join($boundary, ("(.*)") x @_);
    reset;
    $str =~ /^$re$/;

## Do it
    my @vals = map {$$_;} @ary;
    $sth->execute(@vals) || &HTML::HTPL::Db::dbdie;
    &HTML::HTPL::Db::load($sth);
}

1;
