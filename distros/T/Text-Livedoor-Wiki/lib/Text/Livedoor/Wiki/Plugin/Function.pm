package Text::Livedoor::Wiki::Plugin::Function;
use warnings;
use strict;
use base qw(Class::Data::Inheritable);
__PACKAGE__->mk_classdata('function_name');
__PACKAGE__->mk_classdata('operation_regexp');

sub process { die 'implement me' }
sub process_mobile { shift->process(@_) }
sub prepare_args {
    my $class= shift;
    my $args = shift;
    return $args;
}
sub prepare_value {
    my $class = shift;
    my $value = shift;
    return $value;
}

sub uid {
    return $Text::Livedoor::Wiki::scratchpad->{core}{inline_uid};
}
sub opts {
    return $Text::Livedoor::Wiki::opts;
}
1;


=head1 NAME

Text::Livedoor::Wiki::Plugin::Function - Base Class For Function Plugin

=head1 DESCRIPTION

you can use this class as base to create Function Plugin. 

=head1 SYNOPSIS

 package Text::Livedoor::Wiki::Plugin::Function::Superscript;
 
 use warnings;
 use strict;
 use base qw/Text::Livedoor::Wiki::Plugin::Function/;
 __PACKAGE__->function_name('sup');
 
 sub process {
     my ( $class, $inline, $data ) = @_;
     my $value = $data->{value};
     $value = $inline->parse( $value );
     return "<sup>$value</sup>";
 }
 
 1;

 &function_name(argument_here){value here}

=head1 FUNCTION

=head2 function_name

you can specify your function name. 

=head2 process

you must implement your self . return text what you want for your plugin.

=head2 process_mobile

if you did not implement this ,then $class->process() is used.

=head2 prepare_args 

you can validate argument with this function.

=head2 prepare_value

you can validate value with this function.

=head2 uid

get unique id

=head2 opts

get option hash data

=head1 AUTHOR

polocky

=cut
