package Vim::Snippet::Converter;
use warnings;
use strict;
use File::Path qw(mkpath rmtree);
use File::Copy 'copy';

=head1 NAME

Vim::Snippet::Converter - A Template Converter for Slippery Snippet Vim Plugin

=head1 VERSION

Version 0.082

=cut

our $VERSION = '0.082';

=head1 SYNOPSIS

    #!perl
    use Vim::Snippet::Converter;

    my $vsc = Vim::Snippet::Converter->new();
    open my $in , "<" , "perl.snt";
    open my $out , ">" , "perl_snippets.vim";
    $vsc->convert( $in , $out );
    close ($in , $out);

=head1 DESCRIPTION

This module provides template conversion for Vim SnippetEmu Plugin (
L<http://www.vim.org/scripts/script.php?script_id=1318> )

You can write your template simply. see L</"TEMPLATE FORMAT">

=head1 SCRIPT

convert template file (*.snt)

    $ scc -s [filename]  [-i {path}] [-c {path}]

for example: 

    # generate snippet vim script to stdout
    $ scc -s perl.snt

    $ scc -s filename.snt > perl_snippets.vim
    

    # to replace the previous install automatically.
    $ scc -s filename.snt -i ~/.vim/syntax/perl.vim

    -s, --src  [filename]
        specify source file path

    -i, --install-to [filename]
        specify vim script path, e.g.  ~/.vim/syntax/perl.vim

    -c, --create-completion [filepath]
        create snippet keyword completion file for vim

to save triggers into vim completion file:

    $ scc -s perl.snt -c vim_completion

=head1 VIM COMPLETION DICTIONARY

save triggers into vim completion file:

    $ scc -s perl.snt -c vim_completion

append the below setting to your F<.vimrc> , it is located in your home directory.

    set dictionary+=/path/to/vim_completion

when you want to call the keyword completion , just press C<Ctrl-X Ctrl-K> in Insert-Mode.

=head1 TEMPLATE FORMAT

    # comments
    ;sub
    sub <<function>> ( <<prototype>> ) {
        my <<>> = <<>>;
        return <<returnValue>>;
    }
    ;end

C<sub> is a trigger name , when you press C<E<lt>TabE<gt>> , the trigger will be replaced with the template.

C<E<lt>E<lt>functionE<gt>E<gt>> is called Place Holder , when you press
C<E<lt>TabE<gt>> again , curosr will jump to the next position to let you enter
some text.

=head1 FUNCTIONS

=head2 new

=cut

sub new {
    my $class = shift;
    return bless {} , $class;
}

=head2 convert

=cut

sub convert {
    my ( $self , $in , $out ) = @_;
    $self->parse( $in , $out );
}

=head2 _gen_trigger

=cut

sub _gen_trigger {
    my $self = shift;
    my $trigger_name = shift;
    my $snippet_code = shift;

    my $output = "exec \"Snippet $trigger_name ";
    $output .= $snippet_code . "\"\n";
    return $output;
}

=head2 _gen_snippet

=cut

sub _gen_snippet {
    my $self = shift;
    my $buf  = shift;

    # strip comment
    return $buf if( $buf =~ s/^#/"/ );

    # place holder
    my $space = ' ' x 4;
    $buf =~ s{"}{\\"}g;
    $buf =~ s{<<>>}{".st.et."}g;
    $buf =~ s{<<(.+?)>>}{".st."$1".et."}g;
    $buf =~ s{\n}{<CR>}g;
    $buf =~ s{\t}{<Tab>}g;
    $buf =~ s{$space}{<Tab>}g;
    return $buf;
}

=head2 parse

=cut

sub parse {
    my ( $self , $in , $out ) = @_;

    my @trigger_names = ( );
    $self->{triggers} = \@trigger_names;

	print $out $self->gen_header();
    while (<$in>) { 
        # print $out snippet_gen( $1) 
        if ( my ( $snippet_name ) = ( $_ =~ m/^;(\w+?)$/ ) ) {
            # read snippet template
            
            # print STDERR "Add trigger: $snippet_name\n";
            push @{ $self->{triggers} } , $snippet_name;
            my $code_buffer = '';

            R_SNIPPET:
            while( my $tpl_line = <$in> ) {
                if( $tpl_line =~ m/^;end$/ ) {
                    # write template
                    my $snippet_o = $self->_gen_snippet( $code_buffer );
                    print $out $self->_gen_trigger( $snippet_name , $snippet_o );
                    last R_SNIPPET;
                }
                $code_buffer .= $tpl_line;
            }
        }
    }
}

=head2 gen_header 

=cut

sub gen_header {
	return <<EOF;
if !exists('loaded_snippet') || &cp
    finish
endif

let st = g:snip_start_tag
let et = g:snip_end_tag
let cd = g:snip_elem_delim

EOF

}


=head1 AUTHOR

Cornelius, C<< <cornelius.howl+cpan at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-vim-snippet-compiler at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Vim-Snippet-Converter>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Vim::Snippet::Converter

You can also look for information at:

=over 4

=item * Vim

L<http://www.vim.org/>

=item * Slippery Snippets Vim Plugin

L<http://slipperysnippets.blogspot.com/2006/12/howto-try-out-latest-version-of.html>

L<http://c9s.blogspot.com/2007/06/vim-snippet.html>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Vim-Snippet-Converter>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Vim-Snippet-Converter>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Vim-Snippet-Converter>

=item * Search CPAN

L<http://search.cpan.org/dist/Vim-Snippet-Converter>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2007 Cornelius, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of Vim::Snippet::Converter
