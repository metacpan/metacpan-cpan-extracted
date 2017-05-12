package Text::Livedoor::Wiki::Plugin::Function::Lislog;
use warnings;
use strict;
use base qw/Text::Livedoor::Wiki::Plugin::Function/;
__PACKAGE__->function_name('lislog');

sub prepare_args {
    my $class= shift;
    my $args = shift;

    # no args
    die 'no arg' unless scalar @$args ;

    # not valid lislig url
    my $url = $args->[0];
   
    die 'not valid url' unless $url =~ m{^http://(lislog|research.news)\.livedoor\.com/r/(\d+)};
    my ($service, $listid ) = $url =~ m{^http://(lislog|research.news)\.livedoor\.com/r/(\d+)};

    my $type = 'pie';
    my $color = 'red';
    for ( @$args ) {
        if ( $_ =~ /^(pie|bar)$/ ) {
            $type = $_;
        }

        if ( $_ =~ /^(red|orange|yellow|lime|green|sky|blue|purple|pink|black)$/ ) {
            $color = $_;
        }
    }

    # ok
    return { listid => $listid , type => $type , color => $color };
}
sub prepare_value {
    my $class = shift;
    my $value = shift;
    # no more large support but for legacy user
    $value = 'medium' if ( $value !~ m/^(?:small|medium|large)$/ );
    $value = 'middle' if ( $value eq 'medium' ); # medium is middle.... >_<
    return { size => $value };
}

sub process {
    my ( $class, $inline, $data ) = @_;
    my $listid  = $data->{args}{listid};
    my $type    = $data->{args}{type};
    my $color   = $data->{args}{color};
    my $size    = $data->{value}{size};
    
    return qq|<div><script language='javascript' type='text/javascript' charset='utf-8' src='http://research.news.livedoor.com/publish/$size/$listid/plugin.js?graph_type=$type&color=$color'></script></div>|;
}

sub process_mobile{ '' }
1;

=head1 NAME

Text::Livedoor::Wiki::Plugin::Function::Lislog - Lislog Function Plugin

=head1 DESCRIPTION

let's your choice.

=head1 SYNOPSIS

 &lislog(http://lislog.livedoor.com/r/20853)
 &lislog(http://research.news.livedoor.com/r/20853){small}
 &lislog(http://research.news.livedoor.com/r/20853){large}
 &lislog(http://research.news.livedoor.com/r/20853){medium}
 &lislog(http://research.news.livedoor.com/r/20853,bar)
 &lislog(http://research.news.livedoor.com/r/20853,bar,green)

=head1 FUNCTION

=head2 prepare_args

=head2 prepare_value

=head2 process

=head2 process_mobile

=head1 SEE ALSO

http://research.news.livedoor.com

=head1 AUTHOR

polocky

=cut
