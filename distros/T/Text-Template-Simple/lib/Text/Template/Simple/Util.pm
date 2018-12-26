package Text::Template::Simple::Util;
$Text::Template::Simple::Util::VERSION = '0.91';
use strict;
use warnings;
use base qw( Exporter );
use Carp qw( croak );
use Text::Template::Simple::Constants qw(
   :info
   DIGEST_MODS
   EMPTY_STRING
);

BEGIN {
   if ( UNICODE_PERL ) {
      # older perl binmode() does not accept a second param
      *binary_mode = sub {
         my($fh, $layer) = @_;
         binmode $fh, q{:} . $layer;
      };
   }
   else {
      *binary_mode = sub { binmode $_[0] };
   }
   our %EXPORT_TAGS = (
      util  => [qw( binary_mode DIGEST trim rtrim ltrim escape )],
      debug => [qw( fatal       DEBUG  LOG  L                  )],
      misc  => [qw( visualize_whitespace                       )],
   );
   our @EXPORT_OK    = map { @{ $EXPORT_TAGS{$_} } } keys %EXPORT_TAGS;
   $EXPORT_TAGS{all} = \@EXPORT_OK;
   our @EXPORT       =  @EXPORT_OK;
}

my $lang = {
   error => {
      q{tts.base.examine.notglob}                 => q{Unknown template parameter passed as %s reference! Supported types are GLOB, PATH and STRING.},
      q{tts.base.examine.notfh}                   => q{This GLOB is not a filehandle},
      q{tts.main.cdir}                            => q{Cache dir %s does not exist!},
      q{tts.main.bogus_args}                      => q{Malformed add_args parameter! 'add_args' must be an arrayref!},
      q{tts.main.bogus_delims}                    => q{Malformed delimiters parameter! 'delimiters' must be a two element arrayref!},
      q{tts.cache.opendir}                        => q{Can not open cache dir (%s) for reading: %s},
      q{tts.util.digest}                          => q{Can not load a digest module. Disable cache or install one of these (%s or %s). Last error was: %s},
      q{tts.cache.dumper}                         => q{Can not dump in-memory cache! Your version of Data::Dumper (%s) does not implement the Deparse() method. Please upgrade this module!},
      q{tts.cache.pformat}                        => q{Parameters must be in 'param => value' format},
      q{tts.cache.incache}                        => q{I need an 'id' or a 'data' parameter for cache check!},
      q{tts.main.dslen}                           => q{Start delimiter is smaller than 2 characters},
      q{tts.main.delen}                           => q{End delimiter is smaller than 2 characters},
      q{tts.main.dsws}                            => q{Start delimiter contains whitespace},
      q{tts.main.dews}                            => q{End delimiter contains whitespace},
      q{tts.main.import.invalid}                  => q{%s isn't a valid import parameter for %s},
      q{tts.main.import.undef}                    => q{%s is not defined in %s},
      q{tts.main.import.redefine}                 => q{%s is already defined in %s},
      q{tts.main.tts.args}                        => q{Nothing to compile!},
      q{tts.main.connector.args}                  => q{connector(): id is missing},
      q{tts.main.connector.invalid}               => q{connector(): invalid id: %s},
      q{tts.main.init.thandler}                   => q{user_thandler parameter must be a CODE reference},
      q{tts.main.init.include}                    => q{include_paths parameter must be a ARRAY reference},
      q{tts.util.escape}                          => q{Missing the character to escape},
      q{tts.tokenizer.new.ds}                     => q{Start delimiter is missing},
      q{tts.tokenizer.new.de}                     => q{End delimiter is missing},
      q{tts.tokenizer.tokenize.tmp}               => q{Template string is missing},
      q{tts.tokenizer._get_symbols.regex}         => q{Regex is missing},
      q{tts.io.validate.type}                     => q{No type specified},
      q{tts.io.validate.path}                     => q{No path specified},
      q{tts.io.validate.file}                     => q{validate(file) is not yet implemented},
      q{tts.io.layer.fh}                          => q{Filehandle is absent},
      q{tts.io.slurp.open}                        => q{Error opening '%s' for reading: %s},
      q{tts.io.slurp.taint}                       => q{Can't untaint FH},
      q{tts.io.hls.invalid}                       => q{FH is either absent or invalid},
      q{tts.caller.stack.hash}                    => q{Parameters to stack() must be a HASH},
      q{tts.caller.stack.type}                    => q{Unknown caller stack type: %s},
      q{tts.caller._text_table.module}            => q{Caller stack type 'text_table' requires Text::Table: %s},
      q{tts.cache.new.parent}                     => q{Parent object is missing},
      q{tts.cache.dumper.hash}                    => q{Parameters to dumper() must be a HASHref},
      q{tts.cache.dumper.type}                    => q{Dumper type '%s' is not valid},
      q{tts.cache.develsize.buggy}                => q{Your Devel::Size version (%s) has a known bug. Upgrade Devel::Size to 0.72 or newer or do not use the size() method},
      q{tts.cache.develsize.total}                => q{Devel::Size::total_size(): %s},
      q{tts.cache.hit.meta}                       => q{Can not get meta data: %s},
      q{tts.cache.hit.cache}                      => q{Error loading from disk cache: %s},
      q{tts.cache.populate.write}                 => q{Error writing disk-cache %s : %s},
      q{tts.cache.populate.chmod}                 => q{Can not change file mode},
      q{tts.base.compiler._compile.notmp}         => q{No template specified},
      q{tts.base.compiler._compile.param}         => q{params must be an arrayref!},
      q{tts.base.compiler._compile.opt}           => q{opts must be a hashref!},
      q{tts.base.compiler._wrap_compile.parsed}   => q{nothing to compile},
      q{tts.base.compiler._mini_compiler.notmp}   => q{_mini_compiler(): missing the template},
      q{tts.base.compiler._mini_compiler.noparam} => q{_mini_compiler(): missing the parameters},
      q{tts.base.compiler._mini_compiler.opt}     => q{_mini_compiler(): options must be a hash},
      q{tts.base.compiler._mini_compiler.param}   => q{_mini_compiler(): parameters must be a HASH},
      q{tts.base.examine._examine_type.ftype}     => q{ARRAY does not contain the type},
      q{tts.base.examine._examine_type.fthing}    => q{ARRAY does not contain the data},
      q{tts.base.examine._examine_type.extra}     => q{Type array has unknown extra fields},
      q{tts.base.examine._examine_type.unknown}   => q{Unknown first argument of %s type to compile()},
      q{tts.base.include._include.unknown}        => q{Unknown include type: %s},
      q{tts.base.include._interpolate.bogus_share} => q{Only SCALARs can be shared. You have tried to share a variable }
                                                    .q{type of %s named "%s". Consider converting it to a SCALAR or try }
                                                    .q{the monolith option to enable automatic variable sharing. }
                                                    .q{But please read the fine manual first},
      q{tts.base.include._interpolate.bogus_share_notbare} => q{It looks like you've tried to share an expression (%s) instead of a simple variable.},
      q{tts.base.parser._internal.id}             => q{_internal(): id is missing},
      q{tts.base.parser._internal.rv}             => q{_internal(): id is invalid},
      q{tts.base.parser._parse.unbalanced}        => q{%d unbalanced %s delimiter(s) in template %s},
      q{tts.cache.id.generate.data}               => q{Can't generate id without data!},
      q{tts.cache.id._custom.data}                => q{Can't generate id without data!},
   },
   warning => {
      q{tts.base.include.dynamic.recursion}       => q{%s Deep recursion (>=%d) detected in the included file: %s},
   }
};

my @WHITESPACE_SYMBOLS = map { q{\\} . $_ } qw( r n f s );

my $DEBUG = 0; # Disabled by default
my $DIGEST;    # Will hold digester class name.

sub L {
   my($type, $id, @param) = @_;
   croak q{Type parameter to L() is missing} if ! $type;
   croak q{ID parameter ro L() is missing}   if ! $id;
   my $root  = $lang->{ $type } || croak "$type is not a valid L() type";
   my $value = $root->{ $id }   || croak "$id is not a valid L() ID";
   return @param ? sprintf($value, @param) : $value;
}

sub fatal {
   my @args = @_;
   return croak L( error => @args );
}

sub escape {
   my($c, $s) = @_;
   fatal('tts.util.escape') if ! $c;
   return $s if ! $s; # false or undef
   my $e = quotemeta $c;
   $s =~ s{$e}{\\$c}xmsg;
   return $s;
}

sub trim {
   my $s = shift;
   return $s if ! $s; # false or undef
   my $extra = shift || EMPTY_STRING;
      $s =~ s{\A \s+   }{$extra}xms;
      $s =~ s{   \s+ \z}{$extra}xms;
   return $s;
}

sub ltrim {
   my $s = shift;
   return $s if ! $s; # false or undef
   my $extra = shift || EMPTY_STRING;
      $s =~ s{\A \s+ }{$extra}xms;
   return $s;
}

sub rtrim {
   my $s = shift;
   return $s if ! $s; # false or undef
   my $extra = shift || EMPTY_STRING;
      $s =~ s{ \s+ \z}{$extra}xms;
   return $s;
}

sub visualize_whitespace {
   my($str) = @_;
   $str =~ s<[$_]><$_>xmsg for @WHITESPACE_SYMBOLS;
   return $str;
}

*LOG = __PACKAGE__->can('MYLOG') || sub {
   my @args = @_;
   my $self    = ref $args[0] ? shift @args : undef;
   my $id      = shift @args;
   my $message = shift @args;
      $id      = 'DEBUG'        if not defined $id;
      $message = '<NO MESSAGE>' if not defined $message;
      $id      =~ s{_}{ }xmsg;
   $message = sprintf q{[ % 15s ] %s}, $id, $message;
   warn "$message\n";
   return;
};

sub DEBUG {
   my $thing = shift;

   # so that one can use: $self->DEBUG or DEBUG
   $thing = shift if _is_parent_object( $thing );

   $DEBUG = $thing+0 if defined $thing; # must be numeric
   return $DEBUG;
}

sub DIGEST {
   return $DIGEST->new if $DIGEST;

   local $SIG{__DIE__};
   # local $@;
   foreach my $mod ( DIGEST_MODS ) {
     (my $file = $mod) =~ s{::}{/}xmsog;
      $file .= '.pm';
      my $ok = eval { require $file; };
      if ( ! $ok ) {
         LOG( FAILED => "$mod - $file" ) if DEBUG;
         next;
      }
      $DIGEST = $mod;
      last;
   }

   if ( not $DIGEST ) {
      my @report     = DIGEST_MODS;
      my $last_error = pop @report;
      fatal( 'tts.util.digest' => join(', ', @report), $last_error, $@ );
   }

   LOG( DIGESTER => $DIGEST . ' v' . $DIGEST->VERSION ) if DEBUG;
   return $DIGEST->new;
}

sub _is_parent_object {
   my $test = shift;
   return ! defined $test       ? 0
         : ref $test            ? 1
         : $test eq __PACKAGE__ ? 1
         : $test eq PARENT      ? 1
         :                        0
         ;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Text::Template::Simple::Util

=head1 VERSION

version 0.91

=head1 SYNOPSIS

   TODO

=head1 DESCRIPTION

Contains utility functions for Text::Template::Simple.

=head1 NAME

Text::Template::Simple::Util - Utility functions

=head1 FUNCTIONS

=head2 DEBUG

Returns the debug status.

=head2 DIGEST

Returns the C<digester> object.

=head2 binary_mode FILE_HANDLE, LAYER

Sets the I/O layer of C<FILE_HANDLE> in modern C<perls>, only sets C<binmode>
on C<FILE_HANDLE> otherwise.

=head2 L TYPE, ID [, PARAMETERS]

Internal method.

=head2 fatal ID [, PARAMETERS]

Internal method.

=head2 C<trim STRING>

Returns the trimmed version of the C<STRING>.

=head2 C<ltrim STRING>

Returns the left trimmed version of the C<STRING>.

=head2 C<rtrim STRING>

Returns the right trimmed version of the C<STRING>.

=head2 escape CHAR, STRING

Escapes all occurrences of C<CHAR> in C<STRING> with backslashes.

=head2 visualize_whitespace STRING

Replaces the white space in C<STRING> with visual representations.

=head1 C<OVERRIDABLE FUNCTIONS>

=head2 LOG

If debugging mode is enabled in Text::Template::Simple, all
debugging messages will be captured by this function and will
be printed to C<STDERR>.

If a sub named C<Text::Template::Simple::Util::MYLOG> is defined,
then all calls to C<LOG> will be redirected to this sub. If you want to
save the debugging messages to a file or to a database, you must define
the C<MYLOG> sub.

=head1 AUTHOR

Burak Gursoy <burak@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2004 by Burak Gursoy.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
