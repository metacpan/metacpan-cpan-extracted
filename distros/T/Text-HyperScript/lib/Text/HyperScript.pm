use 5.008001;
use strict;
use warnings;

package Text::HyperScript;

our $VERSION = "0.08";

use Exporter::Lite;

our @EXPORT = qw(raw true false text h);

sub raw {
    my $html = $_[0];
    return bless \$html, 'Text::HyperScript::NodeString';
}

sub true {
    my $true = !!1;
    return bless \$true, 'Text::HyperScript::Boolean';
}

sub false {
    my $false = !!0;
    return bless \$false, 'Text::HyperScript::Boolean';
}

# copied from HTML::Escape::PurePerl
my %escape = (
    '&'  => '&amp;',
    '>'  => '&gt;',
    '<'  => '&lt;',
    q{"} => '&quot;',
    q{'} => '&#39;',
    q{`} => '&#96;',
    '{'  => '&#123;',
    '}'  => '&#125;',
);

sub text {
    my ($src) = @_;
    $src =~ s/([&><"'`{}])/$escape{$1}/ge;
    return $src;
}

sub h {
    my $tag  = text(shift);
    my $html = qq(<${tag});

    my %attrs;
    my @contents;

    for my $data (@_) {
        if ( ref $data eq 'Text::HyperScript::NodeString' ) {
            push @contents, ${$data};
            next;
        }

        if ( ref $data eq 'HASH' ) {
            %attrs = ( %attrs, %{$data} );
            next;
        }

        if ( ref $data eq 'ARRAY' ) {
            push @contents, @{$data};
            next;
        }

        push @contents, text($data);
    }

    for my $prefix ( sort keys %attrs ) {
        my $data = $attrs{$prefix};
        if ( !ref $data ) {
            $html .= q{ } . text($prefix) . q{="} . text($data) . q{"};

            next;
        }

        if ( ref $data eq 'Text::HyperScript::Boolean' && ${$data} ) {
            $html .= " " . text($prefix);

            next;
        }

        if ( ref $data eq 'HASH' ) {
        PREFIX:
            for my $suffix ( sort keys %{$data} ) {
                my $key   = text($prefix) . '-' . text($suffix);
                my $value = $data->{$suffix};

                if ( !ref $value ) {
                    $html .= qq( ${key}=") . text($value) . qq(");

                    next PREFIX;
                }

                if ( ref $value eq 'Text::HyperScript::Boolean' && ${$value} ) {
                    $html .= qq( ${key});

                    next PREFIX;
                }

                if ( ref $value eq 'ARRAY' ) {
                    $html .= qq( ${key}=") . ( join q{ }, map { text($_) } sort @{$value} ) . qq(");

                    next PREFIX;
                }

                $html .= qq( ${key}=") . text($value) . qq(");
            }

            next;
        }

        if ( ref $data eq 'ARRAY' ) {
            $html .= q( ) . text($prefix) . q(=") . ( join q{ }, map { text($_) } sort @{$data} ) . q(");

            next;
        }

        $html .= q{ } . text($prefix) . q(=") . text($data) . q(");
    }

    if ( @contents == 0 ) {
        $html .= " />";
        return bless \$html, 'Text::HyperScript::NodeString';
    }

    $html .= q(>) . join( q{}, @contents ) . qq(</${tag}>);
    return bless \$html, 'Text::HyperScript::NodeString';
}

package Text::HyperScript::NodeString;

use overload q("") => \&to_string;

sub new {
    my ( $class, $html ) = @_;
    return bless \$html, $class;
}

sub to_string {
    return ${ $_[0] };
}

package Text::HyperScript::Boolean;

use overload ( q(bool) => \&is_true, q(==) => \&is_true );

sub is_true {
    return !!${ $_[0] };
}

sub is_false {
    return !${ $_[0] };
}

package Text::HyperScript;

1;

=encoding utf-8

=head1 NAME

Text::HyperScript - Let's write html/xml templates as perl code!

=head1 SYNOPSIS

    use feature qw(say);
    use Text::HyperScript qw(h true);

    # tag only
    say h('hr');          # => '<hr />'
    say h(script => q{}); # => '<script></script>'

    # tag with content
    say h('p', 'hi,');    # => '<p>hi,</p>'
    say h('p', ['hi,']);  # => '<p>hi,</p>'

    say h('p', 'hi', h('b', ['anonymous']));  # => '<p>hi,<b>anonymous</b></p>'
    say h('p', 'foo', ['bar'], 'baz');        # => '<p>foobarbarz</p>'

    # tag with attributes
    say h('hr', { id => 'foo' });                     # => '<hr id="foo" />'
    say h('hr', { id => 'foo', class => 'bar'});      # => '<hr class="bar" id="foo">'
    say h('hr', { class => ['foo', 'bar', 'baz'] });  # => '<hr class="bar baz foo">' 

    # tag with prefixed attributes
    say h('hr', { data => { foo => 'bar' } });              # => '<hr data-foo="bar">'
    say h('hr', { data => { foo => [qw(foo bar baz)] } });  # => '<hr data-foo="bar baz foo">'

    # tag with value-less attribute
    say h('script', { crossorigin => true }, ""); # <script crossorigin></script>

=head1 DESCRIPTION

This module is a html/xml tags generator like as hyperscript-ish style.

=head1 FEATURES

=over

=item All html/xml tags write as perl code!

We're able to write html/xml templates witout raw markup.

=item Generates automatic escaped html/xml tags

This module generates automatic escaped html/xml tags by default.

Like this:

    use feature qw(say);
    
    say h('p', 'hello, <script>alert("XSS!")</script>')
    # => <p>hello, &lt;scrip&gt;alert("XSS!")&lt;/script&gt;</p>

=item Includes shorthand for multiple class name and prefixed attributes

This module has shorthand multiple class name, and data or aria and others prefixed attributes.

For examples:

    use feature qw(say);
    
    say h('h1', { class => [qw/ C B A /] }, 'msg');
    # => <h1 class="A B C">msg</h1>
    
    say h('button', { data => { click => '1' } }, 'label');
    # => <button data-click="1">label</button>
    
    say h('a', { href => '#', aria => {label => 'label' } }, 'link');
    # => <a aria-label="label" href="#">link</a>

=item Enable to generate empty and empty content tags

This module supports empty element and empty content tags.

Like that:

    use feature qw(say);
    
    say h('hr'); # empty tag
    # => <hr />
    
    say h('script', '') # empty content tag
    # => <script></script>

=back

=head1 TAGSETS

This modules includes shorthand modules for writes tag name as subroutine.

Currently Supported:

HTML5: L<Text::HyperScript::HTML5>

=head1 MODULE FUNCTIONS

=head2 text

This function generates html/xml escaped text.

=head2 raw

This function generates raw text B<without html/xml escape>.

This function B<should be used for display trusted text content>.

=head2 true / false (constants)

This constants use for value-less attributes.

For examples, if we'd like to use C<crossorigin> attriute on C<script> tag,
we're able to use these contants like this:

    use feature qw(say);

    say h('scirpt', { crossorigin => true }, '')
    # => <scritp crossorigin></script>

C<false> constants exists for override value-less attributes.
If set C<false> to value-less attribute, that attribute ignored.

=head2 h

This function makes html/xml text from perl code.

The first argument is tag name, and after argument could be passed these values as repeatable.

NOTICE:

The all element attributes sorted by ascendant.

This behaviour is intentional for same result of reproducible output.

=over

=item $text : Str

The text string uses as a element content.

For example:

    use feature qw(say);

    say h('p', 'hi,') # <- 'hi,' is a plain text string
    # => <p>hi,</p>

=item \%attributes : HashRef[Str | ArrayRef[Str] | HashRef[Str] ]

The element attributes could be defined by these styles:

=over

=item \%attributes contains Str

In this case, Str value uses for single value of attribute.

    use feature qw(say);
    
    say h('p', { id => 'msg' }, 'hi,')
    # => <p id="msg">hi,</p>

=item \%attributes contains ArrayRef[Str]

If attribute is ArrayRef[Str], these Str values joined by whitespace and sorted ascendant.

    use feature qw(say);
    
    say h('p', { class => [qw/ foo bar baz /] }, 'hi,')
    # => <p class="bar baz foo">hi,</p>

=item HashRef[Str]

If attribute is HashRef[Str], this code means shorthand for prefixed attribute.

    use feature qw(say);

    say h('p', { data => { label => 'foo' } }, 'hi,')
    # => <p data-label="foo"></p>

=back

=item \@nested : ArrayRef

The all ArrayRef passed to C<h> function is flatten by internally.

This ArrayRef supported all content type of C<h> function.

=back

=head1 LICENSE

Copyright (C) OKAMURA Naoki a.k.a nyarla.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

OKAMURA Naoki a.k.a nyarla: E<lt>nyarla@kalaclista.comE<gt>

=cut
