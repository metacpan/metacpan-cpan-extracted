package WebSource::DB;

use strict;
use WebSource::Module;
use Carp;
use DBI;

our @ISA = ('WebSource::Module');

=head1 NAME

WebSource::DB : For each input execute a query and return the result as output

=head1 DESCRIPTION

A DB operator allows to execute a parameterized SQL query for each input.
This allows, for example, to populate a database with extracted data.

A typical DB operator declaration is as follows :

  <ws:database name="db" forward-to="format">
    <parameters>
      <param name="db" value="factbook" />
      <param name="user" value="username" />
      <param name="pass" value="password" />
    </parameters>
    <query>
      INSERT INTO country(name, population, coordinates)
      VALUES ('$country','$population','$coordinates')
    </query>
  </ws:database>

When the query is active (results are produced), the operator returns
these results. Otherwise, the input is simply forwarded on for further
treatment.

=head1 SYNOPSIS

  $cache = WebSource::DB->new(wsnode => $node);

  # for the rest it works as a WebSource::Module

=head1 METHODS

=over 2

=item B<< $source = WebSource->new(desc => $node); >>

Create a new DB operator;

=cut

sub _init_ {
  my $self = shift;
  $self->SUPER::_init_;

  $self->{db} or croak("No database selected for ", $self->{name});
  $self->{host} or $self->{host} = "localhost";
  $self->{user} or $self->{user} = getlogin;
  $self->{dsn} = "DBI:mysql:" .
       "database=". $self->{db}   . ";" .
       "host="    . $self->{host};
  if(my $wsd = $self->{wsdnode}) {
    $self->{query} = $wsd->findvalue("query");
  }
  $self->{query} or croak("No query for ",$self->{name});
}

sub handle {
  my ($self,$env) = @_;
  my $query = $self->{query};
  
  foreach my $key (keys(%$env)) {
    my $val = $env->{$key};
    $val =~  s/'/''/g;
    $query =~ s/\$$key/$val/g;
  }
  $self->log(3,"Executing...\n",$query,"\n");

  my @res;
  my $dbh = DBI->connect($self->{dsn},$self->{user},$self->{pass});
  my $sth = $dbh->prepare($query);
  $sth->execute();
  if($sth->{Active}) {
    while (my $ref = $sth->fetchrow_hashref()) {
      push @res, (WebSource::Envelope->new(
        %$ref,
        data => undef,
        type => "empty"
      ));
    }
    $sth->finish();
  } else {
    # just forward the envelope for further treament
    push @res, $env;
  }
  $dbh->disconnect();
  return @res;
}

=back

=head1 SEE ALSO

WebSource::Module

=cut

1;
