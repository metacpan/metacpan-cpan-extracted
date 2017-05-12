package WWW::Finances::Bovespa;
use Moose;
use WWW::Mechanize;
use XML::XPath;

our $VERSION = '0.10';


has [ qw/descricao codigo ibovespa delay data hora oscilacao valor_ultimo quant_neg mercado bovespa_response/ ] => ( is => 'rw' , isa => 'Str' );
has [ qw/is_valid/ ] => ( is => 'rw' , isa => 'Int' );

sub find {
    my ( $self , $args ) = @_;
    $self->clean;
    if ( ! $args || ref $args ne 'HASH' || ! exists $args->{ codigo } ) {
        $self->is_valid( 0 );
        warn "Utilize um código da bovespa para obter resultados.";
        return 0;
    }
    $self->get_stock_data( $args->{ codigo } );
    $self->fill_stock_data( ) if $self->is_valid;
} 

sub clean {
    my ( $self ) = @_; 
    $self->is_valid( 0 );
    $self->descricao( '' );
    $self->codigo( '' ); 
    $self->ibovespa ( '' );
    $self->delay ( '' );
    $self->data ( '' );
    $self->hora ( '' );
    $self->oscilacao ( '' );
    $self->valor_ultimo( '' );
    $self->quant_neg( '' );
    $self->mercado( '' );
    $self->bovespa_response( '' );
}
  
sub get_stock_data {
  my ( $self, $codigo ) = @_;
  my $base_url = 'http://www.bmfbovespa.com.br/cotacoes2000/formCotacoesMobile.asp?codsocemi=';
  my $mech = WWW::Mechanize->new();
  $mech->agent_alias( 'Windows IE 6' );
  $mech->get( $base_url . $codigo );
  my $content = $mech->content;
  if ( $content =~ m/erros/i ) {
    $self->is_valid( 0 ) ;
    return;
  }
  if ( $mech->res->is_success ) {
    $self->is_valid( 1 );
    $self->bovespa_response( $content ) ;
    return;
  }
  $self->is_valid( 0 );
}       
        
sub fill_stock_data {
    my ( $self ) = @_;  
    my $xml = XML::XPath->new( xml => $self->bovespa_response );
    foreach my $node_html ( $xml->findnodes( '//PAPEL', )->[0] ) {
        $self->descricao( $node_html->getAttribute( 'DESCRICAO' ) );
        $self->codigo( $node_html->getAttribute( 'CODIGO' ) );
        $self->ibovespa( $node_html->getAttribute( 'IBOVESPA' ) );
        $self->delay( $node_html->getAttribute( 'DELAY' ) );
        $self->data( $node_html->getAttribute( 'DATA' ) );
        $self->hora( $node_html->getAttribute( 'HORA' ) );
        $self->oscilacao( $node_html->getAttribute( 'OSCILACAO' ) );
        $self->valor_ultimo( $node_html->getAttribute( 'VALOR_ULTIMO' ) );
        $self->quant_neg( $node_html->getAttribute( 'QUANT_NEG' ) );
        $self->mercado( $node_html->getAttribute( 'MERCADO' ) );
    } 
}

1;

__END__


=head1 NAME

  WWW::Finances::Bovespa Reads stock options values from bovespa ( with 15 minutes lag )

=head1 SYNOPSIS

  use WWW::Finances::Bovespa;

  my $bovespa = WWW::Finances::Bovespa->new();
  $bovespa->find( { codigo => 'PETR3' } );

  print $bovespa->ibovespa;
  print $bovespa->valor_ultimo;
  print $bovespa->quant_neg;
  print $bovespa->delay;
  print $bovespa->codigo;
  print $bovespa->hora;
  print $bovespa->data;
  print $bovespa->descricao;
  print $bovespa->oscilacao;
  print $bovespa->mercado;

  print $bovespa->is_valid; #always true when the code is found.

=head1 DESCRIPTION

  Documentation for WWW::Finances::Bovespa;

=head1 METHODS

=head2 WWW::Finances::Bovespa->new()
  
  Creates a new empty WWW::Finances::Bovespa object.
  Use WWW::Finances::Bovespa->find( { codigo => 'foo' } ) to retrieve data.

=head2 WWW::Finances::Bovespa->find( { codigo => 'foo' } )

  Attempts to retrieve data from bovespa based on the code/codigo. 
  To see a list of valid codes, search at http://www.bmfbovespa.com.br .

=head2 is_valid

  Indicates if the code was found is valid.

=head2 ibovespa

  Returns ibovespa

=head2 valor_ultimo
  
  Returns last value

=head2 quant_neg

  Returns negociated amount

=head2 delay

  Returns delay

=head2 codigo

  Returns codigo 

=head2 hora

  Returns hora

=head2 data

  Returns date

=head2 descricao

  Returns description

=head2 oscilacao

  Returns oscilation

=head2 mercado

  Returns market name
  
=head1 BUGS

  Please report any... 

=head1 SUPPORT

  Send me a msg

=head1 AUTHOR

    Hernan Lopes
    CPAN ID: HERNAN
    HERNAN
    hernanlopes@gmail.com
    -

=head1 COPYRIGHT

This program is free software licensed under the...

	The BSD License

The full text of the license can be found in the
LICENSE file included with this module.


=head1 SEE ALSO

  http://www.bovespa.com.br

=cut

