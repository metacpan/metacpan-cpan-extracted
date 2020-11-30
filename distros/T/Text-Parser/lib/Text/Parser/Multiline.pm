use strict;
use warnings;

package Text::Parser::Multiline 1.000;

# ABSTRACT: To be used to add custom line-unwrapping routines to the Text::Parser object.

use Moose::Role;


requires(
    qw(save_record multiline_type lines_parsed __read_file_handle),
    qw(join_last_line is_line_continued _set_this_line this_line)
);

use Text::Parser::Error;

around save_record       => \&__around_save_record;
around is_line_continued => \&__around_is_line_continued;
after __read_file_handle => \&__after__read_file_handle;

my $orig_save_record = sub {
    return;
};

my %save_record_proc = (
    join_last => \&__join_last_proc,
    join_next => \&__join_next_proc,
);

sub __around_save_record {
    my ( $orig, $self ) = ( shift, shift );
    $orig_save_record = $orig;
    return $orig->( $self, @_ ) if not defined $self->multiline_type;
    my $type = $self->multiline_type;
    $save_record_proc{$type}->( $orig, $self, @_ );
}

sub __around_is_line_continued {
    my ( $orig, $self, $line ) = ( shift, shift, shift );
    return $orig->( $self, $line )
        if not defined $self->multiline_type
        or $self->multiline_type eq 'join_next';
    return 0 if not $orig->( $self, $line );
    return 1 if $self->lines_parsed() > 1;
    parser_exception("join_last continuation character on first line $line");
}

sub __after__read_file_handle {
    my $self = shift;
    return if not defined $self->multiline_type;
    return $self->__test_safe_eof()
        if $self->multiline_type eq 'join_next';
    $self->_set_this_line( $self->__pop_last_line );
    $orig_save_record->( $self, $self->this_line );
}

sub __test_safe_eof {
    my $self = shift;
    my $last = $self->__pop_last_line();
    return if not defined $last;
    my $lnum = $self->lines_parsed();
    parser_exception(
        "join_next continuation character in last line ($lnum \"$last\"): unexpected EoF"
    );
}

sub __join_next_proc {
    my ( $orig, $self ) = ( shift, shift );
    $self->__append_last_stash(@_);
    return if $self->is_line_continued(@_);
    $self->__call_orig_save_rec($orig);
}

sub __call_orig_save_rec {
    my $self = shift;
    my $orig = shift;
    $self->_set_this_line( $self->__pop_last_line );
    $orig->( $self, $self->this_line );
}

sub __join_last_proc {
    my ( $orig, $self ) = ( shift, shift );
    return $self->__append_last_stash(@_) if $self->__more_may_join_last(@_);
    $self->__call_orig_save_rec($orig);
    $self->__append_last_stash(@_);
}

sub __more_may_join_last {
    my $self = shift;
    $self->is_line_continued(@_) or not defined $self->_joined_line;
}

has _joined_line => (
    is      => 'rw',
    isa     => 'Str|Undef',
    default => undef,
    clearer => '_delete_joined_line',
);

sub __append_last_stash {
    my ( $self, $line ) = @_;
    return $self->_joined_line($line) if not defined $self->_joined_line;
    my $joined_line = $self->join_last_line( $self->__pop_last_line, $line );
    $self->_joined_line($joined_line);
}

sub __pop_last_line {
    my $self      = shift;
    my $last_line = $self->_joined_line();
    $self->_delete_joined_line;
    return $last_line;
}

no Moose::Role;


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Text::Parser::Multiline - To be used to add custom line-unwrapping routines to the Text::Parser object.

=head1 VERSION

version 1.000

=head1 SYNOPSIS

Input text file:

    This is a line that is wrapped with a trailing percent sign %
    like the last one. This may seem unusual, but hey, it's an %
    example.

The code required to unwrap this:

    use Text::Parser;

    my $parser = Text::Parser->new(multiline_type => 'join_next');
    $parser->custom_line_unwrap_routines(
        is_wrapped => sub {  # A method to detect if this line is wrapped
            my ($self, $this_line) = @_;
            $this_line =~ /\%\s*$/;
        }, 
        unwrap_routine => sub { # Method to unwrap line, gets called only on line after % sign
            my ($self, $last_line, $this_line) = @_;
            chomp $last_line;
            $last_line =~ s/\%\s*$//g;
            "$last_line $this_line";
        }, 
    );

When C<$parser> gets to C<read> the input text, those three lines get unwrapped and processed by the rules as if it were a single line.

=head1 DESCRIPTION

You should not C<use> this module directly in your code. The functionality of this L<role|Moose::Role> is accessed through L<Text::Parser>. The purpose of this L<role|Moose::Role> is to write custom routines to unwrap line-wrapped text input, using an object of L<Text::Parser>.

=head1 SEE ALSO

=over 4

=item *

L<Text::Parser>

=back

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<http://github.com/balajirama/Text-Parser/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Balaji Ramasubramanian <balajiram@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018-2019 by Balaji Ramasubramanian.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
