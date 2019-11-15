package Util::Medley::String;
$Util::Medley::String::VERSION = '0.008';
use Modern::Perl;
use Moose;
use namespace::autoclean;
use Kavorka '-all';
use Data::Printer alias => 'pdump';
use String::Util 'nocontent';

=head1 NAME

Util::Medley::String - utility methods for working with strings

=head1 VERSION

version 0.008

=head1 SYNOPSIS

...
 
=head1 DESCRIPTION

...

=cut

#########################################################################################

=head1 METHODS

=head2 camelize

Converts a string to camelcase.

=over

=item usage:

  $camelCase = $util->camelize($str);

  $camelCase = $util->camelize(str => $str);

=item args:

=over

=item str [Str]

The string you wish to camelize.

=back

=back
  
=cut

multi method camelize (Str $str) {

	my @a = split( /[:_-]+/, $str );
	my @b = lc shift @a;
	push @b, map { ucfirst lc $_ } @a;

	return join '', @b;
}

multi method camelize (Str :$str!) {
	
	return $self->camelize($str);
}


=head2 isBlank

Checks whether a string is strictly whitespace or empty.

=over

=item usage:

  $bool = $util->isBlank($str);

  $bool = $util->isBlank(str => $str);

=item args:

=over

=item str [Str]

The string to check.

=back
 
=back
 
=cut

multi method isBlank (Str $str) {

	if ( nocontent($str) ) {
		return 1;
	}

	return 0;
}

multi method isBlank (Str :$str!) {

	return $self->isBlank($str);
}

=head2 ltrim

Just a pass-through to String::Util::ltrim.

=over

=item usage:

  $lTrimmed = $util->ltrim($str);

  $lTrimmed = $util->ltrim(str => $str);

=item args:

=over

=item str [Str]

The string to ltrim.

=back

=back
 
=cut

multi method ltrim (Str $str) {

	return String::Util::ltrim($str);
}

multi method ltrim (Str :$str!) {
	
	return $self->ltrim($str);
}

=head2 pascalize

Converts a string to Pascal case.

=over

=item usage:

  $pascalCase = $util->pascalize($str);

  $pascalCase = $util->pascalize(str => $str);

=item args:

=over

=item str [Str]

The string you wish to camelize.

=back

=back
 
=cut

multi method pascalize (Str $str) {

	my @a = split( /[:_-]+/, $str );
	my @b;
	push @b, map { ucfirst lc $_ } @a;

	return join '', @b;
}

multi method pascalize (Str :$str!) {

	return $self->pascalize($str);
}


=head2 rtrim

Just a pass-through to String::Util::rtrim.

=over

=item usage:

  $rTrimmed = $util->rtrim($str);

  $rTrimmed = $util->rtrim(str => $str);

=item args:

=over

=item str [Str]

The string to rtrim.

=back

=back
 
=cut

multi method rtrim (Str $str) {

	return String::Util::rtrim($str);
}

multi method rtrim (Str :$str!) {
	
	return $self->rtrim($str);
}

=head2 snakelize

Converts a string to snake case.

=over

=item usage:

  $snakeCase = $util->snakeize($str);

  $snakeCase = $util->snakeize(str => $str);

=item args:

=over

=item str [Str]

The string to snakeize.

=back

=back
 
=cut

multi method snakeize (Str $str) {

    $str =~ s/:+/_/g;
    $str =~ s/ +/_/g;

    my @a = split( /_/, $str );
    my @b;
    foreach my $a (@a) {
        if ( $a eq '' ) {
            push @b, '';
        }
        else {
            push @b, split( /(?=[A-Z])/, $a );
        }
    }

    return lc join( '_', @b );
}

multi method snakeize (Str :$str!) {
	
	return $self->snakeize($str);
}


=head2 titleize

Converts a string to title case.

=over

=item usage:

  $titleCase = $util->titleize($str);

  $titleCase = $util->titleize(str => $str);

=item args:

=over

=item str [Str]

The string to titleize.

=back

=back
 
=cut

multi method titleize (Str $str) {

	return $self->pascalize($str);	
}

multi method titleize (Str :$str!) {

	return $self->pascalize($str);	
}

=head2 trim

Just a pass-through to String::Util::trim.

=over

=item usage:

  $trimmed = $util->trim($str);

  $trimmed = $util->trim(str => $str);

=item args:

=over

=item str [Str]

The string to trim.

=back

=back
 
=cut

multi method trim (Str $str) {

	return String::Util::trim($str);
}

multi method trim (Str :$str!) {
	
	return $self->trim($str);
}


=head2 undefToString

Convert scalar to a string if its value is undef.  The string arg
is optional and defaults to ''.

=over

=item usage:

  $str = $util->undefToString($str);

  $str = $util->undefToString(str => $str);

=item args:

=over

=item val [Str]

The string to check for undef.

=item str [Str]

The string to replace undef with.

=back

=back
 
=cut

multi method undefToString (Str|Undef  $val, 
                       	  	Str  	   $str = '' ) {

	if ( !defined $val ) {
		return $str;
	}

	return $val;
}

multi method undefToString (Str|Undef  :$val!, 
                       	  	Str  	   :$str = '' ) {

	return $self->undefToString($val, $str);	
}
                       	  	                       	  		
1;
