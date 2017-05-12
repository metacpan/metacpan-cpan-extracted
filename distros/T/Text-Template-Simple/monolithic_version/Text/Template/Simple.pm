BEGIN { $INC{$_} = 1 for qw(Text/Template/Simple.pm Text/Template/Simple/Cache.pm Text/Template/Simple/Caller.pm Text/Template/Simple/Compiler.pm Text/Template/Simple/Dummy.pm Text/Template/Simple/IO.pm Text/Template/Simple/Tokenizer.pm Text/Template/Simple/Util.pm Text/Template/Simple/Base/Compiler.pm Text/Template/Simple/Base/Examine.pm Text/Template/Simple/Base/Include.pm Text/Template/Simple/Base/Parser.pm Text/Template/Simple/Cache/ID.pm Text/Template/Simple/Compiler/Safe.pm Text/Template/Simple/Constants.pm); }
package Text::Template::Simple;
sub ________monolith {}
package Text::Template::Simple::Cache;
sub ________monolith {}
package Text::Template::Simple::Caller;
sub ________monolith {}
package Text::Template::Simple::Compiler;
sub ________monolith {}
package Text::Template::Simple::Dummy;
sub ________monolith {}
package Text::Template::Simple::IO;
sub ________monolith {}
package Text::Template::Simple::Tokenizer;
sub ________monolith {}
package Text::Template::Simple::Util;
sub ________monolith {}
package Text::Template::Simple::Base::Compiler;
sub ________monolith {}
package Text::Template::Simple::Base::Examine;
sub ________monolith {}
package Text::Template::Simple::Base::Include;
sub ________monolith {}
package Text::Template::Simple::Base::Parser;
sub ________monolith {}
package Text::Template::Simple::Cache::ID;
sub ________monolith {}
package Text::Template::Simple::Compiler::Safe;
sub ________monolith {}
package Text::Template::Simple::Constants;
sub ________monolith {}
package Text::Template::Simple::Constants;
use strict;
use warnings;

our $VERSION = '0.90';

my($FIELD_ID);

use constant RESET_FIELD         => -1;

# object fields
BEGIN { $FIELD_ID = RESET_FIELD } # init object field id counter
use constant DELIMITERS          => ++$FIELD_ID;
use constant AS_STRING           => ++$FIELD_ID;
use constant DELETE_WS           => ++$FIELD_ID;
use constant FAKER               => ++$FIELD_ID;
use constant FAKER_HASH          => ++$FIELD_ID;
use constant FAKER_SELF          => ++$FIELD_ID;
use constant FAKER_WARN          => ++$FIELD_ID;
use constant MONOLITH            => ++$FIELD_ID;
use constant CACHE               => ++$FIELD_ID;
use constant CACHE_DIR           => ++$FIELD_ID;
use constant CACHE_OBJECT        => ++$FIELD_ID;
use constant IO_OBJECT           => ++$FIELD_ID;
use constant STRICT              => ++$FIELD_ID;
use constant SAFE                => ++$FIELD_ID;
use constant HEADER              => ++$FIELD_ID;
use constant ADD_ARGS            => ++$FIELD_ID;
use constant CAPTURE_WARNINGS    => ++$FIELD_ID;
use constant WARN_IDS            => ++$FIELD_ID;
use constant TYPE                => ++$FIELD_ID;
use constant TYPE_FILE           => ++$FIELD_ID;
use constant COUNTER             => ++$FIELD_ID;
use constant COUNTER_INCLUDE     => ++$FIELD_ID;
use constant INSIDE_INCLUDE      => ++$FIELD_ID;
use constant NEEDS_OBJECT        => ++$FIELD_ID;
use constant CID                 => ++$FIELD_ID;
use constant FILENAME            => ++$FIELD_ID;
use constant IOLAYER             => ++$FIELD_ID;
use constant STACK               => ++$FIELD_ID;
use constant USER_THANDLER       => ++$FIELD_ID;
use constant DEEP_RECURSION      => ++$FIELD_ID;
use constant INCLUDE_PATHS       => ++$FIELD_ID;
use constant PRE_CHOMP           => ++$FIELD_ID;
use constant POST_CHOMP          => ++$FIELD_ID;
use constant VERBOSE_ERRORS      => ++$FIELD_ID;
use constant TAINT_MODE          => ++$FIELD_ID;
use constant MAXOBJFIELD         =>   $FIELD_ID;

# token type ids
BEGIN { $FIELD_ID = 0 }
use constant T_DELIMSTART        => ++$FIELD_ID;
use constant T_DELIMEND          => ++$FIELD_ID;
use constant T_DISCARD           => ++$FIELD_ID;
use constant T_COMMENT           => ++$FIELD_ID;
use constant T_RAW               => ++$FIELD_ID;
use constant T_NOTADELIM         => ++$FIELD_ID;
use constant T_CODE              => ++$FIELD_ID;
use constant T_CAPTURE           => ++$FIELD_ID;
use constant T_DYNAMIC           => ++$FIELD_ID;
use constant T_STATIC            => ++$FIELD_ID;
use constant T_MAPKEY            => ++$FIELD_ID;
use constant T_COMMAND           => ++$FIELD_ID;
use constant T_MAXID             =>   $FIELD_ID;

# settings
use constant MAX_RECURSION       => 50; # recursion limit for dynamic includes
use constant PARENT              => ( __PACKAGE__ =~ m{ (.+?) ::Constants }xms );
use constant IS_WINDOWS          => $^O eq 'MSWin32';
use constant DELIM_START         => 0; # field id
use constant DELIM_END           => 1; # field id
use constant RE_NONFILE          => qr{ [ \n \r < > * ? ] }xmso;
use constant RE_DUMP_ERROR       => qr{
    \QCan't locate object method "first" via package "B::SVOP"\E
}xms;
use constant COMPILER            => PARENT   . '::Compiler';
use constant COMPILER_SAFE       => COMPILER . '::Safe';
use constant DUMMY_CLASS         => PARENT   . '::Dummy';
use constant MAX_FILENAME_LENGTH => 120;
use constant CACHE_EXT           => '.tts.cache';
use constant STAT_SIZE           => 7;
use constant STAT_MTIME          => 9;
use constant DELIMS              => qw( <% %> );
use constant UNICODE_PERL        => $] >= 5.008;

use constant CHOMP_NONE          => 0x000000;
use constant COLLAPSE_NONE       => 0x000000;
use constant CHOMP_ALL           => 0x000002;
use constant CHOMP_LEFT          => 0x000004;
use constant CHOMP_RIGHT         => 0x000008;
use constant COLLAPSE_LEFT       => 0x000010;
use constant COLLAPSE_RIGHT      => 0x000020;
use constant COLLAPSE_ALL        => 0x000040;

use constant TAINT_CHECK_NORMAL  => 0x000000;
use constant TAINT_CHECK_ALL     => 0x000002;
use constant TAINT_CHECK_WINDOWS => 0x000004;
use constant TAINT_CHECK_FH_READ => 0x000008;

# first level directives
use constant DIR_CAPTURE         => q{=};
use constant DIR_DYNAMIC         => q{*};
use constant DIR_STATIC          => q{+};
use constant DIR_NOTADELIM       => q{!};
use constant DIR_COMMENT         => q{#};
use constant DIR_COMMAND         => q{|};
# second level directives
use constant DIR_CHOMP           => q{-};
use constant DIR_COLLAPSE        => q{~};
use constant DIR_CHOMP_NONE      => q{^};

# token related indexes
use constant TOKEN_STR           =>  0;
use constant TOKEN_ID            =>  1;
use constant TOKEN_CHOMP         =>  2;
use constant TOKEN_TRIGGER       =>  3;

use constant TOKEN_CHOMP_NEXT    =>  0; # sub-key for TOKEN_CHOMP
use constant TOKEN_CHOMP_PREV    =>  1; # sub-key for TOKEN_CHOMP

use constant LAST_TOKEN          => -1;
use constant PREVIOUS_TOKEN      => -2;

use constant CACHE_PARENT        => 0; # object id
use constant CACHE_FMODE         => 0600;

use constant EMPTY_STRING        => q{};

use constant FMODE_GO_WRITABLE   => 022;
use constant FMODE_GO_READABLE   => 066;
use constant FTYPE_MASK          => 07777;

use constant MAX_PATH_LENGTH     => 255;
use constant DEVEL_SIZE_VERSION  => 0.72;

use constant DEBUG_LEVEL_NORMAL  => 1;
use constant DEBUG_LEVEL_VERBOSE => 2;
use constant DEBUG_LEVEL_INSANE  => 3;


# SHA seems to be more accurate, so we'll try them first.
# Pure-Perl ones are slower, but they are fail-safes.
# However, Digest::SHA::PurePerl does not work under $perl < 5.6.
# But, Digest::Perl::MD5 seems to work under older perls (5.5.4 at least).
use constant DIGEST_MODS => qw(
   Digest::SHA
   Digest::SHA1
   Digest::SHA2
   Digest::SHA::PurePerl
   Digest::MD5
   MD5
   Digest::Perl::MD5
);

use constant RE_PIPE_SPLIT   => qr/ [|] (?:\s+)? (NAME|PARAM|FILTER|SHARE) : /xms;
use constant RE_FILTER_SPLIT => qr/ \, (?:\s+)? /xms;
use constant RE_INVALID_CID  =>
    qr{[^A-Za-z_0-9]}xms; ## no critic (ProhibitEnumeratedClasses)

use constant DISK_CACHE_MARKER => q{# This file is automatically generated by }
                               .  PARENT
                               ;

use base qw( Exporter );

BEGIN {

   our %EXPORT_TAGS = (
      info      =>   [qw(
                        UNICODE_PERL
                        IS_WINDOWS
                        COMPILER
                        COMPILER_SAFE
                        DUMMY_CLASS
                        MAX_FILENAME_LENGTH
                        CACHE_EXT
                        PARENT
                     )],
      templates =>   [qw(
                        DISK_CACHE_MARKER
                     )],
      delims    =>   [qw(
                        DELIM_START
                        DELIM_END
                        DELIMS
                     )],
      fields    =>   [qw(
                        DELIMITERS
                        AS_STRING
                        DELETE_WS
                        FAKER
                        FAKER_HASH
                        FAKER_SELF
                        FAKER_WARN
                        CACHE
                        CACHE_DIR
                        CACHE_OBJECT
                        MONOLITH
                        IO_OBJECT
                        STRICT
                        SAFE
                        HEADER
                        ADD_ARGS
                        WARN_IDS
                        CAPTURE_WARNINGS
                        TYPE
                        TYPE_FILE
                        COUNTER
                        COUNTER_INCLUDE
                        INSIDE_INCLUDE
                        NEEDS_OBJECT
                        CID
                        FILENAME
                        IOLAYER
                        STACK
                        USER_THANDLER
                        DEEP_RECURSION
                        INCLUDE_PATHS
                        PRE_CHOMP
                        POST_CHOMP
                        VERBOSE_ERRORS
                        TAINT_MODE
                        MAXOBJFIELD
                     )],
      chomp     =>   [qw(
                        CHOMP_NONE
                        COLLAPSE_NONE
                        CHOMP_ALL
                        CHOMP_LEFT
                        CHOMP_RIGHT
                        COLLAPSE_LEFT
                        COLLAPSE_RIGHT
                        COLLAPSE_ALL
                     )],
      directive =>   [qw(
                        DIR_CHOMP
                        DIR_COLLAPSE
                        DIR_CHOMP_NONE
                        DIR_CAPTURE
                        DIR_DYNAMIC
                        DIR_STATIC
                        DIR_NOTADELIM
                        DIR_COMMENT
                        DIR_COMMAND
                     )],
      token     =>   [qw(
                        TOKEN_ID
                        TOKEN_STR
                        TOKEN_CHOMP
                        TOKEN_TRIGGER
                        TOKEN_CHOMP_NEXT
                        TOKEN_CHOMP_PREV
                        LAST_TOKEN
                        PREVIOUS_TOKEN

                        T_DELIMSTART
                        T_DELIMEND
                        T_DISCARD
                        T_COMMENT
                        T_RAW
                        T_NOTADELIM
                        T_CODE
                        T_CAPTURE
                        T_DYNAMIC
                        T_STATIC
                        T_MAPKEY
                        T_COMMAND
                        T_MAXID
                      )],
      taint     =>   [qw(
                        TAINT_CHECK_NORMAL
                        TAINT_CHECK_ALL
                        TAINT_CHECK_WINDOWS
                        TAINT_CHECK_FH_READ
                     )],
      etc       =>   [qw(
                        DIGEST_MODS
                        STAT_MTIME
                        RE_DUMP_ERROR
                        RE_PIPE_SPLIT
                        RE_FILTER_SPLIT
                        RE_NONFILE
                        RE_INVALID_CID
                        STAT_SIZE
                        MAX_RECURSION
                        CACHE_FMODE
                        CACHE_PARENT
                        RESET_FIELD
                        EMPTY_STRING
                        MAX_PATH_LENGTH
                        DEVEL_SIZE_VERSION
                     )],
      fmode     =>   [qw(
                        FMODE_GO_WRITABLE
                        FMODE_GO_READABLE
                        FTYPE_MASK
                     )],
      debug     =>   [qw(
                        DEBUG_LEVEL_NORMAL
                        DEBUG_LEVEL_VERBOSE
                        DEBUG_LEVEL_INSANE
                     )],
   );

   our @EXPORT_OK    = map { @{ $EXPORT_TAGS{$_} } } keys %EXPORT_TAGS;
   our @EXPORT       = @EXPORT_OK;
   $EXPORT_TAGS{all} = \@EXPORT_OK;
}

package Text::Template::Simple::Util;
use strict;
use warnings;
use base qw( Exporter );
use Carp qw( croak );
use Text::Template::Simple::Constants qw(
   :info
   DIGEST_MODS
   EMPTY_STRING
);

our $VERSION = '0.90';

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

package Text::Template::Simple::Compiler::Safe;
# Safe compiler. Totally experimental
use strict;
use warnings;

use Text::Template::Simple::Dummy;

our $VERSION = '0.90';

sub compile {
   shift;
   return __PACKAGE__->_object->reval(shift);
}

sub _object {
   my $class = shift;
   if ( $class->can('object') ) {
      my $safe = $class->object;
      if ( $safe && ref $safe ) {
         return $safe if eval { $safe->isa('Safe'); 'Safe-is-OK' };
      }
      my $end = $@ ? q{: }.$@ : q{.};
      warn 'Safe object failed. Falling back to default' . $end . "\n";
   }
   require Safe;
   my $safe = Safe->new('Text::Template::Simple::Dummy');
   $safe->permit( $class->_permit );
   return $safe;
}

sub _permit {
   my $class = shift;
   return $class->permit if $class->can('permit');
   return qw( :default require caller );
}

package Text::Template::Simple::Cache::ID;
use strict;
use warnings;
use overload q{""} => 'get';

use Text::Template::Simple::Constants qw(
   MAX_FILENAME_LENGTH
   RE_INVALID_CID
);
use Text::Template::Simple::Util qw(
   LOG
   DEBUG
   DIGEST
   fatal
);

our $VERSION = '0.90';

sub new {
   my $class = shift;
   my $self  = bless do { \my $anon }, $class;
   return $self;
}

sub get {
   my $self = shift;
   return ${$self};
}

sub set { ## no critic (ProhibitAmbiguousNames)
   my $self = shift;
   my $val  = shift;
   ${$self} = $val if defined $val;
   return;
}

sub generate { # cache id generator
   my($self, $data, $custom, $regex) = @_;

   if ( ! $data ) {
      fatal('tts.cache.id.generate.data') if ! defined $data;
      LOG( IDGEN => 'Generating ID from empty data' ) if DEBUG;
   }

   $self->set(
      $custom ? $self->_custom( $data, $regex )
              : $self->DIGEST->add( $data )->hexdigest
   );

   return $self->get;
}

sub _custom {
   my $self  = shift;
   my $data  = shift or fatal('tts.cache.id._custom.data');
   my $regex = shift || RE_INVALID_CID;
      $data  =~ s{$regex}{_}xmsg; # remove bogus characters
   my $len   = length $data;

   # limit file name length
   if ( $len > MAX_FILENAME_LENGTH ) {
      $data = substr $data,
                     $len - MAX_FILENAME_LENGTH,
                     MAX_FILENAME_LENGTH;
   }

   return $data;
}

sub DESTROY {
   my $self = shift || return;
   LOG( DESTROY => ref $self ) if DEBUG;
   return;
}

## no critic (ProhibitUnusedPrivateSubroutines)
package Text::Template::Simple::Base::Parser;
use strict;
use warnings;

our $VERSION = '0.90';

use Text::Template::Simple::Util      qw(:all);
use Text::Template::Simple::Constants qw(:all);
use constant MAPKEY_NUM => 5;

my %INTERNAL = __PACKAGE__->_set_internal_templates;

sub _needs_object {
   my $self = shift;
   $self->[NEEDS_OBJECT]++;
   return $self;
}

sub _internal {
   my $self = shift;
   my $id   = shift            || fatal('tts.base.parser._internal.id');
   my $rv   = $INTERNAL{ $id } || fatal('tts.base.parser._internal.id');
   LOG( INTERNAL => "TEMPLATE: $id" ) if DEBUG;
   return $rv;
}

sub _parse {
   my($self, $raw, $opt) = @_;

   # $opt->
   #      map_keys: code sections are hash keys
   #      as_is   : i.e.: do not parse -> static include

   #$self->[NEEDS_OBJECT] = 0; # reset

   my($ds, $de) = @{ $self->[DELIMITERS] };
   my $faker    = $self->[INSIDE_INCLUDE] ? $self->_output_buffer_var
                                          : $self->[FAKER]
                                          ;
   my $buf_hash = $self->[FAKER_HASH];
   my($mko, $mkc) = $self->_parse_mapkeys( $opt->{map_keys}, $faker, $buf_hash );

   LOG( RAW => $raw ) if DEBUG > DEBUG_LEVEL_INSANE;

   my $h = {
      raw     => sub { ";$faker .= q~$_[0]~;" },
      capture => sub { ";$faker .= sub {" . $_[0] . '}->();'; },
      code    => sub { $_[0] . q{;} },
   };

   # little hack to convert delims into escaped delims for static inclusion
   $raw =~ s{\Q$ds}{$ds!}xmsg if $opt->{as_is};

   my($code, $inside) = $self->_walk( $raw, $opt, $h, $mko, $mkc );

   $self->[FILENAME] ||= '<ANON>';

   fatal(
      'tts.base.parser._parse.unbalanced',
         abs($inside),
         ($inside > 0 ? 'opening' : 'closing'),
         $self->[FILENAME]
   ) if $inside;

   return $self->_wrapper( $code, $opt->{cache_id}, $faker, $opt->{map_keys}, $h );
}

sub _walk {
   my($self, $raw, $opt, $h, $mko, $mkc) = @_;
   my $uth    = $self->[USER_THANDLER];
   my $code   = EMPTY_STRING;
   my $inside = 0;
   my $toke   = $self->connector('Tokenizer')->new(
                  @{ $self->[DELIMITERS] },
                  $self->[PRE_CHOMP],
                  $self->[POST_CHOMP]
               );

   my $is_raw = sub { my($id) = @_; T_RAW     == $id || T_NOTADELIM == $id };
   my $is_inc = sub { my($id) = @_; T_DYNAMIC == $id || T_STATIC    == $id };

   # fetch and walk the tree
   PARSER: foreach my $token ( @{ $toke->tokenize( $raw, $opt->{map_keys} ) } ) {
      my($str, $id, $chomp, undef) = @{ $token };

      LOG( TOKEN => $toke->_visualize_tid($id) . " => $str" )
         if DEBUG >= DEBUG_LEVEL_VERBOSE;

      next PARSER if T_DISCARD == $id || T_COMMENT == $id;

      if ( T_DELIMSTART == $id ) { $inside++; next PARSER; }
      if ( T_DELIMEND   == $id ) { $inside--; next PARSER; }

      $code .= $is_raw->($id)   ? $h->{raw    }->( $self->_chomp( $str, $chomp ) )
             : T_COMMAND == $id ? $h->{raw    }->( $self->_parse_command( $str ) )
             : T_CODE    == $id ? $h->{code   }->( $str                          )
             : T_CAPTURE == $id ? $h->{capture}->( $str                          )
             : $is_inc->($id)   ? $h->{capture}->( $self->_walk_inc( $opt, $id, $str) )
             : T_MAPKEY  == $id ? $self->_walk_mapkey(  $mko, $mkc, $str         )
             :                    $self->_walk_unknown( $h, $uth, $id, $str      )
             ;
   }
   return $code, $inside;
}

sub _walk_mapkey {
   my($self, $mko, $mkc, $str) = @_;
   return sprintf $mko, $mkc ? ( ($str) x MAPKEY_NUM ) : $str;
}

sub _walk_inc {
   my($self, $opt, $id, $str) = @_;
   return $self->_needs_object->include($id, $str, $opt);
}

sub _walk_unknown {
   my($self, $h, $uth, $id, $str) = @_;
   if ( DEBUG ) {
      LOG(
         $uth  ? ( USER_THANDLER => "$id" )
               : ( UNKNOWN_TOKEN => "Adding unknown token as RAW: $id($str)" )
      );
   }

   return $uth ? $uth->( $self, $id ,$str, $h ) : $h->{raw}->( $str );
}

sub _parse_command {
   my $self = shift;
   my $str  = shift;
   my($head, $raw_block) = split m{;}xms, $str, 2;
   my @buf  = split RE_PIPE_SPLIT, q{|} . trim($head);
   shift @buf;
   my %com  = map { trim $_ } @buf;

   if ( DEBUG >= DEBUG_LEVEL_INSANE ) {
      require Data::Dumper;
      LOG(
         PARSE_COMMAND => Data::Dumper::Dumper(
                           {
                              string  => $str,
                              header  => $head,
                              raw     => $raw_block,
                              command => \%com,
                           }
                        )
      );
   }

   if ( $com{FILTER} ) {
      # embed into the template & NEEDS_OBJECT++ ???
      my $old = $self->[FILENAME];
      $self->[FILENAME] = '<ANON BLOCK>';
      $self->_call_filters( \$raw_block, split RE_FILTER_SPLIT, $com{FILTER} );
      $self->[FILENAME] = $old;
   }

   return $raw_block;
}

sub _chomp {
   # remove the unnecessary white space
   my($self, $str, $chomp) = @_;

   # NEXT: discard: left;  right -> left
   # PREV: discard: right; left  -> right
   my($next, $prev) = @{ $chomp };
   $next ||= CHOMP_NONE;
   $prev ||= CHOMP_NONE;

   my $left_collapse  = ( $next & COLLAPSE_ALL ) || ( $next & COLLAPSE_RIGHT);
   my $left_chomp     = ( $next & CHOMP_ALL    ) || ( $next & CHOMP_RIGHT   );

   my $right_collapse = ( $prev & COLLAPSE_ALL ) || ( $prev & COLLAPSE_LEFT );
   my $right_chomp    = ( $prev & CHOMP_ALL    ) || ( $prev & CHOMP_LEFT    );

   $str = $left_collapse  ? ltrim($str, q{ })
        : $left_chomp     ? ltrim($str)
        :                   $str
        ;

   $str = $right_collapse ? rtrim($str, q{ })
        : $right_chomp    ? rtrim($str)
        :                   $str
        ;

   return $str;
}

sub _wrapper {
   # this'll be tricky to re-implement around a template
   my($self, $code, $cache_id, $faker, $map_keys, $h) = @_;
   my $buf_hash   = $self->[FAKER_HASH];
   my $wrapper    = EMPTY_STRING;
   my $inside_inc = $self->[INSIDE_INCLUDE] != RESET_FIELD ? 1 : 0;

   # build the anonymous sub
   if ( ! $inside_inc ) {
      # don't duplicate these if we're including something
      $wrapper .= 'package ' . DUMMY_CLASS . q{;};
      $wrapper .= 'use strict;' if $self->[STRICT];
   }
   $wrapper .= 'sub { ';
   $wrapper .= sprintf q~local $0 = '%s';~, escape( q{'} => $self->[FILENAME] );
   if ( $self->[NEEDS_OBJECT] ) {
      --$self->[NEEDS_OBJECT];
      $wrapper .= 'my ' . $self->[FAKER_SELF] . ' = shift;';
   }
   $wrapper .= $self->[HEADER].q{;}            if $self->[HEADER];
   $wrapper .= "my $faker = '';";
   $wrapper .= $self->_add_stack( $cache_id )  if $self->[STACK];
   $wrapper .= "my $buf_hash = {\@_};"         if $map_keys;
   $wrapper .= $self->_add_sigwarn if $self->[CAPTURE_WARNINGS];
   $wrapper .= "\n#line 1 " .  $self->[FILENAME] . "\n";
   $wrapper .= $code . q{;};
   $wrapper .= $self->_dump_sigwarn($h) if $self->[CAPTURE_WARNINGS];
   $wrapper .= "return $faker;";
   $wrapper .= '}';
   # make this a capture sub if we're including
   $wrapper .= '->()' if $inside_inc;

   LOG( COMPILED =>  $self->_mini_compiler(
                        $self->_internal('fragment'),
                        { FRAGMENT => $self->_tidy($wrapper) }
                     )
   ) if DEBUG >= DEBUG_LEVEL_VERBOSE;
   #LOG( OUTPUT => $wrapper );
   # reset
   $self->[DEEP_RECURSION] = 0; # reset
   return $wrapper;
}

sub _parse_mapkeys {
   my($self, $map_keys, $faker, $buf_hash) = @_;
   return( undef, undef ) if ! $map_keys;

   my $mkc = $map_keys eq 'check';
   my $mki = $map_keys eq 'init';
   my $t   = $mki ? 'map_keys_init'
           : $mkc ? 'map_keys_check'
           :        'map_keys_default'
           ;
   my $mko = $self->_mini_compiler(
               $self->_internal( $t ) => {
                  BUF  => $faker,
                  HASH => $buf_hash,
                  KEY  => '%s',
               } => {
                  flatten => 1,
               }
            );
   return $mko, $mkc;
}

sub _add_sigwarn {
   my $self = shift;
   $self->[FAKER_WARN] = $self->_output_buffer_var('array');
   my $rv = $self->_mini_compiler(
               $self->_internal('add_sigwarn'),
               { BUF     => $self->[FAKER_WARN] },
               { flatten => 1                   }
            );
   return $rv;
}

sub _dump_sigwarn {
   my $self = shift;
   my $h    = shift;
   my $rv = $h->{capture}->(
               $self->_mini_compiler(
                  $self->_internal('dump_sigwarn'),
                  { BUF     => $self->[FAKER_WARN] },
                  { flatten => 1                   }
               )
            );
   return $rv;
}

sub _add_stack {
   my $self    = shift;
   my $cs_name = shift || '<ANON TEMPLATE>';
   my $stack   = $self->[STACK] || EMPTY_STRING;

   return if lc($stack) eq 'off';

   my $check   = ($stack eq '1' || $stack eq 'yes' || $stack eq 'on')
               ? 'string'
               : $stack
               ;

   my($type, $channel) = split m{:}xms, $check;
   $channel = ! $channel             ? 'warn'
            :   $channel eq 'buffer' ? $self->[FAKER] . ' .= '
            :                          'warn'
            ;

   foreach my $e ( $cs_name, $type, $channel ) {
      $e =~ s{'}{\\'}xmsg;
   }

   return "$channel stack( { type => '$type', name => '$cs_name' } );";
}

sub _set_internal_templates {
   return
   # we need string eval in this template to catch syntax errors
   sub_include => <<'TEMPLATE_CONSTANT',
      <%OBJECT%>->_compile(
         do {
            local $@;
            my $file = eval '<%INCLUDE%>';
            my $rv;
            if ( my $e = $@ ) {
               chomp $e;
               $file ||= '<%INCLUDE%>';
               my $m = "The parameter ($file) is not a file. "
                     . "Error from sub-include ($file): $e";
               $rv = [ ERROR => '<%ERROR_TITLE%> ' . $m ]
            }
            else {
               $rv = $file;
            }
            $rv;
         },
         <%PARAMS%>,
         {
            _sub_inc => '<%TYPE%>',
            _filter  => '<%FILTER%>',
            _share   => [<%SHARE%>],
         }
      )
TEMPLATE_CONSTANT

   no_monolith => <<'TEMPLATE_CONSTANT',
      <%OBJECT%>->compile(
         q~<%FILE%>~,
         undef,
         {
            chkmt    => 1,
            _sub_inc => q~<%TYPE%>~,
         }
      );
TEMPLATE_CONSTANT

   # see _parse()
   map_keys_check => <<'TEMPLATE_CONSTANT',
      <%BUF%> .= exists <%HASH%>->{"<%KEY%>"}
               ? (
                  defined <%HASH%>->{"<%KEY%>"}
                  ? <%HASH%>->{"<%KEY%>"}
                  : "[ERROR] Key not defined: <%KEY%>"
                  )
               : "[ERROR] Invalid key: <%KEY%>"
               ;
TEMPLATE_CONSTANT

   map_keys_init => <<'TEMPLATE_CONSTANT',
      <%BUF%> .= <%HASH%>->{"<%KEY%>"} || '';
TEMPLATE_CONSTANT

   map_keys_default => <<'TEMPLATE_CONSTANT',
      <%BUF%> .= <%HASH%>->{"<%KEY%>"};
TEMPLATE_CONSTANT

   add_sigwarn => <<'TEMPLATE_CONSTANT',
      my <%BUF%>;
      local $SIG{__WARN__} = sub {
         push @{ <%BUF%> }, $_[0];
      };
TEMPLATE_CONSTANT

   dump_sigwarn => <<'TEMPLATE_CONSTANT',
      join("\n",
            map {
               s{ \A \s+    }{}xms;
               s{    \s+ \z }{}xms;
               "[warning] $_\n"
            } @{ <%BUF%> }
         );
TEMPLATE_CONSTANT

   compile_error => <<'TEMPLATE_CONSTANT',
Error compiling code fragment (cache id: <%CID%>):

<%ERROR%>
-------------------------------
PARSED CODE (VERBATIM):
-------------------------------

<%PARSED%>

-------------------------------
PARSED CODE    (tidied):
-------------------------------

<%TIDIED%>
TEMPLATE_CONSTANT

   fragment => <<'TEMPLATE_CONSTANT',

# BEGIN TIDIED FRAGMENT

<%FRAGMENT%>

# END TIDIED FRAGMENT
TEMPLATE_CONSTANT

   disk_cache_comment => <<'TEMPLATE_CONSTANT',
# !!!   W A R N I N G      W A R N I N G      W A R N I N G   !!!
# This file was automatically generated by <%NAME%> on <%DATE%>.
# This file is a compiled template cache.
# Any changes you make here will be lost.
#
TEMPLATE_CONSTANT
}

## no critic (ProhibitUnusedPrivateSubroutines)
package Text::Template::Simple::Base::Include;
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

our $VERSION = '0.90';

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

## no critic (ProhibitUnusedPrivateSubroutines)
package Text::Template::Simple::Base::Examine;
use strict;
use warnings;

use Text::Template::Simple::Util qw(:all);
use Text::Template::Simple::Constants qw(:all);

our $VERSION = '0.90';

sub _examine {
   my $self   = shift;
   my $TMP    = shift;
   my($type, $thing) = $self->_examine_type( $TMP );
   my $rv;

   if ( $type eq 'ERROR' ) {
      $rv           = $thing;
      $self->[TYPE] = $type;
   }
   elsif ( $type eq 'GLOB' ) {
      $rv           = $self->_examine_glob( $thing );
      $self->[TYPE] = $type;
   }
   else {
      if ( my $path = $self->io->file_exists( $thing ) ) {
         $rv                = $self->io->slurp( $path );
         $self->[TYPE]      = 'FILE';
         $self->[TYPE_FILE] = $path;
      }
      else {
         # just die if file is absent, but user forced the type as FILE
         $self->io->slurp( $thing ) if $type eq 'FILE';
         $rv           = $thing;
         $self->[TYPE] = 'STRING';
      }
   }

   LOG( EXAMINE => sprintf q{%s; LENGTH: %s}, $self->[TYPE], length $rv ) if DEBUG;
   return $rv;
}

sub _examine_glob {
   my($self, $thing) = @_;
   my $type = ref $thing;
   fatal( 'tts.base.examine.notglob' => $type ) if $type ne 'GLOB';
   fatal( 'tts.base.examine.notfh'            ) if ! fileno $thing;
   return $self->io->slurp( $thing );
}

sub _examine_type {
   my $self = shift;
   my $TMP  = shift;
   my $ref  = ref $TMP;

   return EMPTY_STRING ,  $TMP if ! $ref;
   return GLOB         => $TMP if   $ref eq 'GLOB';

   if ( ref $TMP eq 'ARRAY' ) {
      my $ftype  = shift @{ $TMP } || fatal('tts.base.examine._examine_type.ftype');
      my $fthing = shift @{ $TMP } || fatal('tts.base.examine._examine_type.fthing');
      fatal('tts.base.examine._examine_type.extra') if @{ $TMP };
      return uc $ftype, $fthing;
   }

   return fatal('tts.base.examine._examine_type.unknown', $ref);
}

## no critic (ProhibitUnusedPrivateSubroutines)
package Text::Template::Simple::Base::Compiler;
use strict;
use warnings;

use Text::Template::Simple::Util qw(:all);
use Text::Template::Simple::Constants qw(:all);

our $VERSION = '0.90';

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

package Text::Template::Simple::Tokenizer;
use strict;
use warnings;

our $VERSION = '0.90';

use constant CMD_CHAR             => 0;
use constant CMD_ID               => 1;
use constant CMD_CALLBACK         => 2;

use constant ID_DS                => 0;
use constant ID_DE                => 1;
use constant ID_PRE_CHOMP         => 2;
use constant ID_POST_CHOMP        => 3;

use constant SUBSTR_OFFSET_FIRST  => 0;
use constant SUBSTR_OFFSET_SECOND => 1;
use constant SUBSTR_LENGTH        => 1;

use Text::Template::Simple::Util      qw( LOG DEBUG fatal );
use Text::Template::Simple::Constants qw( :all );

my @COMMANDS = ( # default command list
   # command        id
   [ DIR_CAPTURE  , T_CAPTURE   ],
   [ DIR_DYNAMIC  , T_DYNAMIC,  ],
   [ DIR_STATIC   , T_STATIC,   ],
   [ DIR_NOTADELIM, T_NOTADELIM ],
   [ DIR_COMMENT  , T_COMMENT   ],
   [ DIR_COMMAND  , T_COMMAND   ],
);

sub new {
   my $class = shift;
   my $self  = [];
   bless $self, $class;
   $self->[ID_DS]         = shift || fatal('tts.tokenizer.new.ds');
   $self->[ID_DE]         = shift || fatal('tts.tokenizer.new.de');
   $self->[ID_PRE_CHOMP]  = shift || CHOMP_NONE;
   $self->[ID_POST_CHOMP] = shift || CHOMP_NONE;
   return $self;
}

sub tokenize {
   # compile the template into a tree and optimize
   my($self, $tmp, $map_keys) = @_;

   return $self->_empty_token( $tmp ) if ! $tmp;

   my($ds,  $de)  = @{ $self }[ ID_DS, ID_DE ];
   my($qds, $qde) = map { quotemeta $_ } $ds, $de;

   my(@tokens, $inside);

   OUT_TOKEN: foreach my $i ( split /($qds)/xms, $tmp ) {

      if ( $i eq $ds ) {
         push @tokens, [ $i, T_DELIMSTART, [], undef ];
         $inside = 1;
         next OUT_TOKEN;
      }

      IN_TOKEN: foreach my $j ( split /($qde)/xms, $i ) {
         if ( $j eq $de ) {
            my $last_token = $tokens[LAST_TOKEN];
            if ( T_NOTADELIM == $last_token->[TOKEN_ID] ) {
               $last_token->[TOKEN_STR] = $self->tilde(
                                             $last_token->[TOKEN_STR] . $de
                                          );
            }
            else {
               push @tokens, [ $j, T_DELIMEND, [], undef ];
            }
            $inside = 0;
            next IN_TOKEN;
         }
         push @tokens, $self->_token_code( $j, $inside, $map_keys, \@tokens );
      }
   }

   $self->_debug_tokens( \@tokens ) if $self->can('DEBUG_TOKENS');

   return \@tokens;
}

sub tilde {
   my(undef, @args) = @_;
   return Text::Template::Simple::Util::escape( q{~} => @args );
}

sub quote {
   my(undef, @args) = @_;
   return Text::Template::Simple::Util::escape( q{"} => @args );
}

sub _empty_token {
   my $self = shift;
   my $tmp  = shift;
   fatal('tts.tokenizer.tokenize.tmp') if ! defined $tmp;
   # empty string or zero
   return [
         [ $self->[ID_DS], T_DELIMSTART, [], undef ],
         [ $tmp          , T_RAW       , [], undef ],
         [ $self->[ID_DE], T_DELIMEND  , [], undef ],
   ]
}

sub _get_command_chars {
   my($self, $str) = @_;
   return
      $str ne EMPTY_STRING # left
         ? substr $str, SUBSTR_OFFSET_FIRST , SUBSTR_LENGTH : EMPTY_STRING,
      $str ne EMPTY_STRING # extra
         ? substr $str, SUBSTR_OFFSET_SECOND, SUBSTR_LENGTH : EMPTY_STRING,
      $str ne EMPTY_STRING # right
         ? substr $str, length($str) - 1    , SUBSTR_LENGTH : EMPTY_STRING,
   ;
}

sub _user_commands {
   my $self = shift;
   return +() if ! $self->can('commands');
   return $self->commands;
}

sub _token_for_command {
   my($self, $tree, $map_keys, $str, $last_cmd, $second_cmd, $cmd, $inside) = @_;
   my($copen, $cclose, $ctoken) = $self->_chomp_token( $second_cmd, $last_cmd );
   my $len  = length $str;
   my $cb   = $map_keys ? 'quote' : $cmd->[CMD_CALLBACK];
   my $soff = $copen ? 2 : 1;
   my $slen = $len - ($cclose ? $soff+1 : 1);
   my $buf  = substr $str, $soff, $slen;

   if ( T_NOTADELIM == $cmd->[CMD_ID] ) {
      $buf = $self->[ID_DS] . $buf;
      $tree->[LAST_TOKEN][TOKEN_ID] = T_DISCARD;
   }

   my $needs_chomp = defined $ctoken;
   $self->_chomp_prev($tree, $ctoken) if $needs_chomp;

   my $id  = $map_keys ? T_RAW              : $cmd->[CMD_ID];
   my $val = $cb       ? $self->$cb( $buf ) : $buf;

   return [
            $val,
            $id,
            [ (CHOMP_NONE) x 2 ],
            $needs_chomp ? $ctoken : undef # trigger
          ];
}

sub _token_for_code {
   my($self, $tree, $map_keys, $str, $last_cmd, $first_cmd) = @_;
   my($copen, $cclose, $ctoken) = $self->_chomp_token( $first_cmd, $last_cmd );
   my $len  = length $str;
   my $soff = $copen ? 1 : 0;
   my $slen = $len - ( $cclose ? $soff+1 : 0 );

   my $needs_chomp = defined $ctoken;
   $self->_chomp_prev($tree, $ctoken) if $needs_chomp;

   return   [
               substr($str, $soff, $slen),
               $map_keys ? T_MAPKEY : T_CODE,
               [ (CHOMP_NONE) x 2 ],
               $needs_chomp ? $ctoken : undef # trigger
            ];
}

sub _token_code {
   my($self, $str, $inside, $map_keys, $tree) = @_;
   my($first_cmd, $second_cmd, $last_cmd) = $self->_get_command_chars( $str );

   if ( $inside ) {
      my @common = ($tree, $map_keys, $str, $last_cmd);
      foreach my $cmd ( @COMMANDS, $self->_user_commands ) {
         next if $first_cmd ne $cmd->[CMD_CHAR];
         return $self->_token_for_command( @common, $second_cmd, $cmd, $inside );
      }
      return $self->_token_for_code( @common, $first_cmd );
   }

   my $prev = $tree->[PREVIOUS_TOKEN];

   return [
            $self->tilde( $str ),
            T_RAW,
            [ $prev ? $prev->[TOKEN_TRIGGER] : undef, CHOMP_NONE ],
            undef # trigger
         ];
}

sub _chomp_token {
   my($self, $open_tok, $close_tok) = @_;
   my($pre, $post) = ( $self->[ID_PRE_CHOMP], $self->[ID_POST_CHOMP] );
   my $c      = CHOMP_NONE;

   my $copen  = $open_tok  eq DIR_CHOMP_NONE ? RESET_FIELD
              : $open_tok  eq DIR_COLLAPSE   ? do { $c |=  COLLAPSE_LEFT; 1 }
              : $pre       &  COLLAPSE_ALL   ? do { $c |=  COLLAPSE_LEFT; 1 }
              : $pre       &  CHOMP_ALL      ? do { $c |=     CHOMP_LEFT; 1 }
              : $open_tok  eq DIR_CHOMP      ? do { $c |=     CHOMP_LEFT; 1 }
              :                                0
              ;

   my $cclose = $close_tok eq DIR_CHOMP_NONE ? RESET_FIELD
              : $close_tok eq DIR_COLLAPSE   ? do { $c |= COLLAPSE_RIGHT; 1 }
              : $post      &  COLLAPSE_ALL   ? do { $c |= COLLAPSE_RIGHT; 1 }
              : $post      &  CHOMP_ALL      ? do { $c |=    CHOMP_RIGHT; 1 }
              : $close_tok eq DIR_CHOMP      ? do { $c |=    CHOMP_RIGHT; 1 }
              :                                0
              ;

   my $cboth  = $copen > 0 && $cclose > 0;

   $c |= COLLAPSE_ALL if ( ( $c & COLLAPSE_LEFT ) && ( $c & COLLAPSE_RIGHT ) );
   $c |= CHOMP_ALL    if ( ( $c & CHOMP_LEFT    ) && ( $c & CHOMP_RIGHT    ) );

   return $copen, $cclose, $c || CHOMP_NONE;
}

sub _chomp_prev {
   my($self, $tree, $ctoken) = @_;
   my $prev = $tree->[PREVIOUS_TOKEN] || return; # no previous if this is first
   return if T_RAW != $prev->[TOKEN_ID]; # only RAWs can be chomped

   my $tc_prev = $prev->[TOKEN_CHOMP][TOKEN_CHOMP_PREV];
   my $tc_next = $prev->[TOKEN_CHOMP][TOKEN_CHOMP_NEXT];

   $prev->[TOKEN_CHOMP] = [
                           $tc_next ? $tc_next           : CHOMP_NONE,
                           $tc_prev ? $tc_prev | $ctoken : $ctoken
                           ];
   return;
}

sub _get_symbols {
   # fetch the related constants
   my $self  = shift;
   my $regex = shift || fatal('tts.tokenizer._get_symbols.regex');
   no strict qw( refs );
   return grep { $_ =~ $regex } keys %{ ref($self) . q{::} };
}

sub _visualize_chomp {
   my $self  = shift;
   my $param = shift;
   return 'undef' if ! defined $param;

   my @test = map  { $_->[0]             }
              grep { $param & $_->[1]    }
              map  { [ $_, $self->$_() ] }
              $self->_get_symbols( qr{ \A (?: CHOMP|COLLAPSE ) }xms );

   return @test ? join( q{,}, @test ) : 'undef';
}

sub _visualize_tid {
   my $self = shift;
   my $id   = shift;
   my @ids  = (
      undef,
      sort { $self->$a() <=> $self->$b() }
      grep { $_ ne 'T_MAXID' }
      $self->_get_symbols( qr{ \A (?: T_ ) }xms )
   );

   my $rv = $ids[ $id ] || ( defined $id ? $id : 'undef' );
   return $rv;
}

sub _debug_tokens {
   my $self   = shift;
   my $tokens = shift;
   my $buf    = $self->_debug_tokens_head;

   foreach my $t ( @{ $tokens } ) {
      $buf .=  $self->_debug_tokens_row(
                  $self->_visualize_tid( $t->[TOKEN_ID]  ),
                  Text::Template::Simple::Util::visualize_whitespace(
                     $t->[TOKEN_STR]
                  ),
                  map { $_ eq 'undef' ? EMPTY_STRING : $_ }
                  map { $self->_visualize_chomp( $_ )     }
                  $t->[TOKEN_CHOMP][TOKEN_CHOMP_NEXT],
                  $t->[TOKEN_CHOMP][TOKEN_CHOMP_PREV],
                  $t->[TOKEN_TRIGGER]
               );
   }
   Text::Template::Simple::Util::LOG( DEBUG => $buf );
   return;
}

sub _debug_tokens_head {
   my $self = shift;
   return <<'HEAD';

---------------------------
       TOKEN DUMP
---------------------------
HEAD
}

sub _debug_tokens_row {
   my($self, @params) = @_;
   return sprintf <<'DUMP', @params;
ID        : %s
STRING    : %s
CHOMP_NEXT: %s
CHOMP_PREV: %s
TRIGGER   : %s
---------------------------
DUMP
}

sub DESTROY {
   my $self = shift || return;
   LOG( DESTROY => ref $self ) if DEBUG;
   return;
}

package Text::Template::Simple::IO;
use strict;
use warnings;
use constant MY_IO_LAYER      => 0;
use constant MY_INCLUDE_PATHS => 1;
use constant MY_TAINT_MODE    => 2;

use File::Spec;
use Text::Template::Simple::Constants qw(:all);
use Text::Template::Simple::Util qw(
   binary_mode
   fatal
   DEBUG
   LOG
);

our $VERSION = '0.90';

sub new {
   my $class = shift;
   my $layer = shift;
   my $paths = shift;
   my $tmode = shift;
   my $self  = [ undef, undef, undef ];
   bless $self, $class;
   $self->[MY_IO_LAYER]      = $layer if defined $layer;
   $self->[MY_INCLUDE_PATHS] = [ @{ $paths } ] if $paths; # copy
   $self->[MY_TAINT_MODE]    = $tmode;
   return $self;
}

sub validate {
   my $self = shift;
   my $type = shift || fatal('tts.io.validate.type');
   my $path = shift || fatal('tts.io.validate.path');

   if ( $type eq 'dir' ) {
      require File::Spec;
      $path = File::Spec->canonpath( $path );
      my $wdir;

      if ( IS_WINDOWS ) {
         $wdir = Win32::GetFullPathName( $path );
         if( Win32::GetLastError() ) {
            LOG( FAIL => "Win32::GetFullPathName( $path ): $^E" ) if DEBUG;
            $wdir = EMPTY_STRING; # die "Win32::GetFullPathName: $^E";
         }
         else {
            my $ok = -e $wdir && -d _;
            $wdir  = EMPTY_STRING if not $ok;
         }
      }

      $path = $wdir if $wdir;
      my $ok = -e $path && -d _;
      return if not $ok;
      return $path;
   }

   return fatal('tts.io.validate.file');
}

sub layer {
   return if ! UNICODE_PERL;
   my $self   = shift;
   my $fh     = shift || fatal('tts.io.layer.fh');
   my $layer  = $self->[MY_IO_LAYER];
   binary_mode( $fh, $layer ) if $layer;
   return;
}

sub slurp {
   require IO::File;
   require Fcntl;
   my $self = shift;
   my $file = shift;
   my($fh, $seek);

   LOG(IO_SLURP => $file) if DEBUG;

   if ( ref $file && fileno $file ) {
      $fh   = $file;
      $seek = 1;
   }
   else {
      $fh = IO::File->new;
      $fh->open($file, 'r') or fatal('tts.io.slurp.open', $file, $!);
   }

   flock $fh,    Fcntl::LOCK_SH();
   seek  $fh, 0, Fcntl::SEEK_SET() if $seek;
   $self->layer( $fh ) if ! $seek; # apply the layer only if we opened this

   if ( $self->_handle_looks_safe( $fh ) ) {
      require IO::Handle;
      my $rv = IO::Handle::untaint( $fh );
      fatal('tts.io.slurp.taint') if $rv != 0;
   }

   my $tmp = do { local $/; my $rv = <$fh>; $rv };
   flock $fh, Fcntl::LOCK_UN();
   if ( ! $seek ) {
      # close only if we opened this
      close $fh or die "Unable to close filehandle: $!\n";
   }
   return $tmp;
}

sub _handle_looks_safe {
   # Cargo Culting: original taint checking code was taken from "The Camel"
   my $self = shift;
   my $fh   = shift;
   fatal('tts.io.hls.invalid') if ! $fh || ! fileno $fh;

   require File::stat;
   my $i = File::stat::stat( $fh );
   return if ! $i;

   my $tmode = $self->[MY_TAINT_MODE];

   # ignore this check if the user is root
   # can happen with cpan clients
   if ( $< != 0 ) {
      # owner neither superuser nor "me", whose
      # real uid is in the $< variable
      return if $i->uid != 0 && $i->uid != $<;
   }

   # Check whether group or other can write file.
   # Read check is disabled by default
   # Mode is always 0666 on Windows, so all tests below are disabled on Windows
   # unless you force them to run
   LOG( FILE_MODE => sprintf '%04o', $i->mode & FTYPE_MASK) if DEBUG;

   my $bypass   = IS_WINDOWS && ! ( $tmode & TAINT_CHECK_WINDOWS ) ? 1 : 0;
   my $go_write = $bypass ? 0 : $i->mode & FMODE_GO_WRITABLE;
   my $go_read  = ! $bypass && ( $tmode & TAINT_CHECK_FH_READ )
                ? $i->mode & FMODE_GO_READABLE
                : 0;

   LOG( TAINT => "tmode:$tmode; bypass:$bypass; "
                ."go_write:$go_write; go_read:$go_read") if DEBUG;

   return if $go_write || $go_read;
   return 1;
}

sub is_file {
   # safer than a simple "-e"
   my $self = shift;
   my $file = shift || return;
   return $self->_looks_like_file( $file ) && ! -d $file;
}

sub is_dir {
   # safer than a simple "-d"
   my $self = shift;
   my $file = shift || return;
   return $self->_looks_like_file( $file ) && -d $file;
}

sub file_exists {
   my $self = shift;
   my $file = shift;

   return $file if $self->is_file( $file );

   foreach my $path ( @{ $self->[MY_INCLUDE_PATHS] } ) {
      my $test = File::Spec->catfile( $path, $file );
      return $test if $self->is_file( $test );
   }

   return; # fail!
}

sub _looks_like_file {
   my $self = shift;
   my $file = shift || return;
   return     ref $file                    ? 0
         :        $file =~ RE_NONFILE      ? 0
         : length $file >= MAX_PATH_LENGTH ? 0
         :     -e $file                    ? 1
         :                                   0
         ;
}

sub DESTROY {
   my $self = shift;
   LOG( DESTROY => ref $self ) if DEBUG;
   return;
}

package Text::Template::Simple::Dummy;
# Dummy Plug provided by the nice guy Mr. Ikari from NERV :p
# All templates are compiled into this package.
# You can define subs/methods here and then access
# them inside templates. It is also possible to declare
# and share package variables under strict (safe mode can
# have problems though). See the Pod for more info.
use strict;
use warnings;
use Text::Template::Simple::Caller;
use Text::Template::Simple::Util qw();

our $VERSION = '0.90';

sub stack { # just a wrapper
   my $opt = shift || {};
   Text::Template::Simple::Util::fatal('tts.caller.stack.hash')
      if ref $opt ne 'HASH';
   $opt->{frame} = 1;
   return Text::Template::Simple::Caller->stack( $opt );
}

package Text::Template::Simple::Compiler;
# the "normal" compiler
use strict;
use warnings;
use Text::Template::Simple::Dummy;

our $VERSION = '0.90';

sub compile {
    shift;
    my $code = eval shift;
    return $code;
}

## no critic (ProhibitUnusedPrivateSubroutines)
package Text::Template::Simple::Caller;
use strict;
use warnings;

use constant PACKAGE    => 0;
use constant FILENAME   => 1;
use constant LINE       => 2;
use constant SUBROUTINE => 3;
use constant HASARGS    => 4;
use constant WANTARRAY  => 5;
use constant EVALTEXT   => 6;
use constant IS_REQUIRE => 7;
use constant HINTS      => 8;
use constant BITMASK    => 9;

use Text::Template::Simple::Util      qw( fatal );
use Text::Template::Simple::Constants qw( EMPTY_STRING );

our $VERSION = '0.90';

sub stack {
   my $self    = shift;
   my $opt     = shift || {};
   fatal('tts.caller.stack.hash') if ref $opt ne 'HASH';
   my $frame   = $opt->{frame} || 0;
   my $type    = $opt->{type}  || EMPTY_STRING;
   my(@callers, $context);

   TRACE: while ( my @c = caller ++$frame ) {

      INITIALIZE: foreach my $id ( 0 .. $#c ) {
         next INITIALIZE if $id == WANTARRAY; # can be undef
         $c[$id] ||= EMPTY_STRING;
      }

      $context = defined $c[WANTARRAY] ?  ( $c[WANTARRAY] ? 'LIST' : 'SCALAR' )
               :                            'VOID'
               ;

      push  @callers,
            {
               class    => $c[PACKAGE   ],
               file     => $c[FILENAME  ],
               line     => $c[LINE      ],
               sub      => $c[SUBROUTINE],
               context  => $context,
               isreq    => $c[IS_REQUIRE],
               hasargs  => $c[HASARGS   ] ? 'YES' : 'NO',
               evaltext => $c[EVALTEXT  ],
               hints    => $c[HINTS     ],
               bitmask  => $c[BITMASK   ],
            };

   }

   return if ! @callers; # no one called us?
   return reverse @callers if ! $type;

   if ( $self->can( my $method = '_' . $type ) ) {
      return $self->$method( $opt, \@callers );
   }

   return fatal('tts.caller.stack.type', $type);
}

sub _string {
   my $self    = shift;
   my $opt     = shift;
   my $callers = shift;
   my $is_html = shift;

   my $name = $opt->{name} ? "FOR $opt->{name} " : EMPTY_STRING;
   my $rv   = qq{[ DUMPING CALLER STACK $name]\n\n};

   foreach my $c ( reverse @{$callers} ) {
      $rv .= sprintf qq{%s %s() at %s line %s\n},
                     @{ $c }{ qw/ context sub file line / }
   }

   $rv = "<!-- $rv -->" if $is_html;
   return $rv;
}

sub _html_comment {
   my($self, @args) = @_;
   return $self->_string( @args, 'add html comment' );
}

sub _html_table {
   my $self    = shift;
   my $opt     = shift;
   my $callers = shift;
   my $rv      = EMPTY_STRING;

   foreach my $c ( reverse @{ $callers } ) {
      $self->_html_table_blank_check( $c ); # modifies  in place
      $rv .= $self->_html_table_row(  $c )
   }

   return $self->_html_table_wrap( $rv );
}

sub _html_table_wrap {
   my($self, $content) = @_;
   return <<"HTML";
   <div id="ttsc-wrapper">
   <table border      = "1"
          cellpadding = "1"
          cellspacing = "2"
          id          = "ttsc-dump"
      >
      <tr>
         <td class="ttsc-title">CONTEXT</td>
         <td class="ttsc-title">SUB</td>
         <td class="ttsc-title">LINE</td>
         <td class="ttsc-title">FILE</td>
         <td class="ttsc-title">HASARGS</td>
         <td class="ttsc-title">IS_REQUIRE</td>
         <td class="ttsc-title">EVALTEXT</td>
         <td class="ttsc-title">HINTS</td>
         <td class="ttsc-title">BITMASK</td>
      </tr>
      $content
      </table>
   </div>
HTML
}

sub _html_table_row {
   my($self,$c) = @_;
   return <<"HTML";
   <tr>
      <td class="ttsc-value">$c->{context}</td>
      <td class="ttsc-value">$c->{sub}</td>
      <td class="ttsc-value">$c->{line}</td>
      <td class="ttsc-value">$c->{file}</td>
      <td class="ttsc-value">$c->{hasargs}</td>
      <td class="ttsc-value">$c->{isreq}</td>
      <td class="ttsc-value">$c->{evaltext}</td>
      <td class="ttsc-value">$c->{hints}</td>
      <td class="ttsc-value">$c->{bitmask}</td>
   </tr>
HTML
}

sub _html_table_blank_check {
   my $self   = shift;
   my $struct = shift;
   foreach my $id ( keys %{ $struct }) {
      if ( not defined $struct->{ $id } or $struct->{ $id } eq EMPTY_STRING ) {
         $struct->{ $id } = '&#160;';
      }
   }
   return;
}

sub _text_table {
   my $self    = shift;
   my $opt     = shift;
   my $callers = shift;
   my $ok      = eval { require Text::Table; 1; };
   fatal('tts.caller._text_table.module', $@) if ! $ok;

   my $table = Text::Table->new( qw(
                  | CONTEXT    | SUB      | LINE  | FILE    | HASARGS
                  | IS_REQUIRE | EVALTEXT | HINTS | BITMASK |
               ));

   my $pipe = q{|};
   foreach my $c ( reverse @{$callers} ) {
      $table->load(
         [
           $pipe, $c->{context},
           $pipe, $c->{sub},
           $pipe, $c->{line},
           $pipe, $c->{file},
           $pipe, $c->{hasargs},
           $pipe, $c->{isreq},
           $pipe, $c->{evaltext},
           $pipe, $c->{hints},
           $pipe, $c->{bitmask},
           $pipe
         ],
      );
   }

   my $name = $opt->{name} ? "FOR $opt->{name} " : EMPTY_STRING;
   my $top  = qq{| DUMPING CALLER STACK $name |\n};

   my $rv   = qq{\n} . ( q{-} x (length($top) - 1) ) . qq{\n} . $top
            . $table->rule( qw( - + ) )
            . $table->title
            . $table->rule( qw( - + ) )
            . $table->body
            . $table->rule( qw( - + ) )
            ;

   return $rv;
}

## no critic (ProhibitUnusedPrivateSubroutines)
package Text::Template::Simple::Cache;
use strict;
use warnings;

use Carp qw( croak );
use Text::Template::Simple::Constants qw(:all);
use Text::Template::Simple::Util      qw( DEBUG LOG fatal );

our $VERSION = '0.90';

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

package Text::Template::Simple;
use strict;
use warnings;

our $VERSION = '0.90';

use File::Spec;

use Text::Template::Simple::Cache;
use Text::Template::Simple::Cache::ID;
use Text::Template::Simple::Caller;
use Text::Template::Simple::Compiler;
use Text::Template::Simple::Compiler::Safe;
use Text::Template::Simple::Constants qw(:all);
use Text::Template::Simple::Dummy;
use Text::Template::Simple::IO;
use Text::Template::Simple::Tokenizer;
use Text::Template::Simple::Util      qw(:all);

use base qw(
   Text::Template::Simple::Base::Compiler
   Text::Template::Simple::Base::Examine
   Text::Template::Simple::Base::Include
   Text::Template::Simple::Base::Parser
);

my %CONNECTOR = qw(
   Cache       Text::Template::Simple::Cache
   Cache::ID   Text::Template::Simple::Cache::ID
   IO          Text::Template::Simple::IO
   Tokenizer   Text::Template::Simple::Tokenizer
);

my %DEFAULT = ( # default object attributes
   delimiters       => [ DELIMS ],   # default delimiters
   cache            => 0,            # use cache or not
   cache_dir        => EMPTY_STRING, # will use hdd intead of memory for caching...
   strict           => 1,            # set to false for toleration to un-declared vars
   safe             => 0,            # use safe compartment?
   header           => 0,            # template header. i.e. global codes.
   add_args         => EMPTY_STRING, # will unshift template argument list. ARRAYref.
   warn_ids         => 0,            # warn template ids?
   capture_warnings => 0,            # bool
   iolayer          => EMPTY_STRING, # I/O layer for filehandles
   stack            => EMPTY_STRING, # dump caller stack?
   user_thandler    => undef,        # user token handler callback
   monolith         => 0,            # use monolithic template & cache ?
   include_paths    => [],           # list of template dirs
   verbose_errors   => 0,            # bool
   pre_chomp        => CHOMP_NONE,
   post_chomp       => CHOMP_NONE,
   taint_mode       => TAINT_CHECK_NORMAL,
);

my @EXPORT_OK = qw( tts );

sub import {
   my($class, @args) = @_;
   return if ! @args;
   my $caller = caller;
   my %ok     = map { ($_, $_) } @EXPORT_OK;

   no strict qw( refs );
   foreach my $name ( @args ) {
      fatal('tts.main.import.invalid', $name, $class) if ! $ok{$name};
      fatal('tts.main.import.undef',   $name, $class) if ! defined &{ $name   };
      my $target = $caller . q{::} . $name;
      fatal('tts.main.import.redefine', $name, $caller) if defined &{ $target };
      *{ $target } = \&{ $name }; # install
   }

   return;
}

sub tts {
   my @args = @_;
   fatal('tts.main.tts.args') if ! @args;
   my @new  = ref $args[0] eq 'HASH' ? %{ shift @args } : ();
   return __PACKAGE__->new( @new )->compile( @args );
}

sub new {
   my($class, @args) = @_;
   my %param = @args % 2 ? () : (@args);
   my $self  = [ map { undef } 0 .. MAXOBJFIELD ];
   bless $self, $class;

   LOG( CONSTRUCT => $self->class_id . q{ @ } . (scalar localtime time) )
      if DEBUG();

   my($fid, $fval);
   INITIALIZE: foreach my $field ( keys %DEFAULT ) {
      $fid = uc $field;
      next INITIALIZE if ! $class->can( $fid );
      $fid  = $class->$fid();
      $fval = delete $param{$field};
      $self->[$fid] = defined $fval ? $fval : $DEFAULT{$field};
   }

   foreach my $bogus ( keys %param ) {
      warn "'$bogus' is not a known parameter. Did you make a typo?\n";
   }

   $self->_init;
   return $self;
}

sub connector {
   my $self = shift;
   my $id   = shift || fatal('tts.main.connector.args');
   return $CONNECTOR{ $id } || fatal('tts.main.connector.invalid', $id);
}

sub cache { return shift->[CACHE_OBJECT] }
sub io    { return shift->[IO_OBJECT]    }

sub compile {
   my($self, @args) = @_;
   my $rv = $self->_compile( @args );
   # we need to reset this to prevent false positives
   # the trick is: this is set in _compile() and sub includes call _compile()
   # instead of compile(), so it will only be reset here
   $self->[COUNTER_INCLUDE] = undef;
   return $rv;
}

# -------------------[ P R I V A T E   M E T H O D S ]------------------- #

sub _init {
   my $self = shift;
   my $d    = $self->[DELIMITERS];
   my $bogus_args = $self->[ADD_ARGS] && ref $self->[ADD_ARGS] ne 'ARRAY';

   fatal('tts.main.bogus_args')   if $bogus_args;
   fatal('tts.main.bogus_delims') if ref $d ne 'ARRAY' || $#{ $d } != 1;
   fatal('tts.main.dslen')        if length($d->[DELIM_START]) < 2;
   fatal('tts.main.delen')        if length($d->[DELIM_END])   < 2;
   fatal('tts.main.dsws')         if $d->[DELIM_START] =~ m{\s}xms;
   fatal('tts.main.dews')         if $d->[DELIM_END]   =~ m{\s}xms;

   $self->[TYPE]           = EMPTY_STRING;
   $self->[COUNTER]        = 0;
   $self->[FAKER]          = $self->_output_buffer_var;
   $self->[FAKER_HASH]     = $self->_output_buffer_var('hash');
   $self->[FAKER_SELF]     = $self->_output_buffer_var('self');
   $self->[INSIDE_INCLUDE] = RESET_FIELD;
   $self->[NEEDS_OBJECT]   = 0; # the template needs $self ?
   $self->[DEEP_RECURSION] = 0; # recursion detector

   fatal('tts.main.init.thandler')
      if $self->[USER_THANDLER] && ref $self->[USER_THANDLER] ne 'CODE';

   fatal('tts.main.init.include')
      if $self->[INCLUDE_PATHS] && ref $self->[INCLUDE_PATHS] ne 'ARRAY';

   $self->[IO_OBJECT] = $self->connector('IO')->new(
                           @{ $self }[ IOLAYER, INCLUDE_PATHS, TAINT_MODE ],
                        );

   if ( $self->[CACHE_DIR] ) {
      $self->[CACHE_DIR] = $self->io->validate( dir => $self->[CACHE_DIR] )
                           or fatal( 'tts.main.cdir' => $self->[CACHE_DIR] );
   }

   $self->[CACHE_OBJECT] = $self->connector('Cache')->new($self);

   return;
}

sub _output_buffer_var {
   my $self = shift;
   my $type = shift || 'scalar';
   my $id   = $type eq 'hash'  ? {}
            : $type eq 'array' ? []
            :                    \my $fake
            ;
   $id  = "$id";
   $id .= int rand $$; # . rand() . time;
   $id  =~ tr/a-zA-Z_0-9//cd;
   $id  =~ s{SCALAR}{SELF}xms if $type eq 'self';
   return q{$} . $id;
}

sub class_id {
   my $self = shift;
   my $class = ref($self) || $self;
   return sprintf q{%s v%s}, $class, $self->VERSION;
}

sub _tidy { ## no critic (ProhibitUnusedPrivateSubroutines)
   my $self = shift;
   my $code = shift;

   TEST_TIDY: {
      local($@, $SIG{__DIE__});
      my $ok = eval { require Perl::Tidy; 1; };
      if ( ! $ok ) { # :(
         $code =~ s{;}{;\n}xmsgo; # new lines makes it easy to debug
         return $code;
      }
   }

   # We have Perl::Tidy, yay!
   my($buf, $stderr);
   my @argv; # extra arguments

   Perl::Tidy::perltidy(
      source      => \$code,
      destination => \$buf,
      stderr      => \$stderr,
      argv        => \@argv,
   );

   LOG( TIDY_WARNING => $stderr ) if $stderr;
   return $buf;
}

sub DESTROY {
   my $self = shift || return;
   undef $self->[CACHE_OBJECT];
   undef $self->[IO_OBJECT];
   @{ $self } = ();
   LOG( DESTROY => ref $self ) if DEBUG();
   return;
}

1;

__END__

=head1 NAME

Text::Template::Simple - Simple text template engine

=head1 SYNOPSIS

   use Text::Template::Simple;
   my $tts = Text::Template::Simple->new();
   print $tts->compile( $FILEHANDLE );
   print $tts->compile('Hello, your perl is at <%= $^X %>');
   print $tts->compile(
            'hello.tts', # the template file
            [ name => 'Burak', location => 'Istanbul' ]
         );

Where C<hello.tts> has this content:

   <% my %p = @_; %>
   Hello <%= $p{name} %>,
   I hope it's sunny in <%= $p{location} %>.
   Local time is <%= scalar localtime time %>

=head1 DESCRIPTION

B<WARNING>! This is the monolithic version of Text::Template::Simple
generated with an automatic build tool. If you experience problems
with this version, please install and use the supported standard
version. This version is B<NOT SUPPORTED>.

This document describes version C<0.90> of C<Text::Template::Simple>
released on C<5 July 2016>.

This is a simple template module. There is no extra template/mini 
language. Instead, it uses Perl as the template language. Templates
can be cached on disk or inside the memory via the internal cache 
manager. It is also possible to use static/dynamic includes,
pass parameters to includes and apply filters on them.
Also see L<Text::Template::Simple::API> for the full C<API> reference.

=head1 SYNTAX

Template syntax is very simple. There are few kinds of delimiters:

=over 4

=item *

C<< <% %>  >> Code Blocks

=item *

C<< <%= %> >> Self-printing Blocks

=item *

C<< <%! %> >> Escaped Delimiters

=item *

C<< <%+ %> >> Static Include Directives

=item *

C<< <%* %> >> Dynamic include directives

=item *

C<< <%# %> >> Comment Directives

=item *

C<< <%| %> >> Blocks with commands

=back

A simple example:

   <% foreach my $x (@foo) { %>
      Element is <%= $x %>
   <% } %>

Do not directly use print() statements, since they'll break the template
compilation. Use the self printing C<< <%= %> >> blocks.

It is also possible to alter the delimiters:

   $tts = Text::Template::Simple->new(
      delimiters => [qw/<?perl ?>/],
   );

then you can use them inside templates:

   <?perl
      my @foo = qw(bar baz);
      foreach my $x (@foo) {
   ?>
   Element is <?perl= $x ?>
   <?perl } ?>

If you need to remove a code temporarily without deleting, or need to add
comments:

   <%#
      This
      whole
      block
      will
      be
      ignored
   %>

If you put a space before the pound sign, the block will be a code block:

   <%
      # this is normal code not a comment directive
      my $foo = 42;
   %>

If you want to include a text or I<HTML> file, you can use the
static include directive:

   <%+ my_other.html %>
   <%+ my_other.txt  %>

Included files won't be parsed and included statically. To enable
parsing for the included files, use the dynamic includes:

   <%* my_other.html %>
   <%* my_other.txt  %>

Interpolation is also supported with both kinds of includes, so the following
is valid code:

   <%+ "/path/to/" . $txt    %>
   <%* "/path/to/" . $myfile %>

=head2 Chomping

Chomping is the removal of white space before and after your directives. This
can be useful if you're generating plain text (instead of HTML which will ignore
spaces most of the time). You can either remove all space or replace multiple
white space with a single space (collapse). Chomping can be enabled per
directive or globally via options to the constructor.
See L<Text::Template::Simple::API/pre_chomp> and
L<Text::Template::Simple::API/post_chomp> options to
L<Text::Template::Simple::API/new> to globally enable chomping.

Chomping is enabled with second level commands for all directives. Here is
a list of commands:

   -   Chomp
   ~   Collapse
   ^   No chomp (override global)

All directives can be chomped. Here are some examples:

Chomp:

   raw content
   <%- my $foo = 42; -%>
   raw content
   <%=- $foo -%>
   raw content
   <%*- /mt/dynamic.tts  -%>
   raw content

Collapse:

   raw content
   <%~ my $foo = 42; ~%>
   raw content
   <%=~ $foo ~%>
   raw content
   <%*~ /mt/dynamic.tts  ~%>
   raw content

No chomp:

   raw content
   <%^ my $foo = 42; ^%>
   raw content
   <%=^ $foo ^%>
   raw content
   <%*^ /mt/dynamic.tts  ^%>
   raw content

It is also possible to mix the chomping types:

   raw content
   <%- my $foo = 42; ^%>
   raw content
   <%=^ $foo ~%>
   raw content
   <%*^ /mt/dynamic.tts  -%>
   raw content

For example this template:

   Foo
   <%- $prehistoric = $] < 5.008 -%>
   Bar

Will become:

   FooBar

And this one:

   Foo
   <%~ $prehistoric = $] < 5.008 -%>
   Bar

Will become:

   Foo Bar

Chomping is inspired by Template Toolkit (mostly the same functionality,
although C<TT> seems to miss collapse/no-chomp per directive option).

=head2 Accessing Template Names

You can use C<$0> to get the template path/name inside the template:

   I am <%= $0 %>

=head2 Escaping Delimiters

If you have to build templates like this:

   Test: <%abc>

or this:

   Test: <%abc%>

This will result with a template compilation error. You have to use the
delimiter escape command C<!>:

   Test: <%!abc>
   Test: <%!abc%>

Those will be compiled as:

   Test: <%abc>
   Test: <%abc%>

Alternatively, you can change the default delimiters to solve this issue.
See the L<Text::Template::Simple::API/delimiters> option for
L<Text::Template::Simple::API/new> for more information on how to
do this.

=head2 Template Parameters

You can fetch parameters (passed to compile) in the usual C<perl> way:

   <%
      my $foo = shift;
      my %bar = @_;
   %>
   Baz is <%= $bar{baz} %>

=head2 INCLUDE COMMANDS

Include commands are separated by pipes in an include directive.
Currently supported parameters are:

=over 4

=item C<PARAM>

=item FILTER

=item SHARE

=back

   <%+ /path/to/static.tts  | FILTER: MyFilter %>
   <%* /path/to/dynamic.tts | FILTER: MyFilter | PARAM: test => 123 %>

C<PARAM> defines the parameter list to pass to the included file.
C<FILTER> defines the list of filters to apply to the output of the include.
C<SHARE> used to list the variables to share with the included template when
the monolith option is disabled.

=head3 INCLUDE FILTERS

Use the include command C<FILTER:> (notice the colon in the command):

   <%+ /path/to/static.tts  | FILTER: First, Second        %>
   <%* /path/to/dynamic.tts | FILTER: Third, Fourth, Fifth %>

=head4 IMPLEMENTING INCLUDE FILTERS

Define the filter inside C<Text::Template::Simple::Dummy> with a C<filter_>
prefix:

   package Text::Template::Simple::Dummy;
   sub filter_MyFilter {
      # $tts is the current Text::Template::Simple object
      # $output_ref is the scalar reference to the output of
      #    the template.
      my($tts, $output_ref) = @_;
      $$output_ref .= "FILTER APPLIED"; # add to output
      return;
   }

=head3 INCLUDE PARAMETERS

Just pass the parameters as described above and fetch them via C<@_> inside
the included file.

=head3 SHARED VARIABLES

C<Text::Template::Simple> compiles every template individually with separate
scopes. A variable defined in the master template is not accessible from a
dynamic include. The exception to this rule is the C<monolith> option to C<new>.
If it is enabled; the master template and any includes it has will be compiled
into a single document, thus making every variable defined at the top available
to the includes below. But this method has several drawbacks, it disables cache
check for the sub files (includes) --you'll need to edit the master template
to force a cache reload-- and it can not be used with interpolated includes.
If you use an interpolated include with monolith enabled, you'll get an error.

If you don't use C<monolith> (disabled by default), then you'll need to share
the variables somehow to don't repeat yourself. Variable sharing is demonstrated
in the below template:

   <%
      my $foo = 42;
      my $bar = 23;
   %>
   <%* dyna.inc | SHARE: $foo, $bar %>

And then you can access C<$foo> and C<$bar> inside C<dyna.inc>. There is one
drawback by shared variables: only C<SCALARs> can be shared. You can not share
anything else. If you want to share an array, use an array reference instead:

   <%
      my @foo = (1..10);
      my $fooref = \@foo;
   %>
   <%* dyna.inc | SHARE: $fooref %>

=head2 BLOCKS

A block consists of a header part and the content.

   <%| HEADER;
       BODY
   %>

C<HEADER> includes the commands and terminated with a semicolon. C<BODY> is the
actual block content.

=head3 BLOCK FILTERS

B<WARNING> Block filters are considered to be experimental. They may be changed
or completely removed in the future.

Identical to include filters, but works on blocks of text:

   <%| FILTER: HTML, OtherFilter;
      <p>&FooBar=42</p>
   %>

Note that you can not use any variables in these blocks. They are static.

=head1 METHODS & FUNCTIONS

=head2 new

=head2 cache

=head2 class_id

=head2 compile

=head2 connector

=head2 C<io>

=head2 C<tts>

See L<Text::Template::Simple::API> for the technical/gory details.

=head1 EXAMPLES

   TODO

=head1 ERROR HANDLING

You may need to C<eval> your code blocks to trap exceptions. Some recoverable
failures are silently ignored, but you can display them as warnings 
if you enable debugging.

=head1 BUGS

Contact the author if you find any bugs.

=head1 CAVEATS

=head2 No mini language

There is no mini-language. Only C<perl> is used as the template
language. So, this may or may not be I<safe> from your point
of view. If this is a problem for you, just don't use this 
module. There are plenty of template modules with mini-languages
inside C<CPAN>.

=head2 Speed

There is an initialization cost and this will show itself after
the first compilation process. The second and any following compilations
will be much faster. Using cache can also improve speed, since this will
eliminate the parsing phase. Also, using memory cache will make
the program run more faster under persistent environments. But the 
overall speed really depends on your environment.

Internal cache manager generates ids for all templates. If you supply 
your own id parameter, this will improve performance.

=head2 Optional Dependencies

Some methods/functionality of the module needs these optional modules:

   Devel::Size
   Text::Table
   Perl::Tidy

=head1 SEE ALSO

L<Text::Template::Simple::API>, L<Apache::SimpleTemplate>, L<Text::Template>,
L<Text::ScriptTemplate>, L<Safe>, L<Opcode>.

=head2 MONOLITHIC VERSION

C<Text::Template::Simple> consists of C<15+> separate modules. If you are
after a single C<.pm> file to ease deployment, download the distribution
from a C<CPAN> mirror near you to get a monolithic C<Text::Template::Simple>.
It is automatically generated from the separate modules and distributed in
the C<monolithic_version> directory.

However, be aware that the monolithic version is B<not supported>.

=head1 AUTHOR

Burak Gursoy <burak@cpan.org>.

=head1 COPYRIGHT

Copyright 2004 - 2016 Burak Gursoy. All rights reserved.

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.24.0 or,
at your option, any later version of Perl 5 you may have available.
=cut
