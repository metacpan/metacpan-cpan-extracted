package YATT::Translator::Perl::macro_dbfetch;
use strict;
use warnings qw(FATAL all NONFATAL misc);
require YATT::Translator::Perl;

YATT::Translator::Perl::make_arg_spec
  (\ my %arg_dict, \ my @arg_order, qw(row sth table schema));

sub macro {
  my ($trans, $scope, $args) = @_;
  my $orig_node = $args->clone;
  my @hash_spec
    = $trans->feed_arg_or_make_hash_of(text => $scope, $args
				       , \%arg_dict, \@arg_order
				       , my ($rowVarName
					     , $sth, $table, $schema));

  unless ($table) {
    die $trans->node_error($orig_node->parent, "table= is missing");
  }

  my %local;
  my $sthVar = $sth ? node_body($sth) : 'sth';
  $local{$sthVar} = $trans->create_var('scalar' => $args
				       , varname => $sthVar);
  my ($loop, $else);
  my $found = my $header = $args->variant_builder;
  for (; $args->readable; $args->next) {
    unless ($args->is_attribute) {
      $found->add_node($args->current);
      next;
    }
    if ($args->node_name eq 'row') { # XXX: body でも良いのでは？
      $loop = $args->open;
      $found = $args->variant_builder;
    } elsif ($args->node_name eq 'else') {
      $else = $args->open;
      last;
    } else {
    }
  }
  my @columns;
  my %inner;
  if ($loop) {
    for (; $loop->readable && $loop->is_primary_attribute; $loop->next) {
      my ($name, $typename) = $trans->arg_name_types($loop);
      $inner{$name} = $trans->create_var
	($typename || 'text', $loop, varname => $name);
      my $expr = $loop->node_body;
      # [varName => columnExpr]
      push @columns, [$name => defined $expr ? "$expr as $name" : $name];
    }
  } else {
  }

  my ($fetchMode, $rowVarExpr) = do {
    if (@columns) {
      (array => '('.join(", ", map {'$'.$_->[0]} @columns).')')
    } else {
      my $name = $rowVarName ? node_body($rowVarName) : 'row';
      $local{$name} = $trans->create_var('list' => $args
					 , varname => $name);
      (hashref => '$'.$name);
    }
  };

  my $loopBody = do {
    if ($loop) {
      $trans->as_block
	($trans->as_statement_list
	 ($trans->generate_body([\%inner, [\%local, $scope]], $loop)));
    } else {
      die "NIMPL";
    }
  };

  # XXX: Static check! (But, to check, quoted expression is too much!)
  my $schemaExpr = $trans->default_gentype
    (DBSchema => text => $scope, $args, $schema);

  my $tableExpr = $trans->faked_gentype
    (text => $scope, $args, $table);

  my $prepare = sprintf(q|my $%s = $this->%s->to_fetch(%s, %s, %s)|
			, $sthVar
			, $schemaExpr
			, $tableExpr
			, (@columns ?
			   ('['.join(", ", map {
			     YATT::Translator::Perl::qparen($_->[1])
			     } @columns).']')
			   : 'undef')
			, join(", ", map {"$_->[0] => $_->[1]"}
			       @hash_spec));

  my $if = sprintf(q|if (my %1$s) {%2$s; do %3$s while (%1$s); %4$s}|
		   , sprintf(q|%s = $%s->fetchrow_%s|
			     , $rowVarExpr, $sthVar, $fetchMode)
		   , $trans->as_statement_list
		   ($trans->generate_body([\%local, $scope], $header))
		   , $loopBody
		   , $trans->as_statement_list
		   ($trans->generate_body([\%local, $scope], $found))
		  );
  $if .= " else ".$trans->as_block
    ($trans->as_statement_list
     ($trans->generate_body([\%local, $scope], $else))) if $else;

  \ "{$prepare; $if}";
}

1;
