# -*- perl -*-


use Data::TreeDumper ;
use Data::Hexdumper ;
use Text::Diff ;

use strict ;
use warnings ;

use Test::More tests => 2 ;
use Test::Exception ;

use Text::Editor::Vip::Buffer ; 

my $buffer = new Text::Editor::Vip::Buffer() ;

$buffer->ExpandWith('GetAttribute') ;
$buffer->ExpandWith('SetAttribute') ;

sub GetAttribute
{
=head2 GetAttribute

Retrieves  a named attribute 

  $buffer->GetAttribute( 'TEST', $some_data) ;
  $retrieved_data = $buffer->GetAttribute(0, 'TEST') ;

=cut

my ($self, $attribute) = @_ ;

my $value ;

unless(defined $attribute)
	{
	$self->PrintError('Invalid attribute name!') ;
	}
else
	{
	if(exists($self->{USER_ATTRIBUTES}{$attribute}))
		{
		$value = $self->{USER_ATTRIBUTES}{$attribute} ;
		}
	}

return($value) ;
}

sub SetAttribute
{
=head2 GetAttribute

Retrieves  a named attribute 

  $buffer->GetAttribute( 'TEST', $some_data) ;
  $retrieved_data = $buffer->GetAttribute(0, 'TEST') ;

=cut

my ($self, $attribute, $value) = @_ ;

unless(defined $attribute)
	{
	$self->PrintError('Invalid attribute name!') ;
	}
else
	{
	$self->{USER_ATTRIBUTES}{$attribute} = $value ;
	}
}

is(undef, $buffer->GetAttribute('test'), 'unexisting attribute') ;

my $attribute = { complex => 'attribute' } ;

$buffer->SetAttribute('test', $attribute) ;
is_deeply($attribute, $buffer->GetAttribute('test'), 'attribute is right') ;

