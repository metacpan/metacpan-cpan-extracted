use strict;
use warnings;

use Test::More;


{
    package TestLogSeq;
    use Win32::EventLog;

    sub new
    {
        my $class = shift;
        #$class = (ref $class) ? (ref $class) : $class;
        my $log = Win32::EventLog->new('Application', '');
        Test::More::isa_ok($log, 'Win32::EventLog', "$class log");
        return bless {
            log => $log,
            flags => (EVENTLOG_SEQUENTIAL_READ | EVENTLOG_BACKWARDS_READ),
        }, $class;
    }

    sub _next_offset
    {
        0
    }

    sub read
    {
        my $self = shift;
        local $Win32::EventLog::GetMessageText = 1;
        my ($flags, $offset) = ($self->{flags}, $self->_next_offset);
        #printf "# %s: 0x%X %d\n", (ref $self), $flags, $offset;
        $self->{log}->Read($flags, $offset, my $entry) or die "Read failure";
        Test::More::is(ref $entry, 'HASH', "entry is HASHREF");
        Test::More::ok(exists $entry->{RecordNumber}, "entry has RecordNumber");
        if ($offset > 1) {
            Test::More::is($entry->{RecordNumber}, $offset, "RecordNumber is $offset");
        }
        return $entry;
    }

    sub DESTROY
    {
        $_[0]->{log}->Close;
    }
}

{
    package TestLogSeek;
    use Win32::EventLog;
    use Test::More;

    our @ISA = qw(TestLogSeq);

    sub new
    {
        my $class = shift;
        my $self = $class->SUPER::new(@_);
        $self->{flags} = (EVENTLOG_SEEK_READ | EVENTLOG_BACKWARDS_READ);

        my $log = $self->{log};

        my ($oldest, $lastRec);
        $log->GetOldest($oldest);
        $log->GetNumber($lastRec);
        $self->{offset} = $oldest + $lastRec;

        return $self;
    }

    sub _next_offset
    {
        return --$_[0]->{offset};
    }
}


my @CHECK_ATTR = qw<RecordNumber>;
@CHECK_ATTR = qw<RecordNumber Computer Source EventType Category EventID> if $ENV{TEST_VERBOSE};
use constant COUNT => 15;

plan tests => 2 + COUNT * (2+2+1+1+@CHECK_ATTR);

sub check_entries
{
    my ($a, $b) = @_;
    is(scalar localtime $a->{TimeGenerated}, scalar localtime $b->{TimeGenerated}, 'TimeGenerated is "'.scalar(localtime $a->{TimeGenerated}).'"');
    #foreach my $attr (qw(RecordNumber Computer Source EventType Category EventID Message)) {
    #foreach my $attr (qw(RecordNumber Computer Source EventType Category EventID)) {
    foreach my $attr (@CHECK_ATTR) {
        is($a->{$attr}, $b->{$attr}, "$attr is $b->{$attr}");
    }
}


my $log_seq = TestLogSeq->new;
my $log_seek = TestLogSeek->new;

foreach (1..COUNT) {
    note "== Read $_ ==";
    check_entries($log_seq->read, $log_seek->read);
}

# vim:set et sw=4 sts=4:
