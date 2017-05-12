# ************************************************************************* 
# Copyright (c) 2014-2016, SUSE LLC
# 
# All rights reserved.
# 
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
# 
# 1. Redistributions of source code must retain the above copyright notice,
# this list of conditions and the following disclaimer.
# 
# 2. Redistributions in binary form must reproduce the above copyright
# notice, this list of conditions and the following disclaimer in the
# documentation and/or other materials provided with the distribution.
# 
# 3. Neither the name of SUSE LLC nor the names of its contributors may be
# used to endorse or promote products derived from this software without
# specific prior written permission.
# 
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.
# ************************************************************************* 

package Web::MREST::Util;

use 5.012;
use strict;
use warnings;

use App::CELL qw( $log );
use File::Spec;
use JSON;
use Params::Validate qw( :all );
use Pod::Simple::HTML;
use Pod::Simple::Text;


our $JSON = JSON->new->allow_nonref->convert_blessed->utf8->pretty;



=head1 NAME

Web::MREST::Util - Miscellaneous utilities




=head1 SYNOPSIS

Miscellaneous utilities





=head1 EXPORTS

This module provides the following exports:

=over 

=item C<$JSON> (singleton)

=item C<pod_to_html> (function)

=item C<pod_to_text> (function)

=back

=cut

use Exporter qw( import );
our @EXPORT_OK = qw(
    $JSON
    pod_to_html
    pod_to_text
);




=head1 FUNCTIONS


=head2 pod_to_html

Every L<Web::MREST> resource definition includes a 'documentation'
property containing a POD string. Our 'docu/html' resource converts this
POD string into HTML with a little help from this routine.

=cut

sub pod_to_html {
    my ( $pod_str ) = @_;
    $log->debug( "Entering " . __PACKAGE__ . "::pod_to_html" );

    #$log->debug( "pod_to_html before: $pod_str" );
    my $p = Pod::Simple::HTML->new;
    $p->output_string(\my $html_str);
    $p->parse_string_document($pod_str);

    # now $html_str contains a full-blown HTML file, of which only one part is
    # of interest to us. That part starts with the line <!-- start doc --> and
    # ends with <!-- end doc -->

    $html_str =~ s/.*<!-- start doc -->//s;
    $html_str =~ s/<!-- end doc -->.*//s;

    $log->debug( "pod_to_html after: $html_str" );
    return $html_str;
}


=head2 pod_to_text

Convert POD string into text

=cut

sub pod_to_text {
    my $pod_str = shift;
    $log->debug( "Entering " . __PACKAGE__ . "::pod_to_text" );

    my $p = Pod::Simple::Text->new;
    $p->output_string(\my $text_str);
    $p->parse_string_document($pod_str);
    return $text_str;
}


1;
