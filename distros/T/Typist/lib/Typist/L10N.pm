package Typist::L10N;
use strict;
use base qw( Locale::Maketext );

@Typist::L10N::Lexicon = (_AUTO => 1);

sub language_name {
    my $tag = $_[0]->language_tag;
    require I18N::LangTags::List;
    I18N::LangTags::List::name($tag);
}

sub encoding   { 'iso-8859-1' }    ## Latin-1
sub ascii_only { 0 }

#--- for plugins

sub add_lexicon {
    no strict 'refs';
    my $lex = *{ref(Typist->language_handle) . '::Lexicon'}{'HASH'};
    map { $lex->{$_} = $_[1]->{$_} } keys %{$_[1]};
}

sub has_lexicon {                  # phrase???
    no strict 'refs';
    my $lex = *{ref(Typist->language_handle) . '::Lexicon'}{'HASH'};
    exists $lex->{$_[1]};
}

1;

__END__

=head1 NAME

Typist::L10N - Base class for localization services

=head1 METHODS

=over

=item add_lexicon(\%lexicon)

Adds lexical elements to the template engine

=item has_lexicon($phrase)

Checks if a phrase is already it the language Typist is
initialized for the given phrase.

=back

=end
