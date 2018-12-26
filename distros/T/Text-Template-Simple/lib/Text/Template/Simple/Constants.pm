package Text::Template::Simple::Constants;
$Text::Template::Simple::Constants::VERSION = '0.91';
use strict;
use warnings;

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

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Text::Template::Simple::Constants

=head1 VERSION

version 0.91

=head1 SYNOPSIS

   TODO

=head1 DESCRIPTION

Constants for Text::Template::Simple.

=head1 NAME

Text::Template::Simple::Constants - Constants

=head1 AUTHOR

Burak Gursoy <burak@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2004 by Burak Gursoy.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
