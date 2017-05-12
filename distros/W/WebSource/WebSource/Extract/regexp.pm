package WebSource::Extract::regexp;
use strict;
use WebSource::Parser;
use Carp;

our @ISA = ('WebSource::Module');

=head1 NAME

WebSource::Extract::regexp - Extract information using a regular expression

=head1 DESCRIPTION

The regexp B<Extract> operator allows to extract information based on a regular
expression.



=head1 METHODS

See WebSource::Module

=cut

sub _init_ {
  my $self = shift;
  $self->SUPER::_init_;
  my $wsd = $self->{wsdnode};
  if($wsd) {
    $self->{regexp} = $wsd->findvalue('regexp');
    my @keys = map { $_->textContent } $wsd->findnodes('map/key');
    $self->{keys} = \@keys;
    $self->{slot} = $wsd->getAttribute("apply-to");
  } 
  $self->{regexp} or croak "No regular expression given";
  return $self;
}

sub handle {
  my $self = shift;
  my $env = shift;
  my $re = $self->{regexp};
  my %meta = %$env;

  my $slot = $self->{slot} ? $self->{slot} : "data";
  $self->log(5,"Extracting with m/$re/ from $slot");
  my $str = $slot eq "data" ? $env->dataString : $env->{$slot};

  if(my @keys = @{$self->{keys}}) {
    if($str =~ m/$re/) {
      my %map;
      no strict "refs";
      for(my $i=0; $i<=$#keys && $i<9; $i++) {
        $map{$keys[$i]} = ${$i+1};
      }
      use strict "refs";
      $map{data} and $map{type} = "text/string";
      return WebSource::Envelope->new(
        %meta,
        %map,
      );
    } else {
      return ();
    }
  } else {
    # matching part is data
    if($str =~ m/$re/) {
      $slot eq "data" and $meta{type} = "text/string";
      return WebSource::Envelope->new(
        %meta,
        $slot => $&,
      );
    } else {
      return ();
    }
  }
}

=head1 SEE ALSO

WebSource

=cut

1;
