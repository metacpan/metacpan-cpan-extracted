# ABSTRACT: spelling of HTML documents


package Test::HTML::Spelling;

use v5.10;

use Moose;
use MooseX::NonMoose;

extends 'Test::Builder::Module';

use utf8;

use curry;

use Const::Fast;
use Encode;
use HTML::Parser;
use List::Util qw( reduce );
use Scalar::Util qw( looks_like_number );
use Search::Tokenizer;
use Text::Aspell;

our $VERSION = 'v0.4.0';

# A placeholder key for the default spellchecker

const my $DEFAULT => '_';



has 'ignore_classes' => (
    is      => 'rw',
    isa     => 'ArrayRef[Str]',
    default => sub { [qw( no-spellcheck )] },
);


has 'check_attributes' => (
    is      => 'rw',
    isa     => 'ArrayRef[Str]',
    default => sub { [qw( title alt )] },
);

has '_empty_elements' => (
    is      => 'rw',
    isa     => 'HashRef',
    default => sub {
        return {
            map { $_ => 1 } (
                qw( area base basefont br col frame hr img input isindex link meta param )
            )
        };
    },
);


has 'ignore_words' => (
    is      => 'rw',
    isa     => 'HashRef',
    default => sub { {} },
);

has 'tester' => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        my $self = shift;
        return $self->builder;
    },
);

has 'tokenizer' => (
    is      => 'rw',
    lazy    => 1,
    default => sub {

        my ($self) = @_;

        return Search::Tokenizer->new(

            regex     => qr/\p{Word}+(?:[-'.]\p{Word}+)*/,
            lower     => 0,
            stopwords => $self->ignore_words,

        );

    },
);

has 'parser' => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        my ($self) = @_;

        return HTML::Parser->new(

            api_version => 3,

            ignore_elements    => [qw( script style )],
            empty_element_tags => 1,

            start_document_h => [ $self->curry::_start_document ],
            start_h =>
              [ $self->curry::_start_element, "tagname,attr,line,column" ],
            end_h  => [ $self->curry::_end_element, "tagname,line" ],
            text_h => [ $self->curry::_text,        "dtext,line,column" ],

        );

    },
);

has '_spellers' => (
    is      => 'ro',
    isa     => 'HashRef',
    lazy    => 1,
    default => sub {
        my $speller = Text::Aspell->new();
        my $self = { $DEFAULT => $speller, };
        return $self;
    },
);


sub speller {
    my ( $self, $lang ) = @_;
    $lang =~ tr/-/_/ if ( defined $lang );

    if ( my $speller = $self->_spellers->{ $lang // $DEFAULT } ) {

        return $speller;

    }
    elsif ( $lang eq $self->_spellers->{$DEFAULT}->get_option('lang') ) {

        $speller = $self->_spellers->{$DEFAULT};

        # Extract non-regional ISO 639-1 language code

        if ( $lang =~ /^([a-z]{2})[_-]/ ) {
            if ( defined $self->_spellers->{$1} ) {
                $speller = $self->_spellers->{$1};
            }
            else {
                $self->_spellers->{$1} = $speller;
            }
        }

        $self->_spellers->{$lang} = $speller;

        return $speller;

    }
    else {

        $speller = Text::Aspell->new();
        $speller->set_option( "lang", $lang );

        # Extract non-regional ISO 639-1 language code

        if ( $lang =~ /^([a-z]{2})[_-]/ ) {
            if ( defined $self->_spellers->{$1} ) {
                $speller = $self->_spellers->{$1};
            }
            else {
                $self->_spellers->{$1} = $speller;
            }
        }

        $self->_spellers->{$lang} = $speller;

        return $speller;

    }
}


sub langs {
    my ($self) = @_;
    my @langs = grep { !/[_]/ } ( keys %{ $self->_spellers } );
    return @langs;
}

has '_errors' => (
    is      => 'rw',
    isa     => 'Int',
    default => 0,
);

has '_context' => (
    is      => 'rw',
    isa     => 'ArrayRef[HashRef]',
    default => sub { [] },
);

sub _context_depth {
    my ($self) = @_;
    return scalar( @{ $self->_context } );
}

sub _context_top {
    my ($self) = @_;
    return $self->_context->[0];
}

sub _is_ignored_context {
    my ($self) = @_;
    if ( $self->_context_depth ) {
        return $self->_context_top->{ignore};
    }
    else {
        return 0;
    }
}

sub _context_lang {
    my ($self) = @_;
    if ( $self->_context_top ) {
        return $self->_context_top->{lang};
    }
    else {
        return $self->speller->get_option("lang");
    }
}

sub _push_context {
    my ( $self, $element, $lang, $ignore, $line ) = @_;

    if ( $self->_empty_elements->{$element} ) {
        return;
    }

    unshift @{ $self->_context },
      {
        element => $element,
        lang    => $lang,
        ignore  => $ignore || $self->_is_ignored_context,
        line    => $line,
      };
}

sub _pop_context {
    my ( $self, $element, $line ) = @_;

    if ( $self->_empty_elements->{$element} ) {
        return;
    }

    my $context = shift @{ $self->_context };
    return $context;
}

sub _start_document {
    my ($self) = @_;
    $self->_context( [] );
    $self->_errors(0);

}

sub _start_element {
    my ( $self, $tag, $attr, $line ) = @_;

    $attr //= {};

    my %classes = map { $_ => 1 } split /\s+/, ( $attr->{class} // "" );

    my $state = $self->_is_ignored_context;

    my $ignore = reduce {
        no warnings 'once';
        $a || $b;
    }
    ( $state, map { $classes{$_} // 0 } @{ $self->ignore_classes } );

    my $lang = $attr->{lang} // $self->_context_lang;

    $self->_push_context( $tag, $lang, $ignore, $line );

    unless ($ignore) {

        foreach my $name ( @{ $self->check_attributes } ) {
            $self->_text( $attr->{$name}, $line ) if ( exists $attr->{$name} );
        }
    }
}

sub _end_element {
    my ( $self, $tag, $line ) = @_;

    if ( my $context = $self->_pop_context( $tag, $line ) ) {

        if ( $tag ne $context->{element} ) {
            $self->tester->croak(
                sprintf(
                    "Expected element '%s' near input line %d",
                    $context->{element}, $line // 0
                )
            );
        }

        my $lang = $context->{lang};
    }

}

sub _text {
    my ( $self, $text, $line ) = @_;

    unless ( $self->_is_ignored_context ) {

        my $speller  = $self->speller( $self->_context_lang );
        my $encoding = $speller->get_option('encoding');

        my $iterator = $self->tokenizer->($text);

        while ( my $u_word = $iterator->() ) {

            my $word = encode( $encoding, $u_word );

            my $check =
                 $speller->check($word)
              || looks_like_number($word)
              || $word =~ /^\d+(?:[-'._]\d+)*/;
            unless ($check) {

                $self->_errors( 1 + $self->_errors );
                $self->tester->diag(
                    "Unrecognized word: '${word}' at line ${line}");
            }

        }

    }

}


sub check_spelling {
    my ( $self, $text ) = @_;

    $self->_errors(0);
    $self->parser->parse($text);
    $self->parser->eof;

    if ( $self->_errors ) {
        $self->tester->diag(
            sprintf(
                "Found %d spelling %s",
                $self->_errors, ( $self->_errors == 1 ) ? "error" : "errors"
            )
        );
    }

    return ( $self->_errors == 0 );
}


sub spelling_ok {
    my ( $self, $text, $message ) = @_;

    $self->tester->ok( $self->check_spelling($text), $message );
}

__PACKAGE__->meta->make_immutable;

no Moose;


use namespace::autoclean;

1;    # End of Test::HTML::Spelling

__END__

=pod

=encoding UTF-8

=head1 NAME

Test::HTML::Spelling - spelling of HTML documents

=head1 VERSION

version v0.4.0

=head1 SYNOPSIS

  use Test::More;
  use Test::HTML::Spelling;

  use Test::WWW::Mechanize;

  my $sc = Test::HTML::Spelling->new(
      ignore_classes   => [qw( no-spellcheck )],
      check_attributes => [qw( title alt )],
  );

  $sc->speller->set_option('lang','en_GB');
  $sc->speller->set_option('sug-mode','fast');

  my $mech = Test::WWW::Mechanize->new();

  $mech->get_ok('http://www.example.com/');

  $sc->spelling_ok($mech->content, "spelling");

  done_testing;

=head1 DESCRIPTION

This module parses an HTML document, and checks the spelling of the
text and some attributes (such as the C<title> and C<alt> attributes).

It will not spellcheck the attributes or contents of elements
(including the contents of child elements) with the class
C<no-spellcheck>.  For example, elements that contain user input, or
placenames that are unlikely to be in a dictionary (such as timezones)
should be in this class.

It will fail when an HTML document is not well-formed.

=begin readme

=head1 REQUIREMENTS

This module requires Perl v5.10 or newer and the following non-core
modules:

=over

=item L<Const::Fast>

=item L<curry>

=item L<HTML::Parser>

=item L<Moose>

=item L<MooseX::NonMoose>

=item L<namespace::autoclean>

=item L<Search::Tokenizer>

=item L<Text::Aspell>

=back

The following modules are used for tests but are not needed to run
this module:

=over

=item L<File::Slurp>

=item L<Test::Builder>

=item L<Test::Pod::Spelling>

=back

=end readme

=for readme stop

=head1 METHODS

=head2 ignore_classes

This is an accessor method for the names of element classes that will
not be spellchecked.  It is also a constructor parameter.

It defaults to C<no-spellcheck>.

=head2 check_attributes

This is an accessor method for the names of element attributes that
will be spellchecked.  It is also a constructor parameter.

It defaults to C<title> and C<alt>.

=head2 ignore_words

This is an accessor method for setting a hash of words that will be
ignored by the spellchecker.  Use it to specify a custom dictionary,
e.g.

  use File::Slurp;

  my %dict = map { chomp($_); $_ => 1 } read_file('custom');

  $sc->ignore_words( \%dict );

=head2 speller

  my $sc = $sc->speller($lang);

This is an accessor that gives you access to a spellchecker for a
particular language (where C<$lang> is a two-letter ISO 639-1 language
code).  If the language is omitted, it returns the default
spellchecker:

  $sc->speller->set_option('sug-mode','fast');

Note that options set for the default spellchecker will not be set for
other spellcheckers.  To ensure all spellcheckers have the same
options as the default, use something like the following:

  foreach my $lang (qw( en es fs )) {
      $sc->speller($lang)->set_option('sug-mode',
          $sc->speller->get_option('sug-mode')
      )
  }

=head2 langs

    my @langs = $sc->langs;

Returns a list of languages (as two-letter ISO 639-1 codes) that there
are spellcheckers for.

This can be checked I<after> testing a document to ensure that the
document does not contain markup in unexpected languages.

=head2 check_spelling

  if ($sc->check_spelling( $content )) {
    ..
  }

Check the spelling of a document, and return true if there are no
spelling errors.

=head2 spelling_ok

    $sc->spelling_ok( $content, $message );

Parses the HTML file and checks the spelling of the document text and
selected attributes.

=head1 KNOWN ISSUES

=head2 Using Test::HTML::Spelling in a module

Suppose you subclass a module like L<Test::WWW::Mechanize> and add a
C<spelling_ok> method that calls L</spelling_ok>.  This will work
fine, except that any errors will be reported as coming from your
module, rather than the test scripts that call your method.

To work around this, call the L</check_spelling> method from within
your module.

=for readme continue

=head1 SEE ALSO

The following modules have similar functionality:

=over 4

=item L<Apache::AxKit::Language::SpellCheck>

=item L<HTML::Spelling::Site>

=back

=head1 SOURCE

The development version is on github at L<https://github.com/robrwo/Test-HTML-Spelling>
and may be cloned from L<git://github.com/robrwo/Test-HTML-Spelling.git>

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/robrwo/Test-HTML-Spelling/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 CONTRIBUTORS

=for stopwords Interactive Information, Ltd Murray Walker Rusty Conover Shlomi Fish

=over 4

=item *

Interactive Information, Ltd <cpan@interactive.co.uk>

=item *

Murray Walker <perl@minty.org>

=item *

Rusty Conover <rusty@luckydinosaur.com>

=item *

Shlomi Fish <shlomif@shlomifish.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2012-2018 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
