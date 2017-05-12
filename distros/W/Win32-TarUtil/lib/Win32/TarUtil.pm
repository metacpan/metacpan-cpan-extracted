package Win32::TarUtil;
$Win32::TarUtil::VERSION = '0.02';
use strict;
use warnings;

use Archive::Extract;
use Carp;

require Exporter;
our @ISA         = qw(Exporter);
our %EXPORT_TAGS = ( 'all' => [ qw(tu_extract tu_wipe tu_copy) ] );
our @EXPORT_OK   = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT      = qw();

sub tu_extract {
    my $arch    = $_[0];

    $arch =~ s{/}'\\'xmsg;

    my $out_dir = $ENV{'TEMP'}.'\\A_Out';
  
    tu_wipe($out_dir);

    mkdir $out_dir or croak "can't mkdir out_dir '$out_dir' ($!)";

    unless (-f $arch) {
        croak "Can't find archive '$arch'";
    }

    my $ae = Archive::Extract->new(archive => $arch);
    my $ok = $ae->extract(to => $out_dir);

    unless ($ok) {
        croak "Can't extract '$arch' => '$out_dir'";
    }

    my @D = do {
        opendir my $dh, $out_dir or croak "Can't opendir '$arch' => '$out_dir'";
        grep { $_ ne '.' and $_ ne '..' } readdir $dh;
    };

    unless (@D == 1) {
        croak "extract '$arch' => '$out_dir': invalid structure (".scalar(@D).")";
    }

    my $item = $out_dir.'\\'.$D[0];

    unless (-d $item) {
        croak "extract '$arch' => '$out_dir': directory not found ('$item')";
    }

    return $item;
}

sub tu_wipe {
    my ($thing) = @_;

    $thing =~ s{/}'\\'xmsg;

    if (-e $thing) {
        if (-f $thing) {
            unlink $thing or croak "Panic in tu_wipe('$thing'), can't unlink because $!";
        }
        elsif (-d $thing) {
            for (1..4) {
                my $text = '';
                $text .= qq{del /s /q "$thing"\n};
                $text .= qx{del /s /q "$thing" 2>&1};
                $text .= "\n\n";
                $text .= qq{rd  /s /q "$thing"\n};
                $text .= qx{rd  /s /q "$thing" 2>&1};

                last unless -e $thing;

                select(undef, undef, undef, 0.25);
            }

            if (-e $thing) {
                croak "Panic in tu_wipe('$thing'), has not disappeared as it should";
            }
        }
        else {
            croak "Panic in tu_wipe('$thing'), neither file nor dir";
        }
    }
}

sub tu_copy {
    my ($t_from, $t_to) = @_;

    s{/}'\\'xmsg for $t_from, $t_to;

    unless (-e $t_from) {
        croak "Panic in transfer('$t_from', '$t_to'), source does not exist";
    }

    if (-e $t_to) {
        croak "Panic in transfer('$t_from', '$t_to'), target does exist";
    }

    if (-d $t_from) {
        mkdir $t_to or croak "Panic in transfer('$t_from', '$t_to'), can't mkdir because $!";
        my $text = qx{xcopy /s /q "$t_from" "$t_to" 2>&1} =~ s{\s+}' 'xmsgr =~ s{\A \s}''xmsr =~ s{\s \z}''xmsr;
    }
    elsif (-f $t_from) {
        my $text = qx{copy "$t_from" "$t_to" 2>&1} =~ s{\s+}' 'xmsgr =~ s{\A \s}''xmsr =~ s{\s \z}''xmsr;
    }
    else {
        croak "Panic in transfer('$t_from', '$t_to'), neither file nor dir";
    }
}

1;

__END__

=head1 NAME

Win32::TarUtil - UnTgz, copy and wipe entire directories in Windows

=head1 SYNOPSIS

    use Win32::TarUtil qw(:all);

    my $d = tu_extract('C:/test/arch.tar.gz');
    print "Archive has been extracted into '$d'\n";

    tu_wipe('C:/data/dir1');
    tu_copy($d => 'C:/data/dir1');

=head1 AUTHOR

Klaus Eichner <klaus03@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014 by Klaus Eichner

All rights reserved. This program is free software; you can redistribute
it and/or modify it under the terms of the artistic license 2.0,
see http://www.opensource.org/licenses/artistic-license-2.0.php

=cut
