package XML::XSS::Template;
our $AUTHORITY = 'cpan:YANICK';
$XML::XSS::Template::VERSION = '0.3.5';
# ABSTRACT: XML::XSS templates


use 5.10.0;

use Moose;
use MooseX::SemiAffordanceAccessor;

use experimental 'smartmatch';

with qw(MooseX::Clone);

use overload
  '&{}'  => sub { $_[0]->compiled },
  'bool' => sub { length $_[0]->code };

no warnings qw/ uninitialized /;

our @sigils = qw/ = ~ @ /;


Moose::Exporter->setup_import_methods( as_is => ['xsst'], );

sub xsst($) {
    my $template = shift;

    my ( undef, $filename, $line ) = caller;

    return XML::XSS::Template->new(
        _filename => $filename,
        _line     => $line,
        template  => $template,
    );
}


has template => ( 
    isa => 'Str', 
    is => 'rw', 
    required => 1,
    traits => [qw(Clone)],
);


has code => ( isa => 'Str', is => 'rw',
    traits => [qw(Clone)],
);

has compiled => ( is => 'rw',
    traits => [qw(Clone)],
);

has _filename => ( is => 'rw',
    traits => [qw(Clone)],
);
has _line     => ( is => 'rw',
    traits => [qw(Clone)],
);

sub BUILD {
    my $self = shift;

    $self->_parse_template;

    my $sub = <<"END_SUB";
sub {
my ( \$style, \$node, \$args ) = \@_;
local *STDOUT;
my \$output;
open STDOUT, '>', \\\$output or die;
@{[ $self->code ]}
return \$output;
}
END_SUB

    $self->set_code($sub);

    $self->set_compiled( eval $sub );
    die $@ if $@;

}

sub _parse_template {
    my $self = shift;

    my $sigil_re = '[' . join( '', @sigils ) . ']';

    my @tokens = split /(<-?%$sigil_re?|%-?>)/, $self->template;

    my @parsed;

  TOKEN:
    while (@tokens) {
        my $token = shift @tokens;

        if ( $token =~ s/<(-?)%// ) {
            if ( $1 and @parsed and $parsed[-1][0] ) {
                $parsed[-1][1] =~ s/\s+\Z//;
            }
            $self->_parse_block( $token, \@tokens, \@parsed );
        }
        else {

            # it's a verbatim block
            my ( $f, $l ) = ( $self->_filename, $self->_line );
            $self->_set_line( $l + $token =~ y/\n// );
            if ( @parsed and $parsed[-1][2] ) {
                $token =~ s/^\s+//;
            }
            push @parsed, [ 1, $token, undef, $f, $l ];
        }
    }

    my $code;
    my ( $pf, $pl );
    for my $block (@parsed) {
        $code .= join( ' ', "\n#line ", $block->[4], $block->[3] ) . "\n"
          unless $block->[4] == $pl and $block->[3] eq $pf;
        ( $pf, $pl ) = ( $block->[3], $block->[4] );
        if ( $block->[0] and length $block->[1] ) {
            $block->[1] =~ s/\|/\\\|/g;
            $block->[1] = 'print(qq|' . quotemeta($block->[1]) . '|);';
        }

        $code .= $block->[1];

    }

    return $self->set_code($code);
}

sub _parse_block {
    my $self = shift;

    my ( $token, $tokens, $parsed ) = @_;

    my $code;
    my $closing_tag;
    my $level = 1;
    while (@$tokens) {
        my $t = shift @$tokens;
        $level++ if $t =~ /\A<-?%/;
        $level-- if $t =~ /\A%-?>/;
        if ( $level == 0 ) {
            $closing_tag = $t;
            last;
        }
        $code .= $t;
    }

    my ( $f, $l ) = ( $self->_filename, $self->_line );

    $self->_set_line( $l + $code =~ y/\n// );

    die "stylesheet <% %>s are unbalanced: <%$token $code\n"
      unless $closing_tag;

    given ($token) {
        when ('=') {
            $code = 'print(' . $code . ');';
        }
        when ('~') {
            $code =~ s/\A\s+|\s+Z//g;    # trim
            $code =~ s/'/\\'/g;
            $code =
              qq{eval { print \$style->render(\$node->findnodes('$code'), \$args) } or warn $@;};

        }
        when ('@') {
            $code =~ s/\A\s+|\s+Z//g;    # trim
            $code =~ s/'/\\'/g;
            $code = qq{eval { print \$node->findvalue('$code') } or warn $@;};
        }
        default {

            # add a semi-colon if there is none
            $code .= ';' unless $code =~ /;\s*\Z/;
        }
    }

    push @$parsed, [ 0, $code, !!( $closing_tag =~ /-/ ), $f, $l ];
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

XML::XSS::Template - XML::XSS templates

=head1 VERSION

version 0.3.5

=head1 SYNOPSIS

    use XML::XSS;

    my $xss = XML::XSS->new;

    $xss.'chapter'.'content' *= xsst q{
        <%~ title %>
        <%~ para %>
        <%~ note %>
    };

=head1 DESCRIPTION

XML::XSS::Template provides a templating markup language to ease the
writing of rules for XML::XSS stylesheet rules. So that the style

    $xss.'chapter'.'content' *= sub {
        my ( $style, $node, $args ) = @_;
        my $output;

        $output .= $style->render( $node->findnodes( 'title' ) );

        $output .= $style->render( $node->findnodes( 'para' ) );

        if ( my @notes = $node->findnodes('note') ) {
            $output .= '<div class="notes">'
                    .  $style->render( @notes )
                    .  '</div>';
        }

        return $output;
    };

can be written

    $xss.'chapter'.'content' *= xsst q{
        <%~ title %>
        <%~ para %>

        <% if ( my  @notes = $node->findnodes('note') ) { %>
            <div class="notes">
                <%= $style->render( @notes ) %>
            </div>
        <% } %>
    };

=head1 TEMPLATE SYNTAX

The template directives are surrounded by '<%', '%>' delimiters.
An optional dash can be squeezed in ('<-%', '%->'), which will
cause all preceding or following whitespaces (including carriage returns) 
to be squished from the rendered document. 
This is useful to keep a stylesheet readable without
generating transformed document with many whitespace gaps. The dash can be 
added independently to the right and left delimiter.

For example

    <h1>
        <-%@ /doc/title %->
    </h1>

will be rendered as

    <h1>A Tale of Two Cities</h1>

As an empty directive is an no-op, one can 
take advantage of it and use '<-%%->' as
a magic template compacter.

=head2 Template Directives

=head3 <%  %>

Evaluates the code enclosed without printing anything.

Example:

    <% my $now = localtime %>

To make the directive output something, simply C<print> it.

    <% print "oooh, shiny" if $thingy->albedo_index > 50  %>

To create a loop in your template, use two directives to wrap the opening and
closing pieces of code:

    <% for my $item ( @shopping_list ) { %>
        <p>I need a <%= $item %>.</p>
    <% } %>

=head3 <%= %>

Evaluates the enclosed code and prints its result. 

    Author: <%= 'Hi ' + $name %>

=head3 <%# %>

Comments out the enclosed text, which will neither be executed or
show in the rendered document.

=head3 <%~ $xpath %>

Takes the XPath expression, applies it on the current
node and renders the resulting nodes. Equivalent of doing

    <%= $style->render( $node->findnodes( $xpath ), $args ) %>

Example:

    $xss->set( chapter => { content => <<'END_CONTENT' } );
        <%~ title %>   <%# process the title node %>
        <%~ para %>    <%# ... and then the paragraphs %>
        <%~ note %>    <%# ... and the notes %>
    END_CONTENT

=head3 <%@ $xpath %>

Takes the XPath expression and prints its value.  Equivalent of doing

    <%= $node->findvalue( $xpath ) %>

=head1 EXPORTED FUNCTIONS

=head2 xsst( $template )

Takes the template given as a string and convert it as a 
C<XML::XSS::Template> object ready to be used by a style attribute 
of the stylesheet.

    my $template = xsst q{
        <div>
            <h2>List of stuff</h2>
            <%~ item %>
        </div>
    };

    $xss->set( list => { content => $template } );

From the point of view of the stylesheet, the template object created by
C<xsst> is just another coderef, and will be passed the usual rendering node,
xml node and option hashref arguments. For convenience, those are already
made available as C<$style>, C<$node> and C<$args>.

    my $template = xstt q{
        <h2><%= $style->stylesheet->stash->{section_nbr}++ %>. <%~ title %></h2>
        <% for my $child ( $node->childNodes ) { %>
            do something...
        <% } %>
    };

=head1 ATTRIBUTES

=head2 template

The original template string.

=head2 code

The code generated out of the original template, as a string.

    my $template = xsst q{ Hello <%= $style->stylesheet->stash->{name} %> };
    print $template->code;

=head1 AUTHOR

Yanick Champoux <yanick@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017, 2013, 2011, 2010 by Yanick Champoux.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
