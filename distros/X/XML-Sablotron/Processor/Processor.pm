# 
# The contents of this file are subject to the Mozilla Public
# License Version 1.1 (the "License"); you may not use this file
# except in compliance with the License. You may obtain a copy of
# the License at http://www.mozilla.org/MPL/
# 
# Software distributed under the License is distributed on an "AS
# IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or
# implied. See the License for the specific language governing
# rights and limitations under the License.
# 
# The Original Code is the XML::Sablotron module.
# 
# The Initial Developer of the Original Code is Ginger Alliance Ltd.
# Portions created by Ginger Alliance are 
# Copyright (C) 1999-2000 Ginger Alliance Ltd.
# All Rights Reserved.
# 
# Contributor(s): Nicolas Trebst, science+computing ag
#                 n.trebst@science-computing.de
# 
# Alternatively, the contents of this file may be used under the
# terms of the GNU General Public License Version 2 or later (the
# "GPL"), in which case the provisions of the GPL are applicable 
# instead of those above.  If you wish to allow use of your 
# version of this file only under the terms of the GPL and not to
# allow others to use your version of this file under the MPL,
# indicate your decision by deleting the provisions above and
# replace them with the notice and other provisions required by
# the GPL.  If you do not delete the provisions above, a recipient
# may use your version of this file under either the MPL or the
# GPL.
# 

############################################################
# inner object (holds circular reference)
############################################################
package XML::Sablotron::Processor;


use strict;
use Carp;
use vars qw( @ISA $_unique );

require Exporter;
require DynaLoader;

use XML::Sablotron;

@ISA = qw( Exporter DynaLoader );

$_unique = 0;


sub new {
    my $class = shift;
    my $sit   = shift;
    $class = (ref $class) || $class;
    my $self = {};
    bless $self,  $class;
    if ( defined $sit ) {
        $self->{_sit}    = $sit; # to keep the situation alive
	$self->{_handle} = $self->_createProcessorForSituation( $sit );
    } else {
	$self->{_handle} = $self->_createProcessor();
    }
    $self->{_handlers} = []; #confusing names, aren't? :-)
    return $self;
}

my $pkg_template = <<'eof';
sub new {
my $cn = shift;
bless {}, $cn;
}
eof

sub RegHandler {
    my ($self, $type, $ref) = @_;
    my $wrapper;
    if ((ref $ref eq "HASH")) {
	$_unique++;
	my $classname = "sablot_handler_$_unique";
	eval ("package $classname;\n" . $pkg_template);
	no strict;
	foreach (keys %$ref) {
	    *{"${classname}::$_"} = $$ref{$_};
	}
	use strict;
	$wrapper = eval "new $classname()";
    } else {
	$wrapper = $ref;
    }
    
    warn "Trying to register the same handler twice\n"
      if grep {${$_}[0] == $type and ${$_}[1] == $wrapper} 
	@{$self->{_handlers}}; 

    #the trick with @foo is very important for a correct reference counting
    my @foo = ($type, $wrapper);
    push @{$self->{_handlers}}, \@foo;;

    my $ret = $self->_regHandler(@foo);

    return $ret;
}

sub UnregHandler {
    my ($self, $type, $wrapper) = @_;
    for (my $i = 0; $i <= $#{$self->{_handlers}}; $i++) {
	my $he = ${$self->{_handlers}}[$i];
	if ($$he[0] == $type and $$he[1] = $wrapper) {
	    $self->_unregHandler($$he[0], $$he[1]);
	    splice @{$self->{_handlers}}, $i, 1;
	    last;
	}
    }
}

sub _releaseHandlers {
    my $self = shift;
    my $he; #handler entry
    foreach $he (@{$self->{_handlers}}) {
	$self->_unregHandler($$he[0], $$he[1]);
    }
    @{$self->{_handlers}} = ();
}

sub SetContentType {
    my ($self, $value) = @_;
    return $self->{_contentType} = $value;
}

sub GetContentType {
    my ($self, $value) = @_;
    return $self->{_contentType};
}

sub SetEncoding {
    my ($self, $value) = @_;
    return $self->{_encoding} = $value;
}

sub GetEncoding {
    my ($self, $value) = @_;
    return $self->{_encoding};
}

DESTROY {
    my $self = shift;
    $self->_releaseHandlers();
    $self->_destroyProcessor();
};

1;

__END__
