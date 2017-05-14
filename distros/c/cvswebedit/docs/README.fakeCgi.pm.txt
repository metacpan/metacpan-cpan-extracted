package CGI;
use Exporter;
@CGI::ISA=qw(Exporter);
@CGI::EXPORT=qw(escape unescape);

use URI::Escape ();

sub escape {
   URI::Escape::uri_escape(@_);
}


sub unescape {
   URI::Escape::uri_unescape(@_);
	
}

# PRIVATE SUBROUTINE
# Smart rearrangement of parameters to allow named parameter
# calling.  We do the rearangement if:
# 1. The first parameter begins with a -
# 2. The use_named_parameters() method returns true
sub rearrange {
    my($self,$order,@param) = @_;
    return () unless @param;
    
    return @param unless (defined($param[0]) && substr($param[0],0,1) eq '-')
        || $self->use_named_parameters;

    my $i;
    for ($i=0;$i<@param;$i+=2) {
        $param[$i]=~s/^\-//;     # get rid of initial - if present
        $param[$i]=~tr/a-z/A-Z/; # parameters are upper case
    }
    
    my(%param) = @param;                # convert into associative array
    my(@return_array);
    
    my($key)='';
    foreach $key (@$order) {
        my($value);
        # this is an awful hack to fix spurious warnings when the
        # -w switch is set.
        if (ref($key) && ref($key) eq 'ARRAY') {
            foreach (@$key) {
                last if defined($value);
                $value = $param{$_};
                delete $param{$_};
            }
        } else {
            $value = $param{$key};
            delete $param{$key};
        }
        push(@return_array,$value);
    }
#    push (@return_array,$self->make_attributes(\%param)) if %param;
    return (@return_array);
}


1;
