package WWW::Lipsum::Chinese;
use strict;
use warnings;
use LWP::Simple;
use Encode;
our $VERSION = '0.03';

sub new {
    return bless {};
}

sub generate {
    my ($self) = @_;
    $self->_fetch;
    $self->_to_utf8;
    $self->_parse;
    return $self->{content};
}

sub _fetch {
    my ($self) = @_;
    my $content = get("http://www.richyli.com/tool/loremipsum/")
        or die("Couldn't get lorem ipsum content from richili.com");
    $self->{content} = $content;
    $self->{parsed}  = 0;
}

sub _parse {
    my ($self, $content) = @_;
    $content ||= $self->{content};
    $content =~ s{^.*</h2>}{}s;
    $content =~ s{<hr size="1">.*$}{}s;
    $content =~ s{</?p>}{}sg;
    $self->{parsed} = 1;
    $self->{content} = $content;
    return $content;
}

sub _to_utf8 {
    my $self = shift;
    return unless defined $self->{content};
    if ( Encode::is_utf8($self->{content} )) {
        return $self->{content};
    }
    $self->{content} = Encode::decode("big5", $self->{content});
    return $self->{content}
}

1;

__END__

=head1 NAME

WWW::Lipsum::Chinese - Chinese Lorem Ipsum Generator

=head1 SYNOPSIS

  my $lipsum = WWW::Lipsum::Chinese->new;
  print $lipsum->generate;

=head1 DESCRIPTION

This module retrive Chinese "Lorem Ipsum" text genereated by
<http://www.richyli.com/tool/loremipsum/> .

=head1 METHODS

=over 4

=item new

Object constructor.

=item generate

Generate some random piece of placeholder text.

=back

=head1 COPYRIGHT

Copyright 2006 by Kang-min Liu <gugod@gugod.org>.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

See <http://www.perl.com/perl/misc/Artistic.html>

The author of <http://www.richyli.com/tool/loremipsum/> web tool
is Richy Li, See <http://www.richyli.com/about/copyright.htm> for
the copyright of richyli.com. The author of this module is not
responsible for any possible legal issue of module user. Use
at your own risk.

=cut
