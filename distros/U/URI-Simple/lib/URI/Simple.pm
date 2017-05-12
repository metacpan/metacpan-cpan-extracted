package URI::Simple;
use strict;
use warnings;

#==========================================================================
# Regex
#==========================================================================
our $VERSION = '1.00';
my $REGEX = {
    strictMode => 0,
    key => ["source","protocol","authority","userInfo","user","password","host","port","relative","path","directory","file","querystring","anchor"],
    
    q => {
	name => "query",
	parser => qr{(?:^|&)([^&=]*)=?([^&]*)}
    },
    
    parser => {
	strict => qr/^(?:([^:\/?#]+):)?(?:\/\/((?:(([^:@]*)(?::([^:@]*))?)?@)?([^:\/?#]*)(?::(\d*))?))?((((?:[^?#\/]*\/)*)([^?#]*))(?:\?([^#]*))?(?:#(.*))?)/,
	loose =>  qr/^(?:(?![^:@]+:[^:@\/]*@)([^:\/?#.]+):)?(?:\/\/)?((?:(([^:@]*)(?::([^:@]*))?)?@)?([^:\/?#]*)(?::(\d*))?)(((\/(?:[^?#](?![^?#\/]*\.[^?#\/.]+(?:[?#]|$)))*\/?)?([^?#\/]*))(?:\?([^#]*))?(?:#(.*))?)/
    }
};

#==========================================================================
# Quick Accessors on load
#========================================================================== 
my @subs = ( @ { $REGEX->{key} },'query' );
foreach my $method (@subs){
    my $code = __PACKAGE__.'::'.$method;
    {
        no strict 'refs';
        *$code = sub {
            my $self = shift;
            return $method eq 'query' ? $self->{$method} : uri_decode($self->{$method});
        };
    }
}

sub new {
    my $class = shift;
    my $url = shift;
    my $isStrict = shift;
    return bless ( parseUri($url,$isStrict) , $class);
}

sub scheme { shift->{protocol} }
sub fragment { shift->{anchor} }

#==========================================================================
# Parsing sub
#==========================================================================
sub parseUri {
    my $str = shift;
    my $mode = shift;
    my $o = $REGEX;
    my $m = $o->{parser}->{ $mode ? "loose" : "strict" };
    my @m = _exec($m,$str);
    my $uri = {};
    my $i   = 14;
    while ($i--) { $uri->{ $o->{key}->[$i] } = $m[$i] || "" };
    $uri->{ $o->{q}->{name} } = {};
    my $p = $o->{q}->{parser};
    my @q = $uri->{ $o->{key}->[12] } =~ /$p/g;
    
    if ($1){       
        while (@q){
            my $value = pop @q;
            my $key = pop @q;
            if ( $uri->{ $o->{q}->{name} }->{$key} ){
                if (ref $uri->{ $o->{q}->{name} }->{$key} eq 'ARRAY'){
                    push (  @{$uri->{ $o->{q}->{name} }->{$key}} , uri_decode($value) );
                } else {
                    $uri->{ $o->{q}->{name} }->{$key} = [$uri->{ $o->{q}->{name} }->{$key} , uri_decode($value) ];
                }
            } else {
                $uri->{ $o->{q}->{name} }->{$key} = uri_decode($value);
            }
        }
    }
    
    return $uri;
}

#==========================================================================
# javascript like exec function
#==========================================================================
sub _exec {
    my ($expr,$string) = @_;
    my @m = $string =~ $expr;
    
    #javascript exe method adds the whole matched strig
    #to the results array as index[0]
    if (@m){
	unshift @m, substr $string,$-[0],$+[0];
    }
    return @m;
}

sub uri_decode {
    $_[0] =~ tr/+/ /;
    $_[0] =~ s/\%([A-Fa-f0-9]{2})/pack('C', hex($1))/seg;
    return $_[0];
}

1;

__END__

=head1 NAME

URI::Simple - Simple way to parse uri

=head1 SYNOPSIS

  use URI::Simple;
  my $uri = URI::Simple->new('http://google.com/some/path/index.html?x1=yy&x2=pp#anchor');
  
  #enable strict mode
  my $uri = URI::Simple->new('mailto:username@example.com?subject=Topic');
  
  print $uri->path;
  print $uri->source;
  ....
  
=head1 DESCRIPTION

This module is a direct port of javascript parseURI regex by Steven Levithan
Please See L<Original Code|http://blog.stevenlevithan.com/archives/parseuri>

This module will attempts to split URIs according to L<RFC 3986|http://en.wikipedia.org/wiki/URI_scheme>

=head2 Methods;

=over 4

=item path

returns URI path

=item query

return parsed query string as hash ref key,value
if key has multiple values value will be an array ref

=item source

returns URI source - ex: google.com

=item protocol

returns uri protocol - http, https, ftp ...

=item port

returns URI port if available

=item directory

returns URI directory = path without the file name

=item file

returns URI file's name : ex. index.html

=item querystring

return raw query string

=item anchor

returns anchor part of the URI

=item userInfo

=item user

=item password

=item host

=item relative

=item authority

=back

=head2 EXPORT

None by default.

=head1 AUTHOR

Mamod A. Mehyar, E<lt>mamod.mehyar@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012-2013 by Mamod A. Mehyar

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.

=cut

