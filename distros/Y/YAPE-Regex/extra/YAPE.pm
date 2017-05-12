=head1 NAME

YAPE - Yet Another Parser/Extractor

=head1 SYNOPSIS

  use YAPE::Something;
  
  my $parser = YAPE::Something->new(...);
  
  # do magical and wondrous things

=head1 DESCRIPTION

The C<YAPE> hierarchy of modules is an attempt at a unified means of parsing
and extracting content.  It attempts to maintain a generic interface, to
promote simplicity and reusability.  The API is powerful, yet simple.  The
modules do tokenization (which can be intercepted) and build trees, so that
extraction of specific nodes is doable.

=head2 Wishful Thinking

This discipline of parsing/extracting is here in hopes of creating an API that
allows you to parse some language -- C, for instance -- and fiddle with it.  Here
are a couple examples of what C<YAPE::C> might be capable of.

=head3 Code Filtering

First, we create a C<YAPE::C> object:

  use YAPE::C;
  
  open ORIG, "+<myprog.c"
    or die "can't open myprog.c for r/w: $!";
  my $code;
  { local $/; $code = <ORIG>; }
  
  seek ORIG, 0, 0;
  truncate ORIG, 0;
  
  my $parser = YAPE::C->new($code);

Now, we go through the code it parses, chunk by chunk (tokenizing):

  while (my $chunk = $parser->next) {
    # turn 'foo.bar = 2 * 3;'
    # into 'foo.bar = filter(2 * 3);'
    if (
      $chunk->type eq 'assign' and
      $chunk->lhs->fullstring eq 'foo.bar'
    ) {
      my $func = YAPE::C::function('filter');
      $func->args($chunk->rhs);
      $chunk->rhs($func);
    }
  }

Now, we print the modified code:

  print ORIG $parser->fullstring;
  
  close ORIG;

In an ideal world, that would safely place the C<filter()> function around the
arguments of all assignments to C<foo.bar>.

=head3 Code Creation

A statement like C<alpha.beta.gamma = 2 * 3;> would be represented as

  my $assign = YAPE::C::statement->new(
    YAPE::C::assign->new(
      YAPE::C::struct->new(
        'alpha',
          YAPE::C::struct->new(
          'beta',
          YAPE::C::attr->new('gamma'),
        ),
      ),
      YAPE::C::op->new(
        '*',
        YAPE::C::num->new(2),
        YAPE::C::num->new(3),
      ),
    )
  );

The internal tree for this would look like

  {
    TYPE => 'statement',
    CONTENT => [
      {
        TYPE => 'assign',
        
        LHS => {
          TYPE => 'struct',
          VAL => 'alpha',
          ATTR => {
            TYPE => 'struct',
            VAL = 'beta',
            ATTR => {
              TYPE => 'attr',
              VAL => 'gamma',
            },
          },
        },
        
        RHS => {
          TYPE => 'op',
          OP => '*',
          TERMS => [
            {
              TYPE => 'num',
              VAL => 2,
            },
            {
              TYPE => 'num',
              VAL => 3,
            },
          ],
        },
      },
    ],
  }

=head3 Code Extraction

If you wanted to extract all the comments from a C program, you would do so in
the following manner:

  my $extractor = $parser->extract(-COMMENT);
  my @comments;
  while (my $chunk = $extractor->()) {
    push @comments, $chunk;
  }

Or, if you wanted to find all the C<if>-statements in a program, you might do:

  my $extractor = $parser->extract(if_stmt => []);
  my @if_stmts;
  while (my $chunk = $extractor->()) {
    push @if_stmts, $chunk;
  }

=head2 Reality Check

Obviously, C<YAPE::C> would have to do a lot of work to offer the potentially
massive requests sent to it ("give me all function calls that use the variable
C<foo.bar> in them"); so this module might be a long way off.

But it's not impossible, if the C code is parsed properly.

=head1 DEVELOPMENT

Jeff C<japhy> Pinyan is the front-man for the C<YAPE> hierarchy of modules; all
requests/candidates for a new C<YAPE> module should be sent through him.  His
contact information is at the bottom of this document.  The C<YAPE> web site is
at F<http://www.pobox.com/~japhy/YAPE/>.

All C<YAPE> modules are designed to have the same general exterior API.  This
is like the C<DBI> approach.  Jeff intends to keep things this way.  If a new
feature gets added to C<YAPE::Foo>, that feature should be added (even if only
as a no-op if not applicable) to all other C<YAPE> modules.  This is only true
for the parser's API; individual elements (such as HTML tags, or C operators,
or regular expression nodes) can behave in their own idiom.

=head1 AUTHOR

  Jeff "japhy" Pinyan
  CPAN ID: PINYAN
  japhy@pobox.com
  http://www.pobox.com/~japhy/

=head1 SEE ALSO

The C<YAPE> module you're looking for.

=cut
