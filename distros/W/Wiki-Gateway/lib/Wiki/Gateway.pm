package Wiki::Gateway;
$VERSION = 0.001991;


=head1 NAME
  
Wiki::Gateway - library for interacting with remote wikis
  
=head1 SYNOPSIS
  
use Wiki::Gateway;

$result = Wiki::Gateway::getPage('http://interwiki.sourceforge.net/cgi-bin/wiki.pl', $wiki_type, 'SandBox');


$result = Wiki::Gateway::putPage('http://interwiki.sourceforge.net/cgi-bin/wiki.pl', $wiki_type, 'SandBox', $page_source_text);


$timestamp = Wiki::Gateway::daysAgoToDate(1);
$result = Wiki::Gateway::getRecentChanges('http://interwiki.sourceforge.net/cgi-bin/wiki.pl',$wiki_type, $timestamp);


$result = Wiki::Gateway::getAllPages('http://interwiki.sourceforge.net/cgi-bin/wiki.pl',$wiki_type);


# to check if there was an error, and to see what it was if so:
if (Wiki::Gateway::getLastExceptionType()) {
    print Wiki::Gateway::getLastExceptionType() . "\n";
}
  
=head1 DESCRIPTION
  
Wiki::Gateway allows you to interact with remote wikis. It presents a unified API for interfacing with a variety of different wiki engines. It allows you to read, to write, to get RecentChanges, and to get a list of all pages on the target wiki.

Right now, WikiGateway supports (i.e. knows how to talk to) the following wiki engines:

 * MoinMoin             
     $wiki_type = "moinmoin1"
 * UseMod version 1.0         
     $wiki_type = "usemod1"
 * Some older UseMod versions (tested on .91) 
     $wiki_type = "usemod1"
 * OddMuse                    
     $wiki_type = "oddmuse1"
 * Any wiki which provides the WikiRPCInterface2 XMLRPC interface
     $wiki_type = "xmlrpc2"


=head1 LICENSE & COPYRIGHT

Wiki::Gateway is free software; you may redistribute it and/or modify it under the same terms as Perl itself.

Wiki::Gateway is copyright (c) 2004-2005 Bayle Shanks. 


=head1 CREDITS
  
 Bayle Shanks
 L. M. Orchard
 David Jacoby

 (see CREDITS.txt for more detail)

To get help, email the WikiGateway users' mailing list: interwiki-wgateway-usr@lists.sourceforge.net.


=head1 SEE ALSO

Wiki::Gateway is part of a suite of related programs, including a command-line client, a Python API, an Atom gateway server which can act as a proxy for a wiki, an XML-RPC gateway server, a WebDAV gateway server, and more. See L<http://interwiki.sourceforge.net/cgi-bin/wiki.pl?WikiGateway> for more information.


=cut


###############################
# sorry this file is not commented very well yet
# basically, it wraps the Python WikiGateway
# package using Inline::Python.
#
# The black magic stuff is where we
# wrap each Python method in order to trap Python exceptions 
# so that the Perl caller
# has a way to see what the exception was.
###############################


use Inline::Python qw(py_study_package py_bind_func py_call_function);



###############################
# "new"
###############################

sub new {
    my $proto = shift;
    my ($wikiURL, $wikiType) = @_;

    $obj = WikiGatewayConstructor($wikiURL, $wikiType);
    hook_obj($obj);

    return $obj;
}


###########################################################################
###########################################################################
###########################################################################
# misc packaging stuff
###########################################################################
###########################################################################


BEGIN {
    use Exporter   ();
    our ($VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);

    my @LIST_OF_ALL_WIKIGATEWAY_API_SUBROUTINES = qw(&getRecentChanges &getRPCVersionSupported &getPage &getPageHTML &getPageHTMLVersion &getAllPages &getPageInfo &getPageInfoVersion &listLinks &putPage &daysAgoToDate &daysSinceDate);

    # set the version for version checking
    @ISA         = qw(Exporter);
    @EXPORT      = qw();
    %EXPORT_TAGS = ( 
                     ALL => 
                       \@LIST_OF_ALL_WIKIGATEWAY_API_SUBROUTINES
                     );    

    # your exported package globals go here,
    # as well as any optionally exported functions
    @EXPORT_OK   = @LIST_OF_ALL_WIKIGATEWAY_API_SUBROUTINES;
}
our @EXPORT_OK;


1;

use Inline Python => <<'END_OF_PYTHON_CODE';

from WikiGateway import WikiGateway as WikiGatewayConstructor 
import WikiGateway as WikiGatewayModule
from WikiGateway import *
import sys


class lastExceptionClass:
    def __init__(self):
      self.info = None
    pass

lastException = lastExceptionClass()


def _method_substitute(method, *args, **keywords):
    lastException.info = None
    try:
      result = method(*args, **keywords)
      return deUnicodeRecursive(result)  # workaround for a bug 
                                         # in Inline::Python
    except:
      lastException.info = sys.exc_info()
      #print lastException.info[1]
      return -1
      #raise sys.exc_info()[1] 
 



def _method_substitute_factory(method):
    def m(*args, **keywords):
      return _method_substitute(method, *args, **keywords)
    return m
 
def call_method(obj, methodName, args, keywords):
    method = getattr(obj, methodName)
    return _method_substitute(method, *args, **keywords)



def getattr(*args, **keywords):
    return __builtins__.getattr(*args, **keywords)

def getLastExceptionType():
    if lastException.info:
      return lastException.info[0]

def make_list_of_methods(obj):
    import types
    return [itemName for itemName in dir(obj) if type(getattr(obj, itemName)) == types.UnboundMethodType or type(getattr(obj, itemName)) == types.FunctionType]



def hook_obj(classobj):
    fnList = make_list_of_methods(classobj)
    for fnName in fnList: 
      method = getattr(classobj, fnName)
      setattr(classobj, fnName, _method_substitute_factory(method))
      

def import_methods_into_global_namespace(obj):
    fnList = make_list_of_methods(obj)
    for fnName in  fnList:
      cmd = 'global %s\n' % fnName
      cmd += '%s = obj.%s' % (fnName, fnName)
      exec(cmd)




def recursiveMap_sequences_dicts(data, baseCasePredicate, operation):
    '''
NOTE: if the structure has cycles (aside from sequences whose
subsequences are themselves, such as single-character strings), 
this will not halt
    '''
    if baseCasePredicate(data):
      return operation(data)

    import types
    if type(data) == types.DictType:
      for key in data.keys():
        item = data[key]

        newItem = recursiveMap_sequences_dicts(item, baseCasePredicate, operation)

        newKey = recursiveMap_sequences_dicts(key, baseCasePredicate, operation) 

        # "if newKey != key:" doesn't catch unicode difference; 
        # so instead of introducing a new predicate, 
        # let's just always change the key
        del data[key]
        data[newKey] = newItem

    else:
      try:
        for index, item in enumerate(data):
          if item == data:
            return data
          data[index] = recursiveMap_sequences_dicts(item,  baseCasePredicate, operation)        
      
      except TypeError:
        return data

    return data

def deUnicode(data):
    import types
    if type(data) == types.UnicodeType:
      return data.encode('ascii','replace')
    else:
      return data

def deUnicodeRecursive(data):
    '''
    De-unicodes recursive structures involving only lists and dicts
    '''
    import types

    return recursiveMap_sequences_dicts(
					data, 
					lambda data: (type(data) == types.UnicodeType),
					deUnicode)





### "hook_obj" for globals from WikiGateway package
import types
fnList = [itemName for itemName in globals().keys() if type(globals()[itemName]) == types.UnboundMethodType or type(globals()[itemName]) == types.FunctionType]

fnList = filter(lambda x: x in dir(WikiGatewayModule), fnList)


for fnName in fnList: 
    method = globals()[fnName]
    globals()[fnName] = _method_substitute_factory(method)

END_OF_PYTHON_CODE
