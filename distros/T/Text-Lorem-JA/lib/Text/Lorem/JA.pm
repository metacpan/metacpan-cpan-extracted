package Text::Lorem::JA;
use 5.008005;
use strict;
use warnings;
use utf8;
use Carp;
use File::Basename qw( dirname );
use File::Spec::Functions qw( catdir catfile canonpath );
use Cwd qw( abs_path );

our $VERSION = "0.04";

use constant DICTIONARY_DIR =>
    canonpath(catdir(dirname(__FILE__), '..', '..', '..', 'auto', 'share', 'dist', 'Text-Lorem-JA'));
use constant DEFAULT_DICTIONARY =>
    catdir(DICTIONARY_DIR, 'dict.txt');

sub new {
    my ($class, %options) = @_;
    my $self = bless {}, $class;

    $self->{dictionary} = $options{dictionary};
    $self->{chain}      = $options{chain} || 1;

    my $lazy = $options{lazy};

    $self->{dict} = [];
    $self->{tree} = {};
    $self->{loaded} = 0;

    if (! $lazy) {
        $self->_load_dict($self->{dictionary});
    }

    return $self;
}

my $_singleton;
sub _singleton {
    my ($class) = @_;

    unless (defined $_singleton) {
        $_singleton = $class->new();
    }

    return $_singleton;
}

sub sentences {
    my ($self, $count, %options) = @_;

    unless (ref $self) {
        $self = $self->_singleton();
    }

    return join("", map { $self->sentence(%options) } ( 1 .. $count ));
}

sub sentence {
    my ($self, %options) = @_;

    unless (ref $self) {
        $self = $self->_singleton();
    }

    unless ($self->{loaded}) {
        $self->_load_dict($self->{dictionary});
    }

    my $chain = $options{chain} || $self->{chain};

    unless ($chain > 0) {
        croak "invalid chain option value ($chain)";
    }
    unless ($chain <= $self->{chain}) {
        croak "chain option value ($chain) exceeds dict's chain ($self->{chain})";
    }

    my @tokens;
    my @stack = ( 0 ) x $chain;

    my $limitter = 100;
    while ($limitter -- > 0) {
        my @cands = $self->_lookup_candidates(@stack);
        my $cand = $cands[int(rand(scalar @cands))];
        last if $cand < 0;     # EOS

        push @tokens, $self->{dict}->[$cand];

        shift @stack;
        push @stack, $cand;
    }

    return join("", @tokens);
}

sub words {
    my ($self, $count) = @_;

    unless (ref $self) {
        $self = $self->_singleton();
    }

    unless ($self->{loaded}) {
        $self->_load_dict($self->{dictionary});
    }

    my @tokens;
    while ($count > @tokens) {
        push @tokens, $self->_words($count - @tokens);
    }

    return join("", @tokens);
}

sub _words {
    my ($self, $count) = @_;

    my @tokens;
    my @stack = ( 0 );

    while ($count > 0) {
        my @cands = grep { $_ >= 0 } $self->_lookup_candidates(@stack);

        last if @cands == 0 || @cands == 1 && $cands[0] < 0;   # EOS only

        my @new_cands;
        foreach my $cand (@cands) {
            foreach my $next_cand ($self->_lookup_candidates($cand)) {
                if ($next_cand >= 0) {
                    push @new_cands, $cand;
                    last;
                }
            }
        }
        last unless @new_cands;

        my $cand = $new_cands[int(rand(scalar @new_cands))];

        push @tokens, $self->{dict}->[$cand];
        $count --;

        shift @stack;
        push @stack, $cand;
    }

    return @tokens;
}

sub word {
    my ($self, $length) = @_;

    unless (ref $self) {
        $self = $self->_singleton();
    }

    unless ($self->{loaded}) {
        $self->_load_dict($self->{dictionary});
    }

    my $word = "";
    while ($length > length $word) {
        $word .= $self->_word($length - length $word);
    }

    return $word;
}

sub _word {
    my ($self, $length) = @_;

    my $dict = $self->{dict};
    my $word = "";
    my @stack = ( 0 );

    while ($length > 0) {
        my @cands
            = grep { $dict->[$_] !~ m{\A[。、．，]\z}xmso }
              grep { $_ >= 0 }
                   $self->_lookup_candidates(@stack);

        last if @cands == 0 || @cands == 1 && $cands[0] < 0;   # EOS only

        my @new_cands;
        foreach my $cand (@cands) {
            foreach my $next_cand ($self->_lookup_candidates($cand)) {
                if ($next_cand >= 0
                 && $dict->[$next_cand] !~ m{\A[。、．，]\z}xmso) {
                    push @new_cands, $cand;
                    last;
                }
            }
        }
        last unless @new_cands;

        my @short_cands
            = grep { $length >= length $dict->[$_] } @new_cands;

        if (! @short_cands) {
            @short_cands
                = sort { length $dict->[$a] <=> length $dict->[$b] }
                       @new_cands;
            my $shortest = length $dict->[$short_cands[0]];
            @short_cands
                = grep { $shortest >= length $dict->[$_] } @short_cands;
        }

        my $cand  = $short_cands[int(rand(scalar @short_cands))];
        my $token = $dict->[$cand];
        if (length $token > $length) {
            $token = substr $token, 0, $length;
        }

        $word .= $token;
        $length -= length $token;

        shift @stack;
        push @stack, $cand;
    }

    return $word;
}

sub _load_dict {
    my ($self, $dictionary) = @_;

    if (! ref $dictionary) {
        $self->_load_dict_from_file(_dictionary_file($dictionary));
    }
    elsif (ref $dictionary eq 'SCALAR') {
        my @lines = split /(\r?\n)/, $$dictionary;
        $self->_load_dict_from_stream(
            sub {
                my ($line, $lf) = splice @lines, 0, 2;
                return unless defined $line;
                $line . ($lf || "");
            }
        );
    }
    elsif (ref $dictionary eq 'IO') {
        $self->_load_dict_from_handle($dictionary);
    }
    elsif (eval { $dictionary->can('getline') }) {
        # IO::Handle like interface
        $self->_load_dict_from_stream(sub { $dictionary->getline() });
    }
    else {
        croak "Unsupported type for dictionary ($dictionary).";
    }
}

sub _dictionary_file {
    my ($filename) = @_;

    my $pathname;
    if ($filename) {
        $pathname = abs_path($filename);
        unless (-f $pathname) {
            $pathname = catfile(DICTIONARY_DIR, $filename);
            unless (-f $pathname) {
                $pathname = undef;
            }
        }
    } else {
        $filename = DEFAULT_DICTIONARY;
        $pathname = $filename;
    }

    unless ($pathname) {
        croak "dictionary file ($filename) not found";
    }

    return $pathname;
}

sub _load_dict_from_file {
    my ($self, $filename) = @_;

    open my $handle, '<:encoding(UTF-8)', $filename
        or croak "open $filename error: $!";

    $self->_load_dict_from_handle($handle);

    close $handle;
}

sub _load_dict_from_handle {
    my ($self, $handle) = @_;

    $self->_load_dict_from_stream(sub { <$handle> });
}

sub _load_dict_from_stream {
    my ($self, $sub_getline) = @_;

    my $step = 0;
    my @stack;

    while (my $line = &$sub_getline()) {
        chomp $line;
        next if $line =~ /^#/o;     # comment line

        if ($step == 0) {
            # chain
            $self->{chain} = +$line;
            $step = 1;
        }
        elsif ($step == 1) {
            # first word dict entry must be "" (empty)
            push @{$self->{dict}}, $line;
            $step = 2;
        }
        elsif ($step == 2) {
            # word dictionary
            if ($line eq "") {  # separator
                $step = 3;
            } else {
                push @{$self->{dict}}, $line;
            }
        }
        else {
            # probability tree

            # turn heading spaces into preceding stack
            my @new_stack;
            my @tokens = split / /o, $line;
            while (@tokens) {
                if ($tokens[0] eq "") {
                    shift @tokens;      # trim first (empty) token
                    push @new_stack, shift @stack;
                } else {
                    push @new_stack, join("", @tokens);
                    @tokens = ();
                }
            }
            @stack = @new_stack;

            $self->_insert_tree_node(@stack);
        }
    }

    $self->{loaded} = 1;
}

sub _insert_tree_node {
    my ($self, @stack) = @_;

    my $node = $self->{tree};
    while (@stack) {
        my $token = shift @stack;

        if ($token =~ /=/o) {
            my ($child, $cands) = split '=', $token, 2;
            my $word_id = +$child;
            $node->{$word_id}
                = [ map { +$_ } split(/,\s*/o, $cands) ];
            last;
        } else {
            my $word_id = +$token;
            $node->{$word_id} ||= {};
            $node = $node->{$word_id};
        }
    }
}

sub _lookup_candidates {
    my ($self, @stack) = @_;

    my $node = $self->{tree};
    while (@stack) {
        last unless $node;
        return @$node if ref $node eq 'ARRAY';

        my $word = shift @stack;
        $node = $node->{$word};
    }

    if (ref($node) eq 'HASH') {
        return keys %$node;
    } elsif (ref($node) eq 'ARRAY') {
        return @$node;
    } else {
        return ( -1 );      # EOS
    }
}

1;
__END__

=encoding utf-8

=head1 NAME

Text::Lorem::JA - Japanese Lorem Ipsum generator

=head1 SYNOPSIS

    use Text::Lorem::JA;
    
    # Generated text are represented in Perl internal format (Unicode).
    binmode \*STDOUT, ':encoding(UTF-8)';
    
    my $lorem = Text::Lorem::JA->new();
    
    # Generate a string of text with 10 characters.
    print $lorem->word(10), "\n";
    # => 好きな強みとを考えて
    
    # Generate a string of text with 10 tokens.
    print $lorem->words(10), "\n";
    # => 主要な素質にしばしばあるまいまではっきりつかまえる
    
    # Generate a string of text with 3 sentences.
    # Invoking via class methods are also allowed.
    print Text::Lorem::JA->sentences(3), "\n";
    # => いちばん面白いいい方をはっきりさせない会社があっても、
    #    やがてかわって、許されない。人物の生きている、ほこり、
    #    品位のあらわれである。文明社会は、正しくそういう立場に
    #    いながら、求めて一塊の岩礁に膠着してみる。

=head1 DESCRIPTION

Text::Lorem::JA generates fake Japanese text via Markov chain.

=head1 METHODS

Most of instance methods can be called as class methods.
Generated strings are in Perl's internal format (Unicode).

=over 4

=item C<new>

    $lorem = Text::Lorem::JA->new();
    $lorem = Text::Lorem::JA->new( dictionary => ..., chains => ... );

Creates a new Text::Lorem::JA generator object.

Can specify dictionary file and chains for generating sentences.

=item C<word>

    $word = $lorem->word($length);

Returns a exact given C<$length> string.

Argument length represents number of Unicode characters.  Not bytes.

=item C<words>

    $words = $lorem->words($number_of_morphems);

Generates a string composed from morphemes of given number.

At Japanese language, words are not delimited by whitespaces in normal style.

=item C<sentence>

    $sentence = $lorem->sentence();

Generates a single sentence.

=item C<sentences>

    $sentences = $lorem->sentences($number_of_sentences);

Generates sentences.

=back

=head1 TOOL

You can use L<lorem_ja> executable for generating Japanese Lorem text from CLI.

=head1 LICENSE

Copyright (C) ITO Nobuaki.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

ITO Nobuaki E<lt>dayflower@cpan.orgE<gt>

=cut

