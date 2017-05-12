package WWW::NFSe::Guarapari;

#ABSTRACT: Another scraper perl

=encoding utf8

=head1 NAME

WWW::NFSe::Guarapari- Module for issuance electronic invoice and customer management.

=head1 VERSION

version 0.02

=cut

    our $VERSION = '0.02'; # VERSION

=head1 SYNOPSIS

    use WWW::NFSe::Guarapari; 

    my $nfse = WWW::NFSe::Guarapari->new();
    #my $nfse= new WWW::NFSe::Guarapari();

    # Loga no sistema
    $nfse->logar( "cpfcnpj", "senha" );

    # Novo Cliente(Tomador/Intermediário)
    my $tipo_tomador = "J"; # F - J - E(Estrangeiro)
    my $documento = "000.000.000-00"; # CPF ou CNPJ
    my $nome = "Fulano de Tal";
    my $NomeFantasia = "Beltranos S.A"; #If tipo_tomador = "F"
    my $InscricaoMunicipal = "000.000"; #If tipo_tomador = "F"
    my $InscricaoEstadual = "000.000"; #If tipo_tomador = "F"
    my $telefone = "";
    my $email = "fulano@de.tal";
    my $municipioEstrangeiro = "NeverLand"; #If tipo_tomador = "E"
    my $PaisEstrangeiro = "NeverLand"; #If tipo_tomador = "E"
    my $tipologradouro = "";
    my $tipoEndereco = "-1"; # -1/Selecione | 3/Cobrança | 2/Comercial | 4/Correspondência | 1/Residencial
    my $logradouro = "";
    my $numero = "";
    my $complemento = "";
    my $bairro = "";
    my #cep = "000.000-000";
    my $uf = "DF";
    my $cidades = "";

    print $nfse->novo_cliente( $tipo_tomador, $documento, $nome, $telefone, $email, $tipologradouro, $tipoendereco, $logradouro, $numero, $complemento, $bairro, $cep, $uf, $cidades );

=cut

    use strict;
    use warnings;
    use vars qw($VERSION);
    use utf8;
    use WWW::Mechanize;
    use HTML::TreeBuilder::XPath;
    use HTML::Entities;
    use JSON;    

    my $statusLogin;
    my $statusLoginRegistro;
    my $entitieschars;
    my $mech;

    sub new
    {
        my $class = shift;
        my $self = {

        };
            
        $statusLogin = 0;
        $entitieschars = 'ÁÍÓÚÉÄÏÖÜËÀÌÒÙÈÃÕÂÎÔÛÊáíóúéäïöüëàìòùèãõâîôûêÇç';
        $mech = WWW::Mechanize->new;
        $mech->agent_alias( 'Windows Mozilla' );
        $mech->cookie_jar(HTTP::Cookies->new());
            
        bless $self, $class;           
        return $self, $class;
    }
    
=head1 METHODS

=head2 logar()

Loga no painel de controle. Este método deverá ser chamado antes de qualquer outro método. Ativa flag $statusLogin.

    my $status_login = $painel->logar($email, $senha);
    
Return string
    
    logged, invalid login, not found, unknow HTTP error, connection error


=cut    
    sub logar
    {
        my($self, $cpfcnpj, $senha) = @_;
        my $html;
        my $login_page = 'http://nfseteste.guarapari.es.gov.br/NFSETESTE/';
        
        $mech->get($login_page);
        die $mech->response->status_line unless $mech->success;
        
        if($mech->success())
        {
            if($mech->status() == 200)
            {
            
                
                my $name = 'ctl00$ctl00$MasterConteudo$Conteudo$LoginSistema$UserName';
                my $pass = 'ctl00$ctl00$MasterConteudo$Conteudo$LoginSistema$Password';
                my $button = 'ctl00$ctl00$MasterConteudo$Conteudo$LoginSistema$LoginButton';
                my $viewstate = ($mech->find_all_inputs( type => 'hidden', name => '__VIEWSTATE' ))[0]->value;
                my $validation = ($mech->find_all_inputs( type => 'hidden', name => '__EVENTVALIDATION' ))[0]->value;
                
                #loga no painel
                $mech->field($name => $cpfcnpj);
                $mech->field($pass => $senha);
                $mech->field(__VIEWSTATE => $viewstate);
                $mech->field(__EVENTVALIDATION => $validation);
                $mech->field(__VIEWSTATEENCRYPTED => '');
                $mech->click(); #Não funcionou nem com post() nem submit() apenas simulando click()
                
                $html = $mech->content;
                $mech->update_html( $html );
                my $tree = HTML::TreeBuilder::XPath->new;
                $tree->parse( $html );
                # resposta da tentiva de login
                my $respostaloga = $tree->findnodes( '//div[@id="_TituloArea"]' );
                
                if(index($respostaloga, "Gerar NFS-e") == -1)
                {
                    $statusLogin = 1;
                    return "logged";
                }
                else
                {
                    return "invalid login";
                }
            }
            elsif($mech->status() == 404)
            {
                return "not found";
            }
            else
            {
                return "unknow HTTP error";
            }
        }
        else
        {
            return "connection error";
        }
    }
    
=head2 novo_cliente()

Cria novo tomador/Intermediário

    # Novo Cliente(Tomador/Intermediário)
    my $tipo_tomador = "J"; # F - J - E(Estrangeiro)
    my $documento = "000.000.000-00"; # CPF ou CNPJ
    my $nome = "Fulano de Tal";
    my $NomeFantasia = "Beltranos S.A";     #If tipo_tomador = "F"
    my $InscricaoMunicipal = "000.000";     #If tipo_tomador = "F"
    my $InscricaoEstadual = "000.000";      #If tipo_tomador = "F"
    my $telefone = "";
    my $email = "fulano@de.tal";
    my $municipioEstrangeiro = "NeverLand";  #If tipo_tomador = "E"
    my $PaisEstrangeiro = "NeverLand";       #If tipo_tomador = "E"
    my $tipologradouro = "";
    my $tipoEndereco = "-1"; # -1/Selecione | 3/Cobrança | 2/Comercial | 4/Correspondência | 1/Residencial
    my $logradouro = "";
    my $numero = "";
    my $complemento = "";
    my $bairro = "";
    my #cep = "000.000-000";
    my $uf = "DF";
    my $cidades = "";

    print $nfse->novo_cliente( $tipo_tomador, $documento, $nome, $telefone, $email, $tipologradouro, $tipoendereco, $logradouro, $numero, $complemento, $bairro, $cep, $uf, $cidades );

Return JSON

    {"nome":"Fulano de Tal","resposta":"registrado","status":"sucesso","codigo":"107630"}
    {"resposta":"E-mail em uso","status":"erro"}
    {"resposta":"efetue login primeiro","status":"erro"}

=cut   
    

1;

__END__

=head1 AUTHOR

Álvaro Luiz Andrade <alvaro@web2solutions.com.br>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by WEB2 Soluções.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
