package VCS::Lite::Repository;

use 5.006;
use strict;
use warnings;

our $VERSION = '0.12';

#----------------------------------------------------------------------------

use Carp;
use File::Spec::Functions qw(:ALL !path);
use Time::Piece;
use VCS::Lite::Element;
use Params::Validate qw(:all);
use Cwd qw(abs_path);

use base qw(VCS::Lite::Common);

#----------------------------------------------------------------------------

sub new {
    my $pkg = shift;
    my $path = shift;
    my %args = validate ( @_, 
        {
            store   => {
                type    => SCALAR | OBJECT,
                default => $pkg->default_store 
            },
            verbose => 0,
        } );

    my $verbose = $args{verbose};

    if (-d $path) {
    } elsif (-f $path) {
        croak "Invalid path '$path' must be a directory";
    } else {
        mkdir $path or croak "Failed to create directory: $!";
    }

    my $abspath = abs_path($path);
    my $proto = bless {
        path        => $abspath,
        verbose     => $verbose,
        contents    => []
    },$pkg;

    my $store_pkg;
    if (ref $args{store}) {
        $store_pkg = $args{store};
    } else {
        $store_pkg = ($args{store} =~ /\:\:/) ? $args{store} : "VCS::Lite::Store::$args{store}";
        eval "require $store_pkg";
        warn "Failed to require $store_pkg\n$@" if $@;
    }

    my $repos = $store_pkg->retrieve_or_create($proto);
    if (exists $repos->{elements}) {
        $repos->_mumble("Upgrading repository $abspath from 0.02 to $VERSION");
        $repos->{contents} ||= $repos->{elements};
        delete $repos->{elements};
        $repos->save;
    }

    $repos->path($abspath);
    $repos->{author} = $repos->user;
    $repos->{verbose} = $verbose;
    $repos;
}

sub add {
    my $self = shift;
    my ($file) = validate_pos(@_, { type => SCALAR });

    my $path = $self->path;
    my ($vol,$dirs,$fil) = splitpath($file);
    my $absfile;
    my $remainder;

    if ($dirs) {
        my ($top,@dirs) = splitdir($dirs);
        $top = shift @dirs if $top eq '';     # VMS quirk
        pop @dirs if !defined($dirs[-1]) || ($dirs[-1] eq '');
        $absfile = abs_path(catfile($path,$top));
        mkdir $absfile unless -d $absfile;
        $remainder = @dirs ? catpath($vol,catdir(@dirs),$fil) : $fil;
        $file = $top;
    } else {
        $absfile = catfile($path,$fil);
    }

    unless ((catdir($file) eq updir) ||
           (catdir($file) eq curdir) ||
           grep {$file eq $_} @{$self->{contents}}) {

        $self->_mumble("Add $file to $path");

        my @newlist = sort(@{$self->{contents}},$file);
        $self->{transactions} ||= [];
        my @trans = (@{$self->{transactions}}, ['add',$file]);
        $self->_update_ctrl( contents => \@newlist, transactions => \@trans);
    }

    my $newobj = (
        -d $absfile) 
            ? VCS::Lite::Repository->new($absfile, store => $self->{store}) 
            : VCS::Lite::Element->new($absfile, store => $self->{store}
    );
    
    $remainder ? $newobj->add($remainder) : $newobj;
}

sub add_element {
    my ($self,$file) = @_;
    (-d $file) ? undef : add(@_);
}

sub add_repository {
    my ($self,$dir) = @_;
    return if -f $dir;

    mkdir catfile($self->{path},$dir);
    add(@_);
}

sub remove {
    my $self = shift;
    my ($file) = validate_pos(@_, { type => SCALAR });

    my @contents;
    my $doit = 0;

    for (@{$self->{contents}}) {
        if ($file eq $_) {
            $doit++;
        } else {
            push @contents,$_;
        }
    }
    return unless $doit;

    $self->_mumble("Remove $file from " . $self->path);
    $self->{transactions} ||= [];
    my @trans = (@{$self->{transactions}}, ['remove',$file]);
    $self->_update_ctrl( contents => \@contents, transactions => \@trans);
    1;
}

sub contents {
    my $self = shift;

    map {
        my $file = catfile($self->{path},$_);
        (-d $file) 
            ? VCS::Lite::Repository->new($file,
                verbose => $self->{verbose},
                store => $self->{store})
            : VCS::Lite::Element->new($file,
                verbose => $self->{verbose},
                store => $self->{store});
        } @{$self->{contents}};
}

sub elements {
    my $self = shift;

    grep {$_->isa('VCS::Lite::Element')} $self->contents;
}

sub repositories {
    my $self = shift;

    grep {$_->isa('VCS::Lite::Repository')} $self->contents;
}

sub traverse {
    my $self = shift;
    my $func = shift;
    my %args = validate(@_, 
        {
            recurse => 0,
            params => { type => ARRAYREF | SCALAR, optional => 1 },
        } );

    my @out;
    $args{params} ||= [];
    $args{params} = [$args{params}] unless ref $args{params};

    for ($self->contents) {
        if ($args{recurse} && ($args{recurse} eq 'pre')) {
            my @subout = grep {defined $_} $_->traverse($func,%args);
            push @out,\@subout if @subout;
        }
        my @res = grep {defined $_} ((ref $func) ?
            &$func($_,@{$args{params}}) :
            $_->$func(@{$args{params}}));
        push @out,@res;
        if ($args{recurse} && ($args{recurse} ne 'pre')) {
            my @subout = grep {defined $_} $_->traverse($func,%args);
            push @out,\@subout if @subout;
        }
    }
    @out;
}

sub check_out {
    my $self = shift;
    my $newpath = shift;
    my %args = validate(@_, 
        {
            store => { type => SCALAR|OBJECT, optional => 1 },
        } );

    $self->_mumble("Check out " . $self->path . " to $newpath");
#    $self->{transactions} ||= [];
    my $newrep = VCS::Lite::Repository->new(
        $newpath,
        verbose => $self->{verbose},
        %args);
    $newrep->_update_ctrl( 
        parent              => $self->{path},
        contents            => $self->{contents},
        original_contents   => $self->{contents},
        parent_baseline     => $self->latest,
        parent_store        => $self->{store}
    );
    $self->traverse('_check_out_member', params => [$newpath,%args]);
    VCS::Lite::Repository->new(
        $newpath,
        verbose => $self->{verbose},
        %args);
    # This is different from the $newrep object, as it is fully populated.
}

sub check_in {
    my $self = shift;
    my %args = validate ( @_, 
        {
            check_in_anyway => 0,
            description     => { type => SCALAR },
        } );

    $self->_mumble("Checking in " . $self->path);
    if (($self->{transactions} && @{$self->{transactions}})
        || $args{check_in_anyway}) {

        $self->_mumble("Updating directory changes");

        my $newgen = $args{generation} || $self->latest;
        $newgen =~ s/(\d+)$/$1+1/e;
        $self->{generation} ||= {};
        my %gen = %{$self->{generation}};
        $gen{$newgen} = {
            author          => $self->user,
            description     => $args{description},
            updated         => localtime->datetime,
            transactions    => $self->{transactions},
            contents        => $self->{contents},
        };

        $self->{latest} ||= {};
        my %lat = %{$self->{latest}};
        $newgen =~ /(\d+\.)*\d+$/;
        my $base = $1 || '';
        $lat{$base}=$newgen;
        delete $self->{transactions};

        $self->_update_ctrl( generation => \%gen, latest => \%lat);
    }

    $self->traverse('check_in', params => [%args]);
}

sub commit {
    my ($self,$parent) = @_;

    my $path = $self->path;
    my $repos_name = (splitdir($self->path))[-1];
    my $parent_repos_path = $self->{parent} || catdir($parent,$repos_name);
    $self->_mumble("Committing $path to $parent_repos_path");
    my $parent_repos = VCS::Lite::Repository->new(
        $parent_repos_path,
        verbose     => $self->{verbose},
        store       => $self->{parent_store} || $self->{store});

    my $orig = VCS::Lite->new($repos_name,undef,$parent_repos->{contents});
    my $changed = VCS::Lite->new($repos_name,undef,$self->{contents});

    $self->_apply($parent_repos,$orig->delta($changed));
    $self->traverse('commit',
        params => $self->{parent} || catdir($parent,$repos_name));
}

sub update {
    my ($self,$srep) = @_;

    my $file = $self->path;
    my $repos_name = (splitdir($file))[-1];
    $self->{parent} ||= catdir($srep,$repos_name);
    my $parent = $self->{parent};
    $self->_mumble("Updating $file from $parent");
    my $baseline = $self->{baseline} || 0;
    my $parbas = $self->{parent_baseline};

    my $orig = $self->fetch( generation => $baseline);
    my $parele = VCS::Lite::Repository->new(
        $parent,
        verbose => $self->{verbose},
        store => $self->{parent_store});

    my $parfrom  = $parele->fetch( generation => $parbas);
    my $parlat   = $parele->latest; # was latest($parbas) - buggy
    my $parto    = $parele->fetch( generation => $parlat);
    my $origplus = $parfrom->merge($parto,$orig);

    my $chg = VCS::Lite->new($repos_name,undef,$self->{contents});
    my $merged = $orig->merge($origplus,$chg);
    $parele->_apply($self,$chg->delta($merged));

    $self->_update_ctrl(baseline => $self->latest, parent_baseline => $parlat);

    $self->traverse('update', params => $parent);
}

sub fetch {
    my $self = shift;
    my %args = validate ( @_, 
        {
            time        => 0,
            generation  => 0,
        } );

    my $gen = exists($args{generation}) ? $args{generation} : $self->latest;

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

    return if $gen && $self->{generation} && !$self->{generation}{$gen};

    my $cont = 
        $gen 
            ? $self->{generation}{$gen}{contents} 
            : $self->{original_contents} || [];

    my $file = $self->{path};
    $gen ||= 0;
    VCS::Lite->new("$file\@\@$gen",undef,$cont);
}

sub _apply {
    my ($src,$dest,$delt) = @_;

    return unless $delt;

    my $srcpath = $src->path;
    my $path = $dest->path;

    for (map {@$_} $delt->hunks) {
        my ($ind,$lin,$val) = @$_;
        if ($ind eq '-') {
            $dest->remove($val);
        } elsif ($ind eq '+') {
            my $destname = catdir($path,$val);
            my $srcname = catdir($srcpath,$val);
            # $srcname is false if catdir can't construct a dir, e.g.
            # if on VMS and $val contains a dot
            mkdir $destname if $srcname && -d $srcname;
            my $newobj = $dest->add($val);
            if (exists($dest->{parent}) && ($dest->{parent} eq $srcpath)) {
                $newobj->{parent} = catdir($dest->{parent},$val);
                $newobj->{parent_store} = $dest->{parent_store};
                $newobj->{parent_baseline} = 0;
                $newobj->save;
            }
            if (exists($src->{parent}) && ($src->{parent} eq $path)) {
                my $srcobj = $src->{store}->retrieve($srcname);
                $srcobj->{parent} = catdir($src->{parent},$val);
                $srcobj->{parent_store} = $src->{parent_store};
                $srcobj->{parent_baseline} = 0;
                $srcobj->save;
            }
        }
    }
}

sub _check_out_member {
    my $self    = shift;
    my $newpath = shift;
    my %args = validate(@_, 
        {
            store => { type => SCALAR|OBJECT, optional => 1 },
        } );

    my $repos_name = (splitdir($self->path))[-1];
    my $newrep = VCS::Lite::Repository->new(
        $newpath,
        verbose => $self->{verbose},
        %args);

    my $new_repos = catdir($newpath,$repos_name);

    $self->check_out($new_repos,%args);
}

sub _update_ctrl {
    my ($self,%args) = @_;

    my $path = $args{path} || $self->{path};
    for (keys %args) {
        $self->{$_} = $args{$_};
    }

    $self->{updated} = localtime->datetime;
    $self->save;
}

1;

__END__

#----------------------------------------------------------------------------

=head1 NAME

VCS::Lite::Repository - Minimal version Control system - Repository object

=head1 SYNOPSIS

  use VCS::Lite::Repository;
  my $rep = VCS::Lite::Repository->new($ENV{VCSROOT});
  my $dev = $rep->check_out('/home/me/dev');
  $dev->add_element('testfile.c');
  $dev->add_repository('sub');
  $dev->traverse(\&do_something);
  $dev->check_in( description => 'Apply change');
  $dev->update;
  $dev->commit;

=head1 DESCRIPTION

VCS::Lite::Repository is a freestanding version control system that is
platform independent. The module is pure perl, and only makes use of
other code that is available for all platforms.

=head2 new

  my $rep = VCS::Lite::Repository->new('/local/fileSystem/path',
                    store => 'inSituYAML');

A new repository object is created and associated with a directory on
the local file system. If the directory does not exist, it is created.
If the directory does not contain a repository, an empty repository
is created.

The store parameter here is used to designate the store in which
the repository is held. This parameter can be an object, a class or
a string representing a package name inside VCS::Lite::Repository::Store.
The default is inSituStorable; also available in the distribution is
inSituYAML, which requires YAML to be installed, but makes repositories
and elements that are human readable.

The control files associated with the repository live under a directory
.VCSLite inside the associated directory (_VCSLITE on VMS as dots are
not allowed in directory names on this platform), and these are in
L<YAML> format. The repository directory can contain VCS::Lite elements
(which are version controlled), other repository diretories, and also files
and directories which are not version controlled.

=head2 add

  my $ele = $rep->add('foobar.pl');
  my $ele = $rep->add('mydir');

If given a directory, returns a VCS::Lite::Repository object for the
subdirectory. If this does not already have a repository, one is created.

Otherwise it returns the VCS::Lite::Element object corresponding to a file
of that name. The element is added to the list of elements inside the
repository. If the file does not exist, it is created as zero length.
If the file does exist, its contents become the generation 0 baseline for
the element, otherwise generation 0 is the empty file.

The methods add_element and add_repository do the same thing, but check
to make sure that the paremeter is a plain file (or a directory in the case
of add_repository) and return if this is not the case. Add_repository
will also create the directory if it does not exist.

=head2 remove

   $rep->remove('foobar.pl');

This is the opposite of add. It does not delete any files, merely removes the
association between the repository and the element or subrepository.

=head2 traverse

  $rep->traverse(\&mysub);
  $rep->traverse('name', recurse => 1);
  $rep->traverse('bar_method', params => ['bar', 1]);

Apply a callback to each element and repository inside the repository.
You can supply a method, such as 'name', which results in the method
being called for all members of the repository rep, or you can supply
your own code in a coderef (the first parameter passed will still be the
object traversed. Return values are passed through traverse as a list.

If you specify a true value for the recurse option, traverse will also
be called on each member of $rep. This has no effect on elements
(VCS::Lite::Element->traverse returns undef). Return values from a
recursion pass appear as an arrayref in the output. If you specify the
parameter recurse as the value 'pre', traverse will be called on each
member before the action being applied.

Of course, the action can do its own recursion, instead of traverse itself
applying the recursion. traverse is used internally to implement check_out,
check_in, commit and update methods.

=head2 check_out

  my $newrep = $rep->check_out( store => 'YAML');

Note: prior to version 0.08, this was known as clone, but the API has
changed to use a more meanningful name.

Checking out generates a new tree of repositories and elements, putting
in place a relationship between the repositories; the original is the
B<parent repository>.

The new repository does not have to use the same repository store as the
parent.

=head2 check_in

Note: this is not the opposite operation to check_out. Use this method when
you have changes that you want to go into a repository.

=head2 commit

This method is used to propagate a change from a repository to its parent.

=head2 update

This method applies changes that have happened to the parent, to the
repository. This will merge with any changes in the current repository.

=head2 repositories

Return the currently available repositories.

=head2 add_repository

Add a repository to the current parent.

=head2 elements

Return the list of elements in the current repository.

=head2 add_element

Add an element to the current repository.

=head2 contents

Returns the full contents of the current repository, as objects.

=head2 fetch

Returns the VCS object for a given generation, or the latest generation.

=head1 ENVIRONMENT VARIABLES

=head2 USER

The environment variable B<USER> is used to determine the author of
changes. In a Unix environment, this should be adequate for out-of-the-box
use. An additional environment variable, B<VCSLITE_USER> is also checked,
and this takes precedence.

Windows users will need to set one of these environment variables, or
the application will croak with "Author not specified".

For more dynamic applications (such as CGI scripts that run as WWW, but
receive the username from a cookie), you can set the package variable:
$VCS::Lite::Repository::username. Note: there could be some problems with
Modperl here - patches welcome.

=head1 TO DO

Integration with L<VCS> suite.

=head1 SEE ALSO

L<VCS::Lite::Element>, L<VCS::Lite>, L<YAML>.

=cut

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
