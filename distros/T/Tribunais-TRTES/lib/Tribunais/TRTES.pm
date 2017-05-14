package Tribunais::TRTES;

use strict;
use warnings 'all';

use JSON;
use WWW::Mechanize;
use HTML::TreeBuilder::XPath;
use utf8;


sub new
{
    my $class = shift;
    my $self = {
        _tiponumeracao => shift, # antiga ou unificada
        _numero => shift,
        _ano => shift,
        _vara => shift,
        _recurso => shift,
        _digito => shift,
    };
    bless $self, $class;
    return $self;
}

sub sincroniza
{
    
    my($self) = @_;

    
    my $tiponumeracao=$self->{_tiponumeracao}; # antiga / unificada
    my $numero=$self->{_numero};
    my $ano=$self->{_ano};
    my $vara=$self->{_vara};
    my $recurso=$self->{_recurso}; #00
    my $digito=$self->{_digito};
    
    
    my $mech = WWW::Mechanize->new;
    $mech->agent_alias( 'Windows IE 6' );
    
    my $URI;
    if($tiponumeracao eq "antiga")
    {
        #numero antigo
        $URI="http://www.trtes.jus.br/sij/sijproc/AcompanhamentoProcessual/paginainicial.aspx?id=236&sequencial=$numero&ano=$ano&vara=$vara&recurso=$recurso";
    }
    elsif($tiponumeracao eq "unificada")
    {
        #numero unificado
        $URI="http://www.trtes.jus.br/sij/sijproc/AcompanhamentoProcessual/paginainicial.aspx?id=236&numero=$numero&digito=$digito&ano=$ano&origem=$vara";
    }
    
    
    
    $mech->post($URI);
    

    
    my $titulo = $mech->title();
    my $html = $mech->content;
    
    my $tree= HTML::TreeBuilder::XPath->new;
    $tree->parse( $html );
    
    my $tabela = $tree->findnodes('//div[@class=\'ajax__tab_panel\'][2]//table[1]');
    my $tabela_com_dados_html =  $tabela->[0]->as_HTML; #
    

    my $table_rows = $tree->findnodes( '//div[@class=\'ajax__tab_panel\'][2]//table[1]/tr' );
    
    my $count = 0;
    
    my @items;
    foreach my $row ( $table_rows->get_nodelist )
    {
       if ( $count > 1 )
       { 
            my $tree_tr = HTML::TreeBuilder::XPath->new;
            $tree_tr->parse( $row->as_HTML );
            my $strdata=$tree_tr->findvalue( '//td[2]' );
            if(length($strdata)>5)
            {
                my $row_data = {
                    data => $tree_tr->findvalue( '//td[2]' ),
                    andamento    => $tree_tr->findvalue( '//td[4]' ),
                    classe   => $tree_tr->findvalue( '//td[1]' ),
                    local   => $tree_tr->findvalue( '//td[3]' ),
                };
                push(@items, $row_data);
            }
            $tree_tr->delete;
       }
       $count++;
    }
    
    my $json = { fases => \@items }; # cria hash com nome de $json, insere no hash uma key com nome de andamentos tendo o array @registros no value dessa key
    
    my $string_json = to_json($json); # encoda o hash com nome de $json em uma string no formato JSON, e atribui à var $string_json
    
    return $string_json;
}

1;

__END__
=encoding utf8
 
=head1 NAME

Tribunais::TRTES - Interface de consulta processual no Tribunal Regional do Trabalho do Espírito Santo - Brasil.

Este módulo tem como finalidade realizar uma consulta processual na base de dados do Tribunal Regional do Trabalho do
Espírito Santo - TRTES

O resultado da sincronização é dado no formato JSON contendo todo o andamento do processo, fase à fase.

=head1 VERSION

version 0.003

=head1 SYNOPSIS

    use TRTES;

    #cria objeto tribunal
    my $tribunal = new Tribunais::TRTES($tiponumeracao, $numero, $ano, $vara, $recurso, $digito);
    
    # onde:
    #
    # $tiponumeracao -> antiga ou unificada
    # $digito -> dígito do processo
    # $numero -> numeração sem o dígito e sem o -
    # $ano -> 4 dígitos do ano da abertura do processo
    # $vara -> vara de abertura do processo
    # $recurso -> numero do recurso em julgamento
    

    # printa o resultado da sincronização no formato JSON
    print $tribunal->sincroniza;


=head1 METHODS

=head2 sincroniza
    
    $tribunal->sincroniza

Realiza busca na base de dados do TRTES e retorna um obj JSON contendo todo o andamento

=head1 RESPONSE FORMAT

    {"fases":
	[
	    {
		"andamento":"EXPEDIDA NOTIFICAÇÃO D.O. /AUTOR ",
		"data":"22/11/2010 09:41:13",
		"local":" ",
		"classe":"RTOrd"
	    }
	]
    }


=head1 EXAMPLES

Para um exemplo de uso, visualize consulta_TRTES.pl sob o diretorio example/ na raiz da distriuição deste módulo
    
=head1 AUTHORS

José Eduardo Perotta de Almeida, C<< eduardo at web2solutions.com.br >>


=head1 LICENSE AND COPYRIGHT

Copyright 2011 José Eduardo Perotta de Almeida.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests through the web interface at
L<http://rt.cpan.org>.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT
WHEN OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER
PARTIES PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND,
EITHER EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
PURPOSE. THE ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE
SOFTWARE IS WITH YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME
THE COST OF ALL NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE LIABLE
TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE THE
SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH
DAMAGES.

=cut


__END__