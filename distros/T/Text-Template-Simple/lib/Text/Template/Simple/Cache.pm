## no critic (ProhibitUnusedPrivateSubroutines)
package Text::Template::Simple::Cache;
$Text::Template::Simple::Cache::VERSION = '0.91';
use strict;
use warnings;

use Carp qw( croak );
use Text::Template::Simple::Constants qw(:all);
use Text::Template::Simple::Util      qw( DEBUG LOG fatal );

my $CACHE = {}; # in-memory template cache

sub new {
   my $class  = shift;
   my $parent = shift || fatal('tts.cache.new.parent');
   my $self   = [undef];
   bless $self, $class;
   $self->[CACHE_PARENT] = $parent;
   return $self;
}

sub id {
   my $self = shift;
   my $val  = shift;
   $self->[CACHE_PARENT][CID] = $val if $val;
   return $self->[CACHE_PARENT][CID];
}

sub type {
   my $self = shift;
   my $parent = $self->[CACHE_PARENT];
   return $parent->[CACHE] ? $parent->[CACHE_DIR] ? 'DISK'
                                                  : 'MEMORY'
                           : 'OFF';
}

sub reset { ## no critic (ProhibitBuiltinHomonyms)
   my $self   = shift;
   my $parent = $self->[CACHE_PARENT];
   %{$CACHE}  = ();

   if ( $parent->[CACHE] && $parent->[CACHE_DIR] ) {

      my $cdir = $parent->[CACHE_DIR];
      require Symbol;
      my $CDIRH = Symbol::gensym();
      opendir $CDIRH, $cdir or fatal( 'tts.cache.opendir' => $cdir, $! );
      require File::Spec;
      my $ext = quotemeta CACHE_EXT;
      my $file;

      while ( defined( $file = readdir $CDIRH ) ) {
         if ( $file =~ m{ ( .* $ext) \z}xmsi ) {
            $file = File::Spec->catfile( $parent->[CACHE_DIR], $1 );
            LOG( UNLINK => $file ) if DEBUG;
            unlink $file;
         }
      }

      closedir $CDIRH;
   }
   return 1;
}

sub dumper {
   my $self  = shift;
   my $type  = shift || 'structure';
   my $param = shift || {};
   fatal('tts.cache.dumper.hash')        if ref $param ne 'HASH';
   my %valid = map { ($_, $_) } qw( ids structure );
   fatal('tts.cache.dumper.type', $type) if not $valid{ $type };
   my $method = '_dump_' . $type;
   return $self->$method( $param ); # TODO: modify the methods to accept HASH
}

sub _dump_ids {
   my $self   = shift;
   my $parent = $self->[CACHE_PARENT];
   my $p      = shift;
   my $VAR    = $p->{varname} || q{$} . q{CACHE_IDS};
   my @rv;

   if ( $parent->[CACHE_DIR] ) {

      require File::Find;
      require File::Spec;
      my $ext = quotemeta CACHE_EXT;
      my $re  = qr{ (.+?) $ext \z }xms;
      my($id, @list);

      File::Find::find(
         {
            no_chdir => 1,
            wanted   => sub {
                           if ( $_ =~ $re ) {
                              ($id = $1) =~ s{.*[\\/]}{}xms;
                              push @list, $id;
                           }
                        },
         },
         $parent->[CACHE_DIR]
      );

      @rv = sort @list;

   }
   else {
      @rv = sort keys %{ $CACHE };
   }

   require Data::Dumper;
   my $d = Data::Dumper->new( [ \@rv ], [ $VAR ]);
   return $d->Dump;
}

sub _dump_structure {
   my $self    = shift;
   my $parent  = $self->[CACHE_PARENT];
   my $p       = shift;
   my $VAR     = $p->{varname} || q{$} . q{CACHE};
   my $deparse = $p->{no_deparse} ? 0 : 1;
   require Data::Dumper;
   my $d;

   if ( $parent->[CACHE_DIR] ) {
      $d = Data::Dumper->new( [ $self->_dump_disk_cache ], [ $VAR ] );
   }
   else {
      $d = Data::Dumper->new( [ $CACHE ], [ $VAR ]);
      if ( $deparse ) {
         fatal('tts.cache.dumper' => $Data::Dumper::VERSION)
            if !$d->can('Deparse');
         $d->Deparse(1);
      }
   }

   my $str = eval { $d->Dump; };

   if ( my $error = $@ ) {
      if ( $deparse && $error =~ RE_DUMP_ERROR ) {
         my $name = ref($self) . '::dump_cache';
         warn "$name: An error occurred when dumping with deparse "
             ."(are you under mod_perl?). Re-Dumping without deparse...\n";
         warn "$error\n";
         my $nd = Data::Dumper->new( [ $CACHE ], [ $VAR ]);
         $nd->Deparse(0);
         $str = $nd->Dump;
      }
      else {
         croak $error;
      }
   }

   return $str;
}

sub _dump_disk_cache {
   require File::Find;
   require File::Spec;
   my $self    = shift;
   my $parent  = $self->[CACHE_PARENT];
   my $pattern = quotemeta DISK_CACHE_MARKER;
   my $ext     = quotemeta CACHE_EXT;
   my $re      = qr{(.+?) $ext \z}xms;
   my(%disk_cache);

   my $process = sub {
      my $file  = $_;
      my @match = $file =~ $re;
      return if ! @match;
      (my $id = $match[0]) =~ s{.*[\\/]}{}xms;
      my $content = $parent->io->slurp( File::Spec->canonpath($file) );
      my $ok      = 0;  # reset
      my $_temp   = EMPTY_STRING; # reset

      foreach my $line ( split m{\n}xms, $content ) {
         if ( $line =~ m{$pattern}xmso ) {
            $ok = 1;
            next;
         }
         next if not $ok;
         $_temp .= $line;
      }

      $disk_cache{ $id } = {
         MTIME => (stat $file)[STAT_MTIME],
         CODE  => $_temp,
      };
   };

   File::Find::find(
      {
         no_chdir => 1,
         wanted   => $process,
      },
      $parent->[CACHE_DIR]
   );
   return \%disk_cache;
}

sub size {
   my $self   = shift;
   my $parent = $self->[CACHE_PARENT];

   return 0 if not $parent->[CACHE]; # calculate only if cache is enabled

   if ( my $cdir = $parent->[CACHE_DIR] ) { # disk cache
      require File::Find;
      my $total  = 0;
      my $ext    = quotemeta CACHE_EXT;

      my $wanted = sub {
         return if $_ !~ m{ $ext \z }xms; # only calculate "our" files
         $total += (stat $_)[STAT_SIZE];
      };

      File::Find::find( { wanted => $wanted, no_chdir => 1 }, $cdir );
      return $total;

   }
   else { # in-memory cache

      local $SIG{__DIE__};
      if ( eval { require Devel::Size; 1; } ) {
         my $dsv = Devel::Size->VERSION;
         LOG( DEBUG => "Devel::Size v$dsv is loaded." ) if DEBUG;
         fatal('tts.cache.develsize.buggy', $dsv) if $dsv < DEVEL_SIZE_VERSION;
         my $size = eval { Devel::Size::total_size( $CACHE ) };
         fatal('tts.cache.develsize.total', $@) if $@;
         return $size;
      }
      else {
         warn "Failed to load Devel::Size: $@\n";
         return 0;
      }

   }
}

sub has {
   my($self, @args ) = @_;
   fatal('tts.cache.pformat') if @args % 2;
   my %opt    = @args;
   my $parent = $self->[CACHE_PARENT];

   if ( not $parent->[CACHE] ) {
      LOG( DEBUG => 'Cache is disabled!') if DEBUG;
      return;
   }


   my $id  = $parent->connector('Cache::ID')->new;
   my $cid = $opt{id}   ? $id->generate($opt{id}  , 'custom')
           : $opt{data} ? $id->generate($opt{data}          )
           :              fatal('tts.cache.incache');

   if ( my $cdir = $parent->[CACHE_DIR] ) {
      require File::Spec;
      return -e File::Spec->catfile( $cdir, $cid . CACHE_EXT ) ? 1 : 0;
   }
   else {
      return exists $CACHE->{ $cid } ? 1 : 0;
   }
}

sub _is_meta_version_old {
   my $self = shift;
   my $v    = shift;
   return 1 if ! $v; # no version? archaic then
   my $pv = PARENT->VERSION;
   foreach my $i ( $v, $pv ) {
      $i  =~ tr/_//d; # underscore versions cause warnings
      $i +=  0;       # force number
   }
   return 1 if $v < $pv;
   return;
}

sub hit {
   # TODO: return $CODE, $META;
   my $self     = shift;
   my $cache_id = shift;
   my $chkmt    = shift || 0;

   my $method = $self->[CACHE_PARENT][CACHE_DIR] ? '_hit_disk' : '_hit_memory';
   return $self->$method( $cache_id, $chkmt );
}

sub _hit_memory {
   my($self, $cache_id, $chkmt) = @_;
   if ( $chkmt ) {
      my $mtime = $CACHE->{$cache_id}{MTIME} || 0;
      if ( $mtime != $chkmt ) {
         LOG( MTIME_DIFF => "\tOLD: $mtime\n\t\tNEW: $chkmt" ) if DEBUG;
         return; # i.e.: Update cache
      }
   }
   LOG( MEM_CACHE => EMPTY_STRING ) if DEBUG;
   return $CACHE->{$cache_id}->{CODE};
}

sub _hit_disk {
   my($self, $cache_id, $chkmt) = @_;
   my $parent = $self->[CACHE_PARENT];
   my $cdir   = $parent->[CACHE_DIR];
   require File::Spec;
   my $cache = File::Spec->catfile( $cdir, $cache_id . CACHE_EXT );
   my $ok    = -e $cache && ! -d _ && -f _;
   return if not $ok;

   my $disk_cache = $parent->io->slurp($cache);
   my %meta;
   if ( $disk_cache =~ m{ \A \#META: (.+?) \n }xms ) {
      %meta = $self->_get_meta( $1 );
      fatal('tts.cache.hit.meta', $@) if $@;
   }
   if ( $self->_is_meta_version_old( $meta{VERSION} ) ) {
      my $id = $parent->[FILENAME] || $cache_id;
      warn "(This message will only appear once) $id was compiled with"
          .' an old version of ' . PARENT . ". Resetting cache.\n";
      return;
   }
   if ( my $mtime = $meta{CHKMT} ) {
      if ( $mtime != $chkmt ) {
         LOG( MTIME_DIFF => "\tOLD: $mtime\n\t\tNEW: $chkmt") if DEBUG;
         return; # i.e.: Update cache
      }
   }

   my($CODE, $error) = $parent->_wrap_compile($disk_cache);
   $parent->[NEEDS_OBJECT] = $meta{NEEDS_OBJECT} if $meta{NEEDS_OBJECT};
   $parent->[FAKER_SELF]   = $meta{FAKER_SELF}   if $meta{FAKER_SELF};

   fatal('tts.cache.hit.cache', $error) if $error;
   LOG( FILE_CACHE => EMPTY_STRING )    if DEBUG;
   #$parent->[COUNTER]++;
   return $CODE;
}

sub populate {
   my($self, $cache_id, $parsed, $chkmt) = @_;
   my $parent = $self->[CACHE_PARENT];
   my $target = ! $parent->[CACHE]     ? '_populate_no_cache'
              :   $parent->[CACHE_DIR] ? '_populate_disk'
              :                          '_populate_memory'
              ;

   my($CODE, $error) = $self->$target( $parsed, $cache_id, $chkmt );
   $self->_populate_error( $parsed, $cache_id, $error ) if $error;
   ++$parent->[COUNTER];
   return $CODE;
}

sub _populate_error {
   my($self, $parsed, $cache_id, $error) = @_;
   my $parent   = $self->[CACHE_PARENT];
   croak $parent->[VERBOSE_ERRORS]
         ?  $parent->_mini_compiler(
               $parent->_internal('compile_error'),
               {
                  CID    => $cache_id ? $cache_id : 'N/A',
                  ERROR  => $error,
                  PARSED => $parsed,
                  TIDIED => $parent->_tidy( $parsed ),
               }
            )
         : $error
         ;
}

sub _populate_no_cache {
   # cache is disabled
   my($self, $parsed, $cache_id, $chkmt) = @_;
   my($CODE, $error) = $self->[CACHE_PARENT]->_wrap_compile($parsed);
   LOG( NC_POPUL => $cache_id ) if DEBUG >= DEBUG_LEVEL_INSANE;
   return $CODE, $error;
}

sub _populate_memory {
   my($self, $parsed, $cache_id, $chkmt) = @_;
   my $parent = $self->[CACHE_PARENT];
   my $c = $CACHE->{ $cache_id } = {}; # init
   my($CODE, $error)  = $parent->_wrap_compile($parsed);
   $c->{CODE}         = $CODE;
   $c->{MTIME}        = $chkmt if $chkmt;
   $c->{NEEDS_OBJECT} = $parent->[NEEDS_OBJECT];
   $c->{FAKER_SELF}   = $parent->[FAKER_SELF];
   LOG( MEM_POPUL => $cache_id ) if DEBUG >= DEBUG_LEVEL_INSANE;
   return $CODE, $error;
}

sub _populate_disk {
   my($self, $parsed, $cache_id, $chkmt) = @_;

   require File::Spec;
   require Fcntl;
   require IO::File;

   my $parent = $self->[CACHE_PARENT];
   my %meta   = (
      CHKMT        => $chkmt,
      NEEDS_OBJECT => $parent->[NEEDS_OBJECT],
      FAKER_SELF   => $parent->[FAKER_SELF],
      VERSION      => PARENT->VERSION,
   );

   my $cache = File::Spec->catfile( $parent->[CACHE_DIR], $cache_id . CACHE_EXT);
   my $fh    = IO::File->new;
   $fh->open($cache, '>') or fatal('tts.cache.populate.write', $cache, $!);
   flock $fh, Fcntl::LOCK_EX();
   $parent->io->layer($fh);
   my $warn =  $parent->_mini_compiler(
                  $parent->_internal('disk_cache_comment'),
                  {
                     NAME => PARENT->class_id,
                     DATE => scalar localtime time,
                  }
               );
   my $ok = print { $fh } '#META:' . $self->_set_meta(\%meta) . "\n",
                          $warn,
                          $parsed;
   flock $fh, Fcntl::LOCK_UN();
   close $fh or croak "Unable to close filehandle: $!";
   chmod(CACHE_FMODE, $cache) || fatal('tts.cache.populate.chmod');

   my($CODE, $error) = $parent->_wrap_compile($parsed);
   LOG( DISK_POPUL => $cache_id ) if DEBUG >= DEBUG_LEVEL_INSANE;
   return $CODE, $error;
}

sub _get_meta {
   my $self = shift;
   my $raw  = shift;
   my %meta = map { split m{:}xms, $_ } split m{[|]}xms, $raw;
   return %meta;
}

sub _set_meta {
   my $self = shift;
   my $meta = shift;
   my $rv   = join q{|}, map { $_ . q{:} . $meta->{ $_ } } keys %{ $meta };
   return $rv;
}

sub DESTROY {
   my $self = shift;
   LOG( DESTROY => ref $self ) if DEBUG;
   $self->[CACHE_PARENT] = undef;
   @{$self} = ();
   return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Text::Template::Simple::Cache

=head1 VERSION

version 0.91

=head1 SYNOPSIS

   TODO

=head1 DESCRIPTION

Cache manager for C<Text::Template::Simple>.

=head1 NAME

Text::Template::Simple::Cache - Cache manager

=head1 METHODS

=head2 new PARENT_OBJECT

Constructor. Accepts a C<Text::Template::Simple> object as the parameter.

=head2 type

Returns the type of the cache.

=head2 reset

Resets the in-memory cache and deletes all cache files, 
if you are using a disk cache.

=head2 dumper TYPE

   $template->cache->dumper( $type, \%opt );

C<TYPE> can either be C<structure> or C<ids>.
C<dumper> accepts some arguments as a hash reference:

   $template->cache->dumper( $type, \%opt );

=over 4

=item C<varname>

Controls the name of the dumped structure.

=item no_deparse

If you set this to a true value, C<deparsing> will be disabled

=back

=head3 structure

Returns a string version of the dumped in-memory or disk-cache. 
Cache is dumped via L<Data::Dumper>. C<Deparse> option is enabled
for in-memory cache. 

Early versions of C<Data::Dumper> don' t have a C<Deparse>
method, so you may need to upgrade your C<Data::Dumper> or
disable C<deparsing> if you want to use this method.

=head3 ids

Returns a list including the names (ids) of the templates in
the cache.

=head2 id

Gets/sets the cache id.

=head2 size

Returns the total cache (disk or memory) size in bytes. If
memory cache is used, then you must have L<Devel::Size> installed
on your system to get the size of the data structure inside memory.

=head2 has data => TEMPLATE_DATA

=head2 has id   => TEMPLATE_ID

This method can be called with C<data> or C<id> named parameter. If you 
use the two together, C<id> will be used:

   if ( $template->cache->has( id => 'e369853df766fa44e1ed0ff613f563bd' ) ) {
      print "ok!";
   }

or

   if ( $template->cache->has( data => q~Foo is <%=$bar%>~ ) ) {
      print "ok!";
   }

=head2 hit

   TODO

=head2 populate

   TODO

=head1 AUTHOR

Burak Gursoy <burak@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2004 by Burak Gursoy.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
