#!/usr/bin/perl

sub isn {
    my $get = normalize(scalar(getfile($_[0])));
    my $new = normalize($_[1]);
    return is($get, $new);
}

sub getfile($) {
    my $f = shift;
    local *F;
    open(F, "<$f") or die "getfile:cannot open $f:$!";
    my @r = <F>;
    close(F);
    return wantarray ? @r : join ('', @r);
}

sub putfile($@) {
    my $f = shift;
    local *F;
    open(F, ">$f") or die "putfile:cannot open $f:$!";
    print F '' unless @_;
    while (@_) { print F shift(@_) }
    close(F);
}

sub normalize {
    my $r = shift;
    $r =~ s/(BEGIN OUTPUT BY Text::Ngrams version )[\d.]+/$1/;
    $r =~ s/(\s\d\.\d\d\d\d\d\d\d\d\d\d\d\d\d\d)\d*/$1/g;

    # used sometimes
    #$r =~ s/[ _]//g;
    #$r = join("\n", sort(split(/\n/, $r)));

    return $r;
}

1;
