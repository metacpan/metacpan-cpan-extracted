use strict;
use warnings;

=head1 NAME

Win32::MSI::HighLevel::View - Helper module for Win32::MSI::HighLevel.

=head1 AUTHOR

    Peter Jaquiery
    CPAN ID: GRANDPA
    grandpa@cpan.org

=head1 COPYRIGHT & LICENSE

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut

BEGIN {
    use Exporter ();
    use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
    @ISA         = qw(Exporter);
    @EXPORT      = qw();
    @EXPORT_OK   = qw();
    %EXPORT_TAGS = ();
}


package Win32::MSI::HighLevel::View;

use Win32::API;
use Win32::MSI::HighLevel::Handle;
use Win32::MSI::HighLevel::Common qw(kMSICOLINFO_NAMES kMSICOLINFO_TYPES);
use Win32::MSI::HighLevel::Record;
use Carp;

use base qw(Win32::MSI::HighLevel::Handle);

my $MsiViewExecute = Win32::MSI::HighLevel::Common::_def(MsiViewExecute => "II");
my $MsiDatabaseOpenView = Win32::MSI::HighLevel::Common::_def(MsiDatabaseOpenView => "IPP");
my $MsiViewClose = Win32::MSI::HighLevel::Common::_def(MsiViewClose => "I");
my $MsiViewFetch = Win32::MSI::HighLevel::Common::_def(MsiViewFetch => "IP");
my $MsiViewGetColumnInfo = Win32::MSI::HighLevel::Common::_def(MsiViewGetColumnInfo => "IIP");
my $ERROR_NO_MORE_ITEMS = 259;


# View caches column name to number mapping and column name to type mapping.
#   Column numbers are keyed by columnName#
#   Column types are keyed by columnName!

sub new {
    my ($type, $highLevel, %params) = @_;
    my $class = ref $type || $type;

    croak "Constructor requires a HighLevel object as the first parameter"
        unless defined $highLevel and $highLevel->isa ('Win32::MSI::HighLevel');

    my $hdl = Win32::MSI::HighLevel::Handle->null ();

    $params{result} = $MsiDatabaseOpenView->Call
        ($highLevel->{handle}, $params{query}, $hdl);

    croak Win32::MSI::HighLevel::_errorMsg ($highLevel)
        if $params{result};

    my $self = $class->SUPER::new ($hdl, %params, highLevel => $highLevel);

    $hdl = Win32::MSI::HighLevel::Handle->null ();
    $self->{result} = $MsiViewExecute->Call ($self->{handle}, 0);

    croak Win32::MSI::HighLevel::_errorMsg ($self, $self->{result})
        if $self->{result};

    return $self;
}


sub DESTROY {
    my $self = shift;

    $self->{highLevel} = undef;
    $self->SUPER::DESTROY ();
}


sub createRecord {
    my $self = shift;

    return Win32::MSI::HighLevel::Record->new ($self);
}


sub fetch {
    my $self = shift;

    my $hdl = Win32::MSI::HighLevel::Handle->null ();
    my %params;

    $params{result} = $MsiViewFetch->Call ($self->{handle}, $hdl);
    return undef if $params{result} == $ERROR_NO_MORE_ITEMS;
    croak Win32::MSI::HighLevel::_errorMsg ($self)
        if $params{result};

    ++$self->{fetched};
    return Win32::MSI::HighLevel::Record->fromHandle ($hdl, $self, %params, recnum => $self->{fetched});
}


sub columnNames {
    # Return name given number
    my ($self, $columnNumber) = @_;

    $self->getColumnInfo () unless exists $self->{columns};
    return $self->{columns}{names};
}


sub columnName {
    # Return name given number
    my ($self, $columnNumber) = @_;

    $self->getColumnInfo () unless exists $self->{columns};
    return exists $self->{columns}{"#$columnNumber"} ?
        $self->{columns}{"#$columnNumber"} : undef;
}


sub columnNumber {
    # Return number given name or number
    my ($self, $column) = @_;

    $self->getColumnInfo () unless exists $self->{columns};

    return exists $self->{columns}{"#$column"} ? $column : undef
        if $column =~ s/^#(?=\d+$)//;

    return exists $self->{columns}{"$column#"} ? $self->{columns}{"$column#"} : undef;
}


sub columnType {
    # Return type given name or number
    my ($self, $column) = @_;

    my $colNum = $self->columnNumber ($column);
    unless (defined $colNum) {
        croak "Not a valid table column: $column for table $self->{-table}";
    }

    $self->getColumnInfo () unless exists $self->{columns};
    return exists $self->{columns}{"$colNum!"} ?
        $self->{columns}{"$colNum!"} : undef;
}


sub getFieldCount {
    my $self = shift;

    $self->getColumnInfo () unless exists $self->{columns};
    return $self->{columns}{fieldCount};
}


sub getColumnInfo {
    my $self = shift;
    my $hdl = Win32::MSI::HighLevel::Handle->null ();

    return if exists $self->{columns};

    # Get the names and field (column) count
    $self->{result} = $MsiViewGetColumnInfo->Call
        ($self->{handle}, Win32::MSI::HighLevel::Common::kMSICOLINFO_NAMES, $hdl);
    croak Win32::MSI::HighLevel::_errorMsg ($self)
        if $self->{result};

    my $colRec = Win32::MSI::HighLevel::Record->fromHandle ($hdl, $self);

    $self->{columns}{fieldCount} = $colRec->getFieldCount ();

    for (1 .. $self->{columns}{fieldCount}) {
        my $name = $colRec->uncheckedString ("\#$_");

        $self->{columns}{$name . '#'} = $_;
        $self->{columns}{"#$_"} = $name;
        push @{$self->{columns}{names}}, $name;
    }

    $hdl = Win32::MSI::HighLevel::Handle->null ();

    # Get the types
    $self->{result} = $MsiViewGetColumnInfo->Call
        ($self->{handle}, Win32::MSI::HighLevel::Common::kMSICOLINFO_TYPES, $hdl);
    croak Win32::MSI::HighLevel::_errorMsg ($self)
        if $self->{result};

    $colRec = Win32::MSI::HighLevel::Record->fromHandle ($hdl, $self);
    $self->{columns}{"$_!"} = $colRec->uncheckedString ("\#$_")
        for 1 .. $self->{columns}{fieldCount};
}


1;
