#!/usr/bin/perl -*- coding: no-conversion -*-

my $path = $ARGV[0];
die "arg 1 is empty" unless $path;
if($] ge '5.009005') {
    open my $fh, '<', $path or die "Can't open $path: $!";
    my $data;
    {
        binmode($fh);
        local $/ = undef;
        $data = <$fh>;
    }
    close $fh or "Can't close $path: $!";
    my $match = q|    #next 2 lines are special matched in Makefile.PL, update that if changed
    delete local $DynaLoader::{'VERSION'} if $] lt '5.009005';
    delete local $DynaLoader::{'XS_VERSION'} if $] lt '5.009005';
|;
    my $pos = index($data, $match);
    die 'can\'t match in Config_pm.PL' if $pos == -1;
    substr($data, $pos,length($match),'');
    open $fh, '>', $path or die "Can't open $path: $!";
    syswrite($fh, $data) or die "Can't write $path: $!";
    print "patched $path\n";
} else {
    print "did not patch $path\n";
}
