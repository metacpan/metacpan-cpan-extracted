#	@(#)buffer.pl	1.3	8/23/95
#
# Emulating 'client side buffering' in Sybperl.
#
# We create a new 'class' called Sybase::DBlib::Buffer which is derived from
# Sybase::DBlib. This allows us to override certain methods from the
# Sybase::DBlib package to implement a reasonable approximation of DBlibrary
# client side 'buffering' mode.

package Sybase::DBlib::Buffer;

use Sybase::DBlib;

# Inherit methods from the Sybase::DBlib package:
@ISA = qw(Sybase::DBlib);

# Browse mode dbresults:
# Call the 'normal' dbresults (ie the one in Sybase::DBlib), then, if
# the status is SUCCESS, initialize the data array which will
# hold the buffered rows.
sub dbresults
{
    my $self = shift;
    my $ret;

    $ret = $self->Sybase::DBlib::dbresults;

    # Add a new element to the DBPROCESS hash, which will
    # hold the data rows.
    $self->{BROWSE} = [] if $ret == SUCCESS;

    $ret;
}

# Browse mode dbnextrow:
# Sets the number of rows to be buffered in a new hash element,
# gets rid of the oldest row if we've already retrieved more than BROWSE_NROWS,
# then call Sybase::BDlib::dbnextrow to actually retrieve the next row,
# store it, and return it...
sub dbnextrow
{
    my($self, $doAssoc) = @_;   # doAssoc is IGNORED in this version!!!
    my(@data);

    $self->{BROWSE_NROWS} = 20 if(!defined($self->{BROWSE_NROWS}));

    shift(@{$self->{BROWSE}}) if($self->DBCURROW > $self->{BROWSE_NROWS});
    @data = $self->Sybase::DBlib::dbnextrow;
    push(@{$self->{BROWSE}}, \@data);

    @data;
}

sub DBFIRSTROW
{
    my $self = shift;
    my @data;

    @data = @{${$self->{BROWSE}}[0]};
    @data;
}

sub DBLASTROW
{
    my $self = shift;
    my @data;

    @data = @{${$self->{BROWSE}}[$#rows]};
    @data;
}

sub dbgetrow
{
    my $self = shift;
    my $row = shift;
    my $id, @data, @rows;

    @rows = @{$self->{BROWSE}};

    $id = $row - ($self->DBCURROW - $#rows) - 1;

    @data = @{$rows[$id]};
    @data;
}

package main;

# Test the Buffering mode emulation package

$d = new Sybase::DBlib::Buffer;

$d->dbcmd("select * from sysusers");
$d->dbsqlexec; $d->dbresults;
$i = 1;
while(@dd = $d->dbnextrow)
{
    print "$i: @dd\n";
    ++$i;
}

$rows = $d->DBCOUNT;
for($i = $rows; $i > $rows-20; --$i)
{
    @dd = $d->dbgetrow($i);
    print "$i: @dd\n";
}


    
    
