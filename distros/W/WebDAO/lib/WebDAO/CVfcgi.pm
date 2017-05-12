package WebDAO::Fcgi::Writer;
our $VERSION = '0.01';

use strict;
use warnings;
sub new {
    my $class = shift;
    my $self = bless( ( $#_ == 0 ) ? shift : {@_}, ref($class) || $class );
}
sub write   { shift; print  STDOUT @_ }
sub close   { }
sub headers { return $_[0]->{headers} }

1;

package WebDAO::CVfcgi;
our $VERSION = '0.02';

=head1 NAME

WebDAO::CVfcgi - FCGI adapter (FCGI > 0.68)

=head1 SYNOPSIS

=head1 DESCRIPTION

WebDAO::CVfcgi - FCGI adapter for FCGI version > 0.68

=cut



use base qw( WebDAO::CV );
use strict;
use warnings;
use WebDAO::Util;
sub new {
    my $class = shift;
    return $class->SUPER::new(@_, writer=> sub {
        my $code = $_[0]->[0];
        my $headers_ref  = $_[0]->[1];
        my $fd = new WebDAO::Fcgi::Writer:: headers=>$headers_ref;
        my $message = $WebDAO::Util::HTTPStatusCode{$code};
        my $header_str= "Status: $code $message\015\012";
        while ( my ($header, $value) = splice( @$headers_ref, 0, 2) ) {
            $value = '' unless defined $value;
            $header_str .= "$header: $value\015\012"
        }
        $header_str .="\015\012";
        $fd->write($header_str);
        return $fd
    } )
}
sub print {
    my $self = shift;
    foreach my $str (@_) {
        next unless defined $str;
        utf8::encode( $str) if utf8::is_utf8($str);
        print $str;
   }
}
1;
package WebDAO::CVfcgiold;
our $VERSION = '0.01';
use base qw/WebDAO::CVfcgi/;
sub print {
    my $self = shift;
    print for @_;
}
1;
__DATA__

=head1 SEE ALSO

http://webdao.sourceforge.net

=head1 AUTHOR

Zahatski Aliaksandr, E<lt>zag@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2012 by Zahatski Aliaksandr

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
