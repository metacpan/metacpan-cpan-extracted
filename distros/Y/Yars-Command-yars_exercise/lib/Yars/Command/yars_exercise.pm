package Yars::Command::yars_exercise;

# PODNAME: yars_exercise
# ABSTRACT: Exercise a Yars server from the client side
BEGIN {
our $VERSION = '0.07'; # VERSION
}


use strict;
use warnings;
use 5.010;
use Log::Log4perl qw(:easy);
use Clustericious::Log::CommandLine ':all', ':loginit' => { level => $INFO };
use Pod::Usage::CommandLine 0.04 qw(GetOptions pod2usage);
use Yars::Client;
use Number::Bytes::Human 0.09 qw(format_bytes parse_bytes);
use Parallel::ForkManager;
use Path::Tiny;
use Digest::MD5;
use List::Util qw(shuffle);
use Time::HiRes qw(gettimeofday tv_interval);
use YAML::XS qw(LoadFile);

my $chunksize;
my $temppath;

main(@ARGV) unless caller;

sub main
{
    local @ARGV = @_;

    GetOptions(
        'numclients:i' => \(my $clients = 4),        # if you change defaults
        'files:i'      => \(my $numfiles = 20),      # update SYNOPSIS
        'size:s'       => \(my $human_size = '8KiB'),
        'gets:i'       => \(my $gets = 10),
        'runs:s'       => \(my $runsfilename),
        'chunksize:s'  => \(my $human_chunksize = '8KiB'),
        'temppath:s'   => \($temppath = '/tmp')
    ) or pod2usage;

    $chunksize = parse_bytes($human_chunksize);

    exit multiruns($runsfilename) if $runsfilename;

    my $size = parse_bytes($human_size);
    $human_size = format_bytes($size);

    my $totalfiles = $clients * $numfiles;

    INFO "Create $totalfiles files, each about $human_size bytes.";
    INFO "PUT each file to Yars, then GET $gets times, then DELETE.";
    INFO "$clients clients will work in parallel on $numfiles each.";

    my ($times, $ret) = exercise($clients, $numfiles, $size, $gets);

    say "PUT avg time    ", $times->{PUT};
    say "GET avg time    ", $times->{GET};
    say "DELETE avg time ", $times->{DELETE};

    foreach my $method (qw(PUT GET DELETE))
    {
        say "$method $_ ", $ret->{$method}{$_} foreach keys %{$ret->{$method}};
    }
}

sub multiruns
{
    my ($runsfilename) = @_;

    my $runsdesc = LoadFile($runsfilename);

    foreach my $field (qw(clients files size gets))
    {
        if (not defined $runsdesc->{$field}
            or ref $runsdesc->{$field} ne 'ARRAY')
        {
            LOGDIE "Poorly formatted runs description file $field";
        }
    }

    say "clients,files,gets,size,PUT avg time,GET avg time,DELETE avg time,",
        "PUTs,GETs,DELETEs";

    foreach my $clients (@{ $runsdesc->{clients} })
    {
        foreach my $files (@{ $runsdesc->{files} })
        {
            foreach my $gets (@{ $runsdesc->{gets} })
            {
                foreach my $size (map {parse_bytes $_} @{ $runsdesc->{size} })
                {
                    INFO "Starting clients=$clients, files=$files, ",
                         "gets=$gets, size=$size";

                    my ($times, $ret) = exercise($clients, $files,
                                                 $size, $gets);

                    say join ',', $clients, $files, $gets, $size,
                        $times->{PUT}, $times->{GET}, $times->{DELETE},
                        $ret->{PUT}{ok}, $ret->{GET}{ok}, $ret->{DELETE}{1};

                    if ($ret->{PUT}{ok} != $clients*$files)
                    {
                        ERROR "Failed PUTs";
                    }
                    if ($ret->{GET}{ok} != $clients*$files*$gets)
                    {
                        ERROR "Failed GETs";
                    }
                    if ($ret->{DELETE}{1} != $clients*$files)
                    {
                        ERROR "Failed DELETEs";
                    }
                }
            }
        }
    }

    return 0;
}

sub exercise
{
    my ($clients, $numfiles, $size, $gets) = @_;

    my $pm = Parallel::ForkManager->new($clients)
        or LOGDIE;

    my @client_stats;

    $pm->run_on_finish(sub {
        my ($pid, $exit_code, $ident, $exit_signal, $core_dump, $stats) = @_;
        push @client_stats, $stats;
    });

    CLIENT:
    for (my $i = 0; $i < $clients; $i++)
    {
        $pm->start and next CLIENT;
        $pm->finish(0, exercise_worker($i, $numfiles, $size, $gets));
    }

    $pm->wait_all_children;

    my (%times, %ret);

    foreach my $stat (@client_stats)
    {
        foreach my $method (qw(PUT GET DELETE))
        {
            $times{$method} += $stat->{times}{$method};

            $ret{$method}{$_} += $stat->{ret}{$method}{$_}
                foreach keys %{$stat->{ret}{$method}};
        }
    }
    $times{PUT}    /= $clients*$numfiles;
    $times{GET}    /= $clients*$numfiles*$gets;
    $times{DELETE} /= $clients*$numfiles;

    return \%times, \%ret;
}

sub exercise_worker
{
    my ($clientno, $numfiles, $size, $gets) = @_;

    srand(($clientno+1) * gettimeofday);

    my @filelist;

    for (my $i = 0; $i < $numfiles; $i++)
    {
        my $newfile = make_temp_file($size);
        for (my $j = 0; $j < $gets+2; $j++)
        {
            push @filelist, { %$newfile };
        }
    }

    my %count;
    my %times;
    my %ret;

    my $yc = Yars::Client->new;

    foreach my $file (shuffle @filelist)
    {
        my $instance = ++$count{$file->{filename}};

        my $path = "/file/$file->{filename}/$file->{md5}";

        my $t0 = [gettimeofday];

        my ($ret, $method);

        if ($instance == 1)
        {
            $method = 'PUT';
            DEBUG "PUT $path";
            $ret = $yc->upload($file->{filepath});
        }
        elsif ($instance == $gets+2)
        {
            $method = 'DELETE';
            DEBUG "DELETE $path";
            $ret = $yc->remove($file->{filename}, $file->{md5});
        }
        else
        {
            $method = 'GET';
            DEBUG "GET $path";
            $ret = $yc->download($file->{filename}, $file->{md5}, $temppath);
        }
        my $elapsed = tv_interval($t0);
        $times{$method} += $elapsed;

        unlink $file->{filepath};

        $ret //= 'undef';
        $ret{$method}{$ret}++;

        DEBUG "DONE $ret $elapsed";
    }

    return { times => \%times, ret => \%ret };
}
    
sub make_temp_file
{
    my ($filesize) = @_;

    my $newfile = Path::Tiny->tempfile(UNLINK => 0,
                                       TEMPLATE => 'yarsXXXXX',
                                       DIR => $temppath)
        or LOGDIE "Can't make temp file";

    DEBUG "Creating $newfile";

    my $md5 = Digest::MD5->new;

    for (; $filesize > 0; $filesize -= $chunksize)
    {
        my $chunk = random_bytes($filesize > $chunksize
                                 ? $chunksize : $filesize);

        $md5->add($chunk);

        $newfile->append_raw($chunk)
            or LOGDIE "Failed writing to $newfile";
    }

    return { filename => $newfile->basename, 
             filepath => $newfile->stringify,
             md5 => $md5->hexdigest };
}

sub random_bytes
{
    my $number = shift;
    return '' unless $number > 0;
    pack("C$number", map { int(rand()*256) } 0..$number);
}

1;

__END__

=pod

=head1 NAME

Yars::Command::yars_exercise - code for yars_exercise

=head1 DESCRIPTION

This module contains the machinery for the command line program L<yars_exercise>

=head1 LICENSE

This software is copyright (c) 2015 by NASA GSFC.

This is free software; you can redistribute it and/or modify it under the same terms as the Perl 5 programming language system itself.

=head1 SEE ALSO

L<yars_disk_scan>

=cut