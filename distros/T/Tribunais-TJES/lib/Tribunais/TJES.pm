package Tribunais::TJES;

use strict;
use warnings;

use JSON;
use WWW::Mechanize;
use HTML::TreeBuilder::XPath;
use Path::Class;
use utf8;


sub new
{
    my $class = shift;
    my $self = {
	_edNumProcesso => shift,
	_seInstancia => shift,
	_sePesquisar => shift,
    };
    bless $self, $class;
    return $self;
}

sub sincroniza
{
    my($self) = @_;
    
    my $URI = "http://www.tj.es.gov.br/consulta/cfmx/portal/Novo/cons_proces.cfm";

    my $mech = WWW::Mechanize->new;
    $mech->agent_alias( 'Windows IE 6' );
    
    $mech->post($URI);
    
    my $html = $mech->content;
    
    $html =~ s[action="lista_proces.cfm"][action="desc_proces.cfm"]isg;
    $html =~ s[_blank][_self]isg;
    
    $mech->update_html( $html );


    $mech->submit_form(
	form_name => "cons_proces",
	fields      => {
	    seInstancia => $self->{_seInstancia},
	    sePesquisar => $self->{_sePesquisar},
	    edNumProcesso => $self->{_edNumProcesso},
	    seJuizo => "1",
	    seComarca => "0",
	    edNumCDA => "",
	    edAnoCDA => "",
	    edNumPetic => "",
	    edNumOriginPrim => "",
	    CdPessoa => "",
	    edNome => "",
	    SeqAdvog => "",
	    edNumOab => "",
	    edNomeAdv => "",
	    rbTipoNome => "1",
	    seSituacao => "1",
	    seNatureza => "1",
	    seTipoParte => "",
	}
    );
    
    my $titulo = $mech->title();
    $html = $mech->content;
    
    my $tree= HTML::TreeBuilder::XPath->new;
    $tree->parse( $html );
    
    my $table_rows = $tree->findnodes( '//div[@class=\'conteudo\']//table[1]//tr' );
    
    my $count = 0;
    my @items;
    
    foreach my $row ( $table_rows->get_nodelist )
    {
       if ( $count > 1 )
       { 
	    my $tree_tr = HTML::TreeBuilder::XPath->new;
	    $tree_tr->parse( $row->as_HTML );
	    my $strdata=$tree_tr->findvalue( '//span[1]' );
	    if(length($strdata)>5)
	    {
		my $row_data = {
		    data => $tree_tr->findvalue( '//span[1]' ),
		    andamento    => $tree_tr->findvalue( '//span[2]' ),
		    statusandamento   => $tree_tr->findvalue( '//span[3]' ),
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

Tribunais::TJES - Interface de consulta processual no Tribunal de Justiça do Espírito Santo - Brasil.

Este módulo tem como finalidade realizar, mediante número de processo, um consulta processual na
base de dados do Tribunal de Justiça do Espírito Santo - TJES.

O resultado da sincronização é dado no formato JSON contendo todo o andamento do processo, fase à fase.

=head1 VERSION

version 0.006

=head1 SYNOPSIS

    use TJES;

    #cria objeto tribunal
    my $tribunal = new Tribunais::TJES($numerodoprocesso, $instancia, $sePesquisar);

    # printa o resultado da sincronização no formato JSON
    print $tribunal->sincroniza;


=head1 METHODS

=head2 sincroniza
    
    $tribunal->sincroniza

Realiza busca na base de dados do TJ e retorna um obj JSON contendo todo o andamento

=head1 Formato da resposta

    {"fases":
	[
	    {
	    "statusandamento":" SPTC BAIXA. RÉU SOLTO ",
	    "andamento":"Ofício - Expeça-se ",
	    "data":" 25/08/2001 "
	    }
	]
    }


=head1 EXAMPLES

Para um exemplo de uso, visualize consulta.pl sob o diretorio example/ na raiz da distriuição deste módulo
    
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