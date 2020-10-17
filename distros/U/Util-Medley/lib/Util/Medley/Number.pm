package Util::Medley::Number;
$Util::Medley::Number::VERSION = '0.047';
use Modern::Perl;
use Moose;
use namespace::autoclean;
use Kavorka '-all';
use Data::Printer alias => 'pdump';
use Number::Format;

=head1 NAME

Util::Medley::Number - utility methods for working with numbers

=head1 VERSION

version 0.047

=head1 SYNOPSIS

...
 
=head1 DESCRIPTION

...

=cut

#########################################################################################

=head1 METHODS

=head2 commify

Add commas to a number for readability.

=over

=item usage:

  $string = $util->commify($val);

  $string = $util->commify(val => $val);

=item args:

=over

=item val [Num]

The number value.

=back

=back
  
=cut

multi method commify (Num $val) {
	
	return Number::Format::format_number($val);
}

multi method commify (Num :$val!) {
	
	return $self->commify($val);
}


=head2 decommify

Remove commas from a numeric string.

=over

=item usage:

  $num = $util->decommify($val);

  $num = $util->decommify(val => $val);

=item args:

=over

=item val [Str]

The numeric string value.

=back

=back
  
=cut

multi method decommify (Str $val) {
	
	return Number::Format::unformat_number($val);
}

multi method decommify (Str :$val!) {
	
	return $self->decommify($val);
}
                       	  	                       	  		
1;
