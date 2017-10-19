package urpm::util;


use strict;
use Exporter;
our @ISA = 'Exporter';
our @EXPORT = qw(add2hash_
    any
    append_to_file
    basename
    begins_with
    cat_
    cat_utf8
    copy_and_own
    difference2
    dirname
    file2absolute_file
    file_size
    find
    formatList
    intersection
    max
    member 
    min
    offset_pathname
    output_safe
    partition
    put_in_hash
    quotespace
    reduce_pathname
    remove_internal_name
    same_size_and_mtime
    uniq
    uniq_
    unquotespace
    untaint
    wc_l
);

sub min  { my $n = shift; $_ < $n and $n = $_ foreach @_; $n }
sub max  { my $n = shift; $_ > $n and $n = $_ foreach @_; $n }

#- quoting/unquoting a string that may be containing space chars.
sub quotespace		 { my $x = $_[0] || ''; $x =~ s/(\s)/\\$1/g; $x }
sub unquotespace	 { my $x = $_[0] || ''; $x =~ s/\\(\s)/$1/g; $x }
sub remove_internal_name { my $x = $_[0] || ''; $x =~ s/\(\S+\)$/$1/g; $x }

sub dirname { local $_ = shift; s|[^/]*/*\s*$||; s|(.)/*$|$1|; $_ || '.' }
sub basename { local $_ = shift; s|/*\s*$||; s|.*/||; $_ }

sub file2absolute_file {
    my ($f) = @_;

    if ($f !~ m!^/!) {
	require File::Spec;
	$f = File::Spec->rel2abs($f);
    }
    $f;
}

#- reduce pathname by removing <something>/.. each time it appears (or . too).
sub reduce_pathname {
    my ($url) = @_;

    #- clean url to remove any macro (which cannot be solved now).
    #- take care if this is a true url and not a simple pathname.
    my ($host, $dir) = $url =~ m|([^:/]*://[^/]*/)?(.*)|;
    $host //= '';

    #- remove any multiple /s or trailing /.
    #- then split all components of pathname.
    $dir =~ s|/+|/|g; $dir =~ s|/$||;
    my @paths = split '/', $dir;

    #- reset $dir, recompose it, and clean trailing / added by algorithm.
    $dir = '';
    foreach (@paths) {
	if ($_ eq '..') {
	    if ($dir =~ s|([^/]+)/$||) {
		if ($1 eq '..') {
		    $dir .= "../../";
		}
	    } else {
		$dir .= "../";
	    }
	} elsif ($_ ne '.') {
	    $dir .= "$_/";
	}
    }
    $dir =~ s|/$||;
    $dir ||= '/';

    $host . $dir;
}

#- offset pathname by returning the right things to add to a relative directory
#- to make no change. url is needed to resolve going before to top base.
sub offset_pathname {
    my ($url, $offset) = map { reduce_pathname($_) } @_;

    #- clean url to remove any macro (which cannot be solved now).
    #- take care if this is a true url and not a simple pathname.
    my (undef, $dir) = $url =~ m|([^:/]*://[^/]*/)?(.*)|;
    my @paths = split '/', $dir;
    my @offpaths = reverse split '/', $offset;
    my @corrections;
    my $result = '';

    foreach (@offpaths) {
	if ($_ eq '..') {
	    push @corrections, pop @paths;
	} else {
	    $result .= '../';
	}
    }
    $result . join('/', reverse @corrections);
}

sub untaint {
    my @r = map { /(.*)/ } @_;
    @r == 1 ? $r[0] : @r;
}

sub copy {
    my ($file, $dest) = @_;
    !system("/bin/cp", "-p", "-L", "-R", $file, $dest);
}
sub copy_and_own {
    my ($file, $dest_file) = @_;
    copy($file, $dest_file) && chown(0, 0, $dest_file) == 1;
}

sub move {
    my ($file, $dest) = @_;
    rename($file, $dest) || !system("/bin/mv", "-f", $file, $dest);
}

#- file_size is useful to write file_size(...) > 32 without having warnings if file doesn't exist
sub file_size {
    my ($file) = @_;
    -s $file || 0;
}

sub same_size_and_mtime {
    my ($f1, $f2) = @_;

    my @sstat = stat $f1;
    my @lstat = stat $f2;
    $sstat[7] == $lstat[7] && $sstat[9] == $lstat[9];
}

sub partition(&@) {
    my $f = shift;
    my (@a, @b);
    foreach (@_) {
	$f->($_) ? push(@a, $_) : push(@b, $_);
    }
    \@a, \@b;
}

sub begins_with {
    my ($s, $prefix) = @_;
    index($s, $prefix) == 0;
}
sub formatList {
    my $nb = shift;
    join(", ", @_ <= $nb ? @_ : (@_[0..$nb-1], '...'));
}

sub add2hash_   { my ($a, $b) = @_; while (my ($k, $v) = each %{$b || {}}) { exists $a->{$k} or $a->{$k} = $v } $a }
sub put_in_hash { my ($a, $b) = @_; while (my ($k, $v) = each %{$b || {}}) { $a->{$k} = $v } $a }
sub uniq { my %l; $l{$_} = 1 foreach @_; grep { delete $l{$_} } @_ }
sub difference2 { my %l; @l{@{$_[1]}} = (); grep { !exists $l{$_} } @{$_[0]} }
sub intersection { my (%l, @m); @l{@{shift @_}} = (); foreach (@_) { @m = grep { exists $l{$_} } @$_; %l = (); @l{@m} = () } keys %l }
sub member { my $e = shift; foreach (@_) { $e eq $_ and return 1 } 0 }
sub cat_ { my @l = map { my $F; open($F, '<', $_) ? <$F> : () } @_; wantarray() ? @l : join '', @l }
sub cat_utf8 { my @l = map { my $F; open($F, '<:utf8', $_) ? <$F> : () } @_; wantarray() ? @l : join '', @l }
sub wc_l { my $F; open($F, '<', $_[0]) or return; my $count = 0; while (<$F>) { $count++ } $count }

sub uniq_(&@) {
    my $f = shift;
    my %l;
    $l{$f->($_)} = 1 foreach @_;
    grep { delete $l{$f->($_)} } @_;
}

sub output_safe {
    my ($file, $content, $o_backup_ext) = @_;
    
    open(my $f, '>', "$file.new") or return;
    print $f $content or return;
    close $f or return;

    rename($file, "$file$o_backup_ext") or return if $o_backup_ext;
    rename("$file.new", $file) or return;
    1;
}

sub find(&@) {
    my $f = shift;
    $f->($_) and return $_ foreach @_;
    undef;
}

sub any(&@) {
    my $f = shift;
    $f->($_) and return 1 foreach @_;
    0;
}

sub append_to_file { 
    my $f = shift; 
    open(my $F, '>>', $f) or die "writing to file $f failed: $!\n";
    print $F $_ foreach @_;
    1;
}

1;


=head1 NAME

urpm::util - Misc. utilities subs for urpmi

Mostly a subset of L<MDK::Common>

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 COPYRIGHT

Copyright (C) 2005 MandrakeSoft SA

Copyright (C) 2005-2010 Mandriva SA

Copyright (C) 2011-2017 Mageia

=cut
