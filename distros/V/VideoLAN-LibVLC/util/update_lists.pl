#! /usr/bin/env perl
use strict;
use warnings;
use FindBin;
use File::Temp;

my @constant_sets;
my %per_version;
my @function_sets;
my $xs_boot= qq{  HV* stash= gv_stashpv("VideoLAN::LibVLC", GV_ADD);\n};
my %xs_ctor= (
    i => 'newSViv(%s)',
    u => 'newSVuv(%s)',
    n => 'newSVnv(%s)',
);

{
    open my $consts_fh, "<", "$FindBin::Bin/../const.list" or die;
    my $enum= undef;
    while (<$consts_fh>) {
        chomp;
        if ($_ =~ /^\w/) {
            push @constant_sets, [ $_ ];
            $enum= $_;
        } elsif (my ($typ, $min_v, $max_v, $sym)= ($_ =~ /^\s+(\w)\s+(\S+)\s+(\S+)\s+(\w+)/)) {
            die "Unhandled type code $typ" unless $xs_ctor{$typ};
            my $name= uc($sym);
            $name =~ s/^LIBVLC_//;
            # If the first word of the enum is not the first word of the constant,
            # prefix the constant with the name of the enum, minus _t
            $name = do { my $x= $enum; $x =~ s/_t$//; uc($x) } . '_' . $name
                unless uc((split /_/, $name)[0]) eq uc((split /_/, $enum)[0]);
            push @{$constant_sets[-1]}, $name;
            $min_v= '' if $min_v eq '---';
            $max_v= '' if $max_v eq '---';
            $per_version{"$min_v $max_v"} ||= { min => $min_v, max => $max_v, list => [] };
            push @{ $per_version{"$min_v $max_v"}{list} }, { typ => $typ, sym => $sym, name => $name };
        } else {
            die "parse error: $_\n" if $_ =~ /\S/;
        }
    }
}

# Build list of enums for %EXPORT_TAGS in main module
my $consts_pl= join '',
    map {
        wordwrap(4, 79, "  ".shift(@$_)." => [qw( ".join(' ', sort @$_)." )],\n")
    } sort { $a->[0] cmp $b->[0] } @constant_sets;

# Build XS BOOT section which selects constants by version
for (sort { $a->{min} cmp $b->{min} or $a->{max} cmp $b->{max} } values %per_version) {
    my @min= split /\./, $_->{min};
    my @max= split /\./, $_->{max};
    if (@min || @max) {
        $xs_boot .= "#if (";
        if (@min) {
            my $val= ($min[0]||0) * 10000 + ($min[1]||0) * 100 + ($min[2]||0);
            $xs_boot .= "(LIBVLC_VERSION_MAJOR * 10000 + LIBVLC_VERSION_MINOR * 100 + LIBVLC_VERSION_REVISION) >= $val";
        }
        if (@min && @max) {
            $xs_boot .= " && ";
        }
        if (@max) {
            my $val= ($max[0]||0) * 10000 + ($max[1]||0) * 100 + ($max[2]||0);
            $xs_boot .= "(LIBVLC_VERSION_MAJOR * 10000 + LIBVLC_VERSION_MINOR * 100 + LIBVLC_VERSION_REVISION) >= $val";
        }
        $xs_boot .= ")\n";
    }
    for my $item (sort @{ $_->{list} }) {
        $xs_boot .= sprintf('  newCONSTSUB(stash, "%s", '.$xs_ctor{$item->{typ}}.");\n", $item->{name}, $item->{sym});
    }
    if (@min || @max) {
        $xs_boot .= "#else\n";
        for my $item (sort @{ $_->{list} }) {
            $xs_boot .= sprintf("  newXS(\"VideoLAN::LibVLC::%s\", XS_VideoLAN__LibVLC__const_unavailable, file);\n", $item->{name});
        }
        $xs_boot .= "#endif\n";
    }
}

#{
#    open my $xs_fh, "<", "$FindBin::Bin/../Xlib.xs" or die;
#    my $ignore= 1;
#    while (<$xs_fh>) {
#        if ($_ =~ /PACKAGE\s*=\s*(\S+)/) {
#            #warn "Package $1\n";
#            $ignore= $1 ne 'X11::Xlib';
#        }
#        next if $ignore;
#        if ($_ =~ / \((fn_\w+)\) ---/) {
#            push @function_sets, [ $1 ];
#        } elsif ($_ =~ /^([A-Z]\w+)\(/) {
#            push @{ $function_sets[-1] }, $1
#                unless $1 eq 'DESTROY';
#        }
#    }
#}

sub wordwrap {
    my ($indent, $width, $str)= @_;
    my $prev= 0;
    while (length($str) - $prev > $width) {
        my $break_pos= rindex($str, ' ', $prev + $width);
        $break_pos > $prev or die "word longer than width?";
        substr($str, $break_pos, 1)= "\n" . (' ' x $indent);
        $prev= $break_pos;
    }
    $str;
}

sub patch_file {
    my ($fname, $token, $new_content)= @_;
    my $begin_token= "BEGIN $token";
    my $end_token=   "END $token";
    open my $orig, "<", $fname or die "open($fname): $!";
    my $new= File::Temp->new(DIR => ".", TEMPLATE => "${fname}_XXXX");
    while (<$orig>) {
        $new->print($_);
        last if index($_, $begin_token) >= 0;
    }
    $orig->eof and die "Didn't find $begin_token in $fname\n";
    $new->print($new_content);
    while (<$orig>) { if (index($_, $end_token) >= 0) { $new->print($_); last; } }
    $orig->eof and die "Didn't find $end_token in $fname\n";
    while (<$orig>) { $new->print($_) }
    $new->close or die "Failed to save $new";
    rename($new, $fname) or die "rename: $!";
}

#my $fn_pl= join '',
#    map {
#        wordwrap(4, 79, "  ".shift(@$_)." => [qw( ".join(' ', sort @$_)." )],\n")
#    } sort { $a->[0] cmp $b->[0] } @function_sets;
patch_file("LibVLC.xs",              'GENERATED BOOT CONSTANTS', $xs_boot);
patch_file("lib/VideoLAN/LibVLC.pm", 'GENERATED XS CONSTANT LIST', $consts_pl);
#patch_file("lib/VideoLAN/LibVLC.pm", 'GENERATED XS FUNCTION LIST', $fn_pl);
