## no critic (ProhibitUnusedPrivateSubroutines)
package Text::Template::Simple::Base::Compiler;
$Text::Template::Simple::Base::Compiler::VERSION = '0.91';
use strict;
use warnings;

use Text::Template::Simple::Util qw(:all);
use Text::Template::Simple::Constants qw(:all);

sub _init_compile_opts {
   my $self = shift;
   my $opt  = shift || {};

   fatal('tts.base.compiler._compile.opt') if ref $opt ne 'HASH';

   # set defaults
   $opt->{id}       ||= EMPTY_STRING; # id is AUTO
   $opt->{map_keys} ||= 0;            # use normal behavior
   $opt->{chkmt}    ||= 0;            # check mtime of file template?
   $opt->{_sub_inc} ||= 0;            # are we called from a dynamic include op?
   $opt->{_filter}  ||= EMPTY_STRING; # any filters?

   # first element is the shared names. if it's not defined, then there
   # are no shared variables from top level
   if ( ref $opt->{_share} eq 'ARRAY' && ! defined $opt->{_share}[0] ) {
      delete $opt->{_share};
   }

   $opt->{as_is} = $opt->{_sub_inc} && $opt->{_sub_inc} == T_STATIC;

   return $opt;
}

sub _validate_chkmt {
   my($self, $chkmt_ref, $tmpx) = @_;
   ${$chkmt_ref} = $self->[TYPE] eq 'FILE'
                 ? (stat $tmpx)[STAT_MTIME]
                 : do {
                     DEBUG && LOG( DISABLE_MT =>
                                    'Disabling chkmt. Template is not a file');
                     0;
                  };
   return;
}

sub _compile_cache {
   my($self, $tmp, $opt, $id_ref, $code_ref) = @_;
   my $method   = $opt->{id};
   my $auto_id  = ! $method || $method eq 'AUTO';
   ${ $id_ref } = $self->connector('Cache::ID')->new->generate(
                     $auto_id ? ( $tmp ) : ( $method, 'custom' )
                  );

   # prevent overwriting the compiled version in cache
   # since we need the non-compiled version
   ${ $id_ref } .= '_1' if $opt->{as_is};

   ${ $code_ref } = $self->cache->hit( ${$id_ref}, $opt->{chkmt} );
   LOG( CACHE_HIT =>  ${$id_ref} ) if DEBUG && ${$code_ref};
   return;
}

sub _compile {
   my $self  = shift;
   my $tmpx  = shift || fatal('tts.base.compiler._compile.notmp');
   my $param = shift || [];
   my $opt   = $self->_init_compile_opts( shift );

   fatal('tts.base.compiler._compile.param') if ref $param ne 'ARRAY';

   my $tmp = $self->_examine( $tmpx );
   return $tmp if $self->[TYPE] eq 'ERROR';

   if ( $opt->{_sub_inc} ) {
      # TODO:generate a single error handler for includes, merge with _include()
      # tmpx is a "file" included from an upper level compile()
      my $etitle = $self->_include_error( T_DYNAMIC );
      my $exists = $self->io->file_exists( $tmpx );
      return $etitle . " '$tmpx' is not a file" if not $exists;
      # TODO: remove this second call somehow, reduce  to a single call
      $tmp = $self->_examine( $exists ); # re-examine
      $self->[NEEDS_OBJECT]++; # interpolated includes will need that
   }

   $self->_validate_chkmt( \$opt->{chkmt}, $tmpx ) if $opt->{chkmt};

   LOG( COMPILE => $opt->{id} ) if DEBUG && defined $opt->{id};

   my $cache_id = EMPTY_STRING;

   my($CODE);
   $self->_compile_cache( $tmp, $opt, \$cache_id, \$CODE ) if $self->[CACHE];

   $self->cache->id( $cache_id ); # if $cache_id;
   $self->[FILENAME] = $self->[TYPE] eq 'FILE' ? $tmpx : $self->cache->id;

   my($shead, @sparam) = $opt->{_share} ? @{$opt->{_share}} : ();

   LOG(
      SHARED_VARS => "Adding shared variables ($shead) from a dynamic include"
   ) if DEBUG && $shead;

   $CODE = $self->_cache_miss( $cache_id, $shead, \@sparam, $opt, $tmp ) if ! $CODE;

   my @args;
   push @args, $self   if $self->[NEEDS_OBJECT]; # must be the first
   push @args, @sparam if @sparam;
   push @args, @{ $self->[ADD_ARGS] } if $self->[ADD_ARGS];
   push @args, @{ $param };
   my $out = $CODE->( @args );

   $self->_call_filters( \$out, split RE_FILTER_SPLIT, $opt->{_filter} )
      if $opt->{_filter};

   return $out;
}

sub _cache_miss {
   my($self, $cache_id, $shead, $sparam, $opt, $tmp) = @_;
   # we have a cache miss; parse and compile
   LOG( CACHE_MISS => $cache_id ) if DEBUG;

   my $restore_header;
   if ( $shead ) {
      my $param_x = join q{,}, ('shift') x @{ $sparam };
      my $shared  = sprintf q~my(%s) = (%s);~, $shead, $param_x;
      $restore_header = $self->[HEADER];
      $self->[HEADER] = $shared . q{;} . ( $self->[HEADER] || EMPTY_STRING );
   }

   my %popt   = ( %{ $opt }, cache_id => $cache_id, as_is => $opt->{as_is} );
   my $parsed = $self->_parse( $tmp, \%popt );
   my $CODE   = $self->cache->populate( $cache_id, $parsed, $opt->{chkmt} );
   $self->[HEADER] = $restore_header if $shead;
   return $CODE;
}

sub _call_filters {
   my($self, $oref, @filters) = @_;
   my $fname = $self->[FILENAME];

   APPLY_FILTERS: foreach my $filter ( @filters ) {
      my $fref = DUMMY_CLASS->can( 'filter_' . $filter );
      if ( ! $fref ) {
         ${$oref} .= "\n[ filter warning ] Can not apply undefined filter"
                .  " $filter to $fname\n";
         next;
      }
      $fref->( $self, $oref );
   }

   return;
}

sub _wrap_compile {
   my $self   = shift;
   my $parsed = shift or fatal('tts.base.compiler._wrap_compile.parsed');
   LOG( CACHE_ID => $self->cache->id ) if $self->[WARN_IDS] && $self->cache->id;
   LOG( COMPILER => $self->[SAFE] ? 'Safe' : 'Normal' ) if DEBUG;
   my($CODE, $error);

   my $compiler = $self->[SAFE] ? COMPILER_SAFE : COMPILER;

   $CODE = $compiler->compile( $parsed );

   if( $error = $@ ) {
      my $error2;
      $error .= $error2 if $error2;
   }

   return $CODE, $error;
}

sub _mini_compiler {
   # little dumb compiler for internal templates
   my $self     = shift;
   my $template = shift || fatal('tts.base.compiler._mini_compiler.notmp');
   my $param    = shift || fatal('tts.base.compiler._mini_compiler.noparam');
   my $opt      = shift || {};

   fatal('tts.base.compiler._mini_compiler.opt')   if ref $opt   ne 'HASH';
   fatal('tts.base.compiler._mini_compiler.param') if ref $param ne 'HASH';

   foreach my $var ( keys %{ $param } ) {
      my $str = $param->{$var};
      $template =~ s{<%\Q$var\E%>}{$str}xmsg;
   }

   $template =~ s{\s+}{ }xmsg if $opt->{flatten}; # remove extra spaces
   return $template;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Text::Template::Simple::Base::Compiler

=head1 VERSION

version 0.91

=head1 SYNOPSIS

Private module.

=head1 DESCRIPTION

Private module.

=head1 NAME

Text::Template::Simple::Base::Compiler - Base class for Text::Template::Simple

=head1 AUTHOR

Burak Gursoy <burak@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2004 by Burak Gursoy.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
