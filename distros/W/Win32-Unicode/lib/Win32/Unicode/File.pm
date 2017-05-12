package Win32::Unicode::File;

use strict;
use warnings;
use 5.008003;
use Carp qw(croak);
use File::Basename qw(basename);
use Scalar::Util qw(blessed);
use Exporter 'import';

use Win32::Unicode::Util;
use Win32::Unicode::Error;
use Win32::Unicode::Constant;
use Win32::Unicode::Console;
use Win32::Unicode::XS;
use Fcntl qw(:seek);

our @EXPORT = qw/file_type file_size copyW moveW unlinkW touchW renameW statW utimeW/;
our @EXPORT_OK = qw/filename_normalize slurp/;
our %EXPORT_TAGS = ('all' => [@EXPORT, @EXPORT_OK]);

our $VERSION = '0.38';

my %FILE_TYPE_ATTRIBUTES = (
    s => FILE_ATTRIBUTE_SYSTEM,
    r => FILE_ATTRIBUTE_READONLY,
    h => FILE_ATTRIBUTE_HIDDEN,
    d => FILE_ATTRIBUTE_DIRECTORY,
    a => FILE_ATTRIBUTE_ARCHIVE,
    n => FILE_ATTRIBUTE_NORMAL,
    t => FILE_ATTRIBUTE_TEMPORARY,
    c => FILE_ATTRIBUTE_COMPRESSED,
    o => FILE_ATTRIBUTE_OFFLINE,
    i => FILE_ATTRIBUTE_NOT_CONTENT_INDEXED,
    E => FILE_ATTRIBUTE_ENCRYPTED,
);

sub new {
    my $class = shift;
    $class = ref $class || $class;

    my $self = bless \do { local *FH }, $class;
    tie *$self, $class, $self;

    $self->open(@_) or return if @_;
    return $self;
}

sub open {
    my ($self, $attr, $file) = @_;
    croak('Usage: $wfh->open($attrebute, $filename)') unless defined $attr && defined $file;

    $file = cygpathw($file) or return if CYGWIN;
    my $utf16_file = utf8_to_utf16(catfile $file) . NULL;

    if ($attr =~ s/(:.*)$//) {
        $self->binmode($1);
    }

    my $handle = 
        $attr eq '<' || $attr eq 'r' || $attr eq 'rb' ? _create_file(
            $utf16_file,
            GENERIC_READ,
            OPEN_EXISTING,
        ) :
        $attr eq '>' || $attr eq 'w' || $attr eq 'wb' ? _create_file(
            $utf16_file,
            GENERIC_WRITE,
            CREATE_ALWAYS,
        ) :
        $attr eq '>>' || $attr eq 'a' ? _create_file(
            $utf16_file,
            GENERIC_WRITE,
            OPEN_ALWAYS,
        ) :
        $attr eq '+<' || $attr eq 'r+' ? _create_file(
            $utf16_file,
            GENERIC_READ | GENERIC_WRITE,
            OPEN_EXISTING,
        ) :
        $attr eq '+>' || $attr eq 'w+' ? _create_file(
            $utf16_file,
            GENERIC_READ | GENERIC_WRITE,
            CREATE_ALWAYS,
        ) :
        $attr eq '+>>' || $attr eq 'a+' ? _create_file(
            $utf16_file,
            GENERIC_READ | GENERIC_WRITE,
            OPEN_ALWAYS,
        ) :
        croak("'$attr' is unkown attribute")
    or return Win32::Unicode::Error::_set_errno;

    return Win32::Unicode::Error::_set_errno if $handle == INVALID_VALUE;

    *$self->{_handle} = $handle;
    $self->binmode if $attr eq 'rb' or $attr eq 'wb';

    $self->seek(0, 2) if $attr eq '>>' || $attr eq 'a' || $attr eq '+>>' || $attr eq 'a+';

    require Win32::Unicode::Dir;
    *$self->{_file_path} = File::Spec->rel2abs($file, Win32::Unicode::Dir::getcwdW());
    *$self->{_authflush} = 0;

    return $self;
}

sub _create_file {
    my $file = shift;
    my $type = shift;
    my $disp = shift;

    return create_file(
        $file,
        $type,
        FILE_SHARE_READ | FILE_SHARE_WRITE,
        $disp,
        FILE_ATTRIBUTE_NORMAL,
    );
}

sub close {
    my $self = shift;
    if (exists *$self->{_handle}) {
        close_handle(*$self->{_handle}) or return Win32::Unicode::Error::_set_errno;
        delete *$self->{_handle};
    }
    return 1;
}

sub fileno {
    my $self = shift;
    return *$self->{_handle};
}

sub getc {
    my $self = shift;
    $self->read(my $buf, 1);
    return $buf;
}

sub read {
    my $self   = shift;
    my $into   = \$_[0]; shift;
    my $len    = shift;
    my $offset = shift || 0;

    my ($bytes_read_num, $data) = win32_read_file(*$self->{_handle}, $len);
    return Win32::Unicode::Error::_set_errno if $bytes_read_num == -1;

    if ($offset > 0) {
        substr($$into, $offset) = $data if length($$into) >= $offset;
    }
    elsif ($offset < 0) {
        croak('Offset outside string') if length($$into) + $offset < 0;
        substr($$into, $offset) = $data;
    }
    else {
        $$into = $data;
    }

    if (*$self->{_encode} && length $$into) {
        $$into = *$self->{_encode}->decode($$into);
    }

    return $bytes_read_num;
}
*sysread = *read;

sub _readline {
    my $self = shift;

    my $encoder;
    if (*$self->{_encode}) {
        $encoder = *$self->{_encode};
        delete *$self->{_encode};
    }

    my $line = '';
    while (index($line, $/) == $[ -1) {
        my $char = $self->getc;
        last if not defined $char or $char eq '';
        $line .= $char;
    }

    $line =~ s/\015\012/\n/ unless *$self->{_binmode};

    if ($encoder) {
        $line = $encoder->decode($line);
        *$self->{_encode} = $encoder;
    }

    return $line eq '' ? () : $line;
};

sub readline {
    my $self = shift;

    if (wantarray) {
        my @lines;
        while (my $line = $self->_readline) {
            push @lines, $line;
        }
        return @lines;
    }
    else {
        return $self->_readline;
    }
}

# no fearture 'say' or $wfh->say(@_);
sub say {
    my $self = shift;
    local $\ = "\n";
    $self->print(@_);
}

sub print {
    my $self = shift;
    my $buff = join defined $, ? $, : '', @_;
    $buff .= $\ if defined $\; # maybe use feature 'say'
    $self->write($buff);
}

sub printf {
    my $self = shift;
    my $format = shift;
    $self->write(sprintf $format, @_);
}

sub write {
    @_ = ($_[0], $_[1]);
    goto &syswrite;
}

sub syswrite {
    return 0 if @_ > 2 && !$_[2];
    my ($self, $buff, $len, $offset) = @_;

    $buff =~ s/\r?\n/\r\n/g unless *$self->{_binmode};
    $buff = *$self->{_encode}->encode($buff) if *$self->{_encode};

    use bytes;

    $buff = substr $buff, $offset if $offset;
    unless (defined $len) {
        $len = length $buff;
    }
    elsif ((my $buff_len = length $buff) < $len) {
        $len = $buff_len;
    }

    croak('got negative length on syswrite()') if $len < 0;

    my $write_size = win32_write_file(*$self->{_handle}, $buff, $len);
    return Win32::Unicode::Error::_set_errno if $write_size == -1;

    if (*$self->{_autoflush}) {
        $self->flush or return;
    }

    return $write_size;
}

sub seek {
    my $self = shift;
    my $low = shift;
    my $whence = shift;

    my $result;
    if (is64int($low)) {
        my ($pos_low, $pos_high);
        if ($low > 0) {
            $pos_low  = $low % _32INT;
            $pos_high = $low / _32INT;
        }
        else {
            $pos_low  = $low % _S32INT;
            $pos_high = $low / _S32INT;
        }
        my $st = set_file_pointer(*$self->{_handle}, $pos_low, $pos_high, $whence) or return Win32::Unicode::Error::_set_errno;
        return $st->{high} ? to64int($st->{high}, $st->{low}) : $st->{low};
    }
    else {
        my $high = 0;
        $high = ~0 if $low < 0;
        my $st = set_file_pointer(*$self->{_handle}, $low, $high, $whence) or return Win32::Unicode::Error::_set_errno;
        return $st->{high} ? to64int($st->{high}, $st->{low}) : $st->{low};
    }
}
*sysseek = *seek;

sub tell {
    $_[0]->seek(0, SEEK_CUR);
}

sub flock {
    my $self = shift;
    $self = tied(*$self);
    my $ope = shift;

    croak('Usage: flock $fh, $operation') unless defined $ope;

    return unlock_file(*$self->{_handle}) if $ope == 8;

    my $result = lock_file(*$self->{_handle}, $ope);
    unless (defined $result) {
        require Errno;
        $! = Errno::EINVAL();
        return;
    }

    return $result;
}
*flockW = \&flock;

sub unlock {
    shift->flock(8);
}

sub slurp {
    my $self = shift;
    croak 'Usage: slurp(filename) or $fh->slurp()' unless defined $self;

    my $opts = ref $_[0] eq 'HASH' ? shift : { @_ };
    my $wantarray = wantarray;

    unless (ref $self) {
        my $fh = __PACKAGE__->new(r => $self) or croak "Can't read '$self': $!";
        return $fh->slurp($opts);
    }

    my $org_data = {
        pos     => $self->tell,
        binmode => *$self->{_binmode},
        encode  => *$self->{_encode},
    };

    if (exists $opts->{binmode}) {
        $self->binmode($opts->{binmode});
    }

    my $buf_ref = $opts->{buf_ref} || \my $buf;
    $$buf_ref   = '';

    my $file_size = $self->file_size;
    unless ($file_size) {
        return
            $opts->{scalar_ref} ? $buf_ref :
            $opts->{array_ref}  ? []       :
            $wantarray          ? ()       : '';
    }

    $self->seek(0, SEEK_SET);
    my $blk_size  = $opts->{blk_size} || 1024 * 1024;
    if ($file_size <= $blk_size) {
        $self->read($$buf_ref, $blk_size);
    }
    else {
        1 while $self->read($$buf_ref, $blk_size, length $$buf_ref);
    }
    $self->seek($org_data->{pos}, SEEK_SET);

    $$buf_ref =~ s/\015\012/\n/g unless *$self->{_binmode};

    *$self->{_binmode} = $org_data->{binmode};
    *$self->{_encode}  = $org_data->{encode};

    if ($wantarray || $opts->{array_ref}) {
        my $sep = $/;
        $sep = '\n\n+' if defined $sep && $sep eq '';

        my @lines = length $$buf_ref ? $$buf_ref =~ /(.*?$sep|.+)/sg : ();
        chomp @lines if $opts->{chomp};

        return \@lines if $opts->{array_ref};
        return @lines;
    }

    return $buf_ref if $opts->{scalar_ref};
    return $$buf_ref if defined $wantarray;
    return;
}
*readfile = *slurp;

sub write_file {
    my $self = shift;

    if (!ref $self) {
        my $fh = __PACKAGE__->new(w => $self) or croak("$self: $!");
        return $fh->print(@_);
    }

    return $self->print(@_);
}

sub binmode {
    my $self = shift;
    my $layer = shift;

    if (not defined $layer or $layer eq 1) {
        *$self->{_binmode} = 1;
        return 1;
    }

    if (defined $layer) {
        if ($layer =~ /:raw/) {
            *$self->{_binmode} = 1;
        }

        if ($layer =~ /:(utf-?8)/i or $layer =~ /:encoding\(([^\)]+)\)/) {
            *$self->{_encode} = Encode::find_encoding($1);
        }

        croak("Unknown layer $layer") unless *$self->{_binmode} or *$self->{_encode}
    }

    return 1;
}

sub eof {
    my $self = shift;

    my $current = $self->TELL() + 0;
    my $end     = file_size($self) + 0;

    return $current == $end;
}

sub file_path {
    my $self = shift;
    return *$self->{_file_path} unless @_;
    *$self->{_file_path} = shift;
}
*path = \&file_path;

sub statW {
    my $file = shift;
    croak('Usage: statW(filename)') unless defined $file;
    my $wantarray = wantarray;
    my $blessed = blessed $file;

    my $fi;
    if ($blessed && $file->isa('Win32::Unicode::File') && *$file->{_handle}) {
        my $fh = *$file;
        my $file_path = CYGWIN ? Encode::encode_utf8($fh->{_file_path}) : utf8_to_utf16($fh->{_file_path}) . NULL;
        $fi = get_stat_data($file_path, $fh->{_handle}, 0) or return Win32::Unicode::Error::_set_errno;
    }
    elsif ($blessed && $file->isa('Win32::Unicode::Dir') && $file->{handle}) {
        my $dir_path = CYGWIN ? Encode::encode_utf8($file->{dir}) : utf8_to_utf16($file->{dir}) . NULL;
        $fi = get_stat_data($dir_path, $file->{handle}, 1) or return Win32::Unicode::Error::_set_errno;
    }
    else {
        $file = cygpathw($file) or return if CYGWIN;
        $file = catfile $file;

        my ($handle, $wdir);
        if (file_type(d => $file)) {
            require Win32::Unicode::Dir;
            $wdir = Win32::Unicode::Dir->new->open($file);
            $handle = $wdir->{handle};
        }
        else {
            $handle = create_file(
                utf8_to_utf16($file) . NULL,
                GENERIC_READ,
                FILE_SHARE_READ,
                OPEN_EXISTING,
                FILE_ATTRIBUTE_NORMAL,
            );
        }
        return Win32::Unicode::Error::_set_errno if $handle == INVALID_VALUE;
        $file = CYGWIN ? Encode::encode_utf8($file) : utf8_to_utf16($file) . NULL;
        $fi = get_stat_data($file, $handle, $wdir ? 1 : 0) or return Win32::Unicode::Error::_set_errno;
        if ($wdir) {
            $wdir->close or return Win32::Unicode::Error::_set_errno;
        }
        else {
            close_handle($handle) or return Win32::Unicode::Error::_set_errno;
        }
    }

    my $result = $fi;
    unless (CYGWIN) {
        $result->{blksize} = '';
        $result->{blocks}  = '';
    }
    $result->{size} = $fi->{size_high} ? to64int($fi->{size_high}, $fi->{size_low}) : $fi->{size_low};
    delete $result->{size_high};
    delete $result->{size_low};

    return $wantarray ? (
        $result->{dev},     #  0 dev      device number of filesystem
        $result->{ino},     #  1 ino      inode number
        $result->{mode},    #  2 mode     file mode  (type and permissions)
        $result->{nlink},   #  3 nlink    number of (hard) links to the file
        $result->{uid},     #  4 uid      numeric user ID of file's owner
        $result->{gid},     #  5 gid      numeric group ID of file's owner
        $result->{rdev},    #  6 rdev     the device identifier (special files only)
        $result->{size},    #  7 size     total size of file, in bytes
        $result->{atime},   #  8 atime    last access time in seconds since the epoch
        $result->{mtime},   #  9 mtime    last modify time in seconds since the epoch
        $result->{ctime},   # 10 ctime    inode change time in seconds since the epoch (*)
        $result->{blksize}, # 11 blksize  preferred block size for file system I/O
        $result->{blocks},  # 12 blocks   actual number of blocks allocated
    ) : $result;
}

sub utimeW {
    my ($atime, $mtime, @files) = @_;
    $atime = $mtime = time if !defined $atime && !defined $mtime;
    my $ret = 0;
    for my $file (@files) {
        $file = *$file->{_file_path} if blessed($file) && $file->isa('Win32::Unicode::File') && *$file->{_handle};
        $file = cygpathw($file) or return if CYGWIN;
        $file = catfile $file;
        my $file_path = CYGWIN ? Encode::encode_utf8($file) : utf8_to_utf16($file) . NULL;
        ++$ret if update_time($atime, $mtime, $file_path);
    }
    return $ret;
}

sub file_type {
    croak('Usage: type(attribute, file_or_dir_name)') unless @_ == 2;
    my $attr = shift;
    my $file = shift;
    $file = cygpathw($file) or return if CYGWIN;
    $file = catfile $file;

    my $get_attr = _get_file_type($file);
    return unless defined $get_attr;
    for (split //, $attr) {
        if ($_ eq 'e') {
            next;
        }

        if ($_ eq 'f') {
            return if $get_attr & $FILE_TYPE_ATTRIBUTES{d};
            next;
        }

        unless (defined $FILE_TYPE_ATTRIBUTES{$_}) {
            Carp::carp "unkown attribute '$_'";
            next;
        }
        return unless $get_attr & $FILE_TYPE_ATTRIBUTES{$_};
    }
    return 1;
}

sub file_size {
    my $file = shift;
    croak('Usage: file_size(filename)') unless defined $file;

    if (ref $file eq __PACKAGE__) {
        my $self = "$file" =~ /GLOB/ ? tied *$file : $file;
        my $st = get_file_size(*$self->{_handle}) or return Win32::Unicode::Error::_set_errno;
        return $st->{high} ? to64int($st->{high}, $st->{low}) : $st->{low};
    }

    $file = cygpathw($file) or return if CYGWIN;
    $file = catfile $file;

    return unless file_type(f => $file);

    my $handle = create_file(
        utf8_to_utf16($file) . NULL,
        GENERIC_READ,
        FILE_SHARE_READ,
        OPEN_EXISTING,
        FILE_ATTRIBUTE_NORMAL,
    );
    return Win32::Unicode::Error::_set_errno if $handle == INVALID_VALUE;

    my $st = get_file_size($handle) or return Win32::Unicode::Error::_set_errno;
    close_handle($handle) or return Win32::Unicode::Error::_set_errno;

    return $st->{high} ? to64int($st->{high}, $st->{low}) : $st->{low};
}

# like unix touch command
sub touchW {
    my @files = @_ ? @_ : ($_);
    my $count = 0;
    for my $file (@files) {
        $file = cygpathw($file) or next if CYGWIN;
        my $utf16_file = utf8_to_utf16(catfile $file) . NULL;
        my $handle = _create_file($utf16_file, GENERIC_WRITE, CREATE_NEW) or next;
        $count++;
        close_handle($handle);
    }
    Win32::Unicode::Error::_set_errno unless $count;
    return $count;
}

# like CORE::unlink
sub unlinkW {
    my @files = @_ ? @_ : ($_);
    my $count = 0;
    for my $file (@files) {
        $file = cygpathw($file) or return if CYGWIN;
        $file = utf8_to_utf16(catfile $file) . NULL;
        $count += delete_file($file) ? 1 : 0;
    }
    Win32::Unicode::Error::_set_errno unless $count;
    return $count;
}

# like File::Copy::copy
sub copyW {
    croak('Usage: copyW(from, to [, over])') if @_ < 2;
    my ($from, $to) = _file_name_validete(shift, shift);
    my $over = shift || 0;

    $from = cygpathw($from) or return if CYGWIN;
    $to   = cygpathw($to)   or return if CYGWIN;

    $from = utf8_to_utf16($from) . NULL;
    $to   = utf8_to_utf16($to) . NULL;

    return copy_file($from, $to, !$over) ? 1 : Win32::Unicode::Error::_set_errno;
}

# move file
sub moveW {
    croak('Usage: moveW(from, to [, over])') if @_ < 2;
    my ($from, $to) = _file_name_validete(shift, shift);
    my $over = shift || 0;

    unless (move_file(utf8_to_utf16($from) . NULL, utf8_to_utf16($to) . NULL)) {
        return unless copyW($from, $to, $over);
        return unless unlinkW($from);
    };

    return 1;
}
*renameW = \&moveW;

my $back_to_dir = qr/^\.\.$/;
my $in_dir      = qr#[\\/]$#;

sub _file_name_validete {
    croak('from is a undefined values') unless defined $_[0];
    croak('to is a undefined values')   unless defined $_[1];

    my $from = catfile shift;
    my $to = shift;

    if ($to =~ $back_to_dir or $to =~ $in_dir or (CYGWIN ? file_type(d => cygpathw($to)) : file_type(d => $to))) {
        $to = catfile $to, basename($from);
    }
    $to = catfile $to;

    return $from, $to;
}

my %win32_taboo = (
    '\\' => "\x{ffe5}", # ￥
    '/'  => "\x{ff0f}", # ／
    ':'  => "\x{ff1a}", # ：
    '*'  => "\x{ff0a}", # ＊
    '?'  => "\x{ff1f}", # ？
    '"'  => "\x{2033}", # ″
    '<'  => "\x{ff1c}", # ＜
    '>'  => "\x{ff1e}", # ＞
    '|'  => "\x{ff5c}", # ｜
);

sub filename_normalize {
    my $file_name = shift;
    croak('Usage: filename_nomalize($file_name)') unless defined $file_name;
    $file_name =~ s#([\\\/\:\*\?\"\<\>|])#$win32_taboo{$1}#ge;
    return $file_name;
}

sub error {
    return errorW;
}

sub _get_file_type {
    my $file = shift;
    $file = utf8_to_utf16($file) . NULL;
    my $result = get_file_attributes($file);
    if (defined $result && $result == INVALID_VALUE) {
        return Win32::Unicode::Error::_set_errno;
    }
    return $result;
}

# Tie Handle
sub TIEHANDLE {
    defined $_[1] && UNIVERSAL::isa($_[1], __PACKAGE__) ? $_[1] : shift->new(@_);
}
sub OPEN     { shift->open(@_)    }
sub CLOSE    { shift->close       }
sub BINMODE  { shift->binmode(@_) }
sub PRINT    { shift->print(@_)   }
sub PRINTF   { shift->printf(@_)  }
sub WRITE    { shift->write(@_)   }
sub READ     { shift->read(@_)    }
sub READLINE { shift->readline    }
sub GETC     { shift->getc        }
sub SEEK     { shift->seek(@_)    }
sub TELL     { shift->tell        }
sub EOF      { shift->eof         }
sub FILENO   { shift->fileno      }
sub DESTROY  { shift->close       }

# IO::File compatibles
sub flush {
    my $self = shift;
    win32_flush_file_buffers(*$self->{_handle});
}

sub sync {
    croak('sync not implemented');
}

sub autoflush {
    my $self = shift;
    my $prev = *$self->{_autoflush};
    *$self->{_autoflush} = @_ > 0 ? $_[0] : 1;
    return $prev;
}

sub printflush {
    my $self = shift;
    $self->print(@_) && $self->flush;
}

sub getline  {
    croak('Usage: $fh->getline()') unless @_ == 1;
    scalar shift->readline;
}

sub getlines {
    croak('Usage: $fh->getlines()') unless @_ == 1;
    croak(q|Can't call $fh->getlines in a scalar context, use $fh->getline|)
        unless wantarray;
    shift->readline;
}

sub getpos {
    croak('Usage: $fh->getpos()') unless @_ == 1;
    my $pos = shift->tell;
    return $pos == -1 ? undef : $pos; ## no critic
}

sub setpos {
    croak('Usage: $fh->setpos($pos)') unless @_ == 2;
    my ($self, $pos) = @_;
    $self->seek($pos, 0);
    return $pos == -1 ? undef : $pos; ## no critic
}

sub opened {
    my $self = shift;
    return exists *$self->{_handle} ? 1 : 0;
}

1;
__END__
=head1 NAME

Win32::Unicode::File - Unicode string file utility.

=head1 SYNOPSIS

  use Win32::Unicode::File;

  my $file = "I \x{2665} Perl";

  unlinkW $file or die $!;
  copyW $from, $to or die $!;
  moveW $from, $to or die $!;
  file_type f => $file ? "$file is file" : "$file is not file";
  my $size = file_size $file;
  touchW $new_file;

=head1 DESCRIPTION

Win32::Unicode::File is Unicode string file utility.

=head1 METHODS

=over

=item B<new([$mode, $file_name])>

Crate a new Win32::Unicode::File instance. At the same time you can open the file to create an instance.

  my $fh = Win32::Unicode::File->new;
  my $fh = Win32::Unicode::File->new($mode, $file_name); # create an instance and open the file

=item B<open($mode, $file_name)>

like CORE::open, but compatibility is not an argument. can not be pipe open.

  $fh->open('<', $file_name) or die $!;

or

  open $fh, '<', $file_name or die $!;

Be useful mode

  <   = r   = rb
  >   = w   = wb
  >>  = a
  +<  = r+
  +>  = w+
  +>> = a+

=item B<close()>

like CORE::close.

  $fh->close;

or

  close $fh;

=item B<read($buff, $len)>

Like CORE::read.

  $fh->read(my $buff, $len) or die $!;

or

  read $fh, my $buff, $len;

=item B<readline()>

Like CORE::readline.

  my $line = $fh->readline;
  my @line = $fh->readline;

or
  my $line = readline $fh;
  my @line = <$fh>;

=item B<getc()>

Like CORE::getc.

  my $char = $fh->getc;

or

  my $char = getc $fh;

=item B<print(@str)>

Data write to file.

  $fh->print(@str);
  print $fh @str;

=item B<printf($format, @str)>

Formatted data write to file.

  $fh->printf('[%s]', $str);
  printf $fh '%d', $str;

=item B<write(@str)>

Data write to file. alias of $fh->print

  $fh->write(@str);

=item B<seek($ofset, $whence)>

Like CORE::seek.

  $fh->seek(10, 1);

or

  seek $fh, 1024, 2;

=item B<tell()>

Like CORE::tell.

  my $current = $fh->tell;

or

  my $current = tell $fh;

=item B<eof()>

Like CORE::eof.

  if ($fh->eof) {
     # ...snip
  }

or

  if (eof $fh) {
     # ...snip
  }

=item B<slurp()>

Read all data from the file.

  my $data = $fh->slurp;

=item B<binmode($layer)>

  $fh->binmode(':encoding(cp932)')

or

  binmode $fh, ':raw :utf8';

Currently available now is only the layer below.

  :raw
  :utf8
  :encoding(foo)

=item B<flock($operation)>

Like CORE::flock

  $fh->flock(2);

=item B<unlock()>

equals to

  $fh->flock(8);

=item B<error()>

get error message.

  $fh->error;

=item B<flush>

flush buffers.

  $fh->flush;

=item B<autoflush()>

enable or dsabile autoflush.

  $fh->autoflush;    # enable
  $fh->autoflush(0); # disable
  $fh->autoflush(1); # enable

=item B<printflush()>

write after flush.

  $fh->printflush('foobar');

same as

  $fh->print('foobar') && $fh->flush;

=item B<getline()>

Like C<< IO::File::getline >>.

  my $line = $fh->getline;

=item B<getlines()>

Like C<< IO::File::getlines >>.

  my @$lines = $fh->getlines;

=item B<getpos()>

Like C<< IO::File::getpos >>.

  my $pos = $fh->getpos;

=item B<setpos($pos)>

Like C<< IO::File::setpos >>.

  my $pos = $fh->setpos(10);

=item B<opened()>

Returns true if the object is currentry opened file, false otherwise.

  say $fh->opened ? 1 : 0;

=back

=head1 FUNCTIONS

=over

=item B<unlinkW($file)>

Like CORE::unlink.

  unlinkW $file or die $!;

=item B<copyW($from, $to)>

Like File::Copy::copy.

  copyW $from, $to or die $!;

=item B<moveW($from, $to)>

Like File::Copy::move.

  moveW $from, $to or die $!;

=item B<renameW($from, $to)>

Alias of moveW.

=item B<touchW($file)>

Like shell command C<touch>.

  touchW $file or die $!;

=item B<statW($file || $fh || $dir || $dh)>

Like CORE::stat.

  my @stat = statW $file or die $!;
  my $stat = statW $file or die $!;

or

  my $fh = Win32::Unicode::File->new(r => $file);
  my @stat = statW $fh or die $!;
  my $stat = statW $fh or die $!;

or

  my @stat = statW $dir or die $!;
  my $stat = statW $dir or die $!;

or

  my $dh = Win32::Unicode::Dir->new->open($dir);
  my @stat = statW $dh or die $!;
  my $stat = statW $dh or die $!;

If the array context, CORE:: stat like. However, scalar context case in hashref received.

=item B<utimeW($atime, $mtime, $file || $fh)>

Like CORE::utime.

  my $rc = utime($atime, $mtime, $file, $fh);

=item B<file_type('attribute', $file_or_dir)>

Get windows file type

  # attributes
  f => file
  d => directory
  e => exists
  s => system
  r => readonly
  h => hidden
  a => archive
  n => normal
  t => temporary
  c => compressed
  o => offline
  i => not content indexed
  E => encrypted

  if (file_type d => $file_ro_dir) {
     # snip
  }
  elsif (file_type fr => $file_or_dir) { # file type 'file' and 'readonly'
     # snip
  }

=item B<file_size($file)>

Get file size.
near C<-s $file>

  my $size = file_size $file;
  die $! unless defined $size;

=item B<filename_normalize($filename)>

Normalize the characters are not allowed in the file name. not export.

  use Win32::Unicode::File qw(filename_normalize);
  my $nomalized_file_name = filename_normalize($filename);

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
