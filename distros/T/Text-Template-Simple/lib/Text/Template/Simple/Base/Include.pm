## no critic (ProhibitUnusedPrivateSubroutines)
package Text::Template::Simple::Base::Include;
$Text::Template::Simple::Base::Include::VERSION = '0.91';
use strict;
use warnings;

use Text::Template::Simple::Util qw(:all);
use Text::Template::Simple::Constants qw(:all);
use constant E_IN_MONOLITH =>
    'qq~%s Interpolated includes don\'t work under monolith option. '
   .'Please disable monolith and use the \'SHARE\' directive in the include '
   .'command: %s~';
use constant E_IN_DIR   => q(q~%s '%s' is a directory~);
use constant E_IN_SLURP => 'q~%s %s~';
use constant TYPE_MAP   => qw(
   @   ARRAY
   %   HASH
   *   GLOB
   \   REFERENCE
);

sub _include_no_monolith {
   # no monolith eh?
   my($self, $type, $file, $opt) = @_;

   my $rv   =  $self->_mini_compiler(
                  $self->_internal('no_monolith') => {
                     OBJECT => $self->[FAKER_SELF],
                     FILE   => escape(q{~} => $file),
                     TYPE   => escape(q{~} => $type),
                  } => {
                     flatten => 1,
                  }
               );
   ++$self->[NEEDS_OBJECT];
   return $rv;
}

sub _include_static {
   my($self, $file, $text, $err, $opt) = @_;
   return $self->[MONOLITH]
        ? sprintf('q~%s~;', escape(q{~} => $text))
        : $self->_include_no_monolith( T_STATIC, $file, $opt )
        ;
}

sub _include_dynamic {
   my($self, $file, $text, $err, $opt) = @_;
   my $rv = EMPTY_STRING;

   ++$self->[INSIDE_INCLUDE];
   $self->[COUNTER_INCLUDE] ||= {};

   # ++$self->[COUNTER_INCLUDE]{ $file } if $self->[TYPE_FILE] eq $file;

   if ( ++$self->[COUNTER_INCLUDE]{ $file } >= MAX_RECURSION ) {
      # failsafe
      $self->[DEEP_RECURSION] = 1;
      LOG( DEEP_RECURSION => $file ) if DEBUG;
      my $w = L( warning => 'tts.base.include.dynamic.recursion',
                            $err, MAX_RECURSION, $file );
      $rv .= sprintf 'q~%s~', escape( q{~} => $w );
   }
   else {
      # local stuff is for file name access through $0 in templates
      $rv .= $self->[MONOLITH]
           ? $self->_include_dynamic_monolith( $file, $text )
           : $self->_include_no_monolith( T_DYNAMIC, $file, $opt )
           ;
   }

   --$self->[INSIDE_INCLUDE]; # critical: always adjust this
   return $rv;
}

sub _include_dynamic_monolith {
   my($self,$file, $text) = @_;
   my $old = $self->[FILENAME];
   $self->[FILENAME] = $file;
   my $result = $self->_parse( $text );
   $self->[FILENAME] = $old;
   return $result;
}

sub include {
   my $self       = shift;
   my $type       = shift || 0;
   my $file       = shift;
   my $opt        = shift;
   my $is_static  = T_STATIC  == $type ? 1 : 0;
   my $is_dynamic = T_DYNAMIC == $type ? 1 : 0;
   my $known      = $is_static || $is_dynamic;

   fatal('tts.base.include._include.unknown', $type) if not $known;

   $file = trim $file;

   my $err    = $self->_include_error( $type );
   my $exists = $self->io->file_exists( $file );
   my $interpolate;

   if ( $exists ) {
      $file = $exists; # file path correction
   }
   else {
      $interpolate = 1; # just guessing ...
      return sprintf E_IN_MONOLITH, $err, $file if $self->[MONOLITH];
   }

   if ( $self->io->is_dir( $file ) ) {
      return sprintf E_IN_DIR, $err, escape(q{~} => $file);
   }

   $self->_debug_include_type( $file, $type ) if DEBUG;

   if ( $interpolate ) {
      my $rv = $self->_interpolate( $file, $type );
      $self->[NEEDS_OBJECT]++;
      LOG(INTERPOLATE_INC => "TYPE: $type; DATA: $file; RV: $rv") if DEBUG;
      return $rv;
   }

   my $text = eval { $self->io->slurp($file); };
   if ( $@ ) {
      return sprintf E_IN_SLURP, $err, $@;
   }

   my $meth = '_include_' . ($is_dynamic ? 'dynamic' : 'static');
   return $self->$meth( $file, $text, $err, $opt );
}

sub _debug_include_type {
   my($self, $file, $type) = @_;
   require Text::Template::Simple::Tokenizer;
   my $toke =  Text::Template::Simple::Tokenizer->new(
                  @{ $self->[DELIMITERS] },
                  $self->[PRE_CHOMP],
                  $self->[POST_CHOMP]
               );
   LOG( INCLUDE => $toke->_visualize_tid($type) . " => '$file'" );
   return;
}

sub _interpolate {
   my $self   = shift;
   my $file   = shift;
   my $type   = shift;
   my $etitle = $self->_include_error($type);

   # so that, you can pass parameters, apply filters etc.
   my %inc = (INCLUDE => map { trim $_ } split RE_PIPE_SPLIT, $file );

   if ( $self->io->file_exists( $inc{INCLUDE} ) ) {
      # well... constantly working around :p
      $inc{INCLUDE} = qq{'$inc{INCLUDE}'};
   }

   # die "You can not pass parameters to static includes"
   #    if $inc{PARAM} && T_STATIC  == $type;


   $self->_interpolate_share_setup( \%inc ) if $inc{SHARE};

   my $share  = $inc{SHARE}  ? sprintf(q{'%s', %s}, ($inc{SHARE}) x 2) : 'undef';
   my $filter = $inc{FILTER} ? escape( q{'} => $inc{FILTER} ) : EMPTY_STRING;

   return
      $self->_mini_compiler(
         $self->_internal('sub_include') => {
            OBJECT      => $self->[FAKER_SELF],
            INCLUDE     => escape( q{'} => $inc{INCLUDE} ),
            ERROR_TITLE => escape( q{'} => $etitle ),
            TYPE        => $type,
            PARAMS      => $inc{PARAM} ? qq{[$inc{PARAM}]} : 'undef',
            FILTER      => $filter,
            SHARE       => $share,
         } => {
            flatten => 1,
         }
      );
}

sub _interpolate_share_setup {
   my($self, $inc) = @_;
   my @vars = map { trim $_ } split RE_FILTER_SPLIT, $inc->{SHARE};
   my %type = TYPE_MAP;
   my @buf;
   foreach my $var ( @vars ) {
      if ( $var !~ m{ \A \$ }xms ) {
         my($char)     = $var =~ m{ \A (.) }xms;
         my $type_name = $type{ $char } || '<UNKNOWN>';
         fatal('tts.base.include._interpolate.bogus_share', $type_name, $var);
      }
      $var =~ tr/;//d;
      if ( $var =~ m{ [^a-zA-Z0-9_\$] }xms ) { ## no critic (ProhibitEnumeratedClasses)
         fatal('tts.base.include._interpolate.bogus_share_notbare', $var);
      }
      push @buf, $var;
   }
   $inc->{SHARE} = join q{,}, @buf;
   return;
}

sub _include_error {
   my($self, $type) = @_;
   my $val  = T_DYNAMIC == $type ? 'dynamic'
            : T_STATIC  == $type ? 'static'
            :                      'unknown'
            ;
   return sprintf '[ %s include error ]', $val;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Text::Template::Simple::Base::Include

=head1 VERSION

version 0.91

=head1 SYNOPSIS

Private module.

=head1 DESCRIPTION

Private module.

=head1 NAME

Text::Template::Simple::Base::Include - Base class for Text::Template::Simple

=head1 METHODS

=head2 include

=head1 AUTHOR

Burak Gursoy <burak@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2004 by Burak Gursoy.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
