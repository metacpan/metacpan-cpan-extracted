package Text::Markdown::PerlExtensions;
$Text::Markdown::PerlExtensions::VERSION = '0.06';
use strict;
use warnings;
use 5.8.0;

use parent qw(Text::Markdown Exporter);
use Text::Balanced qw(extract_bracketed);

our @EXPORT_OK = qw(markdown add_formatting_code);
my %handler =
(
 'M' => \&_formatting_code_module,
 'A' => \&_formatting_code_author,
 'D' => \&_formatting_code_distribution,
 'P' => \&_formatting_code_perlfunc,
);

sub markdown
{
    my ( $self, $text, $options ) = @_;

    # Detect functional mode, and create an instance for this run
    unless (ref $self) {
        if ( $self ne __PACKAGE__ ) {
            my $ob = __PACKAGE__->new();
                                # $self is text, $text is options
            $ob->{ handlers } = \%handler;
            return $ob->markdown($self, $text);
        }
        else {
            croak('Calling ' . $self . '->markdown (as a class method) is not supported.');
        }
    }

    $options ||= {};

    %$self = (
              %{ $self->{params} },
              %$options,
              params => $self->{params},
              handlers => $self->{handlers}
             );

    $self->_CleanUpRunData($options);

    return $self->_Markdown($text);
}

sub add_formatting_code
{
    if (@_ == 2) {
        my ($code, $handler_function) = @_;
        $handler{$code} = $handler_function;
    } elsif (@_ == 3) {
        my ($self, $code, $handler_function) = @_;
        $self->{ handlers } = {} if not exists $self->{ handlers };
        $self->{ handlers }->{ $code }  = $handler_function;
    } else {
        croak('wrong number of args to add_handler()');
    }
}

sub _RunSpanGamut {
    my ($self, $text) = @_;

    $text = $self->SUPER::_RunSpanGamut($text);
    return $self->_DoExtendedMarkup($text);
}

sub new
{
    my ($class, %p) = @_;
    my $self = $class->SUPER::new(%p);

    return undef unless defined($self);
    $self->{ handlers } = \%handler;

    return $self;
}

sub _DoExtendedMarkup
{
    my ($self, $text) = @_;
    my $regexp = join('|', keys %{ $self->{ handlers }});

    if ($text =~ m!\A(.*?)($regexp)(<[^/].*)\z!ms) {
        my $prefix = $1;
        my $code   = $2;
        my $tail   = $3;
        my ($extracted, $remainder) = extract_bracketed($tail, '<>');
        if (defined($extracted)) {
            # Need to be able to handled I<B<bob> and B<mary>>,
            # which is why we're using extract_bracketed, and recurse on the contents
            $extracted =~ s/\A<|>\z//msg;
            $extracted = $self->_DoExtendedMarkup($extracted);
            my $result = $self->{handlers}->{$code}->( $extracted );
            return $prefix.$result.$self->_DoExtendedMarkup($remainder);
        }
    }

    $text =~ s!\bRT#([0-9]+)\b!<a href="https://rt.cpan.org/Public/Bug/Display.html?id=$1">RT#$1</a>!msg;
    $text =~ s!\bPRT#([0-9]+)\b!<a href="https://rt.perl.org/Public/Bug/Display.html?id=$1">Perl#$1</a>!msg;

    return $text;
}

sub _formatting_code_distribution
{
    my $dist_name = shift;

    return qq{<a href="https://metacpan.org/release/$dist_name" class="distribution">$dist_name</a>};
}

sub _formatting_code_module
{
    my $module_name = shift;

    return qq{<a href="https://metacpan.org/pod/$module_name" class="module">$module_name</a>};
}

sub _formatting_code_author
{
    my $author_id = shift;

    return qq{<a href="https://metacpan.org/author/$author_id" class="cpanAuthor">$author_id</a>};
}

sub _formatting_code_perlfunc
{
    my $function_name = shift;

    return qq{<a href="http://perldoc.perl.org/functions/$function_name.html" class="function">$function_name</a>};
}

1;

=encoding utf8

=head1 NAME

Text::Markdown::PerlExtensions - markdown converter that supports perl-specific extensions

=head1 SYNOPSIS

In your markdown:

 You might P<use> M<PerlX::Define> in D<Moops> by A<TOBYINK>.

And to convert that:

 use Text::Markdown::PerlExtensions qw(markdown);
 $html = markdown($markdown);

=head1 DESCRIPTION

Text::Markdown::PerlExtensions provides a function for converting markdown
to HTML.
It is a subclass of L<Text::Markdown> that provides three additional
features:

=over 4

=item *

Four pod-style formatting codes, used for distribution names,
module names, PAUSE author IDs, and Perl's built-in functions.
These generate links to the relevant pages on L<MetaCPAN|https://metacpan.org>
or L<perldoc.perl.org|http://perldoc.perl.org>.

=item *

A mechanism for adding further pod-style formatting codes.

=item *

References to RT issues in the format RT#1234 will be hyperlinked to the issue on RT.

=back

I wrote this module to use with my blogging engine.
I found that I was constantly writing links to MetaCPAN,
and wanted a terser notation.

The following sections describe each of the extensions,
one by one.

=head2 Module

To refer to a module on CPAN, you use the B<M> formatting code.
If you write:

 M<Module::Path>

This generates:

 <a href="https://metacpan.org/pod/Module::Path" class="module">Module::Path</a>

The link is given a class, so you can style module names.

=head2 Distribution

To refer to a distribution, use the B<D> formatting code.
If you write

 D<Dancer>

this generates:

 <a href="https://metacpan.org/release/Dancer" class="distribution">Dancer</a>

=head2 CPAN Author

Similarly, to refer to a CPAN author, use the B<A> formatting code.
If you write:

 A<NEILB>

This generates:

 <a href="https://metacpan.org/author/NEILB" class="cpanAuthor">NEILB</a>

=head2 Perl built-in function

To link to documentation for one of Perl's built-in functions,
use the B<P> formatting code:

 P<require>

This example would produce:

 <a href="http://perldoc.perl.org/functions/require.html" class="function">require</a>

I really wanted to use the B<F> formatting code for this,
but that's already taken in the L<pod spec|http://perldoc.perl.org/perlpod.html>,
used for highlighting file names.

Note: this doesn't check whether the function name given is actually a
Perl built-in.

=head2 Markdown

All other syntax is as supported by L<Text::Markdown>.
You shouldn't find any clashes between the Pod-like extensions;
I haven't found any so far, but please let me know if you
experience any problems.

=head1 Adding formatting codes

You can add your own pod-style formatting codes.
For each code you define a function that takes one text argument
and returns the transformed version of that text.

The following shows how you could define B<I> and B<B> formatting codes,
for italic and bold respectively:

 use Text::Markdown::PerlExtensions qw(markdown add_formatting_code);
  
 sub format_italic
 {
   my $text = shift;
   
   return "<I>$text</I>";
 }
 
 sub format_bold
 {
   my $text = shift;
   
   return "<B>$text</B>";
 }
  
 add_formatting_code('I' => \&format_bold);
 add_formatting_code('B' => \&format_bold);

 my $md   = 'Highlight with B<bold> and I<italic>.';
 my $text = markdown($md);

=head1 SEE ALSO

L<Text::Markdown> - the base class for this module.

L<Markdown|http://daringfireball.net/projects/markdown/syntax> - the original spec
for markdown syntax.

=head1 REPOSITORY

L<https://github.com/neilb/Text-Markdown-PerlExtensions>

=head1 AUTHOR

Neil Bowers E<lt>neilb@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Neil Bowers <neilb@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

