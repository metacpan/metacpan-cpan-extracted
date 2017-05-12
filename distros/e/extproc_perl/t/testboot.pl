# $Id: testboot.pl,v 1.9 2006/08/01 17:57:12 jeff Exp $

# test bootstrap file

use ExtProc qw(ora_exception ep_debug);
use DBI;

my $var;

sub ep_generic_func_noargs
{
    return "testing 1 2 3";
}

sub ep_generic_func_1arg
{
    my $arg = shift;
    return $arg;
}

sub ep_generic_proc_noargs
{
    # not much we can really do here...
    sleep(1);
}

sub ep_generic_proc_1arg
{
    my $arg = shift;
    die "expected 'testing 1 2 3', got '$arg'" if ($arg ne 'testing 1 2 3');
}

sub ep_direct_func_noargs
{
    return "testing 1 2 3";
}

sub ep_direct_func_1_in_varchar2
{
    my $arg = shift;
    return $arg;
}

sub ep_direct_proc_noargs
{
    # not much we can really do here...
    sleep(1);
}

sub ep_direct_proc_1_in_varchar2
{
    my $arg = shift;
    ep_debug("arg='$arg'");
    die "expected 'testing 1 2 3', got '$arg'" if ($arg ne 'testing 1 2 3');
}

sub ep_direct_proc_2_out_varchar2
{
    my ($x, $y) = @_;
    ${$x} = 'testing';
    ${$y} = '1 2 3';
}

sub ep_datatype_c
{
    return "testing 1 2 3";
}

sub ep_datatype_i
{
    return 123;
}

sub ep_datatype_r
{
    return 1.23;
}

sub ep_datatype_d
{
    my $date = new ExtProc::DataType::OCIDate;
    $date->setdate(2000, 1, 2);
    return $date;
}

sub ep_datatype_vIc
{
    my $arg = shift;
    die "expected 'testing 1 2 3', got '$arg'" unless ($arg eq 'testing 1 2 3');
}

sub ep_datatype_vBc
{
    my $arg = shift;
    ${$arg} .= ' 1 2 3';
}

sub ep_datatype_vOc
{
    my $arg = shift;
    ${$arg} = 'testing 1 2 3';
}

sub ep_datatype_vIi
{
    my $arg = shift;
    die "expected 123 got $arg" unless ($arg == 123);
}

sub ep_datatype_vBi
{
    my $arg = shift;
    ${$arg} *= 2;
}

sub ep_datatype_vOi
{
    my $arg = shift;
    ${$arg} = 123;
}

sub ep_datatype_vIr
{
    my $arg = sprintf("%2g", shift);
    die "expected 1.23, got $arg" unless ($arg == 1.23);
}

sub ep_datatype_vBr
{
    my $arg = shift;
    ${$arg} = sprintf("%2g", ${$arg} * 2.0);
}

sub ep_datatype_vOr
{
    my $arg = shift;
    ${$arg} = 1.23;
}

sub ep_datatype_vId
{
    my $arg = shift;
    die 'expected 2000-01-02' unless ($arg->to_char('YYYY-MM-DD') eq '2000-01-02');
}

sub ep_datatype_vBd
{
    my $arg = shift;
    my ($y, $m, $d) = $arg->getdate();
    $arg->setdate($y+1, $m+1, $d+1);
}

sub ep_datatype_vOd
{
    my $arg = shift;
    $arg->setdate(2000, 1, 2);
}

sub ep_dbname_via_callback
{
    my $e = ExtProc->new;
    my $dbh = $e->dbi_connect;
    my $sth = $dbh->prepare('SELECT ora_database_name FROM dual');
    my $dbname;
    if ($sth && $sth->execute()) {
        $dbname = ($sth->fetchrow_array)[0];
    }
    return $dbname;
}

sub ep_date_to_char
{
    my $arg = shift;
    return $arg->to_char('YYYY-MM-DD');
}

sub ep_date_getdate
{
    my $arg = shift;
    my ($y, $m, $d) = $arg->getdate();
    return "$y $m $d";
}

sub ep_date_setdate
{
    my $d = new ExtProc::DataType::OCIDate;
    $d->setdate(2000, 1, 2);
    return $d;
}

sub ep_date_gettime
{
    my $arg = shift;
    my ($h, $m, $s) = $arg->gettime();
    return "$h $m $s";
}

sub ep_date_settime
{
    my $d = new ExtProc::DataType::OCIDate;
    $d->settime(1, 2, 3);
    return $d;
}

sub ep_date_setdate_sysdate
{
    my $d = new ExtProc::DataType::OCIDate;
    $d->setdate_sysdate();
    return $d;
}
