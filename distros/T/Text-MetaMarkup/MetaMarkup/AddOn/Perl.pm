package Text::MetaMarkup::AddOn::Perl;
use strict;

sub _eval {
    my ($self, $code) = @_;
    $self->{evals}++;
    # No lexicals must exist at this point
    no strict;
    return eval "package $self->{package};\n#line 1\n$code";
}

sub paragraph_perl {
    my ($self, $tag, $text) = @_;
    my $array = $self->_eval($text);
    return $self->escape($@) if $@;
    
    return if ref $array ne 'ARRAY';
    my $result;
    for (@$array) {
        my $r = $self->parse_paragraph($_);
        $result .= $r if defined $r;
    }   
    return $result;
}

sub inline_perl {
    my ($self, $tag, $text) = @_;
    my $r = $self->_eval($text);
    return $self->escape($@) if $@;   
    return $self->parse_paragraph_text($r);
}

1;

__END__

=head1 NAME

Text::MetaMarkup::AddOn::Perl - Add-on for MM to support embedded Perl

=head1 SYNOPSIS

    package Text::MetaMarkup::Subclass;
    use base qw(Text::MetaMarkup Text::MetaMarkup::AddOn::Perl);

=head1 DESCRIPTION

Text::MetaMarkup::AddOn::Perl adds support for the following special tags:

=over 4

=item Paragraph tag C<perl>

Executes a block of Perl in its own lexical scope.  If the returned value is an
array reference, the elements are parsed as paragraphs, other return values are
discarded. Use of C<print> is useless, assign to a variable instead.

=item Inline tag C<perl>

Evaluates a Perl expression in scalar context in its own lexcial scope. The
returned value is interpolated (parsed as paragraph text).

=back

=head1 EXAMPLE

(When used together with Text::MetaMarkup::HTML)

=head2 Input

    h2: Now is {perl:localtime}

    perl:
    [ map "p: $_", 1..3 ]

=head2 Output

    <h2>Now is Mon Jun  9 19:17:07 2003</h2>

    <p>1</p>

    <p>2</p>

    <p>3</p>

=head1 LICENSE

There is no license. This software was released into the public domain. Do with
it what you want, but on your own risk. The author disclaims any
responsibility.

=head1 AUTHOR

Juerd Waalboer <juerd@cpan.org> <http://juerd.nl/>

=cut
