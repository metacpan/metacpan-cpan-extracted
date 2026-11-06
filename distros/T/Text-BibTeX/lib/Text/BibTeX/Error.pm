package Text::BibTeX::Error;

use 5.026;
use strict;
use warnings;

use Exporter 'import';
use Scalar::Util ();

our $VERSION = '1.00';

our @EXPORT_OK = qw(BTERR_NOTIFY BTERR_CONTENT BTERR_LEXWARN BTERR_USAGEWARN
                    BTERR_LEXERR BTERR_SYNTAX BTERR_USAGEERR BTERR_INTERNAL);
our %EXPORT_TAGS = (errclasses => \@EXPORT_OK);

use constant {
   BTERR_NOTIFY    => 0,
   BTERR_CONTENT   => 1,
   BTERR_LEXWARN   => 2,
   BTERR_USAGEWARN => 3,
   BTERR_LEXERR    => 4,
   BTERR_SYNTAX    => 5,
   BTERR_USAGEERR  => 6,
   BTERR_INTERNAL  => 7,
};

my @class_names = (undef, 'warning', 'warning', 'warning', 'error',
                   'syntax error', 'fatal error', 'internal error');
my @severities  = qw(notify warning warning warning error error fatal fatal);

use overload
   '""'     => sub { $_[0]->as_string },
   'bool'   => sub { 1 },
   fallback => 1;

our $Handler;

sub new {
   my ($class, %args) = @_;
   $args{errclass} //= BTERR_USAGEERR;
   return bless {%args}, ref $class || $class;
}

sub errclass  { $_[0]{errclass} }
sub class     { $class_names[$_[0]{errclass}] }
sub severity  { $severities[$_[0]{errclass}] }
sub message   { $_[0]{message} }
sub filename  { $_[0]{filename} }
sub line      { $_[0]{line} }
sub item_desc { $_[0]{item_desc} }
sub item      { $_[0]{item} }
sub key       { $_[0]{key} }
sub caller_file { $_[0]{caller_file} }
sub caller_line { $_[0]{caller_line} }

# Is this error serious enough to make an entry fail to parse?
sub is_serious {
   my $c = $_[0]{errclass};
   return $c != BTERR_NOTIFY && $c != BTERR_CONTENT && $c != BTERR_LEXWARN;
}

sub is_fatal { $_[0]{errclass} >= BTERR_USAGEERR }

# The same format the C library has always used:
#    filename, line N, name M, warning: message
sub as_string {
   my $self = shift;
   my @where;
   push @where, $self->{filename} if defined $self->{filename};
   push @where, "line $self->{line}" if $self->{line};
   push @where, "$self->{item_desc} $self->{item}"
      if defined $self->{item_desc} && $self->{item};
   push @where, $self->class if defined $self->class;
   my $s = @where ? join(', ', @where) . ": $self->{message}" : $self->{message};
   $s .= " at $self->{caller_file} line $self->{caller_line}.\n"
      if $self->is_fatal && defined $self->{caller_file};
   return $s;
}

sub throw { die $_[0] }


# The innermost stack frame outside Text::BibTeX
sub _caller_frame {
   my $i = 1;
   my @frame;
   while (@frame = caller($i++)) {
      last if $frame[0] !~ /^Text::BibTeX(?:::|\z)/;
   }
   return @frame;
}

# How should errors be reported to the code that called into Text::BibTeX?
# Warnings are on by default (as they always were), but follow the
# caller's lexical warnings: "no warnings 'Text::BibTeX'" (or plain "no
# warnings") turns them off, and "use warnings FATAL => 'Text::BibTeX'"
# makes them fatal.
sub _policy {
   my @frame = _caller_frame();
   return 'warn' unless @frame;

   my $bits = $frame[9];
   return 'warn' unless defined $bits;          # no lexical warnings

   my $off = $warnings::Offsets{'Text::BibTeX'};
   my $all = $warnings::Offsets{'all'};
   $off = $all if !defined $off || length($bits) <= ($off >> 3);

   my $on    = vec($bits, $off, 1);
   my $fatal = vec($bits, $off + 1, 1);
   return 'off' unless $on;
   return $fatal ? 'fatal' : 'warn';
}

sub _stderr_is_utf8 {
   return scalar grep { /^(?:utf8|encoding)/ } PerlIO::get_layers(*STDERR, output => 1);
}

# Called from the XS code with the errors collected during one call into
# the C library, and the entry (if any) they belong to.
sub _dispatch {
   my ($errors, $entry) = @_;

   my $is_entry = ref $entry && Scalar::Util::reftype($entry) eq 'HASH';
   my ($file, $line) = (_caller_frame())[1, 2];
   for my $err (@$errors) {
      @{$err}{qw(caller_file caller_line)} = ($file, $line);
      $err->{key} = $entry->{key} if $is_entry && defined $entry->{key};
   }
   push @{$entry->{errors}}, @$errors if $is_entry;

   my $policy;
   for my $err (@$errors) {
      if ($Handler) {
         $Handler->($err);
         next;
      }
      die $err if $err->is_fatal;
      $policy //= _policy();
      next if $policy eq 'off';
      die $err if $policy eq 'fatal';

      my $s = $err->as_string . "\n";
      utf8::encode($s) if utf8::is_utf8($s) && !_stderr_is_utf8();
      warn $s;
   }
   return;
}

1;

__END__

=encoding UTF-8

=head1 NAME

Text::BibTeX::Error - errors and warnings from the BibTeX parser

=head1 SYNOPSIS

   use Text::BibTeX;

   # Errors are warnings by default, reported through Perl's warn()
   my $entry = Text::BibTeX::Entry->new($bibfile);
   for my $err ($entry->errors) {
      printf "%s:%d: %s\n", $err->filename, $err->line, $err->message;
   }

   # Silence them, or make them fatal, with the usual warnings pragma
   {
      no warnings 'Text::BibTeX';
      $entry = Text::BibTeX::Entry->new($bibfile);
   }
   {
      use warnings FATAL => 'Text::BibTeX';
      eval { $entry = Text::BibTeX::Entry->new($bibfile) };
      warn "bad input: " . $@->message if ref $@;
   }

   # Or take over reporting completely
   local $Text::BibTeX::Error::Handler = sub {
      my $err = shift;
      $logger->warn($err->as_string);
   };

=head1 DESCRIPTION

Every problem found by Text::BibTeX -- a syntax error in a F<.bib> file,
an undefined macro, a malformed name, or a misuse of the library -- is
reported as a C<Text::BibTeX::Error> object.  Nothing is ever written
directly to the standard error stream by the C code, and nothing ever
exits or aborts the program.

=head2 How errors are reported

Errors that arise while parsing an entry are stored in the entry; see
L<Text::BibTeX::Entry/errors>.  In addition, each error is reported as
follows:

=over 4

=item *

If C<$Text::BibTeX::Error::Handler> is set to a code reference, it is
called with the error object, and nothing else happens.

=item *

Otherwise, fatal errors (misuse of the library, or internal errors) are
thrown as exceptions with C<die>.

=item *

Other errors are passed to Perl's C<warn>, with the same text as earlier
versions of Text::BibTeX printed, for example:

   foo.bib, line 12, warning: undefined macro "jan"
   foo.bib, line 30, syntax error: found "author", expected ","

This means they can be caught with C<$SIG{__WARN__}>, and that they go
wherever C<STDERR> goes.  Their reporting follows the warnings pragma in
effect in the code that called Text::BibTeX, using the warnings category
C<Text::BibTeX>: they are reported by default (even without C<use
warnings>), are suppressed by C<no warnings 'Text::BibTeX'> or C<no
warnings>, and are thrown as exceptions under C<use warnings FATAL =E<gt>
'Text::BibTeX'>.

=back

=head1 METHODS

=over 4

=item message

The text of the message.

=item filename

=item line

Where the problem was found, if known.

=item item_desc

=item item

For problems with one item in a list (eg. the second name in a list of
names), a description of the item (eg. C<"name">) and its number.

=item key

The key of the entry being parsed when the problem was found, if any.

=item caller_file

=item caller_line

The place in your program where Text::BibTeX was called (the innermost
caller outside Text::BibTeX).  This is added to the message of fatal
errors.

=item errclass

One of the C<BTERR_*> constants (export tag C<:errclasses>):
C<BTERR_NOTIFY>, C<BTERR_CONTENT>, C<BTERR_LEXWARN>, C<BTERR_USAGEWARN>,
C<BTERR_LEXERR>, C<BTERR_SYNTAX>, C<BTERR_USAGEERR> and C<BTERR_INTERNAL>.

=item class

The name used in messages: C<"warning">, C<"error">, C<"syntax error">,
C<"fatal error"> or C<"internal error"> (C<undef> for notifications).

=item severity

C<"notify">, C<"warning">, C<"error"> or C<"fatal">.

=item is_serious

True if the error makes an entry fail to parse (see
L<Text::BibTeX::Entry/parse_ok>): lexical and syntax errors, and usage
warnings.

=item is_fatal

True for errors that are always thrown as exceptions.

=item as_string

The full message, as shown above.  Error objects also stringify to this.

=back

=cut
