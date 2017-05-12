# -------------------------------------------------------------------------------------
# TripleStore::Driver::SQLResultSet
# -------------------------------------------------------------------------------------
#
#       Author : Jean-Michel Hiver (jhiver@mkdoc.com).
#      Version : $Id: SQL.pm,v 1.2 2003/01/21 14:35:01 jhiver Exp $
#
#    Description:
#
#      ResultSet for SQL queries
#
# -------------------------------------------------------------------------------------
package TripleStore::Driver::SQLResultSet;
use strict;
use warnings;
use Carp;
use DBI;
use base qw /TripleStore::ResultSet
	     TripleStore::Mixin::Class/;

sub new { return bless \$_[1], $_[0]->class }

sub next
{
    my $self = shift;
    return $$self->fetchrow_arrayref;
}


# -------------------------------------------------------------------------------------
# TripleStore::Driver::SQL
# -------------------------------------------------------------------------------------
#
#       Author : Jean-Michel Hiver (jhiver@mkdoc.com).
#      Version : $Id: SQL.pm,v 1.2 2003/01/21 14:35:01 jhiver Exp $
#
#    Description:
#
#      Abstract SQL driver
#
# -------------------------------------------------------------------------------------
package TripleStore::Driver::SQL;
use strict;
use warnings;
use Carp;
use DBI;
use base qw /TripleStore::Driver/;

use vars qw /$TripleStore $SubjectText $SubjectNum $PredicateText $PredicateNum $ObjectText $ObjectNum
	     @ClauseList @VariableList %ClauseToAlias %VariableToBindings/;


# installs the following methods:
# set_dbh dbh
# set_dsn dsn
# set_usr usr
# set_pwd pwd
BEGIN
{
    for my $attribute (qw /dbh dsn usr pwd/)
    {
	no strict 'refs';
	my $set_name = "set_$attribute";
	my $get_name = "$attribute";
	*$set_name = sub {
	    my $self = shift;
	    $self->{$attribute} = shift;
	};
	
	*$get_name = sub {
	    my $self = shift;
	    return $self->{$attribute};
	};
    }
}


##
# $class->new();
# --------------
# Creates a new People::Driver::MySQL method
##
sub new
{
    my $class = shift->class;
    my $self  = bless {}, $class;
    $self->{sql_log} = [];
    $self->set_dsn (shift);
    $self->set_usr (shift);
    $self->set_pwd (shift);
    $self->connect();
    $self->deploy();
    return $self;
}


##
# $self->DESTROY();
# -----------------
# Driver cleanup before it's freed from memory.
##
sub DESTROY
{
    my $self = shift;
    $self->disconnect();
}


##
# $self->insert ($subject, $predicate, $object);
# ----------------------------------------------
# $subject   - a SCALAR subject
# $predicate - a SCALAR predicate
# $object    - a SCALAR object
##
sub insert
{
    my $self = shift;
    my $subject   = shift;
    my $predicate = shift;
    my $object    = shift;
    my $sql = $self->_prepared_sql_insert();
    my @bound = do {
	no warnings;
	( $subject,   0 + $subject,
	  $predicate, 0 + $predicate,
	  $object,    0 + $object );
    };
    
    $self->execute ($sql, @bound);
}


##
# $self->delete (Storage::Triple::Query::Clause $clause);
# -------------------------------------------------------
# $clause - a Storage::Triple::Query::Clause object.
# Returns - Nothing.
##
sub delete
{
    my $self   = shift;
    my $clause = shift;    
    my $where  = $self->_prepared_sql_delete_where ($clause);
    my $sql    = $self->_prepared_sql_delete ($where);
    my @bound  = map { defined $_ ? $_ : () } $clause->criterion_values();
    $self->execute ($sql, @bound);
}


##
# $self->update ($set, $clause);
# ------------------------------
# $set    - a Storage::Triple::Update object.
# $clause - a Storage::Triple::Query::Clause object.
# Returns - Nothing.
##
sub update
{
    my $self   = shift;
    my $set    = shift;
    my $clause = shift;
    
    my $update = $self->_prepared_sql_update_set ($set);
    my $where  = $self->_prepared_sql_update_where ($clause);
    my $sql    = $self->_prepared_sql_update ($update, $where);
    my @bound  = ( $set->bound_values(), map { defined $_ ? $_ : () } $clause->criterion_values() );
    $self->execute ($sql, @bound);
}


##
# $self->deploy();
# ----------------
# Creates the triple store table.
##
sub deploy
{
    my $self = shift;
    my $sql  = $self->_prepared_sql_deploy();
    $self->execute ($sql);
}


# $self->connect();
sub connect
{
    my $self = shift;
    my @args = ($self->dsn, $self->usr, $self->pwd);
    push @args, { RaiseError => 1 };
    my $dbh = DBI->connect (@args);
    $self->set_dbh ($dbh);
}


# $self->disconnect();
sub disconnect
{
    my $self = shift;
    my $dbh  = $self->dbh || return;
    $self->dbh()->disconnect();
    $self->set_dbh (undef);
}


##
# $self->execute ($sql, @bound_values);
# -------------------------------------
# Prepares a handler, executes $sql with @bound_values
# and returns it.
##
sub execute
{
    my $self = shift;
    my $sql  = shift;
    my $dbh = $self->dbh();
    my $sth = $dbh->prepare_cached ($sql);
    $sth->execute (map { "$_" } @_);
    $self->_log ($sql, @_);
    return $sth;
}


##
# $self->last_statement();
# ------------------------
sub last_statement
{
    my $self = shift;
    my @sql  = @{$self->{sql_log}};
    return $sql[$#sql];
}


##
# $self->_log ($sql, @_);
# -----------------------
# Logs an SQL statement which is executed.
##
sub _log
{
    my $self = shift;
    my @stuff = split /\?/, shift;
    my @res = shift (@stuff);
    while (@stuff)
    {
	push @res, "'" . quotemeta (shift (@_)) . "'";
	push @res, shift (@stuff);
    }
    push @res, "'" . shift (@_) . "'" if (+ @_);
    
    my $res = join '', @res;
    push @{$self->{sql_log}}, $res;
    return $res;
}


##
# $class->_sql_operator();
# ------------------------
# Returns the SQL operator which matches the current operator.
##
sub _sql_operator
{
    my $class = shift->class;
    my $op = shift;
    $op eq 'eq'     and return '=';
    $op eq 'ne'     and return '!=';
    $op eq 'like'   and return 'LIKE';
    $op eq 'unlike' and return 'NOT LIKE';
    $op eq 'lt'     and return '<';
    $op eq 'gt'     and return '>';
    $op eq 'le'     and return '<=';
    $op eq 'gt'     and return '>=';
    $op eq '=='     and return '=';
    $op eq '!='     and return '!=';
    $op eq '<'      and return '<';
    $op eq '>'      and return '>';
    $op eq '<='     and return '<=';
    $op eq '>='     and return '>=';
    confess "nothing known about operator $op";
}


##
# $self->_sql_select_where ($var1, [$var2, ...], $query, [$sort1, $sort2, ...], $limit);
# --------------------------------------------------------------------------------------
# Performs a select() on the database and returns the results in
# a ResultSet object.
##
sub select
{
    my $self = shift;
    my ($query)   = map { $_->isa ('TripleStore::Query') ? $_ : () } @_;
    my @variables = map { $_->isa ('TripleStore::Query::Variable') ? $_ : () } @_;
    my @sort      = map { $_->isa ('TripleStore::Query::Sort') ? $_ : () } @_;
    my ($limit)   = map { $_->isa ('TripleStore::Query::Limit') ? $_ : () } @_;
    confess "No query defined" unless (defined $query);
    confess "No variables prompted" unless (@variables);
    
    local $TripleStore   = $self->_sql_symbol_triple_store();
    local $SubjectText   = $self->_sql_symbol_subject_text();
    local $SubjectNum    = $self->_sql_symbol_subject_num();
    local $PredicateText = $self->_sql_symbol_predicate_text();
    local $PredicateNum  = $self->_sql_symbol_predicate_num();
    local $ObjectText    = $self->_sql_symbol_object_text();
    local $ObjectNum     = $self->_sql_symbol_object_num();
    
    local @ClauseList    = $query->list_clauses();
    local @VariableList  = $query->list_variables();
    local %ClauseToAlias = ();
    $self->_construct_clause_to_alias ($query);
    local %VariableToBindings = map { $_ => $self->_select_bindings ($_) } @VariableList;
    
    my @sql = ();
    push @sql, "SELECT "   . $self->_sql_select_variables (@variables);
    push @sql, "FROM "     . join ', ', map { "$TripleStore AS $_" } sort values %ClauseToAlias;
    push @sql, "WHERE "    . $self->_sql_select_where ($query);
    push @sql, "ORDER BY " . $self->_sql_select_order_by (@sort) if (scalar @sort);
    (defined $limit) and push @sql, do {
	my $offset = $limit->offset();
	my $rows   = $limit->rows();
	"LIMIT $offset, $rows";
    };
    
    my $sql = join " ", @sql;
    my @bound = $query->criterion_values;
    my $sth = $self->execute ($sql, @bound);
    return new TripleStore::Driver::SQLResultSet ($sth);
}


##
# $self->_construct_clause_to_alias ($query);
# -------------------------------------------
# Aliases each clause with an alias.
##
sub _construct_clause_to_alias
{
    my $self  = shift;
    my $query = shift;
    
    my @to_process = ();
    if ($query->isa ('TripleStore::Query::Or'))
    {
	my $alias = $self->_next_alias();
	my @subq  = $query->list_subqueries();
	for (@subq)
	{
	    $_->isa ('TripleStore::Query::Criterion') ?
	        $ClauseToAlias{$_} = $alias :
		$self->_construct_clause_to_alias ($_);
	}
    }
    elsif ($query->isa ('TripleStore::Query::And'))
    {
	my @subq  = $query->list_subqueries();
	for (@subq) { $self->_construct_clause_to_alias ($_) }
    }
    else
    {
	$ClauseToAlias{$query} = $self->_next_alias();
    }
}


##
# $self->_sql_select_order_by (@order_by);
# ----------------------------------------
# Returns an SQL ORDER_BY statement
##
sub _sql_select_order_by
{
    my $self = shift;
    my @res  = ();
    while (@_)
    {
	my $order_by  = shift (@_);
	my $variable  = $$order_by;
	my $component = $VariableToBindings{$variable}->[0]->{component};
	my $clause    = $VariableToBindings{$variable}->[0]->{clause};
	my $alias     = $ClauseToAlias{$clause};
	if ($order_by->isa ('TripleStore::Query::Sort::NumericAscending'))
	{
	    push @res, "$alias.$SubjectNum ASC"     if ($component eq $SubjectText or $component eq $SubjectNum);
	    push @res, "$alias.$PredicateNum ASC"   if ($component eq $PredicateText or $component eq $PredicateNum);
	    push @res, "$alias.$ObjectNum ASC"      if ($component eq $ObjectText or $component eq $ObjectNum);
	}
	if ($order_by->isa ('TripleStore::Query::Sort::NumericDescending'))
	{
	    push @res, "$alias.$SubjectNum DESC"    if ($component eq $SubjectText or $component eq $SubjectNum);
	    push @res, "$alias.$PredicateNum DESC"  if ($component eq $PredicateText or $component eq $PredicateNum);
	    push @res, "$alias.$ObjectNum DESC"     if ($component eq $ObjectText or $component eq $ObjectNum);
	}
	if ($order_by->isa ('TripleStore::Query::Sort::StringAscending'))
	{
	    push @res, "$alias.$SubjectText ASC"    if ($component eq $SubjectText or $component eq $SubjectNum);
	    push @res, "$alias.$PredicateText ASC"  if ($component eq $PredicateText or $component eq $PredicateNum);
	    push @res, "$alias.$ObjectText ASC"     if ($component eq $ObjectText or $component eq $ObjectNum);
	}
	if ($order_by->isa ('TripleStore::Query::Sort::StringDescending'))
	{
	    push @res, "$alias.$SubjectText DESC"   if ($component eq $SubjectText or $component eq $SubjectNum);
	    push @res, "$alias.$PredicateText DESC" if ($component eq $PredicateText or $component eq $PredicateNum);
	    push @res, "$alias.$ObjectText DESC"    if ($component eq $ObjectText or $component eq $ObjectNum);
	}
    }
    return join ", ", @res;
}


##
# $self->_sql_select_where ($query);
# ----------------------------------
# Returns the WHERE bit of the SQL query matching $query.
##
sub _sql_select_where
{
    my $self = shift;
    my $query = shift;
    my $relationships = $self->_sql_select_where_relationships ($query);
    my $conditions    = $self->_sql_select_where_conditions   ($query);
    ($relationships  and $conditions) and return "$relationships AND $conditions";
    ($relationships) and return $relationships;
    ($conditions)    and return $conditions;
    confess $self->class . "::_sql_select_where(). Unexpected error: No SQL produced";
}


##
# $self->_sql_select_where_conditions ($query);
# ---------------------------------------------
# Returns SQL representing the conditions which are
# defined by the criterion object within each clause.
##
sub _sql_select_where_conditions
{
    my $self  = shift;
    my $query = shift;
    $query->isa ('TripleStore::Query::Or')  and return $self->_sql_select_where_conditions_or  ($query);
    $query->isa ('TripleStore::Query::And') and return $self->_sql_select_where_conditions_and ($query);
    return $self->_sql_select_where_conditions_clause ($query);
}


##
# $self->_sql_select_where_conditions_or ($query);
# ------------------------------------------------
# Returns SQL representing the conditions which are
# defined by the criterion object within each clause.
# Here query is a TripleStore::Query::Or object.
##
sub _sql_select_where_conditions_or
{
    my $self = shift;
    my $query = shift;
    return join ' OR ', map {
	my $res = $self->_sql_select_where_conditions ($_);
	defined $res ? "($res)" : ();
    } @{$query};
}


##
# $self->_sql_select_where_conditions_and ($query);
# -------------------------------------------------
# Returns SQL representing the conditions which are
# defined by the criterion object within each clause.
# Here query is a TripleStore::Query::And object.
##
sub _sql_select_where_conditions_and
{
    my $self = shift;
    my $query = shift;
    return join ' AND ', map {
	my $res = $self->_sql_select_where_conditions ($_);
	defined $res ? "($res)" : ();
    } @{$query};
}


##
# $self->_sql_select_where_conditions_clause ($query);
# ----------------------------------------------------
# Returns SQL representing the conditions which are
# defined by the criterion object within each clause.
# Here query is a TripleStore::Query::Clause object.
##
sub _sql_select_where_conditions_clause
{
    my $self = shift;
    my $query = shift;
    my @sql = ();
    
    my $subject = $query->subject();
    $subject->isa ('TripleStore::Query::Criterion') and
    push @sql, $self->_select_where_criterion ('subject', $query, $subject);
    
    my $predicate = $query->predicate();
    $predicate->isa ('TripleStore::Query::Criterion') and
        push @sql, $self->_select_where_criterion ('predicate', $query, $predicate);
    
    my $object = $query->object();    
    $object->isa ('TripleStore::Query::Criterion') and
        push @sql, $self->_select_where_criterion ('object', $query, $object);
    
    return if (@sql == 0);
    return join ' AND ', @sql;
}


##
# $self->_select_where_criterion();
# ---------------------------------
# Returns the SQL representation of a criterion.
##
sub _select_where_criterion
{
    my $self = shift;
    my $component = shift;
    my $clause    = shift;
    my $criterion = shift;
    my $clause_id = 0 + $clause;

    my $op = $criterion->operator();
    my $table_name = $ClauseToAlias{$clause};
    my $table_column = do {
        my $res = '';
        $component eq 'subject'   and !$criterion->is_numeric_operator() and $res = $SubjectText;
        $component eq 'subject'   and $criterion->is_numeric_operator()  and $res = $SubjectNum;
        $component eq 'predicate' and !$criterion->is_numeric_operator() and $res = $PredicateText;
        $component eq 'predicate' and $criterion->is_numeric_operator()  and $res = $PredicateNum;
        $component eq 'object'    and !$criterion->is_numeric_operator() and $res = $ObjectText;
        $component eq 'object'    and $criterion->is_numeric_operator()  and $res = $ObjectNum;
	$res;
    };
    
    my $sql_op = $self->_sql_operator ($op);
    return "$table_name.$table_column $sql_op ?";
}


##
# $self->_sql_select_where_relationships;
# ---------------------------------------
# Returns SQL representing the identity relationships between
# all the clauses...
##
sub _sql_select_where_relationships
{
    my $self = shift;
    my @res  = ();
    foreach my $variable (@VariableList)
    {
	my $sql = $self->_sql_select_where_relationships_variable ($variable);
	push @res, $sql if ($sql);
    }
    
    return (@res == 1) ? pop (@res) : join ' AND ', @res;
}


##
# $self->_sql_select_where_relationships_variable ($variable);
# ------------------------------------------------------------
# Returns SQL representing the identity relationships between
# all the clauses for this specific variable.
##
sub _sql_select_where_relationships_variable
{
    my $self = shift;
    my $variable = shift;
    my @res = ();
    
    my @bindings       = @{$VariableToBindings{$variable}};
    
    my $prev_binding   = shift (@bindings);
    my $prev_component = $prev_binding->{component};
    my $prev_clause    = $prev_binding->{clause};
    my $prev_alias     = $ClauseToAlias{$prev_clause};
    while (scalar @bindings)
    {
	my $next_binding   = shift (@bindings);
	my $next_component = $next_binding->{component};
	my $next_clause    = $next_binding->{clause};
	my $next_alias     = $ClauseToAlias{$next_clause};
	
	push @res, "$prev_alias.$prev_component = $next_alias.$next_component";
	
	$prev_binding = $next_binding;
	$prev_component = $next_component;
	$prev_clause = $next_clause;
	$prev_alias = $next_alias;
    }
    
    my $sql = join ' AND ', @res;
    return unless ($sql);
    return $sql;
}


##
# $self->_sql_variables (@variables);
# -----------------------------------
# Returns what to select in the SELECT statement.
# i.e. SELECT A.S_T, B.O_T
##
sub _sql_select_variables
{
    my $self = shift;
    my @res  = ();
    foreach my $variable (@_)
    {
	my $binding = $VariableToBindings{$variable}->[0];
	my $clause  = $binding->{clause};
	my $alias   = $ClauseToAlias{$clause};
	push @res, "$alias.$binding->{component}";
    }
    return join ", ", @res;
}


##
# $self->_select_bindings ($variable);
# ------------------------------------
# Returns a list of bindings for that variable.
#
# A binding is a hash with:
# component => (subject|predicate|object)
# clause    => TripleStore::Query::Clause object
##
sub _select_bindings
{
    my $self = shift;
    my $variable = shift;
    my @res  = ();
    foreach my $clause (@ClauseList)
    {
	($clause->subject() == $variable)   and push @res, { component => $SubjectText,   clause => $clause };
	($clause->predicate() == $variable) and push @res, { component => $PredicateText, clause => $clause };
	($clause->object() == $variable)    and push @res, { component => $ObjectText,    clause => $clause };
    }
    
    @res == 0 and confess ($self->class . "::_select bindings error: $variable has no bindings");
    return \@res;
}


1;
