package Text::Repository;

#----------------------------------------------------------------------
# $Id: Repository.pm,v 1.4 2002/01/18 14:25:11 dlc Exp $
#----------------------------------------------------------------------
#  Text::Repository - A simple way to store and retrieve text
#  Copyright (C) 2002 darren chamberlain <darren@cpan.org>
#
#  This program is free software; you can redistribute it and/or
#  modify it under the terms of the GNU General Public License as
#  published by the Free Software Foundation; version 2.
#
#  This program is distributed in the hope that it will be useful, but
#  WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
#  General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program; if not, write to the Free Software
#  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA
#  02111-1307  USA
#----------------------------------------------------------------------

use strict;
use vars qw($VERSION);
use subs qw(new add_path add_paths paths remove_path replace_paths
            reset fetch cached cache clear_cache);

$VERSION = sprintf "%d.%02d", q$Revision: 1.4 $ =~ /(\d+)\.(\d+)/;

use File::Spec;
use IO::File;
use Carp;

*isa = \&UNIVERSAL::isa;
use constant CACHE => 0;
use constant PATHS => 1;
use constant ORIGINAL => 2;

=head1 NAME

Text::Repository - A simple way to manage text without mixing it with Perl

=head1 ABSTRACT

Text::Repository attempts to simplify storing shared text between
multple Perl modules, scripts, templating systems, etc.  It does this
by allowing chunks of text to be stored with symbolic names.
Text::Repository was originally designed to store SQL queries, but can
of course be used with any kind of text that needs to be shared.

=head1 SYNOPSIS

  use Text::Repository;

  my @paths = ("/www/library", "$ENV{'HOME'}/text");
  my $rep = Text::Repository->new(@paths);

(See EXAMPLES for more.)

=head1 DESCRIPTION

Text::Repository provides the capability to store, use, and manage
text without having to mix them with Perl scripts and modules.  These
pieces of text can then be shared by multiple modules, scripts, or
templating systems with a minimum of fuss.

Text::Repository uses a series of one or more directories (specified
either when the class is instantiated or when needed) as a search
path; when a piece of text is requested using the instance's B<fetch>
method, Text::Repository looks in each of the directories in turn
until it finds a file with that name.  If the file is found, it is
opened and read, and the contents are returned to the caller as a
string.  Furthermore, the contents of the file are cached. Successive
calls to B<fetch> to retrieve the same piece of text return this
cached copy, provided the copy on disk has not changed more recently
than the copy in the cache.

Text::Repository was originally written to share complex SQL queries
among multiple modules; when the usage grew to include printf formats,
I realized it could be generalized to store any kind of text.  Because
no processing is done on the text before it is returned, the text in
the file can have any kind of markup.  In fact, the contents of the
file don't even have to be text; the caller decides how to use the
results returned from the B<fetch>.

=head1 CONSTRUCTOR

The constructor is called B<new>, and can be optionally passed a list
of directories to be added to the search path (directories can also be
added using the B<add_path> object method).

=cut

#
# Instantiates a new instance.  There is very little setup here;
# all the work (adding paths, etc) is handled by add_path.
#
sub new {
    my $class = shift;
    my $self = bless [ { }, [ ], \@_, ] => $class;
    $self->add_path(@_);

    return $self;
}

=head1 INSTANCE METHODS

=head2 B<add_path>

Adds a search path or paths to the instance.  The search path defines
where the instance looks for text snippets.  This can be called
multiple times, and this module imposes no limits on the number of
search paths.

B<add_paths> is an alias for B<add_path>, and should be used wherever
it makes the intent clearer.  For example, use B<add_path> to add a
single path, but B<add_paths> when assigning more than one:

    $rep->add_paths($new_path);

    $rep->add_paths(@new_paths);

Some steps are taken to ensure that a path only appears in the search
path once; any subsequent additions of an existing path are ignored.

=cut

# 
# add_path pushes one or more paths onto the object; these are
# searched when fetch is called.  Should add_path check -d first?
#
sub add_path {
    my $self = shift;
    my $paths = isa($_[0], "ARRAY") ? shift : \@_;
    my %paths;

    @{$self->[PATHS]} =
        grep { -d }
        grep { ++$paths{$_} == 1 }
        (@{$self->[PATHS]}, @{$paths});

    return $self;
}
*add_paths = *add_path;

=head2 B<paths> 

The paths method returns a list of the paths in the object (or a
reference to a list of the paths if called in scalar context).

=cut

sub paths {
    my $self = shift;
    return   @{$self->[PATHS]} if wantarray;
    return [ @{$self->[PATHS]} ];
}

=head2 B<remove_path>
 
remove_path deletes a path from the instance's search path.

=cut

sub remove_path {
    my $self = shift;
    my %paths = map { $_ => 1 } isa($_[0], "ARRAY") ? @{shift()} : @_;

    @{$self->[PATHS]} = grep { not defined $paths{$_} } @{$self->[PATHS]};

    return $self;
}

=head2 B<replace_paths>

B<replace_paths> provides a shortcut to reset the list of paths to a
new value.  It is equivalent to:

    for my $p ($rep->paths()) {
        $rep->remove_path($p);
    }
    $rep->clear_cache();
    $rep->add_paths(@new_paths);

B<replace_paths> returns the Text::Repository instance.

=cut

sub replace_paths {
    my $self = shift;

    for my $p ($self->paths) {
        $self->remove_path($p);
    }

    $self->clear_cache->add_paths(@_);

    return $self;
}

=head2 B<reset>

The B<reset> method returns the instance to the state it had when it
was created. B<reset> returns the Text::Repository instance.

=cut

sub reset {
    my $self = shift;

    $self->replace_paths($self->original_paths);

    return $self;
}

sub original_paths {
    my $self = shift;
    my @orig = @{$self->[ORIGINAL]};
    return wantarray ? @orig : \@orig;
}

=head2 B<fetch(NAME)>

The B<fetch> method does the actual fetching of the text.

B<fetch> is designed to be called with a keyword; this keyword
is turned into a filename that gets appended to each directory in
paths (as defined by $self->paths) in order until it finds a match.

Once fetch finds a match, the contents of the file is returned as a
single string.

If the file is not found, B<fetch> returns undef.

=cut

sub fetch {
    my $self = shift;
    my $text = shift || return;
    my ($fh, $filename);

    #
    # Check that $text doesn't begin with "../" or "/";
    # relative paths only
    #
    $text =~ s:^[./]*::;

    for my $path ($self->paths) {
        $filename = File::Spec->catfile($path, $text);

        # The caching mechanism
        if (my $cached = $self->cached($filename)) {
            return $cached;
        }

        unless (-e $filename && -r _) {
            $filename = "";
            next;
        }
        
        unless ($fh = IO::File->new($filename)) {
            carp "Can't open '$filename'";
            $filename = "";
            next;
        } else {
            local $/ = undef;
            my $content = $fh->getline;
            return $self->cache($filename, \$content);
        }
    }
}

sub cached {
    my $self = shift;
    my $filename = shift || return;

    if (defined $self->[CACHE]->{$filename}) {
        if (-M $filename > $self->[CACHE]->{$filename}->{'timestamp'}) {
            delete $self->[CACHE]->{$filename};
            return;
        } else {
            return ${$self->[CACHE]->{$filename}->{'content'}};
        }
    }

    return;
}

sub cache {
    my ($self, $filename, $content) = @_;
    my $cref;

    if (ref $content eq 'SCALAR') {
        $cref = $content;
    } else {
        $cref = \$content;
    }

    $self->[CACHE]->{$filename} = {
        timestamp => -M $filename,
        content   => $cref,
    };

    return $$cref;
}

=head2 B<clear_cache>

The B<clear_cache> method clears out the internal cache.  The only
times this becomes necessary to call is when the internal paths are
changed to the point where cached files will never be found again
(they become orphaned, in this case).   Note that B<replace_paths>
calls this method for you.

This method returns the Text::Repository instance, for chaining.

=cut

sub clear_cache {
    my $self = shift;
    $self->[CACHE] = { };
    return $self;
}

1;
__END__

=head1 CREATING TEXT FOR A REPOSITORY

The files that can be retrieved using Text::Repository can be stored
anywhere.  Creating files in a path referenced by a Text::Repository
instance can be done using any of the standard file creation or
editing methods:

  $ echo 'Hello, %s!' > /tmp/Greeting
  $ perl -MText::Repository
  my $rep = Text::Repository->new("/tmp");
  print $rep->fetch("Greeting");
  printf $rep->fetch("Greeting"), "world";
  ^D
  Hello, %s!
  Hello, world!

There are no methods for writing files using Text::Repository.

=head1 EXAMPLES

Using Text::Repository to separate SQL statements from code:

  use DBI;
  use Text::Repository;

  my $rep = Text::Repository->new("$ENV{'HOME'}/sql", "/www/sql");
  my $dbh = DBI->connect(@DSN);

  my $search = $rep->fetch("search");
  my $sth = $dbh->prepare($search);
  # and so on

Using Text::Repository to "skin" the output of a CGI script:

  use CGI;
  use Text::Repository;

  my $q = CGI->new;
  my $rep = Text::Repository->new("/www/repository");

  my $skin = $q->param("skin");
  my %components = (
    HEADER  => $rep->fetch("skins/$skin/header"),
    LINKBOX => $rep->fetch("linkbox"),
    FOOTER  => $rep->fetch("skins/$skin/footer"),
  );

  print $q->header("My Skinned Page"),
        $components{ HEADER },
        get_content($components{ LINKBOX }),
        $components{ FOOTER };

  sub get_content ($) {
  # and so on

Using Text::Repository to feed into Template Toolkit

  use Template;
  use Text::Repository;

  my @rep_dirs = qw(/www/templates /usr/local/apache/htdocs);
  my $rep = Text::Repository->new(@rep_dirs);
  my $t = Template->new;

  my $login = $rep->fetch("login");
  $t->process(\$login);

=head1 TODO

=head1 SEE ALSO

L<Perl>, L<Carp>, L<IO::File>, L<File::Spec>

=head1 AUTHOR

darren chamberlain <darren@cpan.org>

