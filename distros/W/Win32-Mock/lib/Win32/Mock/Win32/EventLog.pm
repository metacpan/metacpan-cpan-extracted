package # hide from PAUSE
        Win32::EventLog;
use strict;
use warnings;
use Carp;
use Exporter ();

{
    no strict;
    $VERSION = "0.01";
    @ISA = qw(Exporter);
    @EXPORT = qw(
        EVENTLOG_AUDIT_FAILURE
        EVENTLOG_AUDIT_SUCCESS
        EVENTLOG_BACKWARDS_READ
        EVENTLOG_END_ALL_PAIRED_EVENTS
        EVENTLOG_END_PAIRED_EVENT
        EVENTLOG_ERROR_TYPE
        EVENTLOG_FORWARDS_READ
        EVENTLOG_INFORMATION_TYPE
        EVENTLOG_PAIRED_EVENT_ACTIVE
        EVENTLOG_PAIRED_EVENT_INACTIVE
        EVENTLOG_SEEK_READ
        EVENTLOG_SEQUENTIAL_READ
        EVENTLOG_START_PAIRED_EVENT
        EVENTLOG_SUCCESS
        EVENTLOG_WARNING_TYPE
    );
}

use vars qw($GetMessageText);
use constant {
    TRUE   => !!1,
    FALSE  => !!0,

    ELF_LOG_SIGNATURE               => 0x654c664c,

    # Event Types
    EVENTLOG_SUCCESS                => 0x0000,
    EVENTLOG_ERROR_TYPE             => 0x0001,
    EVENTLOG_WARNING_TYPE           => 0x0002,
    EVENTLOG_INFORMATION_TYPE       => 0x0004,
    EVENTLOG_AUDIT_SUCCESS          => 0x0008,
    EVENTLOG_AUDIT_FAILURE          => 0x0010,

    # ReadEventLog() flags
    EVENTLOG_SEQUENTIAL_READ        => 0x0001,
    EVENTLOG_SEEK_READ              => 0x0002,
    EVENTLOG_FORWARDS_READ          => 0x0004,
    EVENTLOG_BACKWARDS_READ         => 0x0008,

    # don't know what these are, and can't find the actual values
    EVENTLOG_START_PAIRED_EVENT     => 0x0001,
    EVENTLOG_PAIRED_EVENT_ACTIVE    => 0x0002,
    EVENTLOG_PAIRED_EVENT_INACTIVE  => 0x0004,
    EVENTLOG_END_PAIRED_EVENT       => 0x0008,
    EVENTLOG_END_ALL_PAIRED_EVENTS  => 0x0010,
};


# singleton for storing events
my %main_eventlog = (
    # HOSTNAME => {
    #     SOURCE => [
    #         {
    #             Category  => ...,
    #             EventType => ..., 
    #             EventID   => ...,
    #             Data      => ...,
    #             Strings   => ...,
    #         }, 
    #         {
    #             ...
    #         }, 
    #     ]
    # }
);

# index of last read record
my $last_read_record = 0;

#use XXX; END { YYY \%main_eventlog }


# 
# new()
# ---
sub new {
    my ($class, $source, $computer) = @_;
    $class = ref $class if ref $class;
    croak "error: missing source" unless $source;
    my $handle;

    # create new handle
    if ($source =~ /\\/) {
        OpenBackupEventLog($handle, $computer, $source);
    }
    else {
        OpenEventLog($handle, $computer, $source)
    }

    #$handle ||= ( $main_eventlog{$computer}{$source} ||= [] );

    my $self = bless {
            handle => $handle,  Source => $source,  Computer => $computer
        }, $class;

    return $self
}


sub DESTROY {
    shift->Close
}


# 
# Open()
# ----
sub Open {
    $_[0] = Win32::EventLog->new($_[1], $_[2]);
}


# 
# OpenBackup()
# ----------
sub OpenBackup {
    my ($class, $source, $computer) = @_;

    OpenBackupEventLog(my $handle, $computer, $source);

    my $self = bless {
            handle => $handle,  Source => $source,  Computer => $computer
        }, $class;

    return $self
}


# 
# Backup()
# ------
sub Backup {
    my ($self, $filename) = @_;
    die " usage: OBJECT->Backup(FILENAME)\n" unless @_ == 2;
    return BackupEventLog($self->{handle}, $filename);
}


# 
# Close()
# -----
sub Close {
    my ($self) = @_;
    CloseEventLog($self->{handle});
    $self->{handle} = 0;
}


# 
# Read()
# ----
sub Read {
    my ($self, $flags, $offset, $entry_r) = @_;

    # fetch the event
    my $rc = ReadEventLog(
        $self->{handle}, $flags, $offset, 
        # these variables are set by ReadEventLog():
        my $header, my $source, my $computer, my $sid, my $data, my $strings
    );

    # decode the header
    my ($length, $reserved, $record_number, $time_generated, $time_written,
        $event_id, $event_type, $num_strings, $event_category, $reserved_flags,
        $closing_record_number, $string_offset, $user_sid_length, $user_sid_offset,
        $data_length, $data_offset) = unpack("l6s4l6", $header);

    # make a hash out of the values returned from ReadEventLog()
    my %record = (
        Source          => $source,
        Computer        => $computer,
        RecordNumber    => $record_number, 
        TimeGenerated   => $time_generated,
        Timewritten     => $time_written,
        Category        => $event_category, 
        EventType       => $event_type,
        EventID         => $event_id,
        User            => $sid,
        Strings         => $strings,
        Data            => $data,
        Length          => $data_length,
        ClosingRecordNumber => $closing_record_number,
    );

    # get the text message here
    if ($rc and $GetMessageText) {
        GetEventLogText($source, $event_id, $strings, $num_strings, my $message);
        $record{Message} = $message;
    }

    if (ref $entry_r eq 'HASH') {
        %{$entry_r} = %record       # needed for the Read(..., \%foo) case
    }
    else {
        $_[2] = \%record
    }

    return $rc
}


# 
# GetMessageText()
# --------------
sub GetMessageText {
    my ($self) = @_;
    
    GetEventLogText(
        $self->{Source}, $self->{EventID}, $self->{Strings},
        $self->{Strings} =~ tr/\0/\0/,  my $message
    );

    $self->{Message} = $message;
    return $message
}


# 
# Report()
# ------
sub Report {
    my ($self, $EventInfo) = @_;
    die "usage: OBJECT->Report( HASHREF )\n" unless @_ == 2;
    die "Win32::EventLog::Report requires a hash reference as arg 2\n"
        unless ref($EventInfo) eq "HASH";

    my $computer = $EventInfo->{Computer} ? $EventInfo->{Computer}
                                          : $self->{Computer};
    my $source   = exists($EventInfo->{Source}) ? $EventInfo->{Source}
                                                : $self->{Source};

    return WriteEventLog(
                $computer, $source, $EventInfo->{EventType},
                $EventInfo->{Category}, $EventInfo->{EventID}, 0,
                $EventInfo->{Data}, split(/\0/, $EventInfo->{Strings})
    );
}


# 
# GetOldest()
# ---------
sub GetOldest {
    my ($self, $event_r) = @_;
    die "usage: OBJECT->GetOldest( SCALAREF )\n" unless @_ == 2;
    return GetOldestEventLogRecord($self->{handle}, $event_r);
}


# 
# GetNumber()
# ---------
sub GetNumber {
    my ($self, $event_r) = @_;
    die "usage: OBJECT->GetNumber( SCALARREF )\n" unless @_ == 2;
    return GetNumberOfEventLogRecords($self->{handle}, $event_r);
}


# 
# Clear()
# -----
sub Clear {
    my ($self, $file) = @_;
    die "usage: OBJECT->Clear( FILENAME )\n" unless @_ == 2;
    return ClearEventLog($self->{handle}, $file);
}


# =========================================================================
# Mocked XS Functions
# =========================================================================

# 
# ReadEventLog()
# ------------
# http://msdn2.microsoft.com/en-us/library/aa363674.aspx
# 
sub ReadEventLog ($$$\$\$\$\$\$\$) {
    my ($eventlog, $flags, $offset, $event_header_r, $source_r, $computer_r, 
        $sid_r, $data_r, $strings_r) = @_;

    # set all these variables as some are not used even under real Win32::EventLog   
    $$event_header_r = $$source_r = $$computer_r = $$data_r = $$sid_r = $$strings_r = "";

    # find the record number to read
    my $record_num = $last_read_record;

    if ($flags & EVENTLOG_SEEK_READ) {
        $record_num = $offset
    }
    else {  # default to EVENTLOG_SEQUENTIAL_READ
        if ($flags & EVENTLOG_BACKWARDS_READ) {
            $record_num--
        }
        else {  # default to EVENTLOG_FORWARDS_READ
            $record_num++
        }
    }

    # read the record
    my $record = $eventlog->[$record_num];
    my $user_sid = "$<-$(";     # UID-GID
    my $strings_num = $record->{Strings} =~ tr/\0/\0/;

    # construct the event header
    $$event_header_r = pack("l6s4l6" => 
        0,                          # length
        ELF_LOG_SIGNATURE,          # reserved
        $record->{RecordNumber},    # record number
        $record->{TimeGenerated},   # time generated
        $record->{Timewritten},     # time written
        $record->{EventID},         # event ID
        $record->{EventType},       # event type
        $strings_num,               # number of strings
        $record->{Category},        # event category
        0,                          # reserved flags
        0,                          # closing record number
        0,                          # string offset
        length $user_sid,           # user sid length
        0,                          # user sid offset
        0,                          # data length
        0,                          # data offset
    );

    # set the variables
    $$source_r      = $record->{Source};
    $$computer_r    = $record->{Computer};
    $$sid_r         = $user_sid;
    $$data_r        = $record->{Data};
    $$strings_r     = $record->{Strings};

    return TRUE
}


# 
# WriteEventLog()
# -------------
sub WriteEventLog {
    my ($computer, $source, $event_type, $category, $event_id, $reserved, 
        $data, @strings) = @_;

    # get the singleton
    my $eventlog = $main_eventlog{$computer}{$source};

    # prepare fields
    $reserved ||= ELF_LOG_SIGNATURE;
    my $now = time();

    # store the event
    push @$eventlog, {
        Computer        => $computer,  
        Source          => $source,
        RecordNumber    => $#{$eventlog}+1, 
        TimeGenerated   => $now,
        Timewritten     => $now,
        Category        => $category, 
        EventType       => $event_type,
        EventID         => $event_id, 
        Reserved        => $reserved,
        Data            => $data,
        Strings         => \@strings, 
    };

    return TRUE
}


# 
# GetEventLogText()
# ---------------
sub GetEventLogText ($$$$\$) {
    my ($source, $event_id, $strings, $strings_num, $message_r) = @_;
    $$message_r = join "", "[$source/EventId:$event_id] ", split /\0/, $strings;
    return TRUE
}


# 
# BackupEventLog()
# --------------
sub BackupEventLog {
    my ($eventlog, $filename) = @_;

    require YAML;
    return YAML::DumpFile($filename => $eventlog)
}


# 
# ClearEventLog()
# -------------
sub ClearEventLog {
    my ($eventlog, $filename) = @_;

    my $rc = BackupEventLog($eventlog, $filename);
    if ($rc) { %main_eventlog = (); $last_read_record = 0 }

    return $rc
}


# 
# CloseEventLog()
# -------------
sub CloseEventLog {
    my ($eventlog) = @_;
    $last_read_record = 0;
    return TRUE
}


# 
# DeregisterEventSource()
# ---------------------
sub DeregisterEventSource {
    my ($eventlog) = @_;
    return TRUE
}


# 
# GetNumberOfEventLogRecords()
# --------------------------
sub GetNumberOfEventLogRecords ($\$) {
    my ($eventlog, $nb_records_r) = @_;
print STDERR "GetNumberOfEventLogRecords(): @_\n";
    $$nb_records_r = scalar @$eventlog;
    return TRUE
}


# 
# GetOldestEventLogRecord()
# -----------------------
sub GetOldestEventLogRecord {
    my ($eventlog, $oldest_record_r) = @_;
print STDERR "GetOldestEventLogRecord(): @_\n";
    $$oldest_record_r = $#{$eventlog};
    return TRUE
}


# 
# OpenBackupEventLog()
# ------------------
# http://msdn2.microsoft.com/en-us/library/aa363671.aspx
# 
sub OpenBackupEventLog (\$$$) {
    my ($eventlog_r, $computer, $filename) = @_;

    require YAML;
    $$eventlog_r = YAML::LoadFile($filename);

    return TRUE
}


# 
# OpenEventLog()
# ------------
# http://msdn2.microsoft.com/en-us/library/aa363672.aspx
# 
sub OpenEventLog (\$$$) {
    my ($eventlog_r, $computer, $source) = @_;
print STDERR "OpenEventLog(): @_\n";

    $main_eventlog{$computer}{$source} ||= [];
    $$eventlog_r = $main_eventlog{$computer}{$source};

    return TRUE
}


# 
# RegisterEventSource()
# -------------------
sub RegisterEventSource {
    my ($computer, $source) = @_;
    return $main_eventlog{$computer}{$source}
}


1

__END__

=head1 NAME

Win32::EventLog - Mocked Win32 event log functions

=head1 SYNOPSIS

    use Win32::Mock;
    use Win32::EventLog;

=head1 DESCRIPTION

This module is a mock/emulation of C<Win32::EventLog>. 
See the documentation of the real module for more details. 

=head1 SEE ALSO

L<Win32>

L<Win32::EventLog>

L<Win32::Mock>

=head1 AUTHOR

SE<eacute>bastien Aperghis-Tramoni E<lt>sebastien@aperghis.netE<gt>

=head1 COPYRIGHT & LICENSE

Copyright 2007, 2008 SE<eacute>bastien Aperghis-Tramoni, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
