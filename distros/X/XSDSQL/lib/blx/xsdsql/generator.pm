package blx::xsdsql::generator;
use strict;  # use strict is for PBP
use Filter::Include;
include blx::xsdsql::include;
#line 6
use File::Spec;

use blx::xsdsql::ut::ut qw(nvl ev);
use base qw(blx::xsdsql::ios::debuglogger blx::xsdsql::ut::common_interfaces);

use constant {
	STREAM_CLASS => 'blx::xsdsql::ios::ostream'
	,COMMANDS => [ qw(
						drop_table 
						create_table 
						addpk 
						drop_sequence 
						create_sequence 
						drop_view 
						create_view 
						drop_dictionary 
						create_dictionary 
						insert_dictionary
						drop_extra_tables
						create_extra_tables
					)
				]
	
};

sub _check_table_filter {
	my ($self,$table,$level,%params)=@_;
	if (defined $self->{_PARAMS}->{LEVEL_FILTER}) {
		return 0  if $level != $self->{_PARAMS}->{LEVEL_FILTER};
	}
	if (defined $self->{_PARAMS}->{TABLES_FILTER}) {
		return 1 if $self->{_PARAMS}->{TABLES_FILTER}->{uc($table->get_sql_name)};
		my $path=$table->get_attrs_value(qw(PATH));
		return 0 unless defined $path;
		return 1 if $self->{_PARAMS}->{TABLES_FILTER}->{$path};
		return 0;
	}
	return 1;
}

sub _check_view_limits {
	my ($self,$table,%params)=@_;
	my $p=$self->{_PARAMS};
	return 1 unless grep($_ eq $p->{COMMAND},qw( create_view drop_view));	
	return 0 unless $self->{EXTRA_TABLES}->get_attrs_value(qw(CATALOG_INSTANCE))->is_support_views;
	my $handle=$p->{HANDLE_OBJECT};
	return 1 if $p->{MAX_VIEW_COLUMNS} == -1 && $p->{MAX_VIEW_JOINS} == -1; #no limit
	my @a=$handle->get_view_columns($table,%params);
	return 0 if $p->{MAX_VIEW_COLUMNS} > -1 && scalar(@a) > $p->{MAX_VIEW_COLUMNS};
	@a=$handle->get_join_columns($table,%params); 
	return 0 if $p->{MAX_VIEW_JOINS} > -1 && scalar(@a) > $p->{MAX_VIEW_JOINS};
	return 1;
}

sub _cross {
	my ($self,$table,%params)=@_;
	affirm { defined $table } "1^ param not set"; 
	my $handle=$self->{_PARAMS}->{HANDLE_OBJECT};
	if ($self->_check_table_filter($table,$params{LEVEL})) {
		if ($self->_check_view_limits($table)) {
			if (!$params{NO_GENERATE_ROOT_TABLE} || !$table->is_root_table) {
				$handle->table_header($table,%params) || return;
				for my $col($table->get_columns) {
					$handle->column($col,%params,TABLE => $table) || return;
				}
				$handle->table_footer($table,%params) || return;
			}
		}
		else {
			if (!$params{NO_GENERATE_ROOT_TABLE} || !$table->is_root_table) {
				$handle->get_streamer->put_line;
				$handle->put_comment($table,"view '".$table->get_view_sql_name."' is not generate  because overflow the database limits"); 
				$handle->get_streamer->put_line;
			}
		}
	}
	for my $t($table->get_child_tables) {
		$self->_cross($t,%params,LEVEL => $params{LEVEL} + 1) || last;
	}
	if ($table->is_root_table) {
		my $types=$params{SCHEMA}->get_types_name;
		for my $k(keys %$types) {
			my $t=$types->{$k};
			next if $t->is_simple_type;
			$self->_cross($t,%params,LEVEL => -1) || last;			
		}
	}
	return $self; 
}


sub get_namespaces;

sub generate {
	my ($self,%params)=@_;
	my $p=$self->_fusion_params(%params);
	affirm { defined $p->{COMMAND} } "param COMMAND not set";	
	affirm { grep($p->{COMMAND} eq $_,@{&COMMANDS}) } $p->{COMMAND}.": invalid command";
	affirm { !defined $params{SQL_BINDING} } "param SQL_BINDING is obsolete";
	
	$p->{COMMAND}='drop_extra_tables' if $p->{COMMAND} eq 'drop_dictionary';
	$p->{COMMAND}='create_extra_tables' if $p->{COMMAND} eq 'create_dictionary';
	my $handle_class='blx::xsdsql::generator::'.$p->{OUTPUT_NAMESPACE}.'::'.$p->{DB_NAMESPACE}.'::handle::'.$p->{COMMAND};
	if (defined $p->{TABLES_FILTER}) {
		$p->{TABLES_FILTER}=[ $p->{TABLES_FILTER} ] if ref($p->{TABLES_FILTER}) eq '';
		affirm { ref($p->{TABLES_FILTER}) eq 'ARRAY' } "TABLES_FILTER param type not valid  - must be an array of scalar or a scalar not null";		
		for my $e(@{$p->{TABLES_FILTER}}) {
			affirm { defined $e && ref($e) eq '' } "TABLES_FILTER param type not valid  - must be an array of scalar or a scalar not null";			
		}
		$p->{TABLES_FILTER}={ map { /^\// ? ($_,1)  : (uc($_),1) ; } @{$p->{TABLES_FILTER}} }; #transform into hash
	}
	
	{
		my $catalog=$self->{EXTRA_TABLES}->get_attrs_value(qw(CATALOG_INSTANCE));
		$p->{MAX_VIEW_COLUMNS}=$catalog->get_max_columns_view unless defined $p->{MAX_VIEW_COLUMNS};
		$p->{MAX_VIEW_JOINS}=$catalog->get_max_joins_view unless defined $p->{MAX_VIEW_JOINS};
	}
	
	my $fd=nvl($p->{FD},*STDOUT);
	my $encoding=sub {
		return 'UTF-8' unless defined $params{SCHEMA};
		my $xmldecl=$params{SCHEMA}->get_attrs_value(qw(XMLDECL));
		my $encoding=defined $xmldecl ? $xmldecl->[1] : undef;
		$encoding='UTF-8' unless defined $encoding;
		return $encoding;
	}->();	
	$p->{STREAMER}=ref($fd) eq STREAM_CLASS 
		? $fd
		: sub {
			  ev('use ',STREAM_CLASS);
			  return STREAM_CLASS->new(OUTPUT_STREAM => $fd)
		}->();
	if ($encoding=~/utf[\-]{0,1}8/i) {
		$p->{STREAMER}->binmode(':encoding(UTF-8)');
		binmode(STDERR,':encoding(UTF-8)');
	}
	
	ev('use',$handle_class);
	$p->{HANDLE_OBJECT}=$handle_class->new(%$p);
	$self->{_PARAMS}=$p;

	my $objs=$p->{HANDLE_OBJECT}->get_binding_objects($p->{SCHEMA},%$p);
	if (defined $objs->[0]) {
		$p->{HANDLE_OBJECT}->header($objs->[0],%params) unless $p->{NO_HEADER_COMMENT};
	}

	if (grep($p->{COMMAND} eq $_,qw(drop_view create_view))) {
		my $cat=$self->{EXTRA_TABLES}->get_attrs_value(qw(CATALOG_INSTANCE));
		unless($cat->is_support_views) {
			print $fd $cat->comment("views not generated because database not support complex views"),"\n";
			return $self;
		}
	}

	
	$p->{HANDLE_OBJECT}->first_pass(%$p);
	if (grep($_ eq $p->{COMMAND},(qw(create_extra_tables drop_extra_tables)))) {
		my %tables=$p->{EXTRA_TABLES}->factory_extra_tables;
		for my $table(values %tables) {	
			$p->{HANDLE_OBJECT}->table_header($table,%params);
			for my $col($table->get_columns) {
				$p->{HANDLE_OBJECT}->column($col,%$p,TABLE => $table);
			}
			$p->{HANDLE_OBJECT}->table_footer($table,%params);
		}
	}
	elsif (grep($_ eq $p->{COMMAND},(qw(drop_sequence create_sequence)))) {
		$p->{HANDLE_OBJECT}->table_header($p->{EXTRA_TABLES});
	}
	else {
		affirm { defined $p->{SCHEMA} } "param SCHEMA not set";
		affirm { defined $params{SCHEMA_CODE} } "param SCHEMA_CODE not set";
		my %schema_code_list=(uc($params{SCHEMA_CODE}) => 1);
		$self->_cross_childs($p->{SCHEMA},%$p,SCHEMACODE_LIST => \%schema_code_list,FIRST_CALL => 1);
	}
	$p->{HANDLE_OBJECT}->last_pass(%$p);

	return $self;
}

sub _cross_childs {
	my ($self,$schema,%params)=@_;
	my $first_call=delete $params{FIRST_CALL};
	my $objs=$params{HANDLE_OBJECT}->get_binding_objects($schema,%params);
	for my $t(@$objs) {
		next unless defined $t;
		$self->_cross($t,%params,LEVEL => 0,SCHEMA => $schema);
	}
	$params{PARENT_SCHEMA_CODE}=$params{SCHEMA_CODE};
	$params{SCHEMA_CHILD_SEQ}=0;
	for my $h($schema->get_childs_schema) {
		my $t=$self->{EXTRA_TABLES}
			->get_attrs_value(qw(TABLE_CLASS))
			->new(NAME => $first_call ? 'CS0' : $params{SCHEMA_CODE});
		$params{SCHEMA_CODE}=$t->set_sql_name(TABLENAME_LIST => $params{SCHEMACODE_LIST});  #generate a uniq schema_code
		for my $k(qw(SCHEMA NAMESPACE LOCATION)) {
			$params{$k}=$h->{$k};
		}
		$params{HANDLE_OBJECT}->relation_schema(%params);
		$self->_cross_childs($h->{SCHEMA},%params);
		++$params{SCHEMA_CHILD_SEQ};
	}
	return $self;
}

sub new {
	my ($class,%params)=@_;
	affirm { ! defined $params{SQL_BINDING} } "param SQL_BINDING is obsolete";
	affirm { defined $params{BINDING} } "param BINDING not set";
	affirm { defined $params{EXTRA_TABLES} } "param EXTRA_TABLES not set";
	affirm { !defined $params{OUTPUT_NAMESPACE} } "param OUTPUT_NAMESPACE is reserved";
	affirm { !defined $params{DB_NAMESPACE} } "param DB_NAMESPACE is reserved";
	
	for my $k(qw(OUTPUT_NAMESPACE DB_NAMESPACE)) {
		affirm { $params{BINDING}->get_attrs_value($k) eq $params{EXTRA_TABLES}->get_attrs_value($k) }
			"incompatible '$k' attribute from EXTRA_TABLES and BINDING";
		$params{$k}=$params{BINDING}->get_attrs_value($k);
	}
	
	return bless \%params,$class;
}

sub get_namespaces {
	my %n=();
	for my $i(@INC) {
		my $dirgen=File::Spec->catdir($i,'blx','xsdsql','generator');
		next unless  -d "$dirgen";
		next if $dirgen=~/^\./;
		next unless opendir(my $fd,$dirgen);
		while(my $d=readdir($fd)) {
			next if $d=~/^\./;
			my $dirout=File::Spec->catdir($dirgen,$d);
			next unless -d $dirout;
			next unless opendir(my $fd1,$dirout);
			while(my $d1=readdir($fd1)) {
				next if $d1 eq 'generic';
				next if $d1=~/^\./;
				my $dirout=File::Spec->catdir($dirgen,$d,$d1);
				next unless -d $dirout;
				$n{$d.'::'.$d1}=undef;
			}
			closedir $fd1;
		}
		closedir($fd);
	}
	my @k=sort keys %n;
	return wantarray ? @k : \@k;
}

1;

__END__

=head1 NAME

blx::xsdsql::generator  -  generate the files for create table ,drop table ,add primary key,drop sequence,create sequence,drop view,create view

=head1 SYNOPSIS

use blx::xsdsql::generator


=head1 DESCRIPTION

this package is a class - instance it with the method new

=cut



=head1 VERSION

0.10.0

=cut

=head1 FUNCTIONS


new - constructor

    PARAMS
        BINDING                => binding instance
        EXTRA_TABLES        => extra tables instance


generate - generate a file

    PARAMS:
        SCHEMA                 => schema object generated by blx::xsdsql::parser::parse (is't not mandatory for generate the extra tables object)
        FD                  => streamer class, file descriptor  , array or string  (default *STDOUT)
        COMMAND              => create_table|drop_table|addpk|drop_sequence|create_sequence|drop_dictionary|drop_extra_tables|create_dictionary|create_extra_tables
                               for compatibility drop_dictionary is synonimous of drop_extra_tables and create_dictionary is synonimous od create_extra_tables
        LEVEL_FILTER          => <n> -  produce code only for tables at level <n> (n >= 0) - root has level 0  (default none)
        TABLES_FILTER          => [<name>] - produce code only for tables in  <name> - <name> is a table_name or a xml_path
        MAX_VIEW_COLUMNS     =>  produce view code only for views with columns number <= MAX_VIEW_COLUMNS -
                            -1 is a system limit (database depend)
                            false is no limit (the default)
        MAX_VIEW_JOINS         =>  produce view code only for views with join number <= MAX_VIEW_JOINS -
                            -1 is a system limit (database depend)
                            false is no limit (the default)
        NO_EMIT_COMMENTS    => if true not emit the sql comments - default false

    the method return a self to object



get_namespaces  - static method

    the method return an array of namespace founded




=head1 EXPORT

None by default.


=head1 EXPORT_OK

None

=head1 SEE ALSO


See blx::xsdsql::parser  for parse a xsd file (schema file) and blx::xsdsql::xml for read/write a xml file into/from a database

=head1 AUTHOR

lorenzo.bellotti, E<lt>pauseblx@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by lorenzo.bellotti

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut

