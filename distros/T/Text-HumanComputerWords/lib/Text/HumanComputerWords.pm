package Text::HumanComputerWords;

use strict;
use warnings;
use 5.022;
use experimental qw( signatures refaliasing );
use Ref::Util qw( is_ref is_plain_coderef );
use Carp qw( croak );

# ABSTRACT: Split human and computer words in a naturalish manner
our $VERSION = '0.04'; # VERSION


sub new ($class, @args)
{
  croak "uneven arguments passed to constructor" if @args % 2;

  my $i=0;
  while(exists $args[$i])
  {
    my $name = $args[$i];
    my $code = $args[$i+1];

    croak "argument @{[ $i+1 ]} is undef" unless defined $name;
    croak "argument @{[ $i+2 ]} is undef" unless defined $code;
    croak "argument @{[ $i+1 ]} is not a plain string" if is_ref $name;
    croak "argument @{[ $i+2 ]} is not a plain code reference" unless is_plain_coderef $code;

    $i+=2;
  }

  bless [@args], $class;
}


sub default_perl
{
  return (
    path_name => sub ($text) {
         $text =~ m{^/(bin|boot|dev|etc|home|lib|lib32|lib64|mnt|opt|proc|root|sbin|tmp|usr|var)(/|$)}
      || $text =~ m{^[a-z]:[\\/]}i
    },
    url_link => sub ($text) {
         $text =~ /^[a-z]+:\/\//i
      || $text =~ /^(file|ftps?|gopher|https?|ldapi|ldaps|mailto|mms|news|nntp|nntps|pop|rlogin|rtsp|sftp|snew|ssh|telnet|tn3270|urn|wss?):\S/i
    },
    module => sub ($text) {
         $text =~ /^[a-z]+::([a-z]+(::[a-z]+)*('s)?)$/i
    },
  );
}


sub split ($self, $text)
{
  my @result;

  frag_loop: foreach my $frag (CORE::split /\s+/, $text)
  {
    next unless $frag =~ /\w/;

    my $i=0;
    while(defined $self->[$i])
    {
      my $name = $self->[$i++];
      my $code = $self->[$i++];
      if($name eq 'substitute')
      {
        \local $_ = \$frag;
        $code->();
      }
      elsif($code->($frag))
      {
        push @result, [ $name, $frag ] unless $name eq 'skip';
        next frag_loop;
      }
    }

    word_loop: foreach my $word (CORE::split /\b{wb}/, $frag)
    {
      next word_loop unless $word =~ /\w/;
      push @result, [ word => $word ];
    }

  }

  @result;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Text::HumanComputerWords - Split human and computer words in a naturalish manner

=head1 VERSION

version 0.04

=head1 SYNOPSIS

 use Text::HumanComputerWords;
 
 my $hcw = Text::HumanComputerWords->new(
   Text::HumanComputerWords->default_perl,
 );
 
 my $text = "this is some text with a url: https://metacpan.org, "
          . "a unix path name: /usr/local/bin "
          . "and a windows path name: c:\\Windows";
 
 foreach my $combo ($hcw->split($text))
 {
   my($type, $word) = @$combo;
   if($type eq 'word')
   {
     # $word is a regular human word
     # this, is, some, etc.
   }
   elsif($type eq 'module')
   {
     # $word looks like a module
   }
   elsif($type eq 'url_link')
   {
     # $word looks like a URL
     # https://metacpan.org,
   }
   elsif($type eq 'path_name')
   {
     # $word looks like a windows or unix filename
     # /usr/local/bin
     # c:\\Windows
   }
 }

=head1 DESCRIPTION

This module extracts human and computer words from text.  This is useful for checking the validity of these words.  Human
words can be checked for spelling, while "computer" words like URLs can be validated by other means.  URLs for example
could be checked for 404s and module names could be checked against a module registry like CPAN.

The algorithm works like thus:

=over 4

=item 1. The text is split on whitespace into fragments C<< /\s/ >>

fragments could be either a single computer word like a URL or a module, or it could be one or more human words.
If a fragment doesn't contain any word characters then it is skipped entirely C<< /\w/ >>.

=item 2. If the fragment is recognized as a computer word we are done.

Computer words can be defined any way you want.  The C<default_perl> method below is reasonable for Perl technical
documentation.

=item 3. Split the fragment into words using the Unicode word boundary C<< /\b{wb}/ >>

After the split words are identified as those containing word characters C<< /\w/ >>.

=back

=head1 CONSTRUCTOR

=head2 new

 my $hcw = Text::HumanComputerWords->new(@cpu);

Creates a new instance of the splitter class.  The C<@cpu> pairs lets you specify the logic for identifying
"computer" words.  The keys are the type names and the values are code references that identify those words.
These are special reserved types:

=over 4

=item skip

 Text::HumanComputerWords->new(
   skip => sub ($word) {
     # return true if $word should be skipped entirely
   },
 );

This is a code reference which should return true, if the C<$word> should be skipped entirely.  The default skip code reference
always returns false.

=item substitute

 Text::HumanComputerWord->new(
   substitute => sub {
     # the value is passed in as $_ and can be modified
   },
 );

This allows you to substitute the current word.  The main intent here is to allow supporting splitting CamelCase and snakeCase
into separate words, so they can be checked as human words.  Example:

 Text::HumanComputerWords->new(
   substitute => sub {
     # this should split both CamelCase and snakeCase
     s/([A-Z]+)/ $1/g if /^[a-z]+$/i && lcfirst($_) ne lc $_;
   },
 ),

=item word

 Text::HumanComputerWords->new(
   word => sub ($word) {},  # error
 );

The C<word> type is reserved for human words, and cannot be overridden.

=back

The order of the pairs matters and a type can be specified more than once.  If a given computer word matches multiple
types it will only be reported as the first type matches.  Example:

 Text::HumanComputerWords->new(
   foo_or_bar => sub ($word) { $word eq 'foo' },
   foo_or_bar => sub ($word) { $word eq 'bar' },
 );

=head1 METHODS

=head2 default_perl

 my @cpu = Text::HumanComputerWords->default_perl;

Returns the computer word pairs reasonable for a technical Perl document.  These pairs should be
passed into L</new>, optionally with extra pairs if you like, for example:

 my $hcw = Text::HumanComputerWords->new(
 
   # this needs to come first so that platypus modules are recognized before
   # non-platypus modules in the default rule set
   platypus_module => sub ($word) { $word =~ /^FFI::Platypus(::[A-Za-z0-9_]+)*$/ },
 
   # the normal Perl rules.
   Text::HumanComputerWords->default_perl,
 
   # this can go anywhere, but we check for it last.
   plus_one => sub ($word) { $word eq '+1' },
 );

By itself, this returns pairs that will recognize these types:

=over 4

=item path_name

A file system path.  Something that looks like a UNIX or Windows filename or directory path.

=item url_link

A URL.  The regex to recognize a URL is naive so if the URLs need to be validated they should be done separately.

=item module

A Perl module name.  C<Something::Like::This>.

=back

=head2 split

 my @pairs = $hcw->split($text);

This method splits the text into word combo pairs.  Each pair is returned as an array reference.  The first element is the type,
and the second is the word.  The types are as defined when the C<$hcw> object is created, plus the C<word> type for human words.

=head1 CAVEATS

Doesn't recognize VMS paths!  Oh noes!

The C<default_perl> method provides computer "words" that are identified with a regular expression which is somewhat reasonable,
but probably has a few false positives or negatives, and doesn't do any validation for things like URLs or modules.  Modules
like L<strict> or L<warnings> that do not have a C<::> cannot be recognized.

=head1 AUTHOR

Graham Ollis <plicease@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
