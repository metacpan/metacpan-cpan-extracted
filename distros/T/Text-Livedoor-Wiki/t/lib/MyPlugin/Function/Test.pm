package MyPlugin::Function::Test;
use warnings;
use strict;
use base qw/Text::Livedoor::Wiki::Plugin::Function/;
__PACKAGE__->function_name('test');

sub process {
    my ( $class, $inline, $data ) = @_;
    my $args  = $data->{args};
    my $value = $data->{value};
    my $id    = $class->uid();
    $value = $inline->parse( $value );
    return "<TEST-$id>$value</TEST-$id>";
}


1;
