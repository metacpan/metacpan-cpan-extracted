package Text::Livedoor::Wiki::Plugin::Function::AName;
use warnings;
use strict;
use base qw/Text::Livedoor::Wiki::Plugin::Function/;
__PACKAGE__->function_name('aname');

sub prepare_args {
    my $class= shift;
    my $args = shift;
    die 'no arg' unless scalar @$args ;
    my $name = $args->[0];
    # XXX is this regexp valid??  copy from old formatter
    die 'invalid format' unless $name =~ /^[a-zA-Z0-9\$\-_\.\+!\*'\(\),;\/\?:@&=]+$/;
    return { name => $name };
}
sub process {
    my ( $class, $inline, $data ) = @_;
    my $name  = $data->{args}{name};
    my $value = $data->{value};
    $value = $inline->parse( $value );
    return qq{<a class="anchor" id="$name" name="$name" title="$name">$value</a>};
}

1;

=head1 NAME

Text::Livedoor::Wiki::Plugin::Function::AName - Aname Function Plugin

=head1 DESCRIPTION

anchor label where to jump

=head1 SYNOPSIS 

 [[target>>#my_a_name]] <- jump to my_a_name anchor
 

 
 &aname(my_a_name){a name link label}
 
=head1 FUNCTION

=head2 prepare_args

=head2 process

=head1 AUTHOR

polocky

=cut 
