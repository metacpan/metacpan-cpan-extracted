package VSGDR::StaticData;

use strict;
use warnings;

use 5.010;

use List::Util qw(max);
use List::MoreUtils qw(any);
use POSIX qw(strftime);
use Carp;
use DBI;
use Data::Dumper;
use English;
if ($OSNAME eq 'MSWin32') {require Win32}

##TODO 1. Fix multi-column primary/unique keys.
##TODO 2. Check that non-key identity columns are handled correctly when they occur in the final position in the table.

=head1 NAME

VSGDR::StaticData - Static data script support package for SSDT post-deployment steps, Ded MedVed.

=head1 VERSION

Version 0.48

=cut

our $VERSION = '0.48';


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

    my ${LargeDataSetThreshhold}        = 30 ;

    local $_                            = undef;

    my $dbh                             = shift ;
    my $schema                          = shift ;
    my $table                           = shift ;

    croak "bad arg dbh"                 unless defined $dbh;
    croak "bad arg schema"              unless defined $schema;
    croak "bad arg table"               unless defined $table;

    $schema = substr $schema, 1, -1     if $schema =~ m/\A \[ .+ \] \Z /msix;
    $table  = substr $table,  1, -1     if $table  =~ m/\A \[ .+ \] \Z /msix;
    my $combinedName                    = "${schema}.${table}";
    my $quotedCombinedName              = "[${schema}].[${table}]";
    my $tableVarName                    = "LocalTable_${table}";

    my $quotedSchema                    = "[${schema}]";
    my $quotedTable                     = "[${table}]";

    my $database                        = databaseName($dbh);

    no warnings;
    my $userName                        = $OSNAME eq 'MSWin32' ? eval('Win32::LoginName') : ${[getpwuid( $< )]}->[6]; $userName =~ s/,.*//;
    use warnings;

    my $date                            = strftime "%d/%m/%Y", localtime;

    my $hasId                   = has_idCols($dbh,$schema,$table) ;
    my $idCol                   = undef ;
    if ($hasId) {
        $idCol                  = idCols($dbh,$schema,$table) ;
    }
#warn Dumper $idCol ;
    my $set_IDENTITY_INSERT_ON  = "";
    my $set_IDENTITY_INSERT_OFF = "";
    $set_IDENTITY_INSERT_ON     = "set IDENTITY_INSERT ${quotedCombinedName} ON"  if $hasId;
    $set_IDENTITY_INSERT_OFF    = "set IDENTITY_INSERT ${quotedCombinedName} OFF" if $hasId;


    my $ra_columns              = columns($dbh,$schema,$table);
#warn Dumper $quotedSchema,$quotedTable   ;
    my $ra_pkcolumns            = pkcolumns($dbh,$quotedSchema,$quotedTable);

    croak "${quotedCombinedName} doesn't appear to be a valid table"          unless scalar @{$ra_columns};

#warn Dumper $ra_columns ;
#exit ;

#    croak 'No Primary Key defined'          unless scalar @{$ra_pkcolumns};
#    croak 'Unusable Primary Key defined'    unless scalar @{$ra_pkcolumns} == 1;

    my @IsColumnNumeric = map { $_->[1] =~ m{uniqueidentifier|char|text|date}i ? 0 : 1 ;  } @{$ra_columns} ;
#warn Dumper $ra_columns;
#warn Dumper @IsColumnNumeric ;
#exit;

    my $primaryKeyCheckClause   = "";
    my $pk_column               = undef ; #$ra_pkcolumns->[0][0];
    #my @nonKeyColumns = grep { $_->[0][0] ne $pk_column } @{$ra_columns};

    my @nonKeyColumns           = () ;


    my $widest_column_name_len = max ( map { length ($_->[0]); } @{$ra_columns} ) ;
    my $widest_column_name_padding = int($widest_column_name_len/4) + 4;

    my $flatcolumnlist          = "" ;
    my $flatvariablelist        = "" ;
    foreach my $l (@{$ra_columns}) {
        do { local $" = "";   $flatcolumnlist           .= "[$l->[0]]" ; $flatcolumnlist .= ", "} ;
        do { local $" = "";   $flatvariablelist         .= "@"."$l->[0]" ; $flatvariablelist .= ","} ;
    }
    $flatcolumnlist             =~ s{ ,\s? \z }{}msx;
    $flatvariablelist           =~ s{ ,\s? \z }{}msx;


#warn Dumper @{$ra_pkcolumns} ;

    my $reportingPKCols                 = "" ;
    my $recordExistenceCheckSQL         = "" ;
    if ( ! scalar @{$ra_pkcolumns} ) {
        my @pk_ColumnsCheck = () ;
        foreach my $l (@{$ra_columns}) {
            my $varlen  = length($l->[0]) ;
            my $colpadding = $widest_column_name_padding - (int(($varlen)/4));
            my $varpadding = $widest_column_name_padding - (int(($varlen+1)/4));
            push @pk_ColumnsCheck , "([$l->[0]]" . "\t"x$varpadding . " = \@$l->[0]" . "\t"x$varpadding . "or ([$l->[0]]". "\t"x$varpadding . " is null and \@$l->[0] ". "\t"x$varpadding . " is null ) ) " ;
        }
        #my @pk_ColumnsCheck     = map { "( $_->[0]\t\t\t = \@$_->[0] or ( $_->[0]\t\t\t is null and \@$_->[0] is null ) ) " } @{$ra_columns} ;
        $primaryKeyCheckClause  = "where\t" . do { local $" = "\n\t\t\t\tand\t\t"; "@pk_ColumnsCheck" };

        $recordExistenceCheckSQL = <<"EOF";
if exists
                (
                select $flatvariablelist
                except
                select  ${flatcolumnlist}
                from    ${quotedCombinedName}
                )
EOF

    }
    elsif ( scalar @{$ra_pkcolumns} != 1 ) {

        my @pk_ColumnsCheck = () ;

        foreach my $l (@{$ra_pkcolumns}) {
            my $varlen  = length($l->[0]) ;
            my $colpadding = $widest_column_name_padding - (int(($varlen)/4));
            my $varpadding = $widest_column_name_padding - (int(($varlen+1)/4));
            push @pk_ColumnsCheck , "([$l->[0]]" . "\t"x$varpadding . " = \@$l->[0]" . "\t"x$varpadding . "or ([$l->[0]]". "\t"x$varpadding . " is null and \@$l->[0] ". "\t"x$varpadding . " is null ) ) " ;

        my @reportingPKCols         = map { "$_->[0]" } @{$ra_columns} ;
        $reportingPKCols            = do {local $" = ", "; "@reportingPKCols"} ;

#        my @pk_ColumnsCheck     = map { "$_->[0]\t\t\t = \@$_->[0]" } @{$ra_columns} ;
        }
        $primaryKeyCheckClause  = "where\t" . do { local $" = "\n\t\t\t\tand\t\t"; "@pk_ColumnsCheck" }  ;

        foreach my $col (@{$ra_columns}) {
#warn Dumper @{$ra_columns};
#warn Dumper $col;
            push @nonKeyColumns, $col unless grep {$_->[0] eq $col->[0] } @{$ra_pkcolumns} ;
        }
        $recordExistenceCheckSQL = <<"EOF";
if not exists
                (
                select  *
                from    ${quotedCombinedName}
                ${primaryKeyCheckClause}
                )
EOF
    }
    else {
        $reportingPKCols        = $ra_pkcolumns->[0][0];
        $pk_column              = $ra_pkcolumns->[0][0];
        $primaryKeyCheckClause  = "where   ${pk_column}        = \@${pk_column}";
        @nonKeyColumns = grep { $_->[0] ne $pk_column } @{$ra_columns};

        $recordExistenceCheckSQL = <<"EOF";
if not exists
                (
                select  ${flatcolumnlist}
                from    ${quotedCombinedName}
                ${primaryKeyCheckClause}
                )
EOF
    }


    my $variabledeclaration     = "declare\t" ;
    my $tabledeclaration        = "(\t\tStaticDataPopulationId\t\tint\tnot null identity(1,1)\n\t,\t\t" ;
    my $selectstatement         = "select\t" ;
    my $insertclause            = "insert into ${combinedName}\n\t\t\t\t\t\t(";
    my $valuesclause            = "values(";
#   my $flatcolumnlist             = "" ;
    my $flatExtractColumnList   = "" ;
#    my $flatvariablelist        = "" ;
    my $updateColumns           = "set\t";
    my $printStatement          = "" ;

#warn Dumper     $widest_column_name_len;
#warn Dumper     $widest_column_name_padding;
#warn Dumper @{$ra_columns};
    foreach my $l (@{$ra_columns}) {
        my $varlen  = length($l->[0]) ;
        my $colpadding = $widest_column_name_padding - (int(($varlen)/4));
        my $varpadding = $widest_column_name_padding - (int(($varlen+1)/4));
#warn Dumper     $l->[0];
#warn Dumper     $varlen;
#warn Dumper     $padding;
#warn Dumper $variabledeclaration;
#warn Dumper $varpadding;
#        do { local $" = "\t"; $variabledeclaration      .= "@"."@{$l}[0,1,2,3,5]" ; $variabledeclaration .= "\n\t,\t\t"} ;
        do { local $" = "\t"; $variabledeclaration      .= "@"."@{$l}[0]". "\t"x$varpadding . "$$l[1]" ."@{$l}[2,3]" ; $variabledeclaration .= "\n\t,\t\t"} ;
#        do { local $" = "\t"; $tabledeclaration         .= "@{$l}" ; $tabledeclaration .= "\n\t\t,\t"} ;
        do { local $" = "\t"; $tabledeclaration         .= "[@{$l}[0]]". "\t"x$colpadding . "[$$l[1]]" ."@{$l}[2,3,4,5]" ; $tabledeclaration .= "\n\t,\t\t"} ;
#        do { local $" = "";   $selectstatement          .= "@"."$l->[0]\t\t= $l->[0]" ; $selectstatement .= "\n\t\t,\t\t"} ;
        do { local $" = "";   $selectstatement          .= "@"."$l->[0]" . "\t"x$varpadding ."= [$l->[0]]" ; $selectstatement .= "\n\t\t,\t\t"} ;
        do { local $" = "";   $insertclause             .= "[$l->[0]]" ; $insertclause .= ", "} ;
        do { local $" = "";   $valuesclause             .= "[$l->[0]]" ; $valuesclause .= ", "} ;
#        do { local $" = "";   $flatcolumnlist           .= "[$l->[0]]" ; $flatcolumnlist .= ", "} ;
        do { local $" = "";   $flatExtractColumnList    .= $l->[1] =~ m{\A(?:date|datetime[2]?|smalldatetime)\z}i  ? "convert(varchar(30),[$l->[0]],120)" :  "[$l->[0]]" ; $flatExtractColumnList .= ", "} ;
#        do { local $" = "";   $flatvariablelist         .= "@"."$l->[0]" ; $flatvariablelist .= ","} ;

        do { local $" = "";   $printStatement           .= "'  $$l[0]: ' " ; } ;
        my $printFragment                               = $$l[1] !~ m{ (?: char ) }ixms
                                                                  ? "cast( \@$$l[0] as varchar(128))"
                                                                  : "\@$$l[0]" ;

        $printFragment   = " + case when ${printFragment} is null then 'NULL' else '''' + ${printFragment} + '''' end + " ;                                                                  ;
        $printStatement .= $printFragment ;
    }
    foreach my $l (@nonKeyColumns) {
        # create update statement for each non-identity column.
        if ( ! $hasId || ( $l->[0] ne $idCol ) ) {
#warn Dumper $l;
            do { local $" = "";   $updateColumns            .= "$l->[0]\t\t= "."@"."$l->[0]" ; $updateColumns .= "\n\t\t\t\t\t,\t"} ;
        }
        elsif($hasId)  {
            do { local $" = "";   $updateColumns            .= "/* cannot update this identity column -- $l->[0]\t\t= "."@"."$l->[0]" ; $updateColumns .= "\n\t\t\t\t\t,*/\t"} ;
        }
    }


    # trim off erroneous trailing cruft - better to resign array interpolations above .
    $variabledeclaration      =~ s{ \n\t,\t\t \z }{}msx;
    $tabledeclaration         =~ s{ \n\t,\t\t \z }{}msx;
    $selectstatement          =~ s{ \n\t\t,\t\t \z }{}msx;
    $updateColumns            =~ s{ \n\t\t\t,\t \z }{}msx;
    $insertclause             =~ s{ ,\s? \z }{}msx;
    $valuesclause             =~ s{ ,\s? \z }{}msx;
#    $flatcolumnlist           =~ s{ ,\s? \z }{}msx;
    $flatExtractColumnList    =~ s{ ,\s? \z }{}msx;
#    $flatvariablelist         =~ s{ ,\s? \z }{}msx;
    $updateColumns            =~ s{ \n\t\t\t\t\t,\t \z }{}msx;
    $printStatement           =~ s{ \+\s \z }{}msx;


    $tabledeclaration   .= "\n\t)";
    $insertclause       .= ")";
    $valuesclause       .= ")";

    my $insertingPrintStatement = "print 'Inserting ${combinedName}:' + " . $printStatement ;
    my $updatingPrintStatement  = "print 'Updating ${combinedName}: ' + " . $printStatement;


#    my $ra_data = getCurrentTableData($dbh,$combinedName,$pk_column,$flatcolumnlist);
#    my $ra_data = getCurrentTableData($dbh,$quotedCombinedName    ,$pk_column,$flatcolumnlist);
    my $ra_data = getCurrentTableData($dbh,$quotedCombinedName    ,$pk_column,$flatExtractColumnList);

    my @valuesTable     ;
    my $valuesClause    = "values\n\t\t\t";

    my $lno             = 1;
    foreach my $ra_row (@{$ra_data}){
    #    warn Dumper $ra_row;
        my @outVals = undef ;
#warn Dumper @{$ra_row} ;
#exit;
        for ( my $i = 0; $i < scalar @{$ra_row}; $i++ ) {
#warn Dumper $ra_row->[$i] ;
#warn Dumper $IsColumnNumeric[$i] ;
#            $ra_row->[$i] = ( defined $ra_row->[$i] ) ? $ra_row->[$i] : "null" ;

            if ( ( $IsColumnNumeric[$i] == 1 ) and ( not ( defined ($ra_row->[$i]) ) ) ) {
                $outVals[$i] = 'null' ;
            }
            if ( ( $IsColumnNumeric[$i] == 0 ) and ( not ( defined ($ra_row->[$i]) ) ) ) {
                $outVals[$i] = 'null' ;
            }
            if ( ( $IsColumnNumeric[$i] == 1 ) and (     ( defined ($ra_row->[$i]) ) ) ) {
                $outVals[$i] = $ra_row->[$i]  ;
            }
            if ( ( $IsColumnNumeric[$i] == 0 ) and (     ( defined ($ra_row->[$i]) ) ) ) {
                if (${$ra_columns}[$i][1] =~ m{\A(?:date|datetime[2]?|smalldatetime)\z}i) {
                    $outVals[$i] = "convert(". ${$ra_columns}[$i][1] ."," . $dbh->quote($ra_row->[$i]) . ",120)"   ;
                }
                else {
                    $outVals[$i] = $dbh->quote($ra_row->[$i])  ;
                }
            }
        }
        push @valuesTable, \@outVals ;
        #my @outVals = map { $ColumnNumericity{$_} == 1 ? $_ : $dbh->quote($_)  } @{$ra_row};
        my $line = do{ local $" = ", "; "@outVals" } ;
        #$valuesClause    .= "(\t" . $line . ")" . "\n\t\t,\t" ;
        $lno++;
    }

    my @maxWidth;
    my $maxCol;

    if ( scalar @valuesTable ) {
        my @tmp = @{$valuesTable[0]};
        $maxCol = scalar @tmp -1 ;
        for ( my $i = 0; $i <= $maxCol; $i++ ) {
            push @maxWidth, 0;
        }
        for ( my $i = 0; $i < scalar @valuesTable; $i++ ) {
            my @tmp = @{$valuesTable[$i]};
            for ( my $i = 0; $i <= $maxCol; $i++ ) {
                if (length($tmp[$i]) > $maxWidth[$i] ) {
                    $maxWidth[$i] = length($tmp[$i]) ;
                }
            }
        }
    }

    #warn Dumper @maxWidth ;

    for ( my $i = 0; $i < scalar @valuesTable; $i++ ) {
        my @tmp = @{$valuesTable[$i]};
        my $line = "";
        for ( my $j = 0; $j <= $maxCol; $j++ ) {
            my $val    = $tmp[$j];
            my $valWidth = length($val);
            my $PadLength = $maxWidth[$j]-$valWidth;
            my $padding = " "x$PadLength;
            $line .= ", ${padding}${val}";
        }
        $line =~ s{ ^,\s}{}msx;
        $valuesClause    .= "(\t" . $line . ")" . "\n\t\t,\t" ;
    }

    $valuesClause        =~ s{ \n\t\t,\t \z }{}msx;


    my $noopPrintStatement      = "'Nothing to update. Values are unchanged.'";
    my $printNoOpStatement      = "print ${noopPrintStatement}" ;
    if ( ${pk_column} ) {
        $noopPrintStatement     = "'Nothing to update. ${combinedName}: Values are unchanged for Primary/Unique Key: '";
        $printNoOpStatement     = "print ${noopPrintStatement} + cast(\@${reportingPKCols} as varchar(1000)) "
    }

    my $elsePrintSection        = <<"EOF";
else  begin
                ${printNoOpStatement}
            end
EOF

    if ( scalar @{$ra_data} > ${LargeDataSetThreshhold}  ){
        $insertingPrintStatement = "" ;
        $updatingPrintStatement  = "" ;
        $elsePrintSection        = "" ;
    }

    my ${elseBlock} = "";

    if ( scalar @nonKeyColumns ) {
        ${elseBlock} = <<"EOF";

        -- if the static data doesn''t match what is already there then update it.
        -- 'except' handily handles null as equal.  Saves some extensive twisted logic.
        else begin
            if exists
                (
                select  ${flatcolumnlist}
                from    $quotedCombinedName
                ${primaryKeyCheckClause}
                except
                select  ${flatvariablelist}
                ) begin
                $updatingPrintStatement
                if \@DeploySwitch = 1 begin
                    update  s
                    ${updateColumns}
                    from    $quotedCombinedName s
                    ${primaryKeyCheckClause}
                end
                set \@ChangedCount += 1 ;
            end
        ${elsePrintSection}
        end
EOF
    }


    my $tmp_sv = substr(${table},0,20) ;
    my $savePointName = "sc_${tmp_sv}_SP";

    my ${printChangedTotalsSection} = "" ;
#warn Dumper @nonKeyColumns ;

    if ( scalar @{$ra_data} > ${LargeDataSetThreshhold}  ){
        $printChangedTotalsSection        = "print 'Total count of inserted records : ' + cast( \@InsertedCount as varchar(10))" ;
        $printChangedTotalsSection        .= "\n\tprint 'Total count of altered records  : ' + cast( \@ChangedCount as varchar(10))" ;
    }


return <<"EOF";

/****************************************************************************************
 * Database:    ${database}
 * Author  :    ${userName}
 * Date    :    ${date}
 * Purpose :    Static data deployment script for ${combinedName}
 *
 *
 * Version History
 * ---------------
 * 1.0.0    ${date} ${userName}
 * Created.
 ***************************************************************************************/

set nocount on

declare  \@DeployCmd                varchar(20)
        ,\@DeploySwitch             bit

set     \@DeployCmd                 = '\$(StaticDataDeploy)'
set     \@DeploySwitch              = 0
--Check whether a deploy has been stated.
if isnull(upper(\@DeployCmd) , '') <> 'DEPLOY'
    begin
        set \@DeploySwitch = 0 --FALSE, only run a dummy deploy where no actual data will be modified.
        print 'Deploy Type: Dummy Deploy (No data will be changed)'
    end
else
    begin
        set \@DeploySwitch = 1 --TRUE, run real deploy.
        print 'Deploy Type: Actual Deploy'
    end



begin try

    -- Declarations
    declare \@ct                       int
    ,       \@i                        int
    ,       \@InsertedCount            int = 0
    ,       \@ChangedCount             int = 0

    declare \@localTransactionStarted bit;


    begin transaction
    save transaction ${savePointName} ;

    set \@localTransactionStarted       = 1;

    declare \@${tableVarName} table
    ${tabledeclaration}

    ; with src as
    (
    select *
    from    ( ${valuesClause}
            ) AS vtable
    ( $flatcolumnlist)
    )
    insert  into
            \@${tableVarName}
    (       ${flatcolumnlist}
    )
    select  ${flatcolumnlist}
    from    src

    ${variabledeclaration}




    -- count how many records need to be inserted
    select \@ct = count(*) from \@${tableVarName}

    set \@i = 1
    -- insert the records into the ${table} table if they don't already exist, otherwise update them
    while \@i <=\@ct begin

        ${selectstatement}
        from    \@${tableVarName}
        where   StaticDataPopulationId\t\t= \@i

        ${recordExistenceCheckSQL}
            begin
            $insertingPrintStatement
            if \@DeploySwitch = 1 begin
                ${set_IDENTITY_INSERT_ON}
                ${insertclause}
                values (${flatvariablelist})
                ${set_IDENTITY_INSERT_OFF}
            end
            set \@InsertedCount += 1 ;
        end
        ${elseBlock}

        set \@i=\@i+1
    end

    commit


    ${printChangedTotalsSection}

end try
begin catch

    -- if xact_state() = -1 then the transaction isn't recorded in \@\@trancount so check both
    if \@\@trancount > 0 or xact_state() = -1 begin
        if xact_state() = -1
            rollback; -- we can't do anything else
        -- Rollback any locally begun transaction to savepoint.  Don't fail the whole deployment if it's transactional.
        -- If our transaction is the only one, then just rollback.
        if \@\@trancount > 1 begin
            if \@localTransactionStarted is not null and \@localTransactionStarted = 1 begin
                rollback transaction ${savePointName};
                commit ; --  windback our local transaction completely
            end;
            --else it's probably nothing to do with us. but we have to rollback anyway
            else
                rollback;
        end
        else begin
            -- final check to see if we need to unwind the transaction
            if \@\@trancount > 0
                rollback;
        end;
    end;

    print 'Deployment of ${combinedName} static data failed.  This script was rolled back.';
    print error_message();

    ${set_IDENTITY_INSERT_OFF};


end catch

go


EOF

}

sub generateTestDataScript {

    local $_                            = undef;

    my $dbh                             = shift ;
    my $schema                          = shift ;
    my $table                           = shift ;
    my $sql                             = shift ;
    my $use_MinimalForm                 = shift ;
    my $use_IgnoreNulls                 = shift ;

    croak "bad arg dbh"                 unless defined $dbh;
    croak "bad arg schema"              unless defined $schema;
    croak "bad arg table"               unless defined $table;
    croak "bad arg sql"                 unless defined $sql;
    croak "bad arg minimal form"        unless defined $use_MinimalForm;
    croak "bad arg ignore nulls"        unless defined $use_IgnoreNulls;

    $schema = substr $schema, 1, -1     if $schema =~ m/\A \[ .+ \] \Z /msix;
    $table  = substr $table,  1, -1     if $table  =~ m/\A \[ .+ \] \Z /msix;
    my $combinedName                    = "${schema}.${table}";
    my $quotedCombinedName              = "[${schema}].[${table}]";

    my $quotedSchema                    = "[${schema}]";
    my $quotedTable                     = "[${table}]";

    my $database                        = databaseName($dbh);

    my $hasId                           = has_idCols($dbh,$schema,$table) ;
    my $idCol                           = undef ;
    if ($hasId) {
        $idCol                          = idCols($dbh,$schema,$table) ;
    }
#warn Dumper $idCol ;
    my $set_IDENTITY_INSERT_ON  = "";
    my $set_IDENTITY_INSERT_OFF = "";
    $set_IDENTITY_INSERT_ON     = "set IDENTITY_INSERT ${quotedCombinedName} ON"  if $hasId;
    $set_IDENTITY_INSERT_OFF    = "set IDENTITY_INSERT ${quotedCombinedName} OFF" if $hasId;


    my $ra_columns              = columns($dbh,$schema,$table);

    croak "${quotedCombinedName} doesn't appear to be a valid table"          unless scalar @{$ra_columns};


    my @IsColumnNumeric         = map { $_->[1] =~ m{uniqueidentifier|char|text|date}i ? 0 : 1 ;  } @{$ra_columns} ;
    my @nonKeyColumns           = () ;

    my $widest_column_name_len      = max ( map { length ($_->[0]); } @{$ra_columns} ) ;
    my $widest_column_name_padding  = int($widest_column_name_len/4) + 4;

    my $flatvariablelist        = "" ;
    foreach my $l (@{$ra_columns}) {
        do { local $" = "";   $flatvariablelist         .= "@"."$l->[0]" ; $flatvariablelist .= ","} ;
    }
    $flatvariablelist           =~ s{ ,\s? \z }{}msx;

    foreach my $l (@{$ra_columns}) {
        my $varlen  = length($l->[0]) ;
        my $colpadding = $widest_column_name_padding - (int(($varlen)/4));
        my $varpadding = $widest_column_name_padding - (int(($varlen+1)/4));
    }

    my $flatExtractColumnList   = "" ;

    foreach my $l (@{$ra_columns}) {
        my $varlen      = length($l->[0]) ;
        my $colpadding  = $widest_column_name_padding - (int(($varlen)/4));
        my $varpadding  = $widest_column_name_padding - (int(($varlen+1)/4));
        do { local $" = "";   $flatExtractColumnList    .= $l->[1] =~ m{\A(?:date|datetime[2]?|smalldatetime)\z}i  ? "convert(varchar(30),[$l->[0]],120)" :  "[$l->[0]]" ; $flatExtractColumnList .= ", "} ;

    }

    $flatExtractColumnList    =~ s{ ,\s? \z }{}msx;

#warn Dumper $flatExtractColumnList;
#warn Dumper $ra_columns;

    my $ra_metadata = describeTestDataForTable($dbh,$sql,$ra_columns);
    my @cols = map { $$_[0] } @$ra_metadata ;

    my $ra_data     = getTestDataForTable($dbh,$quotedCombinedName,\@cols,$sql);

#warn Dumper $ra_data;    
#warn Dumper $$ra_data[0];    
#warn Dumper @cols;
#warn Dumper @$ra_metadata;
   
    my @useColumnValues   = ();

    #look over data and try to find the slices which are empty
    if ($use_IgnoreNulls) {
        @useColumnValues   = map { 0 } @$ra_metadata ;
        foreach my $ra_row (@{$ra_data}){
            for ( my $i = 0; $i < scalar @{$ra_row}; $i++ ) {
                if ( ( defined ($ra_row->[$i]) ) ) {
                    $useColumnValues[$i] = 1 ;
                }
            }
        }
    }
    else {
        @useColumnValues   = map { 1 } @$ra_metadata ;
    }

    my $colList = "" ;#do { local $" = "," ; "@cols" } ;

    my $i =0;
    foreach my $c (@cols)
    {
        if ($useColumnValues[$i]) {
            if ( ! scalar($colList) ) {
                $colList = "${c}"
            }
            else {
                $colList .= ",${c}"
            }
        }
        $i++;
    }

#warn Dumper $colList;
#exit;
    #need to overlay tables with columns apart from those which are 'hidden'
    my @valuesTable     ;
    my $valuesClause    = "values\n\t\t\t";

    my $lno             = 1;
    foreach my $ra_row (@{$ra_data}){
        my @outVals = undef ;
        for ( my $i = 0; $i < scalar @{$ra_row}; $i++ ) {
            if ($useColumnValues[$i]) {
            if ( not ( defined ($ra_row->[$i]) ) ) {
                $outVals[$i] = 'null' ;
            }
            else {
                if (${$ra_metadata}[$i][1] =~ m{\A(?:date|datetime[2]?|smalldatetime)\z}i) {
                    $outVals[$i] = "convert(". ${$ra_columns}[$i][1] ."," . $dbh->quote($ra_row->[$i]) . ",120)"   ;
                }
                elsif ( ${$ra_metadata}[$i][1] =~ m{(?:uniqueidentifier|char|text|date)}i)  {
                    $outVals[$i] = $dbh->quote($ra_row->[$i])  ;
                }
                else {
                    $outVals[$i] = $ra_row->[$i] ;
                }
            }
            }
        }
        push @valuesTable, \@outVals ;
        #my $line = do{ local $" = ", "; "@outVals" } ;
        $lno++;
    }

    my @maxWidth;
    my $maxCol;

    if ( scalar @valuesTable ) {
        my @tmp = @{$valuesTable[0]};
        $maxCol = scalar @tmp -1 ;
        for ( my $i = 0; $i <= $maxCol; $i++ ) {
            push @maxWidth, 0;
        }
        for ( my $i = 0; $i < scalar @valuesTable; $i++ ) {
            my @tmp = @{$valuesTable[$i]};
            for ( my $i = 0; $i <= $maxCol; $i++ ) {
                if ($useColumnValues[$i]) {
                if (length($tmp[$i]) > $maxWidth[$i] ) {
                    $maxWidth[$i] = length($tmp[$i]) ;
                }
                }
            }
        }
    }

    #warn Dumper @maxWidth ;

    for ( my $i = 0; $i < scalar @valuesTable; $i++ ) {
        my @tmp             = @{$valuesTable[$i]};
        my $line            = "";
        for ( my $j = 0; $j <= $maxCol; $j++ ) {
            if ($useColumnValues[$j]) {

            my $val         = $tmp[$j];
            my $valWidth    = length($val);
            my $PadLength   = $maxWidth[$j]-$valWidth;
            my $padding     = " "x$PadLength;
            $line           .= ", ${padding}${val}";
            }
        }
        $line               =~ s{ ^,\s}{}msx;
        $valuesClause       .= "(\t" . $line . ")" . "\n\t\t,\t" ;
    }

    $valuesClause           =~ s{ \n\t\t,\t \z }{}msx;

    if ( ! $use_MinimalForm) {
return <<"EOF";

    ${set_IDENTITY_INSERT_ON}
    ; with src as
    (
    select  *
    from    ( ${valuesClause}
            ) AS vtable
    ( ${colList})
    )
    insert  into
            ${quotedCombinedName}
    (       ${colList}
    )
    select  ${colList}
    from    src ;
    ${set_IDENTITY_INSERT_OFF}

EOF
    }
    else {
        ${valuesClause} =~ s{\A values\n\t\t\t }{\t\t,\t}msx;
return <<"EOF";
${valuesClause}
EOF

    }
}

sub describeTestDataForTable {

    local $_ = undef ;

    my $dbh             = shift or croak 'no dbh' ;
    my $sql             = shift or croak 'no sql' ;
    my $ra_validColumns = shift or croak 'no valid columns' ;

    ( my $quoted_sql    = $sql ) =~ s{'}{''}g;

    my $metadata_sql    = "exec sp_describe_first_result_set N'${quoted_sql}'" ;

    my $sth2            = $dbh->prepare($metadata_sql);
    my $rs              = $sth2->execute();
    my $res             = $sth2->fetchall_arrayref() ;

#warn Dumper  @$ra_validColumns  ;
#warn Dumper @$res  ;

    my @filteredRes     = grep { my $col = $_; if ( any { $$_[0] eq $$col[2] } @$ra_validColumns) { $col } } @$res;
#warn Dumper @filteredRes  ;
#exit;
    my @ret_res         = map { [($$_[2],$$_[5],$$_[3],$$_[1])] } @filteredRes;

#warn Dumper @ret_res  ;

    return \@ret_res ;

}

sub getTestDataForTable {

    local $_ = undef ;

    my $dbh          = shift or croak 'no dbh' ;
    my $combinedName = shift or croak 'no table' ;
    my $cols         = shift or croak 'no cols list' ;
    my $sql          = shift or croak 'no sql' ;

#warn Dumper "SQL  = ", $sql;    
#warn Dumper "COLS = ", $cols;
my %cols = map {$_ => 1 } @$cols;
#warn Dumper getCurrentTableDataSQL($combinedName,$pkCol,$cols);
#warn Dumper %cols;
    my $sth2 = $dbh->prepare($sql);
    my $rs   = $sth2->execute();
#    my $res  = $sth2->fetchall_arrayref() ;
    my $res  = $sth2->fetchall_arrayref(\%cols) ;

#warn Dumper $res;
my @res2 = ();
my $li=0;
foreach my $row (@$res) {
    
#warn Dumper $row;
    my $ci = 0;
    foreach my $c (@$cols) {
       $res2[$li][$ci] = $$row{$c};
       $ci++;
    }
    $li++;
    }
#warn Dumper \@res2;
    return \@res2 ;

}

sub getCurrentTableData {

    local $_ = undef ;

    my $dbh          = shift or croak 'no dbh' ;
    my $combinedName = shift or croak 'no table' ;
    my $pkCol        = shift ; #or croak 'no primary key' ;
    my $cols         = shift ; #or croak 'no primary key' ;

#warn Dumper getCurrentTableDataSQL($combinedName,$pkCol,$cols);

    my $sth2 = $dbh->prepare(getCurrentTableDataSQL($combinedName,$pkCol,$cols));
    my $rs   = $sth2->execute();
    my $res  = $sth2->fetchall_arrayref() ;

    return $res ;

}

sub getCurrentTableDataSQL {

    local $_ = undef ;

    my $combinedName = shift or croak 'no table' ;
    my $pkCol        = shift ; #or croak 'no primary key' ;
    my $cols         = shift ; #or croak 'no primary key' ;

    my $orderBy      = "" ;

    if ( ! $pkCol ) {
        $orderBy = "" ;
    }
    else {
        $orderBy = "order   by        $pkCol" ;
    }

return <<"EOF" ;

select  ${cols}
from    ${combinedName} so
${orderBy}

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

    my $dbh         = shift or croak 'no dbh' ;
    my $qtd_schema  = shift or croak 'no schema' ;
    my $qtd_table   = shift or croak 'no table' ;

    my $schema  = $qtd_schema ;
    my $table   = $qtd_table ;

       $schema  =~ s/\A\[(.*)\]\z/$1/;
       $table   =~ s/\A\[(.*)\]\z/$1/;

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
    my $rs      = $sth2->execute($schema,$table,"[${schema}]","[${table}]");
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
,       isnull(case	when lower(Data_type) = 'float'
				then '('+cast(Numeric_precision as varchar(10))+')'
				when lower(Data_type) not like '%int%' and lower(Data_type) not like '%money%' and Numeric_precision is not null
				then '('+cast(Numeric_precision as varchar(10))+','+cast(Numeric_scale as varchar(10))+')'
				else ''
				end
				,'')
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
--order by ORDINAL_POSITION

EOF

}






__DATA__



=head1 SYNOPSIS

Package to support the generation of static data population scripts for SQL Server Data Tools post-deployment steps.

=head1 AUTHOR

Ded MedVed, C<< <dedmedved@cpan.org> >>


=head1 BUGS


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc VSGDR::StaticData


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2013 Ded MedVed.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of StaticData
