#   Convert directory paths to/from rooted logical paths to evade
#   VMS's directory depth limitations.
#
#   Version:        0.012
#   Author:         Charles Lane        lane@duphy4.physics.drexel.edu
#   Revised:        4 Mar 2012
##### remove non-vms usage
#

=head1 NAME

    VMS::FileUtils::Root     - convert directory paths to and from rooted logicals
    (only works on VMS systems)

=head1 SYNOPSIS

use VMS::FileUtils::Root;

$r = new VMS::FileUtils::Root 'disk:[dir1.dir2]';

$path = $r->rooted('disk:[dir1.dir2.dir3]');

$path = $r->unrooted('ROOTDIR_1:[dir3]');

=head1 DESCRIPTION

This module creates and uses rooted logical names in the /job logical
name table. This only works on VMS systems.

=head2 new

The directory path specified can be either in VMS or Unix format; and
can be either absolute (disk:[dir] or /disk/dir) or relative to the
current directory ([.dir] or dir/dir2).  A blank or missing path is
taken to be the current directory, and a simple name (without any slashes
or brackets) is taken to be a subdirectory name.

=head2 to_rooted

This routine converts a directory path into a rooted directory path,
and returns the result in Unix format (without trailing '/', so
it can be used in chdir).

The input directory path can be absolute, or relative based on the
current directory.  Input can be either VMS or Unix format.

=head2  from_rooted

This routine converts a rooted directory path to an unrooted equivalent
path and returns the result in Unix format (without trailing '/').

Note that if you input a relative path, it will be taken as relative
to the rooted directory.  Input can be either VMS or Unix format.

The output of this routine may contain more than 8 directory levels
and hence not be directly usable on VMS without conversion to a rooted
path.

=cut

package VMS::FileUtils::Root;
use File::Spec;
use Cwd;
use Carp;
use strict;
use vars qw($VERSION $ROOTNUM $Pnode $Pdev $Pdir $Pname $Ptype $Pvers);

$VERSION = '0.012';

sub new {
    my $pkg = shift;
    $pkg = ref($pkg) || $pkg;
    my $b = shift;
    my $self = {};
    bless $self, $pkg;


    $self->{O_LOWER}      = 1;      # all lowercase
    $self->{O_LOCAL}      = 1;      # strip any node info
    $self->{O_LOCALONLY}  = 1;      # warn if remote node
    $self->{O_DIRONLY} = 1;
    $b = $self->expander($b);
    $self->{O_DIRONLY} = 0;

    my(@d) = split('/',$b);
    pop @d if ($d[$#d] =~ /[\.\;]/);

    while ($#d > 8) { pop @d }
    $b = join('/',@d);

    $self->{base} = $b;
    $b = $self->tran_unix($b, -d $b);
    $b =~ s#\].*#.\]#;

    $ROOTNUM++;
    if ($^O =~ /vms/i) {
	$self->{rootlogical} = sprintf('ROOT_%X_%d',$$,$ROOTNUM);
	my $rslt = `define/nolog/job/trans=conceal $self->{rootlogical} $b`;
	carp("Error defining logical, '$rslt' status:$?\n") if $?;
    }
    return $self;
}

sub DESTROY {
    my $self = shift;

    return if !defined($self->{rootlogical});
    my $rslt = `deassign/job $self->{rootlogical}`;
    carp("Error deassigning logical, '$rslt' status:$?\n") if $?;
}


#
#   have to do this stuff manually, std call chokes on too many subdirs
#

sub rooted ($;$$) {
    my $self = shift;
    my $d = shift;
    $d ||= '';
    my $opt = shift;
    $opt ||= '';
    my $WantVMS = $opt =~ /O_VMS/;

    $d = $self->expander($d);

    if (lc(substr($d,0,length($self->{base}))) ne lc($self->{base})) {
        carp "$d isn't a subdirectory of $self->{base}\n";
        return undef;
    }
    $d = substr($d,length($self->{base}));
    my (@p) = split('/',$d);
    shift @p;
    my $f = pop(@p);
    if (defined($f) && $f !~/\./) {
        push(@p,$f);
        $f = '';
    }
    while($#p >= 0 && $p[0] eq '000000') {shift @p};
    push(@p,'000000') if ($#p < 0);
    unshift(@p,'');
    $f ||= '';
    $d = '/'.lc($self->{rootlogical}).join('/',@p,$f);
    $d =~ s#/$##;
    $d = $self->tran_unix($d) if $WantVMS;
    return $d;
}

sub unrooted ($;$$) {
    my $self = shift;
    my $d = shift;
    my $opt = shift;
    $opt ||= '';
    my $WantVMS = $opt =~ /O_VMS/;

    $d = $self->expander($d,'/'.$self->{rootlogical});
    $d = $self->tran_unix($d) if $WantVMS;
    return $d;
}


sub vms2unix {
    my $self = shift;
    my (@in)  = $self->vmssplit(shift);
    my (@def) = $self->vmssplit(shift);
    my (@cur) = $self->vmssplit(cwd);
    ($cur[3],$cur[4]) = $self->tran_rooted($cur[3],$cur[4]);
    my $j;

    for ($j = 0; $j < 8; $j++) {
        $def[$j] = $cur[$j] if !defined($def[$j]);
        $in[$j]  = $def[$j] if !defined($in[$j]);
    }

    $in[4] = $self->make_abs($cur[4],$in[4]);
    ($in[3],$in[4]) = $self->tran_rooted($in[3],$in[4]);

    $in[5] = $in[6] = $in[7] = undef if ($self->{O_DIRONLY});

    return  $self->combine_for_unix(@in);

}

#
#   translate  "device" + "directory"
#   from a conceal logical with rooted directory to
#   an "absolute" form.
#       and ignore that 8 directory depth stuff, too.
#

sub tran_rooted {
    my $self = shift;
    my $dev = shift;
    my $dir = shift;

    my $d = $dev;
    $d =~ s#\:\Z##;
    $d = $ENV{$d};
    if ($d) {
        my (@r) = $self->vmssplit($d);
        if ($r[3] && $r[4] && $r[4] =~ /\.\]\Z/) {
            $dev = $r[3];
            $dir = $r[4].$dir;
            $dir =~ s#\.\]\[#.#;
        }
    }

    $d = $dir;
    $d =~ s#[\[\]]##g;
    my (@d) = split('\.',$d);
    my (@p) = ();
    foreach (@d) {
        push @p,$_ unless $_ eq '000000';
    }
    push @p,'000000' if $#p < 0;
    $dir = '['.join('.',@p).']';
    return ($dev,$dir);
}


#
#   make a relative directory path absolute
#   VMS syntax
#

sub make_abs {
    my $self = shift;
    my $base = shift;
    my $rel  = shift;

    return $rel unless $rel =~ /\A\[(\.|\-|\])/;

    $base =~ s#[\[\]]##g;
    $rel  =~ s#[\[\]]##g;       # strip brackets
    my (@b) = split('\.',$base);
    my (@r) = split('\.',$rel);

    foreach (@r) {
        if (/\A\-+\Z/) {
            my $j;
            if (length($_) > $#b+1) {
                warn 'relative directory going above root directory';
            }
            for ($j = 0; $j < length($_); $j++) {
                pop @b;
            }
        } elsif ($_ ne '') {
            push @b,$_;
        }
    }
    return '['.join('.',@b).']';
}

#
#   split a VMS filename into components, we don't check for validity
#   of the components, as long as it parses okay.
#
#   directory names in < ... > get translated to [ ... ]
#   versions with '.' separator ( file.txt.1) get translated to ';'
#
$Pnode = '([a-z0-9][a-z0-9\-\.]*)(\"([a-z0-9]+)(\s+(\w*))?\")?\:\:';
$Pdev  = '[\w\$]+\:';
$Pdir  = '\[([\w\.\-]*)\]|\<([\w\.\-]*)\>';
$Pname = '[\w\$\-]+';
$Ptype = '\.[\w\$\-]*';
$Pvers = '(\;|\.)((\+\d|\-\d)?\d*)';





sub vmssplit {
    my $self = shift;
    my $f = shift;
    $f = '' unless defined($f);

    my ($node,$user,$pwd,$dev,$dir,$name,$type,$vers,$adir,$bdir,$idir,$rdir);

    if ($f =~ /\A($Pnode)?($Pdev)?($Pdir)?($Pname)?($Ptype)?($Pvers)?\Z/i) {
        $node = $2;
        $user = $4;
        $pwd = $6;
        $dev = $7;
        $dir = $8;
        $bdir = $9;
        $adir = $10;
        $rdir = $bdir ? $bdir : $adir ;
        $rdir = '['.$rdir.']' if defined($rdir) && $rdir ne '';
        $name = $11;
        $type = $12;
        $vers = $15 ? ';'.$15 : undef;
    } else {
        warn "$f is not a valid VMS filename";
    }

    if ($node && $self->{O_LOCALONLY}) {
        warn 'node specified for what should be a local path';
    }
    if ($self->{O_LOCAL}) {
        $node = $user = $pwd = undef;
    }

    return ($node,$user,$pwd,$dev,$rdir,$name,$type,$vers);
}

#
#   convert deconstructed VMS filespec to Unix
#   note that if we have node/user/password info (a la decnet)
#   it gets converted to a "URL" style prefix:  //user:password@node
#

sub combine_for_unix {
    my $self = shift;
    my ($node,$user,$pwd,$dev,$dir,$name,$type,$vers) = map($self->{O_LOWER}?lc($_):$_,@_);

    my $s = '';

    if ($node) {
        $s .= '//';
        if ($user) {
            $s .= $user;
            if ($pwd) {
                $s .= ':'.$pwd;
            }
            $s .= '@';
        }
        $s .= $node;
    }
    if ($dev) {
        $dev =~ s#\:\Z##;
        $s .= '/'.$dev;
    }
    if ($dir) {
        $dir =~ s#[\[\]]##g;
        $dir =~ s#\.#/#g;
        $s .= '/'.$dir;
    }
    if ($name||$type||$vers) {
        $s .= '/'.$name.$type.$vers;
    }
    return $s;
}



sub tran_unix {
    my $self = shift;
    my (@p) = split('/',shift);
    my (@p2);
    my ($d);

    $d = shift(@p);
    if (defined($d) && $d eq '') {
        $d = shift(@p).':';
    } else {
        unshift(@p,$d);
        $d = '';
        $p2[0] = '';
    }

    foreach (@p) {
        next unless defined($_);
        next if $_ eq '.';

        if ($_ eq '..') {
            if ($#p2 == 0) {
                if ($p2[0] =~ /\A\-*\Z/) {
                    $p2[0] .= '-';
                    next;
                }
            }
            pop @p2;
        } else {
            push @p2, $_;
        }
    }
    my $f = pop @p2;
#
#   our only hint that the trailing bit is a filename: it has a . or ; in it
#
    if (defined($f) && $f !~ /[\.\;]/) {
        push @p2, $f;
        $f = '';
    }
    $f ||= '';
    return $d.'['.join('.',@p2).']'.$f;
}

sub expander {
    my $self = shift;
    my $dir = shift;
    my $def = shift;
    my $dironly = $self->{O_DIRONLY};

    $dir = '' if !defined($dir);
    if ($dir !~ /[\[\<\;\:]/) {
#
#       how can we tell if this is  /dev/dir/file  or /dev/dir/sdir ?
#
        $dir = $self->tran_unix($dir);
    }

    if (defined($def) && $def !~ /[\[\<\;\:]/) {
        $def = $self->tran_unix($def);
    }

    return $self->vms2unix($dir,$def);
}

1;
