package Unicode::Block;

use strict;
use warnings;

use Class::Utils qw(set_params_pub);
use Unicode::Block::Item;

our $VERSION = 0.07;

# Constructor.
sub new {
	my ($class, @params) = @_;

	# Create object.
	my $self = bless {}, $class;

	# Character from.
	$self->{'char_from'} = '0000',

	# Character to.
	$self->{'char_to'} = '007F',

	# Title.
	$self->{'title'} = undef;

	# Process parameters.
	set_params_pub($self, @params);

	# Count.
	$self->{'_count'} = $self->{'char_from'};

	# Object.
	return $self;
}

# Get next character.
sub next {
	my $self = shift;
	my $char_hex = $self->_count;
	if (defined $char_hex) {
		return Unicode::Block::Item->new('hex' => $char_hex);
	} else {
		return;
	}
}

# Get actual character and increase number.
sub _count {
	my $self = shift;
	my $ret = $self->{'_count'};
	if (! defined $ret) {
		return;
	}
	my $num = hex $self->{'_count'};
	$num++;
	my $last_num = hex $self->{'char_to'};
	if ($num > $last_num) {
		$self->{'_count'} = undef;
	} else {
		$self->{'_count'} = sprintf '%x', $num;
	}
	return $ret;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Unicode::Block - Class for unicode block manipulation.

=head1 SYNOPSIS

 use Unicode::Block;
 my $obj = Unicode::Block->new(%parameters);
 my $item = $obj->next;

=head1 METHODS

=over 8

=item C<new(%parameters)>

Constructor.

=over 8

=item * C<char_from>

 Character from.
 Default value is '0000'.

=item * C<char_to>

 Character to.
 Default value is '007f'.

=item * C<title>

 Title of block.
 Default value is undef.

=back

=item C<next()>

 Get next character.
 Returns Unicode::Block::Item object for character, if character exists.
 Returns undef, if character doesn't exist.

=back

=head1 ERRORS

 new():
         From Class::Utils::set_params_pub():
                 Unknown parameter '%s'.

=head1 EXAMPLE

 use strict;
 use warnings;

 use Encode qw(encode_utf8);
 use Unicode::Block;

 # Object.
 my $obj = Unicode::Block->new;

 # Print all.
 my $num = 0;
 while (my $char = $obj->next) {
        if ($num != 0) {
                if ($num % 16 == 0) {
                        print "\n";
                } else {
                        print " ";
                }
        }
        print encode_utf8($char->char);
        $num++;
 }
 print "\n";

 # Output.
 #                                
 #                                
 #   ! " # $ % & ' ( ) * + , - . /
 # 0 1 2 3 4 5 6 7 8 9 : ; < = > ?
 # @ A B C D E F G H I J K L M N O
 # P Q R S T U V W X Y Z [ \ ] ^ _
 # ` a b c d e f g h i j k l m n o
 # p q r s t u v w x y z { | } ~  

=head1 DEPENDENCIES

L<Class::Utils>,
L<Unicode::Block::Item>.

=head1 SEE ALSO

=over

=item L<Unicode::Block::Ascii>

Ascii output of unicode block.

=item L<Unicode::Block::List>

List of unicode blocks.

=back

=head1 REPOSITORY

L<https://github.com/tupinek/Unicode-Block>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

 © 2013-2017 Michal Josef Špaček
 BSD 2-Clause License

=head1 VERSION

0.07

=cut
