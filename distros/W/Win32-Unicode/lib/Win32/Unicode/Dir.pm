package Win32::Unicode::Dir;

use strict;
use warnings;
use 5.008003;
use Carp ();
use File::Basename qw/basename dirname/;
use Exporter 'import';

use Win32::Unicode::Util;
use Win32::Unicode::Error;
use Win32::Unicode::Constant;
use Win32::Unicode::File;
use Win32::Unicode::Console;
use Win32::Unicode::XS;

# export subs
our @EXPORT    = qw/file_type file_size mkdirW rmdirW getcwdW chdirW findW finddepthW mkpathW rmtreeW mvtreeW cptreeW dir_size file_list dir_list/;
our @EXPORT_OK = qw//;
our %EXPORT_TAGS = ('all' => [@EXPORT, @EXPORT_OK]);

our $VERSION = '0.38';

# global vars
our $cwd;
our $name;
our $dir;
our $skip_pattern = qr/\A(?:(?:\.{1,2})|(?:System Volume Information))\z/;

sub new {
    my $class = shift;
    bless {}, $class;
}

# like CORE::opendir
sub open {
    my $self = shift;
    my $dir = shift;
    _croakW('Usage $obj->open(dirname)') unless defined $dir;

    $dir = cygpathw($dir) or return if CYGWIN;

    $self->{dir} = $dir;
    $dir = utf8_to_utf16(catfile $dir, '*') . NULL;

    $self->find_first_file($dir);
    return Win32::Unicode::Error::_set_errno if $self->{handle} == INVALID_HANDLE_VALUE;

    $self->{first} = utf16_to_utf8($self->{first});

    return $self;
}

# like CORE::closedir
sub close {
    my $self = shift;
    _croakW("Can't open directory handle") unless $self->{handle};
    return Win32::Unicode::Error::_set_errno unless $self->find_close;
    delete @$self{qw[dir handle first FileInfo]};
    return 1;
}

# like CORE::readdir
sub fetch {
    my $self = shift;
    _croakW("Can't open directory handle") unless $self->{handle};

    # if defined first file
    my $first;
    if ($self->{first}) {
        $first = $self->{first};
        delete $self->{first};
    }

    # array or scalar
    if (wantarray) {
        my @files;

        push @files, $first if $first;
        while (defined(my $file = $self->find_next_file)) {
            push @files, utf16_to_utf8($file);
        }

        return @files;
    }
    else {
        return $first if $first;
        my $file = $self->find_next_file;
        return Win32::Unicode::Error::_set_errno unless defined $file;
        return utf16_to_utf8($file);
    }
}

*read = *readdir = \&fetch;

# like use Cwd qw/getcwd/;
sub getcwdW {
    utf16_to_utf8 get_current_directory();
}

# like CORE::chdir
sub chdirW {
    my $set_dir = shift;
    my $retry = shift || 0;
    _croakW('Usage: chdirW(dirname)') unless defined $set_dir;
    $set_dir = cygpathw($set_dir) or return if CYGWIN;
    $set_dir = catfile($set_dir);
    return Win32::Unicode::Error::_set_errno unless set_current_directory(utf8_to_utf16($set_dir) . NULL);
    return chdirW($set_dir, ++$retry) if CYGWIN && !$retry; # bug ?
    return 1;
}

# like CORE::mkdir
sub mkdirW {
    my $dir = defined $_[0] ? $_[0] : $_;
    $dir = cygpathw($dir) or return if CYGWIN;
    $dir = utf8_to_utf16(catfile $dir) . NULL;
    return create_directory($dir) ? 1 : Win32::Unicode::Error::_set_errno;
}

# like CORE::rmdir
sub rmdirW {
    my $dir = defined $_[0] ? $_[0] : $_;
    $dir = cygpathw($dir) or return if CYGWIN;
    $dir = utf8_to_utf16(catfile $dir) . NULL;
    return remove_directory($dir) ? 1 : Win32::Unicode::Error::_set_errno;
}

# like File::Path::rmtree
sub rmtreeW {
    my $dir = shift;
    my $stop = shift;
    _croakW('Usage: rmtreeW(dirname)') unless defined $dir;
    $dir = catfile $dir;

    return unless file_type(d => $dir);
    my $code = sub {
        my $file = $_;
        if (file_type(f => $file)) {
            if (not unlinkW $file) {
                return if $stop;
            }
        }

        elsif (file_type(d => $file)) {
            if (not rmdirW $file) {
                return if $stop;
            }
        }
    };

    finddepthW($code, $dir);

    return unless rmdirW($dir);
    return 1;
}

# like File::Path::mkpath
sub mkpathW {
    my $dir = shift;
    _croakW('Usage: mkpathW(dirname)') unless defined $dir;
    $dir = catfile $dir;

    my $mkpath = '.';
    for (splitdir $dir) {
        $mkpath = catfile $mkpath, $_;
        next if file_type d => $mkpath;
        return unless mkdirW $mkpath;
    }
    return 1;
}

# like File::Copy::copy
sub cptreeW {
    _croakW('Usage: cptreeW(from, to [, over])') unless defined $_[0] and defined $_[1];
    _cptree($_[0], $_[1], $_[2], 0);
}

sub mvtreeW {
    _croakW('Usage: mvtreeW(from, to [, over])') unless defined $_[0] and defined $_[1];
    _cptree($_[0], $_[1], $_[2], 1);
}

my $is_drive = qr/^[a-zA-Z]:/;
my $in_dir   = qr#[\\/]$#;

sub _cptree {
    my $from         = shift;
    my $to           = shift;
    my $over         = shift || 0;
    my $bymove       = shift || 0;
    my $content_only = 0;

    _croakW("$from: no such directory") unless file_type d => $from;

    $content_only = 1 if $from =~ $in_dir;
    $from = catfile $from;

    if ($to =~ $is_drive) {
        $to = catfile $to, !$content_only ? basename($from) : ();
    }
    else {
        $to = catfile getcwdW(), $to, !$content_only ? basename($from) : ();
    }

    unless (file_type d => $to) {
        mkdirW $to or _croakW("$to: " . $!);
    }

    my $replace_from = quotemeta $from;
    my $code = sub {
        my $from_file = $_;
        my $from_full_path = $Win32::Unicode::Dir::name;

        (my $to_file = $from_full_path) =~ s/$replace_from//;
        $to_file = catfile $to, $to_file;

        if (file_type d => $from_file) {
            rmdirW $from_file if $bymove;
            return;
        }

        my $to_dir = dirname $to_file;
        mkpathW $to_dir unless file_type d => $to_dir;

        if (file_type f => $from_file) {
            if ($over || not file_type f => $to_file) {
                ($bymove
                    ? moveW($from_file, $to_file, $over)
                    : copyW($from_file, $to_file, $over)
                ) or _croakW("$from_full_path to $to_file can't file copy ", errorW);
            }
        }
    };

    finddepthW($code, $from);
    if ($bymove && !$content_only) {
        return unless rmdirW $from;
    }
    return 1;
}

# like File::Find::find
sub findW {
    _croakW('Usage: findW(code_ref, dir)') unless @_ >= 2;
    my $opts = shift;
    @_ = ($opts, 0, @_);
    goto &_find_wrap;
}

# like File::Find::finddepth
sub finddepthW {
    _croakW('Usage: finddepthW(code_ref, dir)') unless @_ >= 2;
    my $opts = shift;
    @_ = ($opts, 1, @_);
    goto &_find_wrap;
}

sub _find_wrap {
    my $opts = shift;
    my $bydepth = shift;
    my @args = @_;

    if (ref $opts eq 'CODE') {
        $opts = { wanted => $opts };
    }
    elsif (ref $opts ne 'HASH') {
        _croakW('first args must be CODEREF or HASHREF specified');
    }

    if (ref $opts->{wanted} ne 'CODE') {
        _croakW('wanted must be CODEREF specified');
    }
    if (exists $opts->{preprocess} && ref $opts->{preprocess} ne 'CODE') {
        _croakW('preprocess must be CODEREF specified');
    }
    if (exists $opts->{postprocess} && ref $opts->{postprocess} ne 'CODE') {
        _croakW('postprocess must be CODEREF specified');
    }

    $opts->{bydepth} ||= $bydepth;

    local ($dir, $name, $cwd);

    for my $arg (@args) {
        $arg = catfile $arg;
       _croakW("$arg: no such directory") unless file_type(d => $arg);

        my $current = getcwdW;
        _find($opts, $arg);

        $opts->{postprocess}->() if $opts->{postprocess};
        chdirW($current) unless $opts->{no_chdir};

        $name = $cwd = $dir = undef;
    }

    return 1;
}

sub _find {
    my $opts    = shift;
    my $new_dir = shift;

    chdirW $new_dir or _croakW("$new_dir ", errorW) unless $opts->{no_chdir};

    $dir = $cwd = $cwd ? $opts->{no_chdir} ? $new_dir : catfile($cwd, $new_dir) : $new_dir; # $Win32::Unicode::Dir::(dir|cwd)

    my $wdir = Win32::Unicode::Dir->new;
    if ($opts->{no_chdir}) {
        $wdir->open($dir) or _croakW("can't open directory: $dir", errorW);
    }
    else {
        $wdir->open('.') or _croakW("can't open directory: $dir", errorW);
    }
    my @list = $wdir->fetch;
    $wdir->close or _croakW("can't close directory ", errorW);

    @list = $opts->{preprocess}->(@list) if $opts->{preprocess};

    for my $cur (@list) {
        next if $cur =~ $skip_pattern;

        $cur = catfile($cwd, $cur) if $opts->{no_chdir};

        unless ($opts->{bydepth}) {
            $::_ = $cur; # $_
            $name = $opts->{no_chdir} ? $cur : catfile $cwd, $cur; # $Win32::Unicode::Dir::name
            $opts->{wanted}->({
                file => $::_,
                path => $name,
                name => $name,
                cwd  => $cwd,
                dir  => $dir,
            });
        }

        if (file_type 'd', $cur) {
            _find($opts, $cur);

            $opts->{postprocess}->() if $opts->{postprocess};

            chdirW '..' unless $opts->{no_chdir};
            $dir = $cwd = catfile $cwd, '..'; # $Win32::Unicode::Dir::(dir|cwd)
        }

        if ($opts->{bydepth}) {
            $::_ = $cur; # $_
            $name = $opts->{no_chdir} ? $cur : catfile $cwd, $cur; # $Win32::Unicode::Dir::name
            $opts->{wanted}->({
                file => $::_,
                path => $name,
                name => $name,
                cwd  => $cwd,
                dir  => $dir,
            });
        }
    }
}

# get dir size
sub dir_size {
    my $dir = shift;
    _croakW('Usage: dir_size(dirname)') unless defined $dir;

    $dir = catfile $dir;

    my $size = 0;
    finddepthW(sub {
        my $file = $_;
        return if file_type d => $file;
        $size += file_size $file;
    }, $dir);

    return $size;
}

sub file_list {
    my $dir = shift;
    _croakW('Usage: file_list(dirname)') unless defined $dir;

    my $wdir = __PACKAGE__->new->open($dir) or return;
    return grep { !/^\.{1,2}$/ && file_type f => "$dir/$_" } $wdir->fetch;
}

sub dir_list {
    my $dir = shift;
    _croakW('Usage: dir_list(dirname)') unless defined $dir;

    my $wdir = __PACKAGE__->new->open($dir) or return;
    return grep { !/^\.{1,2}$/ && file_type d => "$dir/$_" } $wdir->fetch;
}

# return error message
sub error {
    return errorW;
}

sub _croakW {
    Win32::Unicode::Console::_row_warn(@_);
    die Carp::shortmess();
}

sub DESTROY {
    my $self = shift;
    $self->close if defined $self->{handle};
}

1;
__END__
=head1 NAME

Win32::Unicode::Dir - Unicode string directory utility.

=head1 SYNOPSIS

  use Win32::Unicode::Dir;
  use Win32::Unicode::Console;

  my $dir = "I \x{2665} Perl";

  my $wdir = Win32::Unicode::Dir->new;
  $wdir->open($dir) || die $wdir->error;
  for ($wdir->fetch) {
      next if /^\.{1,2}$/;

      my $full_path = "$dir/$_";
      if (file_type('f', $full_path)) {
          # $_ is file
      }
      elsif (file_type('d', $full_path))
          # $_ is directory
      }
  }
  $wdir->close || dieW $wdir->error;

  my $cwd = getcwdW();
  chdirW($change_dir_name);

  mkdirW $dir;
  rmdirW $dir;

=head1 DESCRIPTION

Win32::Unicode::Dir is Unicode string directory utility.

=head1 METHODS

=over

=item B<new>

Create a Win32::Unicode::Dir instance.

  my $wdir = Win32::Unicode::Dir->new;

=item B<open($dir)>

Like CORE::opendir.

  $wdir->open($dir) or die $!

=item B<fetch()>

Like CORE::readdir.

  while (my $file = $wdir->fetch) {
     # snip
  }

or

  for my $file ($wdir->fetch) {
     # snip
  }

=item B<read()>

Alias of C<fetch()>.

=item B<readdir()>

Alias of C<fetch()>.

=item B<close()>

Like CORE::closedir.

  $wdir->close or dieW $wdir->error

=item B<error()>

get error message.

=back

=head1 FUNCTIONS

=over

=item B<getcwdW>

Like Cwd::getcwd. get current directory.

  my $cwd = getcwdW;

=item B<chdirW($dir)>

Like CORE::chdir.

  chdirW $dir or die $!;

=item B<mkdirW($new_dir)>

Like CORE::mkdir.

  mkdirW $new_dir or die $!;

=item B<rmdirW($del_dir)>

Like CORE::rmdir.

  rmdirW($del_dir) or die $!;

=item B<rmtreeW($del_dir)>

Like File::Path::rmtree.

  rmtreeW $del_dir or die $!;

=item B<mkpathW($make_long_dir_name)>

Like File::Path::mkpath.

  mkpathW $make_long_dir_name or die $!

=item B<cptreeW($from, $to [, $over])>

copy directory tree.

  cptreeW $from, $to or die $!;

If C<$from> delimiter of directory is a terminator, move the contents of C<$from> to C<$to>.

  cptreeW 'foo/', 'hoge';

  # before current directory tree
  # ----------------------------
  # foo
  # foo/bar
  # foo/bar/baz
  # hoge
  # ----------------------------

  # before current directory tree
  # ----------------------------
  # foo
  # foo/bar
  # foo/bar/baz
  # hoge/
  # hoge/bar
  # hoge/bar/baz
  # ----------------------------

If just a directory name, is as follows

  cptreeW 'foo', 'hoge';

  # before current directory tree
  # ----------------------------
  # foo
  # foo/bar
  # foo/bar/baz
  # hoge
  # ----------------------------

  # before current directory tree
  # ----------------------------
  # foo
  # foo/bar
  # foo/bar/baz
  # hoge/foo
  # hoge/foo/bar
  # hoge/foo/bar/baz
  # ----------------------------

=item B<mvtreeW($from, $to [, $over]))>

move directory tree.

  mvtreeW $from, $to or die $!;

If C<$from> delimiter of directory is a terminator, move the contents of C<$from> to C<$to>.

  mvtreeW 'foo/', 'hoge';

  # before current directory tree
  # ----------------------------
  # foo
  # foo/bar
  # foo/bar/baz
  # hoge
  # ----------------------------

  # after current directory tree
  # ----------------------------
  # foo
  # hoge
  # hoge/bar
  # hoge/bar/baz
  # ----------------------------

If just a directory name, is as follows

  mvtreeW 'foo', 'hoge';

  # before current directory tree
  # ----------------------------
  # foo
  # foo/bar
  # foo/bar/baz
  # hoge
  # ----------------------------

  # after current directory tree
  # ----------------------------
  # hoge
  # hoge/foo
  # hoge/foo/bar
  # hoge/foo/bar/baz
  # ----------------------------

=item B<findW($code, $dir)>

like File::Find::find.

  findW \&wanted, $dir;
  sub wanted {
      my $file = $_;
      my $name = $Win32::Unicode::Dir::name;
      my $dir  = $Win32::Unicode::Dir::dir;
      my $cwd  = $Win32::Unicode::Dir::cwd; # $dir eq $cwd
  }

or

  findW \&wanted, @dirs;
  sub wanted{
      my $arg = shift;
      print $args->{file}; # eq $_
      print $args->{name}; # eq $Win32::Unicode::Dir::name
      print $args->{cwd};  # eq $Win32::Unicode::Dir::cwd
      print $args->{dir};  # eq $Win32::Unicode::Dir::dir
      print $args->{path}; # full path
  }

or

  findW \%options, @dirs;

=back

=head2 \%options

=over 3

=item C<wanted>

The value should be a code reference.
Like File::Find#wanted

=item C<preprocess>

The value should be a code reference.
Like File::Find#preprocess

=item C<postprocess>

The value should be a code reference.
Like File::Find#postprocess

=item C<no_chdir>

Boolean. If you set a true value will not change directories.
In this case, $_ will be the same as $Win32::Unicode::Dir::name.
Like File::Find#no_chdir

=back

=over

=item B<finddepthW($code, $dir)>

like File::Find::finddepth.

  finddepthW \&wanted, $driname;

equals to

  findW { wanted => \&wanted, bydepth => 1 }, $dirname;

=item B<dir_size($dir)>

get directory size.
this function are slow.

  my $dir_size = dir_size($dir) or die $!

=item B<file_list($dir)>

get files from $dir

  my @files = file_list $dir;

=item B<dir_list($dir)>

get directories from $dir

  my @dirs = dir_list $dir;

=back

=head1 AUTHOR

Yuji Shimada E<lt>xaicron@cpan.orgE<gt>

=head1 SEE ALSO

L<Win32::Unicode>

L<Win32::Unicode::File>

L<Win32::Unicode::Error>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
