package MyTmpTimer;
use strict;
use warnings;
use MyTest;
use File::Temp;
use Time::HiRes qw(gettimeofday tv_interval);
require Exporter;
use vars qw(@EXPORT);

@EXPORT = qw(tmptimer int_commify);

*import  = \&Exporter::import;

sub tmptimer {
    my ($n, $callback) = @_;
    my $self = bless {files=>[]}, __PACKAGE__;

    my $dir = $self->{dir} = File::Temp->newdir('UUID-test-XXXXXXXX', TMPDIR => 1, CLEANUP => 1);

    my $fh = File::Temp->new( DIR => $dir );
    push @{$self->{files}}, $fh->filename;

    my ($t0, $t1, $t2);
    {
        our $NOW = 0;
        local $SIG{'INT'}  = sub { $NOW = 1; die 'SIGINT'  };
        local $SIG{'HUP'}  = sub { $NOW = 1; die 'SIGHUP'  };
        local $SIG{'PIPE'} = sub { $NOW = 1; die 'SIGPIPE' };
        local $SIG{'TERM'} = sub { $NOW = 1; die 'SIGTERM' };

        $t0 = [gettimeofday];
        $t1 = [gettimeofday];

        eval { $callback->($n, $fh) };

        $t2 = [gettimeofday];

        if ($NOW) {
            undef $self;
            die 'Caught '.$@;
        }
    }

    my $i0 = tv_interval $t0, $t1;
    my $i1 = tv_interval $t1, $t2;
    my $e = $i1 - $i0;

    note int_commify($n, 1). " tests";
    note "$e seconds";
    note int_commify($n, $e), " UUIDs / second";

    $fh->seek(SEEK_SET, 0);
    return $fh;
}

sub int_commify {
    my ($n, $e) = @_;
    return 'Inf' if $e == 0;
    my $input = int($n / $e);
    $input = reverse $input;
    $input =~ s/(\d\d\d)(?=\d)(?!\d*\.)/$1,/g;
    return scalar reverse $input;
}

1;
