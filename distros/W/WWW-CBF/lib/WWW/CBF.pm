package WWW::CBF;
use warnings;
use strict;

use utf8::all;
use URI;
use Web::Scraper;
eval 'use HTML::TreeBuilder::LibXML';

our $VERSION = '0.03';

my $cbf = scraper {
	process 'tr', 'clubes[]' => scraper {
		process 'td', 'dados[]'  => 'TEXT';
	},
};

sub new {
	my $class = shift;
	my $self = {};
	bless $self, $class;

	$self->reload;
	return $self;
}

sub reload {
	my $self = shift;
	my $url = 'http://www.cbf.com.br/competicoes/campeonato-brasileiro/serie-a/2012';

	my $site = $cbf->scrape( URI->new($url) );

	my $pos = -1;
	foreach my $clube ( @{$site->{clubes}} ) {
		next if ++$pos == 0; # first entry contains just table fields

		# get values from scraper
		$self->{$pos} = {
			clube    => $clube->{dados}->[1],
			pontos   => $clube->{dados}->[3],
			jogos    => $clube->{dados}->[4],
			vitorias => $clube->{dados}->[5],
			empates  => $clube->{dados}->[6],
			derrotas => $clube->{dados}->[7],
			gp       => $clube->{dados}->[8],
			gc       => $clube->{dados}->[9],
			sg       => $clube->{dados}->[10],
			ap       => $clube->{dados}->[11],
		};
	}

	return $self;
}


sub pos {
	my $self = shift;
	my $pos  = shift;

	return $self->{$pos};
}

42;
__END__
=encoding utf8

=head1 NAME

WWW::CBF - Brazilian Football Championship status

=head1 SYNOPSIS

    use WWW::CBF;

    my $ranking = WWW::CBF->new();
	my $lider = $ranking->pos(1);

	print $lider->{clube}    . "\n"
	    . $lider->{pontos}   . "\n"
		. $lider->{jogos}    . "\n"
		. $lider->{vitorias} . "\n"
		. $lider->{derrotas} . "\n"
		. $lider->{empates}  . "\n"
		. $lider->{gp}       . "\n"  # gols pro
		. $lider->{gc}       . "\n"  # gols contra
		. $lider->{sg}       . "\n"  # saldo de gols 
		. $lider->{ap}       . "\n"  # aproveitamento
		;

=head1 DESCRIPTION

Este módulo oferece uma interface simples com os dados do site www.cbf.com.br, espeficicamente em relação ao Campeonato Brasileiro (a.k.a. "Brasileirão").

This module provides a simple scraping interface to www.cbf.com.br and its data, mainly the Brazilian Football (soccer) Championship.


=head1 METHODS

=head2 new

Cria uma nova instância do objeto, contento a classificação atual. Nesta versão apenas dados da série A do campeonato são obtidos.

Creates a new object instance, containing current championship ranking. In this version only A series (highest division) data is obtained.

=head2 pos(N)

Retorna um hash com informações a respeito do clube na devida posição do campeonato. Os valores do hash estão descritos na sinopse.

Returns a hash with information regarding the club in the given position on the championship. Hash values are described on the synopsis.

=head2 reload

Realiza nova busca no site e obtém valores atualizados.

Scrapes the site again and gets updated values.


=head1 AUTHOR

Breno G. de Oliveira, C<< <garu at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-www-cbf at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WWW-CBF>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.



=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WWW::CBF


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WWW-CBF>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WWW-CBF>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WWW-CBF>

=item * Search CPAN

L<http://search.cpan.org/dist/WWW-CBF/>

=back


=head1 ACKNOWLEDGEMENTS

Agradecimentos especiais à Confederação Brasileira de Futebol (CBF) por fornecer os dados atualizados do campeonato em seu site.

Special thanks to the Brazilian Football Confederation (CBF) for providing the updated championship data on its website.

=head1 COPYRIGHT & LICENSE

Copyright 2009 Breno G. de Oliveira, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

