package VCS::Lite::Element;

use strict;
use warnings;

our $VERSION = '0.12';

#----------------------------------------------------------------------------

use File::Spec::Functions qw(splitpath catfile catdir catpath rel2abs);
use Time::Piece;
use Carp;
use VCS::Lite;
use Params::Validate qw(:all);
use Cwd qw(abs_path);

use base qw(VCS::Lite::Common);

#----------------------------------------------------------------------------

sub new {
    my $pkg  = shift;
    my $file = shift;
    my %args = validate ( @_, 
        {
            store => {
                type    => SCALAR | OBJECT,
                default => $pkg->default_store,
            },
            verbose     => 0,
            recordsize  => 0, #ignored unless VCS::Lite::Element::Binary
        } );
    my $lite = $file;
    my $verbose = $args{verbose};

    $file = rel2abs($file);
    my $store_pkg;
    if (ref $args{store}) {
        $store_pkg = $args{store};
    } else {
        $store_pkg = ($args{store} =~ /\:\:/) ? $args{store} : "VCS::Lite::Store::$args{store}";
        eval "require $store_pkg";
        warn "Failed to require $store_pkg\n$@" if $@;
    }

    my $ele = $store_pkg->retrieve($file);
    if ($ele) {
        $ele->path($file);
        return $ele;
    }

    my $proto = bless {
        %args,
        path => $file,
    }, $pkg;

    $ele = $store_pkg->retrieve_or_create($proto);

    $ele->{path} = $file;

    if (!ref $lite) {
        unless (-f $file) {
            open FIL, '>', $file or croak("Failed to create $file, $!");
            close FIL;
        }
        $lite = $ele->_slurp_lite($file);
    } else {
        $file = $lite->id;  # Not handled at present
    }

    $ele->_assimilate($lite);
    $ele->save;

    $ele->{verbose} = $verbose;
    $ele;
}

sub check_in {
    my $self = shift;
    my %args = validate ( @_, 
        {
            check_in_anyway => 0,
            description     => { type => SCALAR },
        } );
    my $file = $self->{path};

    my $lite = $self->_slurp_lite($file);

    my $newgen = $self->_assimilate($lite);
    return if !$newgen && !$args{check_in_anyway};

    $self->_mumble("Check in $file");
    $self->{generation} ||= {};
    my %gen = %{$self->{generation}};
    $gen{$newgen} = {
        author => $self->user,
        description => $args{description},
        updated => localtime->datetime,
    };

    $self->{latest} ||= {};
    my %lat = %{$self->{latest}};
    $newgen =~ /(\d+\.)*\d+$/;
    my $base = $1 || '';
    $lat{$base}=$newgen;

    $self->_update_ctrl( generation => \%gen, latest => \%lat);
    $newgen;
}

sub repository {
    my $self = shift;

    my ($vol,$dir,$fil) = splitpath($self->{path});
    my $repos_path = $vol ? catdir($vol,$dir) : $dir;

    VCS::Lite::Repository->new($repos_path, verbose => $self->{verbose});
}

sub traverse {
    undef;
}

sub fetch {
    my $self = shift;
    my %args = validate ( @_, 
        {
            time        => 0,
            generation  => 0,
        } );

    my $gen = $args{generation} || $self->latest;

    if ($args{time}) {
        my $latest_time = '';
        my $branch = $args{generation} || '';
        $branch .= '.' if $branch;
        for (keys %{$self->{generation}}) {
            next unless /^$branch\d+$/;
            next if $self->{generation}{$_}{updated} > $args{time};
            ($latest_time,$gen) = ($self->{generation}{$_}{updated}, $_)
            if $self->{generation}{$_}{updated} > $latest_time;
        }
        return unless $latest_time;
    }
    return if $self->{generation} && !$self->{generation}{$gen};

    my $skip_to;
    my @out;
    for (@{$self->_contents}) {
        if ($skip_to) {
            if (/^=$skip_to$/) {
                undef $skip_to;
            }
            next;
        }
        if (my ($type,$gensel) = /^([+-])(.+)/) {
            if (_is_parent_of($gensel,$gen) ^ ($type eq '+')) {
                $skip_to = $gensel;
            }
            next;
        }
        next if /^=/;

        if (/^ /) {
            push @out,substr($_,1);
        }
    }

    my $file = $self->{path};
    VCS::Lite->new("$file\@\@$gen",undef,\@out);
}

sub commit {
    my ($self,$parent) = @_;

    my ($vol,$dir,$file) = splitpath($self->path);
    my $updfile = catfile($parent,$file);
    my $chg = $self->fetch;
    my $before = VCS::Lite->new($updfile);
    return unless $before->delta($chg);

    $self->_mumble("Committing $file to $parent");

    my $out;
    open $out,'>',$updfile or croak "Failed to open $file for committing, $!";
    print $out $chg->text;
}

sub update {
    my ($self,$parent) = @_;

    my $file = $self->path;
    $self->_mumble("Updating $file from $parent");

    my ($vol,$dir,$fil) = splitpath($file);
    my $fromfile = catfile($parent,$fil);
    my $baseline = $self->{baseline} || 0;
    my $parbas = $self->{parent_baseline};

    my $orig = $self->fetch( generation => $baseline);
    my $parele = VCS::Lite::Element->new($fromfile, verbose => $self->{verbose});
    my $parfrom = $parele->fetch( generation => $parbas);
    my $parlat = $parele->latest($parbas);
    my $parto = $parele->fetch( generation => $parlat);
    my $origplus = $parfrom->merge($parto,$orig);

    my $chg = VCS::Lite->new($file);
    my $merged = $orig->merge($origplus,$chg);
    my $out;
    open $out,'>',$file or croak "Failed to write back merge of $fil, $!";
    print $out $merged->text;
    $self->_update_ctrl(baseline => $self->latest, parent_baseline => $parlat);
}

sub _check_out_member {
    my $self    = shift;
    my $newpath = shift;
    my %args = validate(@_, 
        {
            store => { type => SCALAR|OBJECT, optional => 1 },
        } );

    my $repos = VCS::Lite::Repository->new(
        $newpath,
        verbose => $self->{verbose},
        %args);

    my ($vol,$dir,$fil) = splitpath($self->path);
    my $newfil = catfile($newpath,$fil);
    my $out;
    open $out,'>',$newfil or croak "Failed to check_out $fil, $!";
    print $out $self->fetch->text;
    close $out;

    my $pkg = ref $self;
    $pkg->new($newfil,%args);
}

sub _assimilate {
    my ($self,$lite,%args) = @_;

    my @newgen = map { [' '.$_] } $lite->text;
    my (@oldgen,@openers,@closers,$skip_to);
    my $genbase = $args{generation} || $self->latest;

    if (my $cont = $self->_contents) {
        for (@$cont) {
            if ($skip_to) {
                push @openers, $_;
                if (/^=$skip_to$/) {
                    undef $skip_to;
                }
                next;
            }
            if (my ($type,$gen) = /^([+-])(.+)/) {
                $oldgen[-1][2] = [@closers] if @closers;
                @closers = ();
                push @openers, $_;
                if (_is_parent_of($gen,$genbase) ^ ($type eq '+')) {
                    $skip_to = $gen;
                }
                next;
            }
            if (my ($gen) = /^=(.+)/) {
                push @closers, $_;
                next;
            }
            if (/^ /) {
                $oldgen[-1][2] = [@closers] if @closers;
                push @oldgen,[$_, [@openers]];
                @openers = @closers = ();
                next;
            }
            croak "Invalid format in element contents";
        }
        $oldgen[-1][2] = [@closers] if @closers;
    } else {
        $self->_contents([map $_->[0], @newgen]);
        return 1;
    }

    $genbase =~ s/(\d+)$/$1+1/e;
    my @sd = Algorithm::Diff::sdiff( \@oldgen, \@newgen, sub { $_[0][0] });
    my (@newcont,@pending);
    my $prev = 'u';
    my $changed = 0;

    for (@sd) {
        my ($ind,$c1,$c2) = @$_;
        my @res1;
        if ($c1) {
            @res1 = (@{$c1->[1]},$c1->[0]);
            push @res1,@{$c1->[2]} if defined $c1->[2];
        }
        my $res2 = $c2->[0] if $c2;

        push @newcont,"=$genbase\n" if ($prev ne 'u') && ($ind ne $prev);
        if (@pending && ($ind ne 'c')) {
            push @newcont, @pending, "=$genbase\n";
            @pending=();
        }
        if (($prev =~ /[u+]/) && ($ind =~ /[c-]/)) {
            push @newcont,"-$genbase\n";
            $changed++;
        }
        if ($ind eq '+') {
            push @newcont,"+$genbase\n" if ($prev ne $ind);
            push @newcont, $res2;
            $changed++;
        } else {
            push @newcont, @res1;
        }
        if ($ind eq 'c') {
            push @pending,"+$genbase\n" if ($prev ne $ind);
            push @pending, $res2;
        }
        $prev = $ind;
    }

    push @newcont,"=$genbase\n" if ($prev ne 'u');
    return unless $changed;
    $self->_contents(\@newcont);
    $genbase;
}

sub _is_parent_of {
    my ($gen1,$gen2) = @_;

    my @g1v = split /\./,$gen1;
    my @g2v = split /\./,$gen2;
    (shift @g1v,shift @g2v) while @g1v && @g2v && ($g1v[0] eq $g2v[0]);

    return 1 unless @g2v;
    return 0 unless @g1v;
    return 0 if @g1v > 1;

    $g1v[0] < $g2v[0];
}

sub _update_ctrl {
    my ($self,%args) = @_;

    my $path = $args{path} || $self->{path};
    my ($vol,$dir,$fil) = splitpath($path);
    $self->{$_} = $args{$_} for keys %args;
    $self->{updated} = localtime->datetime;
    $self->save;
}

sub _contents {
    my $self = shift;

    $self->{contents} = shift if @_;
    return unless exists $self->{contents};

    $self->{contents};
}

sub _slurp_lite {
    my ($self,$name) = @_;

    VCS::Lite->new($name);
}

1;

__END__

#----------------------------------------------------------------------------

=head1 NAME

VCS::Lite::Element - Minimal Version Control System - Element object

=head1 SYNOPSIS

  use VCS::Lite::Element;
  my $ele=VCS::Lite::Element->new('/home/me/dev/testfile.c');
  my $lit=$ele->fetch( generation => 2);
  $ele->check_in( description => 'Fix the bug');
  $ele->update;
  $ele->commit;

=head1 DESCRIPTION

A VCS::Lite::Repository contains elements corresponding to the source
files being version controlled. The files are real files on the local file
system, but additional information about the element is held inside the
repository.

This information includes the history of the element, in terms of its
generations.

=head1 METHODS

=head2 new

  my $ele=VCS::Lite::Element->new('/home/me/dev/testfile.c');

Constructs a VCS::Lite::Element for a given element in a repository.
Returns undef if the element is not found in the repository.

=head2 repository

Create a repository object from the current path.

=head2 traverse

Does nothing currently.

=head2 fetch

  my $lit=$ele->fetch( generation => 2);
  my $lit2=$ele->fetch( time => '2003-12-29T12:01:25');

The fetch method is used to retrieve generations from the repository.
If no time or generation is specified, the latest generation is retrieved. The
method returns a VCS::Lite object if successful or undef.

=head2 check_in

  $ele->check_in( description => 'Fix bug in foo method');

This method creates a new latest generation in the repository for the element.

=head2 update

  $ele->update;

This applies any changes to $ele which have happened in the parent repository,
i.e. the one that the current repository was checked out from.

=head2 commit

  $ele->commit;

Applies the latest generation change to the parent repository. Note: this
updates the file inside the parent file tree; a call to update is required
to update the repository.

=head1 SEE ALSO

L<VCS::Lite::Repository>, L<VCS::Lite>.

=head1 BUGS, PATCHES & FIXES

There are no known bugs at the time of this release. However, if you spot a
bug or are experiencing difficulties that are not explained within the POD
documentation, please send an email to barbie@cpan.org or submit a bug to the
RT system (see link below). However, it would help greatly if you are able to
pinpoint problems or even supply a patch.

http://rt.cpan.org/Public/Dist/Display.html?Name=VCS-Lite-Repository

Fixes are dependent upon their severity and my availability. Should a fix not
be forthcoming, please feel free to (politely) remind me.

=head1 AUTHOR

  Original Author: Ivor Williams (RIP)          2002-2009
  Current Maintainer: Barbie <barbie@cpan.org>  2014-2015

=head1 COPYRIGHT

  Copyright (c) Ivor Williams, 2002-2009
  Copyright (c) Barbie,        2014-2015

=head1 LICENCE

This distribution is free software; you can redistribute it and/or
modify it under the Artistic Licence v2.

=cut
