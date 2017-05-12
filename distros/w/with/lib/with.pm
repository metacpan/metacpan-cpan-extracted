package with;

use 5.009004;

use strict;
use warnings;

use Carp qw/croak/;
use Filter::Util::Call;
use Text::Balanced qw/extract_variable extract_quotelike extract_multiple/;
use Scalar::Util qw/refaddr set_prototype/;

use Sub::Prototype::Util qw/flatten wrap/;

=head1 NAME

with - Lexically call methods with a default object.

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';

=head1 SYNOPSIS

    package Deuce;

    sub new { my $class = shift; bless { id = > shift }, $class }

    sub hlagh { my $self = shift; print "Deuce::hlagh $self->{id}\n" }


    package Pants;

    sub hlagh { print "Pants::hlagh\n" }

    our @ISA;
    push @ISA, 'Deuce';
    my $deuce = new Deuce 1;

    hlagh;         # Pants::hlagh

    {
     use with \$deuce;
     hlagh;        # Deuce::hlagh 1
     Pants::hlagh; # Pants::hlagh
 
     {
      use with \Deuce->new(2);
      hlagh;       # Deuce::hlagh 2
     }

     hlagh;        # Deuce::hlagh 1

     no with;
     hlagh;        # Pants::hlagh
    }

    hlagh;         # Pants::hlagh

=head1 DESCRIPTION

This pragma lets you define a default object against with methods will be called in the current scope when possible. It is enabled by the C<use with \$obj> idiom (note that you must pass a reference to the object). If you C<use with> several times in the current scope, the default object will be the last specified one.

=cut

my $EOP = qr/\n+|\Z/;
my $CUT = qr/\n=cut.*$EOP/;
my $pod_or_DATA = qr/
              ^=(?:head[1-4]|item) .*? $CUT
            | ^=pod .*? $CUT
            | ^=for .*? $EOP
            | ^=begin \s* (\S+) .*? \n=end \s* \1 .*? $EOP
            | ^__(DATA|END)__\r?\n.*
            /smx;

my $extractor = [
 { 'with::COMMENT'    => qr/(?<![\$\@%])#.*/ },
 { 'with::PODDATA'    => $pod_or_DATA },
 { 'with::QUOTELIKE'  => sub {
      extract_quotelike $_[0], qr/(?=(?:['"]|\bq.|<<\w+))/
 } },
 { 'with::VARIABLE'   => sub {
      extract_variable $_[0], qr/(?=\\?[\$\@\%\&\*])/
 } },
 { 'with::HASHKEY'    => qr/\w+\s*=>/ },
 { 'with::QUALIFIED'  => qr/\w+(?:::\w+)+(?:::)?/ },
 { 'with::SUB'        => qr/sub\s+\w+(?:::\w+)*/ },
 { 'with::FILEHANDLE' => qr/<[\$\*]?[^\W>]*>/ },
 { 'with::USE'        => qr/(?:use|no)\s+\S+/ },
];

my %skip;
$skip{$_} = 1 for qw/my our local sub do eval goto return
                     if else elsif unless given when or and 
                     while until for foreach next redo last continue
                     eq ne lt gt le ge cmp
                     map grep system exec sort print say
                     new
                     STDIN STDOUT STDERR/;

my @core = qw/abs accept alarm atan2 bind binmode bless caller chdir chmod
              chomp chop chown chr chroot close closedir connect cos crypt
              dbmclose dbmopen defined delete die do dump each endgrent
              endhostent endnetent endprotoent endpwent endservent eof eval
              exec exists exit exp fcntl fileno flock fork format formline
              getc getgrent getgrgid getgrnam gethostbyaddr gethostbyname
              gethostent getlogin getnetbyaddr getnetbyname getnetent
              getpeername getpgrp getppid getpriority getprotobyname
              getprotobynumber getprotoent getpwent getpwnam getpwuid
              getservbyname getservbyport getservent getsockname getsockopt
              glob gmtime goto grep hex index int ioctl join keys kill last lc
              lcfirst length link listen local localtime lock log lstat map
              mkdir msgctl msgget msgrcv msgsnd my next no oct open opendir
              ord our pack package pipe pop pos print printf prototype push
              quotemeta rand read readdir readline readlink recv redo ref
              rename require reset return reverse rewinddir rindex rmdir
              scalar seek seekdir select semctl semget semop send setgrent
              sethostent setnetent setpgrp setpriority setprotoent setpwent
              setservent setsockopt shift shmctl shmget shmread shmwrite
              shutdown sin sleep socket socketpair sort splice split sprintf
              sqrt srand stat study sub substr symlink syscall sysopen sysread
              sysseek system syswrite tell telldir tie tied time times
              truncate uc ucfirst umask undef unlink unpack unshift untie use
              utime values vec wait waitpid wantarray warn write/;

my %core;
$core{$_} = prototype "CORE::$_" for @core;
undef @core;
# Fake prototypes
$core{'not'}        = '$';
$core{'defined'}    = '_';
$core{'undef'}      = ';\[$@%&*]';

my %hints;

sub code {
 no strict 'refs';
 my $name = @_ > 1 ? join '::', @_
                   : $_[0];
 return *{$name}{CODE};
}

sub corewrap {
 my ($name, $par) = @_;
 return '' unless $name;
 my $wrap = 'with::core::' . $name;
 if (not code $wrap) {
  my $proto = $core{$name};
  my $func = wrap { 'CORE::' . $name => $proto }, compile => 1;
  my $code = set_prototype sub {
   my ($caller, $H) = (caller 0)[0, 10];
   my $id = ($H || {})->{with};
   my $obj;
   # Try method call.
   if ($id and $obj = $hints{$id}) {
    if (my $meth = $$obj->can($name)) {
     @_ = flatten $proto, @_ if defined $proto;
     unshift @_, $$obj;
     goto &$meth;
    }
   }
   # Try function call in caller namescape.
   my $qname = $caller . '::' . $name;
   if (code $qname) {
    @_ = flatten $proto, @_ if defined $proto;
    goto &$qname;
   }
   # Try core function call.
   my @ret = eval { $func->(@_) };
   if ($@) {
    # Produce a correct error in regard of the caller.
    my $msg = $@;
    $msg =~ s/(called)\s+at.*/$1/s;
    croak $msg;
   }
   return wantarray ? @ret : $ret[0];
  }, $proto;
  {
   no strict 'refs';
   *$wrap = $code;
  }
 }
 return $wrap . ' ' . $par;
}

sub subwrap {
 my ($name, $par, $proto) = @_;
 return '' unless $name;
 return "with::defer $par'$name'," unless defined $proto;
 my $wrap = 'with::sub::' . $name;
 if (not code $wrap) {
  my $code = set_prototype sub {
   my ($caller, $H) = (caller 0)[0, 10];
   my $id = ($H || {})->{with};
   my $obj;
   # Try method call.
   if ($id and $obj = $hints{$id}) {
    if (my $meth = $$obj->can($name)) {
     @_ = flatten $proto, @_;
     unshift @_, $$obj;
     goto &$meth;
    }
   }
   # Try function call in caller namescape.
   my $qname = $caller . '::' . $name;
   goto &$qname if code $qname;
   # This call won't succeed, but it'll throw an exception we should propagate.
   eval { no strict 'refs'; $qname->(@_) };
   if ($@) {
    # Produce a correct 'Undefined subroutine' error in regard of the caller.
    my $msg = $@;
    $msg =~ s/(called)\s+at.*/$1/s;
    croak $msg;
   }
   croak "$qname didn't exist and yet the call succeeded\n";
  }, $proto;
  {
   no strict 'refs';
   *$wrap = $code;
  }
 }
 return $wrap . ' '. $par;
}

sub defer {
 my $name = shift;
 my ($caller, $H) = (caller 0)[0, 10];
 my $id = ($H || {})->{with};
 my $obj;
 # Try method call.
 if ($id and $obj = $hints{$id}) {
  if (my $meth = $$obj->can($name)) {
   unshift @_, $$obj;
   goto &$meth;
  }
 }
 # Try function call in caller namescape.
 $name = $caller . '::' . $name;
 goto &$name if code $name;
 # This call won't succeed, but it'll throw an exception we should propagate.
 eval { no strict 'refs'; $name->(@_) };
 if ($@) {
  # Produce a correct 'Undefined subroutine' error in regard of the caller.
  my $msg = $@;
  $msg =~ s/(called)\s+at.*/$1/s;
  croak $msg;
 }
 croak "$name didn't exist and yet the call succeeded\n";
}

sub import {
 return unless defined $_[1] and ref $_[1];
 my $caller = (caller 0)[0];
 my $id = refaddr $_[1];
 $hints{$^H{with} = $id} = $_[1];
 filter_add sub {
  my ($status, $lastline);
  my ($data, $count) = ('', 0);
  while ($status = filter_read) {
   return $status if $status < 0;
   return $status unless defined $^H{with} && $^H{with} == $id;
   if (/^__(?:DATA)__\r?$/ || /\b(?:use|no)\s+with\b/) {
    $lastline = $_;
    last;
   }
   $data .= $_;
   ++$count;
   $_ = '';
  }
  return $count if not $count;
  my $instr;
  my @components;
  for (extract_multiple($data, $extractor)) {
   if (ref)       { push @components, $_; $instr = 0 }
   elsif ($instr) { $components[-1] .= $_ }
   else           { push @components, $_; $instr = 1 }
  }
  my $i = 0;
  $_ = join '',
        map { (ref) ? $; . pack('N', $i++) . $; : $_ }
         @components;
  @components = grep ref, @components;
  s/
    \b &? ([^\W\d]\w+) \s* (?!=>) (\(?)
   /
    $skip{$1} ? "$1 $2"
              : exists $core{$1} ? corewrap $1, $2
                                 : subwrap $1, $2, prototype($caller.'::'.$1)
   /sexg;
  s/\Q$;\E(\C{4})\Q$;\E/${$components[unpack('N',$1)]}/g;
  $_ .= $lastline if defined $lastline;
  return $count;
 }
}

sub unimport {
 $^H{with} = undef;
 filter_del;
}

=head1 HOW DOES IT WORK

The main problem to address is that lexical scoping and source modification can only occur at compile time, while object creation and method resolution happen at run-time.

The C<use with \$obj> statement stores an address to the variable C<$obj> in the C<with> field of the hints hash C<%^H>. It also starts a source filter that replaces function calls with calls to C<with::defer>, passing the name of the original function as the first argument. When the replaced function has a prototype or is part of the core, the call is deferred to a corresponding wrapper generated in the C<with> namespace. Some keywords that couldn't possibly be replaced are also completely skipped. C<no with> undefines the hint and deletes the source filter, stopping any subsequent modification in the current scope.

When the script is executed, deferred calls first fetch the default object back from the address stored into the hint. If the object C<< ->can >> the original function name, a method call is issued. If not, the calling namespace is inspected for a subroutine with the proper name, and if it's present the program C<goto>s into it. If that fails too, the core function with the same name is recalled if possible, or an "Undefined subroutine" error is thrown.

=head1 IGNORED KEYWORDS

A call will never be dispatched to a method whose name is one of :

    my our local sub do eval goto return
    if else elsif unless given when or and 
    while until for foreach next redo last continue
    eq ne lt gt le ge cmp
    map grep system exec sort print say
    new
    STDIN STDOUT STDERR

=head1 EXPORT

No function or constant is exported by this pragma.

=head1 CAVEATS

Most likely slow. Almost surely non thread-safe. Contains source filters, hence brittle. Messes with the dreadful prototypes. Crazy. Will have bugs.

Don't put anything on the same line of C<use with \$obj> or C<no with>.

When there's a function in the caller namespace that has a core function name, and when no method with the same name is present, the ambiguity is resolved in favor of the caller namespace. That's different from the usual perl semantics where C<sub push; push @a, 1> gets resolved to CORE::push.

If a method has the same name as a prototyped function in the caller namespace, and if a called is deferred to the method, it will have its arguments passed by value.

=head1 DEPENDENCIES

L<perl> 5.9.4.

L<Carp> (core module since perl 5).

L<Filter::Util::Call>, L<Scalar::Util> and L<Text::Balanced> (core since 5.7.3).

L<Sub::Prototype::Util> 0.08.

=head1 AUTHOR

Vincent Pit, C<< <perl at profvince.com> >>, L<http://www.profvince.com>.

You can contact me by mail or on #perl @ FreeNode (vincent or Prof_Vince).

=head1 BUGS

Please report any bugs or feature requests to C<bug-with at rt.cpan.org>, or through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=with>. I will be notified, and then you'll automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc with

=head1 ACKNOWLEDGEMENTS

A fair part of this module is widely inspired from L<Filter::Simple> (especially C<FILTER_ONLY>), but a complete integration was needed in order to add hints support and more placeholder patterns.

=head1 COPYRIGHT & LICENSE

Copyright 2008 Vincent Pit, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of with
