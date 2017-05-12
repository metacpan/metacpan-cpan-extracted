package XML::FOAF::Person;
use strict;

use RDF::Core::Resource;

sub new {
    bless { foaf => $_[1], subject => $_[2] }, $_[0];
}

sub knows {
    my $person = shift;
    my $knows = RDF::Core::Resource->new($XML::FOAF::NAMESPACE . 'knows');
    my $enum = $person->{foaf}->{model}->getStmts($person->{subject}, $knows);
    my $stmt = $enum->getFirst;
    my @knows;
    while (defined $stmt) {
        push @knows, XML::FOAF::Person->new($person->{foaf}, $stmt->getObject);
        $stmt = $enum->getNext;
    }
    \@knows;
}

sub get {
    my $person = shift;
    my($what) = @_;
    unless ($what =~ /:/) {
        $what = $XML::FOAF::NAMESPACE . $what;
    }
    my $res = RDF::Core::Resource->new($what);
    my $enum = $person->{foaf}->{model}->getStmts($person->{subject}, $res);
    my $stmt = $enum->getFirst or return undef;
    $stmt->getObject->getLabel;
}

sub DESTROY { }

use vars qw( $AUTOLOAD );
sub AUTOLOAD {
    (my $var = $AUTOLOAD) =~ s!.+::!!;
    no strict 'refs';
    *$AUTOLOAD = sub { $_[0]->get($var) };
    goto &$AUTOLOAD;
}

1;
__END__

=head1 NAME

XML::FOAF::Person - A Person class in a FOAF file

=head1 SYNOPSIS

    my $foaf = XML::FOAF->new(URI->new('http://foo.com/my.foaf'));
    my $person = $foaf->person;
    print $person->mbox, "\n";
    my $people = $foaf->knows;

=head1 DESCRIPTION

I<XML::FOAF::Person> represents a I<Person> class in a FOAF file.

=head1 USAGE

You can use any property as a method name and call it on a I<XML::FOAF::Person>
object. For example:

    my $email = $person->mbox;
    my $name = $person->name;

In addition to this, some methods with special beheavior are defined below:

=head2 $person->knows

Returns a reference to an array of I<XML::FOAF::Person> objects representing
the people that I<$person> knows.

=head1 AUTHOR & COPYRIGHT

Please see the I<XML::FOAF> manpage for author, copyright, and license
information.

=cut
