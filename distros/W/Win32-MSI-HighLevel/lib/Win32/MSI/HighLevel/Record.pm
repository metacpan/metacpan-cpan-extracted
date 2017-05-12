use strict;
use warnings;
use File::Spec;

=head1 NAME

Win32::MSI::HighLevel::Record - Helper module for Win32::MSI::HighLevel.

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


package Win32::MSI::HighLevel::Record;

use Win32::API;
use Win32::MSI::HighLevel::Handle;
use Win32::MSI::HighLevel::Common;
use Carp;

use base qw(Win32::MSI::HighLevel::Handle);
use constant kMSI_NULL_INTEGER          => -0x80000000;
use constant kMSIMODIFY_SEEK            => -1;
use constant MSIMODIFY_REFRESH          => 0;
use constant kMSIMODIFY_INSERT          => 1;
use constant kMSIMODIFY_UPDATE          => 2;
use constant MSIMODIFY_ASSIGN           => 3;
use constant MSIMODIFY_REPLACE          => 4;
use constant MSIMODIFY_MERGE            => 5;
use constant MSIMODIFY_DELETE           => 6;
use constant MSIMODIFY_INSERT_TEMPORARY => 7;
use constant MSIMODIFY_VALIDATE         => 8;
use constant MSIMODIFY_VALIDATE_NEW     => 9;
use constant MSIMODIFY_VALIDATE_FIELD   => 10;
use constant MSIMODIFY_VALIDATE_DELETE  => 11;

# Table row states:
use constant kNoState => 0;
use constant kNew     => 1;
use constant kDirty   => 2;
use constant kClean   => 3;
use constant kDelete  => 4;

my $MsiCreateRecord        = Win32::MSI::HighLevel::Common::_def (MsiCreateRecord        => "I");
my $MsiFormatRecord        = Win32::MSI::HighLevel::Common::_def (MsiFormatRecord        => "IIPP");
my $MsiRecordGetFieldCount = Win32::MSI::HighLevel::Common::_def (MsiRecordGetFieldCount => "I");
my $MsiRecordGetInteger    = Win32::MSI::HighLevel::Common::_def (MsiRecordGetInteger    => "II");
my $MsiRecordGetString     = Win32::MSI::HighLevel::Common::_def (MsiRecordGetString     => "IIPP");
my $MsiRecordReadStream    = Win32::MSI::HighLevel::Common::_def (MsiRecordReadStream    => "IIPP");
my $MsiRecordSetInteger    = Win32::MSI::HighLevel::Common::_def (MsiRecordSetInteger    => "III");
my $MsiRecordSetString     = Win32::MSI::HighLevel::Common::_def (MsiRecordSetString     => "IIP");
my $MsiRecordSetStream     = Win32::MSI::HighLevel::Common::_def (MsiRecordSetStream     => "IIP");
my $MsiViewModify      = Win32::MSI::HighLevel::Common::_def (MsiViewModify      => 'III');
my $MsiRecordClearData = Win32::MSI::HighLevel::Common::_def (MsiRecordClearData => 'I');

my $INITIAL_EMPTY_STRING = "\0" x 1024;
my $ERROR_MORE_DATA      = 234;
my $COLTYPE_STREAM       = 1;
my $COLTYPE_INT          = 2;
my $COLTYPE_STRING       = 3;
my %COLTYPES             = (
    "i" => $COLTYPE_INT,
    "j" => $COLTYPE_INT,
    "s" => $COLTYPE_STRING,
    "g" => $COLTYPE_STRING,
    "l" => $COLTYPE_STRING,
    "v" => $COLTYPE_STREAM,
    );


sub new {
    my ($type, $view, %params) = @_;
    my $class = ref $type || $type;

    croak "Constructor requires a View object as the first parameter"
        if !$view->isa ('Win32::MSI::HighLevel::View');

    $params{fieldCount} = $view->getFieldCount ();
    $params{view} = $view;

    my $hdl = $MsiCreateRecord->Call ($params{fieldCount});

    return $class->SUPER::new ($hdl, %params);
}


sub fromHandle {
    my ($type, $hdl, $view, %params) = @_;
    my $class = ref $type || $type;

    croak "Constructor requires a View object as the second parameter"
        if defined $view and !$view->isa ('Win32::MSI::HighLevel::View');

    return $class->SUPER::new ($hdl, view => $view, %params);
}


# fromTable should be only called from derived class 'new' methods
sub fromTable {
    my ($type, $db, %params) = @_;
    my $class = ref $type || $type;

    croak
        "Constructor requires a HighLevel object as the second parameter"
        unless defined $db and $db->isa ('Win32::MSI::HighLevel::HighLevel');

    return new ($class, $db->view ($params{-table}), %params);
}


sub DESTROY {
    my $self = shift;

    $self->{view} = undef;
    $self->SUPER::DESTROY ();
}


sub getFieldCount {
    my $self = shift;

    return $self->{fieldCount} if exists $self->{fieldCount};

    $self->{fieldCount} = $MsiRecordGetFieldCount->Call ($self->{handle});
    croak "Bad handle" if $self->{fieldCount} == -1;

    return $self->{fieldCount};
}


sub getState {
    my $self = shift;

    return $self->{state};
}


sub setValue {
    my ($self, $column, $value) = @_;
    my $type = $self->{view}->columnType ($column);

    croak "Unknown column type $type for column $column"
        unless $type =~ /^(.)(\d+)?/i and lc ($1) =~ /([sliv])/i;

    if (lc ($1) eq 's' or lc ($1) eq 'l') {
        return $self->setString ($column, $value);
    } elsif (lc ($1) eq 'i') {
        return $self->setInteger ($column, $value);
    } elsif (lc ($1) eq 'v') {
        return $self->setStream ($column, $value);
    }
}


sub stream {
    my ($self, $column, $value) = @_;
    my $type = $self->{view}->columnType ($column);

    croak "Called for a non-stream column: $column ($1)"
        unless $type =~ /^(.)(\d+)?/i and ((my $width = $2), lc ($1) =~ /[v]/);

    croak "Called with a too long value for column: $column ($width)"
        if defined $value
        and $width
        and $width < length $value;

    return $self->setStream ($column, $value);
}


sub getStream {
    my ($self, $column, $value) = @_;

    if (0 != index $column, '#') {
        $column = $self->{view}->columnNumber ($column);
    } else {
        $column = substr $column, 1;
    }

    # $column is now the field number
    my $buffer = "\0" x 32768;
    my $length = pack ("l", 32768);                  # Initial size
    my $dir    = File::Spec->rel2abs ('binFiles');
    my $binNum = 1;

    mkdir $dir unless -d $dir;

    ++$binNum while -f "$dir\\bin$binNum";
    $value = "$dir\\bin$binNum";
    open my $StreamOut, '>:raw', $value or croak "File create failed: $!";

    while (
        0 == (
            $self->{result} =
                $MsiRecordReadStream->Call ($self->{handle}, $column, $buffer,
                $length)
        )
        )
    {

        $length = unpack ("l", $length);
        last unless $length;

        print $StreamOut substr $buffer, 0, $length;
        $length = pack ("l", 32768);
    }
    close $StreamOut;

    croak Win32::MSI::HighLevel::_errorMsg ($self)
        if $self->{result} and $self->{result} != $ERROR_MORE_DATA;

    $self->{state} ||= kClean;
    $self->{state} = kDirty
        if $self->{state} != kNew
        and (defined $self->{"\#$column"} != defined $value
        or defined $value && $self->{"\#$column"} ne $value);
    $self->{"\#$column"} = $value;
    return undef;
}


sub setStream {
    my ($self, $column, $value) = @_;

    if (0 != index $column, '#') {
        $column = $self->{view}->columnNumber ($column);
    } else {
        $column = substr $column, 1;
    }

    # $column is now the field number
    croak "Internal error: field number required" unless defined $column;

    # $value is the name of the file to insert into the stream
    croak "Internal error: file name required" unless defined $value;

    $self->{result} =
        $MsiRecordSetStream->Call ($self->{handle}, $column, $value);
    croak Win32::MSI::HighLevel::_errorMsg ($self)
        if $self->{result};

    $self->{state} ||= 0;
    $self->{state} = kDirty if $self->{state} != kNew;
    $self->{"\#$column"} = $value;
    return undef;
}


sub uncheckedString {
    my ($self, $column, $value) = @_;

    return $self->setString ($column, $value) if defined $value;

    if (0 != index $column, '#') {
        $column = $self->{view}->columnNumber ($column);
    } else {
        $column = substr $column, 1;
    }

    # $column is now the field number
    return $self->{"\#$column"}
        if exists $self->{"\#$column"} and defined $self->{"\#$column"};

    $self->{"\#$column"} = '';
    my $length = pack ("l", 0);    # Initial size

    $self->{result} =
        $MsiRecordGetString->Call ("$self->{handle}", $column,
        $self->{"\#$column"}, $length);
    croak Win32::MSI::HighLevel::_errorMsg ($self, $self->{result})
        if $self->{result} and $self->{result} != $ERROR_MORE_DATA;

    return $self->{"\#$column"} if !$self->{result};

    $length = unpack ("l", $length);

    if ($length) {
        my $size = $length * 2;    # length to UTF-16 size

        $self->{"\#$column"} = "\0" x $size;
        $self->{result} =
            $MsiRecordGetString->Call ($self->{handle}, $column,
            $self->{"\#$column"}, $size);
        croak "Error code $self->{result} for column $column"
            if $self->{result};

        # Now UTF-8 encoded, trim to $length
        $self->{"\#$column"} = substr $self->{"\#$column"}, 0, $length;
    } else {
        $self->{"\#$column"} = '';
    }

    return $self->{"\#$column"};
}


sub string {
    my ($self, $column, $value) = @_;
    my $type = $self->{view}->columnType ($column);

    croak "Non-string column: $column ($1)"
        unless $type =~ /^(.)(\d+)?/i and ((my $width = $2), lc ($1) =~ /[sl]/);

    croak "Too long value for column: $column ($width)"
        if defined $value
        and $width
        and $width < length $value;

    return $self->uncheckedString ($column, $value);
}


sub setString {
    my ($self, $column, $value) = @_;

    if (0 != index $column, '#') {
        $self->{"-$column"} = $value;
        $column = $self->{view}->columnNumber ($column);
    } else {
        $column = substr $column, 1;
    }

    # $column is now the field number
    $self->{result} =
        $MsiRecordSetString->Call ($self->{handle}, $column, $value)
        unless !defined $value;
    croak Win32::MSI::HighLevel::_errorMsg ($self)
        if $self->{result} and $self->{result} != $ERROR_MORE_DATA;

    $self->{state} ||= 0;
    $self->{state} = kDirty if $self->{state} != kNew;
    $self->{"\#$column"} = $value;
    return undef;
}


sub uncheckedInteger {
    my ($self, $column, $value) = @_;

    return $self->setInteger ($column, $value) if defined $value;

    if (0 != index $column, '#') {
        $column = $self->{view}->columnNumber ($column);
    } else {
        $column = substr $column, 1;
    }

    # $column is now the field number
    return $self->{"\#$column"}
        if exists $self->{"\#$column"} and defined $self->{"\#$column"};

    $self->{"\#$column"} = '';
    $self->{"\#$column"} =
        $MsiRecordGetInteger->Call ($self->{handle}, $column);
    return $self->{"\#$column"};
}


sub integer {
    my ($self, $column, $value) = @_;
    my $type = $self->{view}->columnType ($column);

    croak "Non-integer column: $column ($1)"
        unless $type =~ /^(.)(\d+)?/i and ((my $width = $2), lc ($1) eq 'i');

    return $self->uncheckedInteger ($column, $value);
}


sub setInteger {
    my ($self, $column, $value) = @_;

    if (0 != index $column, '#') {
        $column = $self->{view}->columnNumber ($column);
    } else {
        $column = substr $column, 1;
    }

    # $column is now the field number
    $self->{result} =
        $MsiRecordSetInteger->Call ($self->{handle}, $column, $value)
        unless !defined $value;
    croak Win32::MSI::HighLevel::_errorMsg ($self)
        if $self->{result} and $self->{result} != $ERROR_MORE_DATA;

    $self->{state} ||= 0;
    $self->{state} = kDirty if $self->{state} != kNew;
    $self->{"\#$column"} = $value;
    return undef;
}


sub update {
    my $self = shift;

    $self->{result} = $MsiViewModify->Call
        ($self->{view}{handle}, kMSIMODIFY_SEEK,$self->{handle});

    croak Win32::MSI::HighLevel::_errorMsg ($self) if $self->{result};

    if ($self->{state} == kDelete) {
        $self->{result} = $MsiViewModify->Call
            ($self->{view}{handle}, MSIMODIFY_DELETE, $self->{handle});
    } else {
        $self->writeFields ();
        $self->{result} = $MsiViewModify->Call
            ($self->{view}{handle}, kMSIMODIFY_UPDATE, $self->{handle});
        $self->{state} = kClean;
    }

    croak Win32::MSI::HighLevel::_errorMsg ($self) if $self->{result};
}


sub insert {
    my $self = shift;

    $self->writeFields ();
    $self->{result} =
        $MsiViewModify->Call ($self->{view}{handle}, kMSIMODIFY_INSERT,
        $self->{handle});
    croak "For table '$self->{view}{-table}':\n"
        . Win32::MSI::HighLevel::_errorMsg ($self)
        if $self->{result};
    $self->{state} = kClean;
}


sub writeFields {
    my $self     = shift;
    my %dispatch = (
        'i' => \&setInteger,
        'I' => \&setInteger,
        's' => \&setString,
        'S' => \&setString,
        'l' => \&setString,
        'L' => \&setString,
        'v' => \&setStream,
        'V' => \&setStream,
        );

    $self->{state} ||= kDirty;
    return if $self->{state} == kClean;

    for my $fieldNum (1 .. $self->getFieldCount ()) {
        my $column = "\#$fieldNum";
        my $type = substr $self->{view}->columnType ($column), 0, 1;

        croak "Can't handle field type $type for column $column"
            unless exists $dispatch{$type};

        $dispatch{$type}->($self, "#$fieldNum", $self->{$column});
    }
}


sub clearFields {
    my ($self, @fields) = @_;

    @fields = @{$self->{view}->columnNames ()} unless @fields;

    for my $field (@fields) {
        my $columnNumber = $self->{view}->columnNumber ($field);
        my $columnName   = $self->{view}->columnName   ($columnNumber);

        delete $self->{"#$columnNumber"};
        delete $self->{"-$columnName"};
    }

    $MsiRecordClearData->Call ($self->{handle});
}


sub populate {
    my ($self) = @_;
    my %dispatch = (
        'i' => \&integer,
        'I' => \&integer,
        's' => \&string,
        'S' => \&string,
        'l' => \&string,
        'L' => \&string,
        'v' => \&getStream,
        );

    for my $fieldNum (1 .. $self->getFieldCount ()) {
        my $field      = \$self->{"#$fieldNum"};
        my $length     = pack ("l", 0);
        my $type       = substr $self->{view}->columnType ("#$fieldNum"), 0, 1;
        my $columnName = $self->{view}->columnName ($fieldNum);

        next if $type eq 'O';
        croak
            "Can't handle field type $type for column $columnName (#$fieldNum)"
            unless exists $dispatch{$type};

        $self->{"-$columnName"} = $dispatch{$type}->($self, "#$fieldNum");
    }

    return unless defined $self->{view};

    for my $fieldNum (1 .. $self->getFieldCount ()) {
        my $columnName = $self->{view}->columnName ($fieldNum);

        $self->{"-$columnName"} = $self->{"#$fieldNum"};
    }

    $self->{state} = kClean;
}


1;


package Feature;

use Win32::MSI::HighLevel::Record;
use Carp;

use base qw(Win32::MSI::HighLevel::Record);


sub new {
    my ($type, $db, %params) = @_;
    my $class = ref $type || $type;

    croak "Constructor requires a HighLevel object as the first parameter"
        if !$db->isa ('Win32::MSI::HighLevel::HighLevel');

    croak
        "Constructor requires a -Feature parameter to provide a feature name"
        unless exists $params{-Feature};

    croak
        "Constructor requires a -parent parameter to provide a parent feature ref (it may be undef however)"
        unless exists $params{-Feature_Parent}
        and !defined ($params{-Feature_Parent})
        || 'Feature' eq ref $params{-Feature_Parent};

    $params{-Level}      ||= 0;
    $params{-Attributes} ||= 0;

    return $class->SUPER::fromTable ($db, -table => 'Feature', %params);
}


1;


package Win32::MSI::HighLevel::Shortcut;

use Win32::MSI::HighLevel::Record;
use Carp;

use base qw(Win32::MSI::HighLevel::Record);


sub new {
    my ($type, $db, %params) = @_;
    my $class = ref $type || $type;

    croak
        "Constructor requires a -Directory_ parameter to provide a directory key"
        unless exists $params{-Directory_};

    croak
        "Constructor requires a -Name parameter to provide a shortcut Name"
        unless exists $params{-Name};

    croak
        "Constructor requires a -Component_ parameter to provide a component key"
        unless exists $params{-Component_};

    croak "Constructor requires a -Target parameter."
        unless exists $params{-Target};

    return $class->SUPER::fromTable ($db, -table => 'Shortcut', %params);
}


package Win32::MSI::HighLevel::Directory;

use Win32::MSI::HighLevel::Record;
use Carp;

use base qw(Win32::MSI::HighLevel::Record);


sub new {
    my ($type, $db, %params) = @_;
    my $class = ref $type || $type;

    return $class->SUPER::fromTable ($db, -table => 'Directory', %params);
}


1;
