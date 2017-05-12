# $Id: Code.pm,v 1.51 2006/08/11 13:27:35 jeff Exp $

package ExtProc::Code;

use 5.6.1;
use strict;
use warnings;
use AutoLoader 'AUTOLOAD';

require Exporter;

our @ISA = qw(Exporter);
our %EXPORT_TAGS = ( 'all' => [ qw(
    &create_extproc
    &import_code
    &drop_code
) ] );
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT = qw(
);
our $VERSION = '2.51';

use ExtProc qw(ep_debug put_line);
use File::Spec;
use DBI;
use Parse::RecDescent;

# for external procedure parameters
our %typemap = (
    'PLS_INTEGER' => 'int',
    'REAL' => 'float',
    'VARCHAR2' => 'string',
    'DATE' => 'OCIDate'
);

# type signatures
our %signature = (
    'VARCHAR2'    => 'c',
    'PLS_INTEGER' => 'i',
    'REAL'        => 'r',
    'DATE'        => 'd',
);

# a persistent Parse::RecDescent parser
our $parser;

1;

__END__

### AUTOLOADED SUBROUTINES ###

# create_extproc(spec,[lib])
# create external procedure based on spec and optional library
sub create_extproc
{
    my ($spec, $lib) = @_;

    # parse the spec
    my $attrs = parse_spec($spec);
    die "invalid specification: $spec" unless $attrs;
    my $sig = args2sig($attrs->{'returntype'}, $attrs->{'args'});

    # set function to call
    my $retsig = substr($sig, 0, 1);
    my $func = "ep_call_";
    if ($retsig eq 'v') {
        $func .= 'proc';
    }
    else {
        $func .= "func_$retsig";
    }

    # generate DDL
    my $sql;
    my $ddl_format = ExtProc::config('ddl_format');
    if ($ddl_format == 0) {
        $sql = 'CREATE OR REPLACE ';
    }
    else {
        $sql = "-- for package specification\n$spec\n";
        $sql .= "-- for package body\n";
    }
     
    $sql .= $attrs->{'calltype'};
    $sql .= " $attrs->{'name'}(";
    foreach my $arg (@{$attrs->{'args'}}) {
        my ($name, $dir, $type) = @{$arg};
        $sql .= "$name $dir $type, ";
    }
    $sql .= "ep_sub IN VARCHAR2 := '$attrs->{'name'}', ep_sig IN VARCHAR2 := '$sig')\n";

    if ($attrs->{'calltype'} eq 'FUNCTION') {
        $sql .= "RETURN $attrs->{'returntype'}\n";
    }

    $sql .= "AS EXTERNAL NAME \"$func\"\n";
    $sql .= "LIBRARY \"" . ($lib ? $lib : "PERL_LIB") . "\"\n";
    $sql .= "WITH CONTEXT\n";
    $sql .= "PARAMETERS (\n";
    $sql .= "   CONTEXT";
    if ($attrs->{'calltype'} eq 'FUNCTION') {
        $sql .= ",\n   RETURN INDICATOR BY REFERENCE"
    }

    $sql .= ",\n   ep_sub string";
    $sql .= ",\n   ep_sig string";

    foreach my $arg (@{$attrs->{'args'}}) {
        my ($name, $dir, $type) = @{$arg};
        $sql .= ",\n   $name $typemap{uc($type)}";
        $sql .= ",\n   $name INDICATOR short";
        if (uc($type) eq 'VARCHAR2') {
            $sql .= ",\n   $name LENGTH sb4";
            if ($dir =~ /OUT/i) {
                $sql .= ",\n   $name MAXLEN sb4";
            }
        }
    }

    $sql .= "\n);";
    if ($ddl_format == 0) {
        $sql .= "\n/\n";
    }

    # write DDL to file
    local *DDL;
    my $trusted_dir = ExtProc::config('trusted_code_directory');
    open(DDL, '>', File::Spec->catfile($trusted_dir, $attrs->{'name'} . '.sql' ))
        or die $!;
    print DDL "$sql\n";
    close(DDL);

    # output DDL ("set serveroutput on" to see it in sqlplus)
    #put_line($_) foreach (split(/[\r\n]+/, $sql));
}

# import_code(name, [filename], [spec])
# import code from a file in the trusted code directory and optionally create
# a C wrapper based on the supplied spec
sub import_code
{
    my ($name, $file, $spec) = @_;

    # DML -- MUST BE CALLED AS A PROCEDURE
    if (!ExtProc::is_procedure) {
        ExtProc::ora_exception('import_code must be called as a procedure!');
        return;
    }

    if ($name eq '') {
        ExtProc::ora_exception('import_code: empty subroutine name');
        return;
    }

    # untaint arguments, since we're being called from oracle
    if ($name =~ /^([A-z\d\-_]+)$/) {
        $name = $1;
    }
    else {
        ExtProc::ora_exception('illegal characters in subroutine name');
        return;
    }
    if ($file =~ /^([\w\.\-\_]+)$/) {
        $file = $1;
    }
    elsif (!defined($file)) {
        $file = "${name}.pl";
    }
    else {
        ExtProc::ora_exception('illegal characters in filename');
        return;
    }

    # what's our code table and trusted code directory?
    my $table = ExtProc::config('code_table');
    my $dir = ExtProc::config('trusted_code_directory');

    my $path = File::Spec->catfile($dir, $file);
    my $size = (stat($path))[7];
    if ($size > ExtProc::config('max_code_size')) {
        ExtProc::ora_exception("file too large for import ($size bytes)");
        return;
    }

    # read code from file
    my ($code, $line);
    local *CODE;
    open(CODE, $path) or die "failed to open code file: $!";
    while(defined($line = <CODE>)) {
        $code .= $line;
    }
    close(CODE);

    # get current version number, if any
    my $dbh = ExtProc->dbi_connect;
    my $sth = $dbh->prepare("select nvl(version, 0) from $table where name = ?");
    $sth->execute($name);
    ExtProc::ep_debug("rows=".$sth->rows);
    my $version = ($sth->fetchrow_array)[0];
    $sth->finish;

    # delete existing code if it exists
    $sth = $dbh->prepare("delete from $table where name = ?");
    $sth->execute($name);
    $sth->finish;

    # find spec, if any
    if (!$spec && $code =~ /^((?:FUNCTION|PROCEDURE)\s+$name.*)/im) {
        $spec = $1;
    }

    # import code into database, incrementing version
    $sth = $dbh->prepare("insert into $table (name, plsql_spec, language, version, code) values(?, ?, 'Perl5', ?, ?)");
    $sth->execute($name, $spec, $version+1, $code);
    $sth->finish;

    # create C wrapper if we have a spec
    $spec && create_extproc($spec);
}

# drop_code(name)
# silently remove code from code table
sub drop_code
{
    my $name = shift;

    # DML -- MUST BE CALLED AS A PROCEDURE
    if (!ExtProc::is_procedure) {
        ExtProc::ora_exception('drop_code must be called as a procedure!');
        return;
    }

    # what's our code table?
    my $table = ExtProc::config('code_table');

    my $dbh = ExtProc->dbi_connect;
    my $sth = $dbh->prepare("delete from $table where name = ?");
    $sth->execute($name);
    $sth->finish;
}

sub parse_spec
{
    my $spec = shift;

    # clear args, which may carry over from previous invocation
    @ExtProc::Parser::args = ();
    
    unless ($parser) {
        $parser = new Parse::RecDescent(q{
            datatype: 'VARCHAR2' | 'PLS_INTEGER' | 'REAL' | 'DATE'

            direction: 'IN' | 'OUT'

            name: /[\w_]+/

            argument: name direction(s) datatype
                { $return = [$item[1], join(' ', @{$item[2]}), $item[3]]; }

            arglist: '(' argument(s /,/) ')'
                { @ExtProc::Parser::args = @{$item[2]}; }

            spec2: name arglist(?)
                { $ExtProc::Parser::callname = $item[1]; }

            procedure: 'PROCEDURE' spec2
                { $ExtProc::Parser::calltype = 'PROCEDURE';
                  $ExtProc::Parser::returntype = undef;
                  1; }

            function: 'FUNCTION' spec2 'RETURN' datatype
                { $ExtProc::Parser::calltype = 'FUNCTION';
                  $ExtProc::Parser::returntype = $item[4]; }

            spec: procedure | function

            startrule: spec
        });
    }

    my $res = $parser->startrule($spec);
    return undef unless $res;

    return ({
        calltype   => $ExtProc::Parser::calltype,
        returntype => $ExtProc::Parser::returntype,
        name       => $ExtProc::Parser::callname,
        args       => [@ExtProc::Parser::args]
    });
}

sub args2sig
{
    my ($returntype, $argref) = @_;
    my @args = @{$argref};
    my $sig = (defined $returntype) ? $signature{$returntype} : 'v';
    foreach my $i (0..$#args) {
        if (uc($args[$i]->[1]) eq 'OUT') {
            $sig .= "O$signature{$args[$i]->[2]}";
        }
        elsif (uc($args[$i]->[1]) eq 'IN OUT') {
            $sig .= "B$signature{$args[$i]->[2]}";
        }
        else {
            $sig .= "I$signature{$args[$i]->[2]}";
        }
    }
    return $sig;
}
