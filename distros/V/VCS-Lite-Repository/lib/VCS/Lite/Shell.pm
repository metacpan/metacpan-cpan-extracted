package VCS::Lite::Shell;

use strict;
use warnings;

our $VERSION = '0.12';

#----------------------------------------------------------------------------

use vars qw (@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);

use Exporter ();
@ISA         = qw (Exporter);
#Give a hoot don't pollute, do not export more than needed by default
@EXPORT      = qw ();
@EXPORT_OK   = qw (store add remove list check_in check_out commit update fetch diff);
%EXPORT_TAGS = (
    local   => [qw/store add remove check_in fetch diff/],
    all     => [qw/store add remove list check_in fetch diff check_out commit update/]
);

use Params::Validate qw(:all);
use VCS::Lite::Repository;
use Cwd;

our %store_list;

#----------------------------------------------------------------------------

sub store {
    my ($which, $type, @att) = @_;

    $which ||= 'current';
    $type = 'VCS::Lite::Store::'.$type unless $type =~ /\:\:/;
    if ($type =~ /^\w+(:?\:\:\w+)*$/) {
        eval "require $type";
        carp $@ if $@;
    }

    $store_list{$which} = @att ? $type->new(@att) : $type;
}

sub repository {
    my ($store,$dir) = validate_pos( @_,
        { type => SCALAR | OBJECT},
        { type => SCALAR, default => '.'} );

    store($store, VCS::Lite::Repository->default_store)
        unless exists $store_list{$store};
    VCS::Lite::Repository->new( $dir, store=>$store_list{$store} );
}

sub member {
    my ($st,$mem) = validate_pos( @_,
        { type => SCALAR | OBJECT},
        { type => SCALAR, default => '.'} );

    store($st, VCS::Lite::Repository->default_store)
        unless exists $store_list{$st};
    $store_list{$st}->retrieve($mem);
}

sub add {
    my $ele = shift;

    repository('current')->add($ele);
}

sub remove {
    my $ele = shift;

    repository('current')->remove($ele);
}

sub list {
    my %par = validate(@_, {
        recurse => 0} );

    repository('current')->traverse( 'name', %par);
}

sub fetch {
    my ($ele, $gen) = validate_pos( @_, {type => SCALAR}, 0);

    my $mem = member('current',$ele);
    my %par = ();
    $par{generation} = $gen if defined $gen && $gen ne 'latest';
    $mem->fetch(%par)->text;
}

sub diff {
    my %par = validate( @_, 
        {
            file1 => { type => SCALAR },
            gen1 => { 
                type => SCALAR,
                optional => 1,
                regex => qr/^\d+$/
            },
            file2 => { 
                type => SCALAR,
                optional => 1,
            },
            gen2 => { 
                type => SCALAR,
                optional => 1,
                regex => qr/^\d+$|^latest$/
            },
        } );

    my $lite1 = member('current',$par{file1})
        ->fetch(exists($par{gen1}) ? (generation => $par{gen1}) : ());
    my $lite2;
    $par{file2} ||= $par{file1};
    if (exists $par{gen2}) {
        $lite2 = member('current',$par{file2})
          ->fetch(($par{gen1} eq 'latest') ? () : (generation => $par{gen2}));
    } else {
        $lite2 = VCS::Lite->new($par{file2});
    }

    my $d = $lite1->delta($lite2) or return '';
    $d->udiff;
}

sub check_out {
    my $parent_path = shift;

    store('current', VCS::Lite::Repository->default_store)
        unless exists $store_list{current};

    repository('parent',$parent_path)
        ->check_out( cwd(), store => $store_list{current} );
}

sub check_in {
    my ($what,$descr) = @_;

    member('current',$what)->check_in( description => $descr);
}

sub commit {
    repository('current')->commit();
}

sub update {
    repository('current')->update();
}

1; #this line is important and will help the module return a true value

__END__

#----------------------------------------------------------------------------

=head1 NAME

VCS::Lite::Shell - Non OO wrapper for VCS::Lite::Repository

=head1 SYNOPSIS

  use VCS::Lite::Shell;

  store('current' => 'YAML');
  store('parent' => 'YAML');
  check_out('../parent_dir');
  add('foo.pl');
  check_in("Add foo.pl to repository");
  commit();

=head1 DESCRIPTION

This module is a thin wrapper for the object orientated calls to methods
and repositories. It is aimed at programmers who don't want to embrace
the fullness of Perl-OO that is used in L<VCS::Lite::Repository>. The aim
is to provide the full functionality of the VCS Lite repository via exportable
subs. This interface is used by the L<VCShell> command shell.

The module retains a context of the current repository store and current
working directory. Move around with chdir, and the subroutines will operate
on the current working directory and the contents thereof.

The functions check_out, commit and update operate on a pair of repository
trees: the current repository and parent repository.

=head1 METHODS

=head2 add

  add('foo.pl');
  add('t/01_basic.t');

The first example adds the file foo.pl to the current repository. The second
example adds 01_basic.t to the repository t, having first added the repository
t to the current repository if this was necessary.

=head2 remove

  remove('foo.pl');

The opposite operation to add is remove. Note that this does not get rid of
the file from the directory, nor the element information. It merely removes
foo.pl from the list of elements in the current repository.

=head2 check_in

  check_in('foo.pl', description => 'Fix foo bugs');
  check_in('.', description => 'Prepare version 0.01 for release');

Checking in an element stores the contents of the file into the element store.
If the contents of the file is different from what was in the store already,
a new generation of the element is created; if the contents is identical, no
new generation is created.

Checking in a repository has two effects: any transactions to the repository,
i.e. adds and removes, are committed to the repository's transaction history,
and the check_in is applied recursively to everything (now) in the repository.

=head2 check_out

Checking out generates a new tree of repositories and elements, putting
in place a relationship between the repositories; the original is the
B<parent repository>.

=head2 fetch

  print fetch('foo.pl');
  my $old_foo = fetch('foo.pl', 1);   # Generation 1 of foo.pl

Fetch returns a scalar containing the contents of an element. The second
parameter is the generation number, which defaults to the latest one.

=head2 diff

  print diff (file1 => 'foo.pl');  # between latest checked in and outside
  print diff (file1 => 'foo.pl', gen1 => 1, gen2 => 3);
  print diff (file1 => 'foo.pl', file2 => 'bar.pl', gen2 => 'latest');

Diff returns the udiff output (similar to diff -u) between two generations,
or between a generation and the file outside. The parameter file1 is
mandatory, all others are optional. The parameter file2 defaults to the
value of file1; gen1 defaults to the latest generation of file1.

If no gen2 is specified, diff uses the file file2 outside the repository
(file1 if no file2 is specified). If you want diff to use the latest
generation of file2 instead, specify gen2 as 'latest'.

=head2 commit

This method is used to propagate a change from a repository to its parent.

=head2 update

This method applies changes that have happened to the parent, to the
repository. This will merge with any changes in the current repository.

=head2 list

Returns a list of all the repository objects.

=head2 member

Returns a repository element object for the given element.

=head2 repository

Returns a repository object for the given path.

=head2 store

Set the storage type.

=head1 SEE ALSO

perl(1).

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
