package Text::Livedoor::Wiki::Plugin::Function::Size;
use warnings;
use strict;
use base qw/Text::Livedoor::Wiki::Plugin::Function/;
__PACKAGE__->function_name('size');

sub prepare_args {
    my $class= shift;
    my $args = shift;
    die 'no arg' unless scalar @$args ;
    my $size = $args->[0];
    die 'must be number' unless $size =~ /^[0-9]+$/;
    return { size => $size } ;
}
sub process {
    my ( $class, $inline, $data ) = @_;
    my $size  = $data->{args}{size};
    my $value = $data->{value};
    $value = $inline->parse($value); 
    return qq|<span class="fsize" style="font-size:${size}px;">$value</span>|; 
}

sub process_mobile {
    my ( $class, $inline, $data ) = @_;
    my $size  = $data->{args}{size};
    my $value = $data->{value};
    $value = $inline->parse($value); 
    return qq|<font size="$size">$value</font>|; 
}

1;

=head1 NAME

Text::Livedoor::Wiki::Plugin::Function::Size - Size Function Plugin

=head1 SYNOPSIS

 &size(20){text here}

=head1 DESCRIPTION

make your text bigger or smaller

=head1 FUNCTION

=head2 prepare_args 

=head2 process

=head2 process_mobile

=head1 AUTHOR

polocky

=cut
