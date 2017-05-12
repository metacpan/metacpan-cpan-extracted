package WWW::SlideShare::Object;

use strict;
use Data::Dumper;
use Carp qw(confess);

our $AUTOLOAD;
our $VERSION="1.01";

sub new
{	
	my $class = shift;
	my $fields = shift;

	my $self = { '_data' => $fields };
	bless $self, $class;
}

sub AUTOLOAD
{
	my $self = shift;
	confess "Too many arguments to method" if (@_ >= 1);

   	my $name = $AUTOLOAD;
        $name =~ s/.*://;

	$self->{'_data'}->{$name} =~ s/^\s+//;
	$self->{'_data'}->{$name} =~ s/\s+$//;
	$self->{'_data'}->{$name};
}

sub DESTROY { }

1;

__END__

=head1 NAME 

WWW::SlideShare::Object

=head1 ABSTRACT

A SlideShare Object represents any entity such as SlideShow, Contact, Group, Tag returned in a Web Service call.

=head1 DESCRIPTION

The object is created from data retrieved by WWW::SlideShare in the Web Service call to SlideShare. Therefore, the constructor is effectively not used outside of WWW::SlideShare. 

There is one accessor method per object attribute returned in the Web Service call eg. ID, URL 

=head1 BUGS

No known ones

=head1 AUTHOR

Ashish Mukherjee

=head1 LICENCE

Same licence as perl source

=head1 CREATION DATE

June 3, 2010
