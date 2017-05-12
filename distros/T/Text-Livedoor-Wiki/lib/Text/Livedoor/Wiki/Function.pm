package Text::Livedoor::Wiki::Function;

use warnings;
use strict;
use UNIVERSAL::require;
use Text::Livedoor::Wiki::Utils;
use Scalar::Util ();

sub new {
    my $class = shift;
    my $self  = shift;
    $self = bless $self, $class;
    return $self;
}

sub setup {
    my $self = shift;
    my $inline = shift;
    my $plugins = delete $self->{plugins};
    $self->{inline} = $inline ;
    Scalar::Util::weaken($self->{inline});
    $self->_load( $plugins );
    return 1;
}
sub inline { 
    my $self = shift;
    return $self->{inline};
}
sub has_function {
    my $self          = shift;
    my $function_name = shift;
    return $self->{function}{ $function_name } ? 1 : 0;
}
sub get_args {
    my $self = shift;
    my $opr  = shift || '';
    $opr =~ s/\s//g;
    my @args = split(',',$opr );
    return \@args;
}
sub prepare {
    my $self          = shift;
    my $function_name = shift;
    my $opr           = shift;
    my $tail_part     = shift;
    my $args = $self->get_args( $opr );
    my $res =  {};
    eval {
        my $my_args = $self->{function}->{$function_name}{prepare_args}->( $args );
        my $value   = $self->{function}->{$function_name}{prepare_value}->( $tail_part );
        $res = { args => $my_args , value => $value };
    };
    if ($@ ){
        #warn $@;
        return;
    }

    return $res;
}

sub parse {
    my $self          = shift; 
    my $function_name = shift;
    $self->{function}->{$function_name}{process}->(@_);
}

sub on_mobile { shift->{on_mobile} }

sub _load {
    my $self    = shift;
    my $plugins = shift;
    my %function = ();
    for my $plugin (@$plugins) {
        $plugin->require or die $@;
        $function{$plugin->function_name} = {
            operation_regexp => $plugin->operation_regexp,
            process     => sub { $self->on_mobile ? $plugin->process_mobile( $self->inline , @_) : $plugin->process( $self->inline , @_) } ,
            prepare_args  => sub { $plugin->prepare_args(@_) },
            prepare_value => sub { $plugin->prepare_value(@_) }
        }
    }
    $self->{function}  = \%function;

    1;
}

1;

=head1 NAME

Text::Livedoor::Wiki::Function - Wiki Function Parser Class

=head1 DESCRIPTION

Function Parser

=head1 METHOD 

=head2 get_args

=head2 has_function

=head2 inline

=head2 new

=head2 on_mobile

=head2 parse

=head2 prepare

=head2 setup

=head1 AUTHOR

polocky

=cut
