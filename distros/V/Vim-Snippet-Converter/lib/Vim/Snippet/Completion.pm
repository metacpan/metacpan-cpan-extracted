package Vim::Snippet::Completion;
use strict;
use warnings;
use utf8;


=head1 SYNOPSIS

    my $comp = new Vim::Snippet::Completion;
    $comp->gen({ 
        output => 'vim_completion', 
        list => \@keyword_list ,
        opt => 'new',
    });

    $comp->gen({ 
        output => 'vim_completion', 
        list => \@keyword_list ,
        opt => 'append',
    });

    $comp->setup_dict({
        file => '~/vim_completion',
        vimrc => '~/.vimrc' ,
    });


=cut

sub new {
    my $class = shift;
    return bless {} , $class;
}

=head3 gen( { output => '/path/to/file' , list => \@keyword_list , opt => 'append' } );

=cut

sub gen {
    my $self = shift;
    my $args = shift;

    if( $args->{opt} eq 'append' ) {
        open FH , ">>" , $args->{output};
    } elsif ( $args->{opt} eq 'new' ) {
        open FH , ">" , $args->{output};
    }
    print FH "$_ " for( @{ $args->{list} } );
    print FH "\n";
    close FH;
}

=head3 setup_dict( { file => '/path/to/vim_completion' , vimrc => '/path/to/vimrc' } );
=cut

sub setup_dict {
    my $self = shift;
    my $args = shift;
    $args->{vimrc} ||= $ENV{HOME} . '/.vimrc';
    open FH , ">>" , $args->{vimrc};
    print FH "set dict+=" . $args->{file} . "\n" ;
    close FH;
}

1;
