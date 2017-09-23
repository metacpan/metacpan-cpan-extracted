package VSGDR::MergeData;

use strict;
use warnings;

use 5.010;

use List::Util qw(max);
use POSIX qw(strftime);
use Carp;
use DBI;
use Data::Dumper;
use English;
use Win32;

##TODO 1. Fix multi-column primary/unique keys.
##TODO 2. Check that non-key identity columns are handled correctly when they occur in the final position in the table.

=head1 NAME

VSGDR::MergeData - Static data script support package for SSDT post-deployment steps, Ded MedVed.

=head1 VERSION

Version 0.03

=cut

our $VERSION = '0.03';


sub databaseName {

    local $_    = undef ;

    my $dbh     = shift ;

    my $sth2    = $dbh->prepare(databaseNameSQL());
    my $rs      = $sth2->execute();
    my $res     = $sth2->fetchall_arrayref() ;

    return $$res[0][0] ;

}

sub databaseNameSQL {

return <<"EOF" ;

select  db_name()

EOF

}

sub dependency {

    local $_    = undef ;

    my $dbh     = shift ;

    my $sth2    = $dbh->prepare( dependencySQL());
    my $rs      = $sth2->execute();
    my $res     = $sth2->fetchall_arrayref() ;

    if ( scalar @{$res} ) { return $res ; } ;
    return [] ;
}



sub dependencySQL {

return <<"EOF" ;
select  distinct
        tc2.TABLE_CATALOG               as to_CATALOG
,       tc2.TABLE_SCHEMA                as to_SCHEMA 
,       tc2.TABLE_NAME                  as to_NAME   
,       tc1.TABLE_CATALOG               as from_CATALOG
,       tc1.TABLE_SCHEMA                as from_SCHEMA
,       tc1.TABLE_NAME                  as from_NAME
,       rc.CONSTRAINT_NAME              as to_CONSTRAINT
from    INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS rc
join    INFORMATION_SCHEMA.TABLE_CONSTRAINTS tc1
on      tc1.CONSTRAINT_SCHEMA           = rc.CONSTRAINT_SCHEMA
and     tc1.CONSTRAINT_CATALOG          = rc.CONSTRAINT_CATALOG
and     tc1.CONSTRAINT_NAME             = rc.CONSTRAINT_NAME
join    INFORMATION_SCHEMA.TABLE_CONSTRAINTS tc2
on      tc2.CONSTRAINT_SCHEMA           = rc.CONSTRAINT_SCHEMA
and     tc2.CONSTRAINT_CATALOG          = rc.CONSTRAINT_CATALOG
and     tc2.CONSTRAINT_NAME             = rc.UNIQUE_CONSTRAINT_NAME

EOF

}


sub generateScript {

    local $_                            = undef;
            
    my $dbh                             = shift ;
    my $src_schema                      = shift ;
    my $src_table                       = shift ;
    my $targ_schema                     = shift ;
    my $targ_table                      = shift ;
    my $script_type                     = shift ;

    croak "bad arg dbh"                 unless defined $dbh;
    croak "bad arg source schema"       unless defined $src_schema;
    croak "bad arg source table"        unless defined $src_table;
    croak "bad arg target schema"       unless defined $targ_schema;
    croak "bad arg target table"        unless defined $targ_table;

    $src_schema  = substr $src_schema, 1, -1     if $src_schema  =~ m/\A \[ .+ \] \Z /msix;
    $src_table   = substr $src_table,  1, -1     if $src_table   =~ m/\A \[ .+ \] \Z /msix;
    $targ_schema = substr $targ_schema, 1, -1    if $targ_schema =~ m/\A \[ .+ \] \Z /msix;
    $targ_table  = substr $targ_table,  1, -1    if $targ_table  =~ m/\A \[ .+ \] \Z /msix;
                  
    my $combinedSourceName              = "${src_schema}.${src_table}"; 
    my $quotedCombinedSourceName        = "[${src_schema}].[${src_table}]"; 
    my $combinedTargetName              = "${targ_schema}.${targ_table}"; 
    my $quotedCombinedTargetName        = "[${targ_schema}].[${targ_table}]"; 

    my $database                        = databaseName($dbh);

    no warnings;
    my $userName                        = $OSNAME eq 'MSWin32' ? Win32::LoginName : ${[getpwuid( $< )]}->[6]; $userName =~ s/,.*//;
    use warnings;
    
    use warnings;                      
    my $date                            = strftime "%d/%m/%Y", localtime;



    my $hasId                   = has_idCols($dbh,$targ_schema,$targ_table) ;
    my $idCol                   = undef ;
    if ($hasId) {
        $idCol                  = idCols($dbh,$targ_schema,$targ_table) ;
    }

    my $ra_columns              = columns($dbh,$targ_schema,$targ_table);
    my $ra_pkcolumns            = pkcolumns($dbh,$targ_schema,$targ_table);

    croak "${combinedTargetName} doesn't appear to be a valid table"          unless scalar @{$ra_columns};
    
#warn Dumper $ra_columns ;
#exit ;

#    croak 'No Primary Key defined'          unless scalar @{$ra_pkcolumns};
#    croak 'Unusable Primary Key defined'    unless scalar @{$ra_pkcolumns} == 1;

    my @IsColumnNumeric = map { $_->[1] =~ m{char|text|date}i ? 0 : 1 ;  } @{$ra_columns} ;

    my $primaryKeyCheckClause   = "";
    my @nonKeyColumns ;
    foreach my $col (@{$ra_columns}) {
        push @nonKeyColumns, $col unless grep {$_->[0] eq $col->[0] } @{$ra_pkcolumns} ;
    }
        

    my $onclause                = do {local $" = " and "; "@{[map {\"tgt.$_->[0]  =  src.$_->[0]\"} @$ra_pkcolumns]}" };

    my $insertclause    = "(" . do {local $" = ", "; "@{[map {\"[$_->[0]]\"} @$ra_columns]}"         } . ")";
    my $valuesclause    = "(" . do {local $" = ", "; "@{[map {\"src.[$_->[0]]\"} @$ra_columns]}" } . ") ";

    my $fullUpdateClause = "" ;
    my $exceptClause  = "select "         . do {local $" = ", "; "@{[map {\"tgt.[$_->[0]]\"} @nonKeyColumns]}" };
       $exceptClause .= " except select " . do {local $" = ", "; "@{[map {\"src.[$_->[0]]\"} @nonKeyColumns]}" };
    
    if ( scalar @nonKeyColumns > 0 ) {
        $fullUpdateClause ="when matched and exists (select * from (${exceptClause}) x )\n    then update\n    set     " . do {local $" = "\n    ,       "; "@{[map {\"tgt.[$_->[0]]\t\t=  src.[$_->[0]]\"} @nonKeyColumns]}" };
    }

    my $maxCol;
    
    #warn Dumper @maxWidth ;
    
    

return <<"EOF";

/****************************************************************************************
 * Database:    ${database}
 * Author  :    ${userName}
 * Date    :    ${date}
 * Purpose :    Merge statement usp for ${combinedTargetName}
 *              
 *
 * Version History
 * ---------------
 * 1.0.0    ${date} ${userName}
 * Created.
 ***************************************************************************************/  

create procedure [${src_schema}].[usp_merge_${src_table}]
as
begin

set nocount on ;
set xact_abort on;

begin try

    merge   into
            ${quotedCombinedTargetName} as tgt
    using   ${quotedCombinedSourceName} as src
    on      ${onclause}
    when not matched by target then
    insert  ${insertclause}
    values  ${valuesclause}
    ${fullUpdateClause}
    when not matched by source then delete ;
    
end try
begin catch

    if \@\@trancount > 0 or xact_state() = -1 begin
        rollback;
        throw;
    end;

end catch
end ;
go


EOF

}


sub idCols {

    local $_ = undef ;
    
    my $dbh    = shift or croak 'no dbh' ;
    my $schema = shift or croak 'no schema' ;
    my $table  = shift or croak 'no table' ;

    my $sth2 = $dbh->prepare(idColsSQL());
    my $rs   = $sth2->execute($schema,$table);
    my $res  = $sth2->fetchall_arrayref() ;

    return $$res[0][0] ;

}

sub idColsSQL {

return <<"EOF" ;

select  sc.name as ID_COL
FROM    dbo.sysobjects so
join    dbo.syscolumns sc
on      so.id               = sc.id
and     sc.colstat & 1      = 1
where   schema_name(so.uid) = ?
and     so.name             = ?

EOF

}

sub has_idCols {

    local $_ = undef ;
    
    my $dbh     = shift or croak 'no dbh' ;
    my $schema  = shift or croak 'no schema' ;
    my $table   = shift or croak 'no table' ;

    my $sth2 = $dbh->prepare(has_idColsSQL());
    my $rs   = $sth2->execute($schema,$table);
    my $res  = $sth2->fetchall_arrayref() ;

    return $$res[0][0] ;

}

sub has_idColsSQL {

return <<"EOF" ;

select  1 as ID_COL
FROM    dbo.sysobjects so
where   schema_name(so.uid) = ?
and     so.name             = ?
and     exists (
        select *
        from dbo.syscolumns sc
        where so.id = sc.id
        and   sc.colstat & 1 = 1
        )
EOF

}


sub pkcolumns {

    local $_    = undef ;
    
    my $dbh     = shift or croak 'no dbh' ;
    my $schema  = shift or croak 'no schema' ;
    my $table   = shift or croak 'no table' ;

    my $sth2    = $dbh->prepare( pkcolumnsSQL());
    my $rs      = $sth2->execute($schema,$table,$schema,$table);
    my $res     = $sth2->fetchall_arrayref() ;

    if ( scalar @{$res} ) { return $res ; } ;
    return [] ;
}



sub pkcolumnsSQL {

return <<"EOF" ;

; with ranking as (
select  CONSTRAINT_SCHEMA, CONSTRAINT_NAME
,       row_number() over (order by case when tc.CONSTRAINT_TYPE = 'PRIMARY KEY' then 1 else 2 end, CONSTRAINT_NAME )  as rn
        from    INFORMATION_SCHEMA.TABLE_CONSTRAINTS tc
where   tc.CONSTRAINT_TYPE          in( 'PRIMARY KEY','UNIQUE' )
and     tc.TABLE_SCHEMA             = ?
and     tc.TABLE_NAME               = ?
)
select  COLUMN_NAME 
from    INFORMATION_SCHEMA.TABLE_CONSTRAINTS tc
join    INFORMATION_SCHEMA.KEY_COLUMN_USAGE  kcu
on      tc.TABLE_CATALOG            = kcu.TABLE_CATALOG
and     tc.TABLE_SCHEMA             = kcu.TABLE_SCHEMA
and     tc.TABLE_NAME               = kcu.TABLE_NAME
and     tc.CONSTRAINT_NAME          = kcu.CONSTRAINT_NAME
join    ranking rk 
on      tc.CONSTRAINT_SCHEMA        = rk.CONSTRAINT_SCHEMA
and     tc.CONSTRAINT_NAME          = rk.CONSTRAINT_NAME
where   tc.CONSTRAINT_TYPE          in( 'PRIMARY KEY','UNIQUE' )
and     tc.TABLE_SCHEMA             = ?
and     tc.TABLE_NAME               = ?
and     rn = 1
order   by      
        ORDINAL_POSITION

EOF

}


sub columns {

    local $_    = undef ;

    my $dbh     = shift or croak 'no dbh' ;
    my $schema  = shift or croak 'no schema' ;
    my $table   = shift or croak 'no table' ;

    my $sth2    = $dbh->prepare( columnsSQL());
    my $rs      = $sth2->execute($schema,$table,$schema,$table);
    my $res     = $sth2->fetchall_arrayref() ;

    if ( scalar @{$res} ) { return $res ; } ;
    return [] ;
}



sub columnsSQL {

return <<"EOF" ;
select  Column_name 
,       data_type
,       case when character_maximum_length is not null then '('+ case when character_maximum_length = -1 then 'max' else cast(character_maximum_length as varchar(10)) end+')' else '' end 
        as datasize
,       case	when lower(Data_type) = 'float'
				then '('+cast(Numeric_precision as varchar(10))+')' 
				when lower(Data_type) not like '%int%' and Numeric_precision is not null 
				then '('+cast(Numeric_precision as varchar(10))+','+cast(Numeric_scale as varchar(10))+')' 
				else '' 
				end 
        as dataprecision
,       case when DATABASEPROPERTYEX(db_name(), 'Collation') != collation_name then 'collate ' + collation_name else '' end 
        as collation
,       case when LOWER(IS_NULLABLE) = 'no' then 'not null' else 'null' end
        as datanullabity
from    INFORMATION_SCHEMA.COLUMNS
where   1=1
and     TABLE_SCHEMA        = ?
and     TABLE_NAME          = ?
and     COLUMNPROPERTY(object_id(?+'.'+?) , COLUMN_NAME,'IsComputed') != 1
EOF

}






__DATA__



=head1 SYNOPSIS

Package to support the generation of data import merge statements.

=head1 AUTHOR

Ded MedVed, C<< <dedmedved@cpan.org> >>


=head1 BUGS


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc VSGDR::MergeData


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2017 Ded MedVed.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of MergeData
