# Copyrights 2010-2015 by [Mark Overmeer].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.01.
use warnings;
use strict;

package XML::eXistDB::RPC;
use vars '$VERSION';
$VERSION = '0.14';


use Log::Report 'xml-existdb', syntax => 'LONG';

use XML::Compile::RPC::Util;
use XML::Compile::RPC::Client ();

use XML::eXistDB::Util;
use XML::eXistDB;

use Digest::MD5  qw/md5_base64 md5_hex/;
use Encode       qw/encode/;
use MIME::Base64 qw/encode_base64/;

# to be removed later
use Data::Dumper;
$Data::Dumper::Indent = 1;

my $dateTime = 'dateTime.iso8601';  # too high chance on typos


sub new(@) { my $class = shift; (bless {}, $class)->init({@_}) }

sub init($)
{   my ($self, $args) = @_;

    unless($self->{rpc} = $args->{rpc})
    {   my $dest = $args->{destination}
            or report ERROR =>
                    __x"{pkg} object required option `rpc' or `destination'"
                 , pkg => ref $self;
        $self->{rpc} = XML::Compile::RPC::Client->new(destination => $dest);
    }

    $self->{repository}
      = exists $args->{repository} ? $args->{repository} : '/db';
    $self->{compr_up}
      = defined $args->{compress_upload} ? $args->{compress_upload} : 128;
    $self->{chunks}  = defined $args->{chunk_size} ? $args->{chunk_size} : 32;

    $self->login($args->{user} // 'guest', $args->{password} // 'guest');
    $self->{pp_up}   = $args->{prettyprint_upload} ? 1 : 0;
    $self->{schemas} = $args->{schemas};

    my $f = $args->{format} || [];
    $self->{format}  = [ ref $f eq 'HASH' ? %$f : @$f ];
    $self;
}

#-----------------

# private method; "options" is an overloaded term, abused by eXist.
sub _format(@)
{   my $self = shift;
    my %args = (@{$self->{format}}, @_);

    if(my $sp = delete $args{'stylesheet-params'})
    {   while(my($k,$v) = each %$sp)
        {   $args{"stylesheet-param.$k"} = $v;
        }
    }
    struct_from_hash string => \%args;
}

sub _date_options($$)
{   my ($created, $modified) = @_;

     !($created || $modified) ? ()
    : ($created && $modified) ? ($dateTime => $created, $dateTime => $modified)
    : report ERROR => "either both or neither creation and modification date";
}


sub _document($)
{   my $self = shift;
    return $_[0]->toString($self->{pp_up})
        if UNIVERSAL::isa($_[0], 'XML::LibXML::Document');
    return encode 'utf-8', ${$_[0]}
        if ref $_[0] eq 'SCALAR';
    return encode 'utf-8', $_[0]
        if $_[0] =~ m/^\s*\</;
    if($_[0] !~ m/[\r\n]/ && -f $_[0])
    {   local *DOC;
        open DOC, '<:raw', $_[0]
            or report FAULT => "cannot read document from file $_[0]";
        local $/ = undef;
        my $xml = <DOC>;
        close DOC
            or report FAULT => "read error for document from file $_[0]";
        return $xml;
   }

   report ERROR => "do not understand document via $_[0]";
}

#-----------------

#T
sub hasCollection($) { $_[0]->{rpc}->hasCollection(string => $_[1]) }


sub hasDocument($) { $_[0]->{rpc}->hasDocument(string => $_[1]) }


#T
sub isXACMLEnabled() {shift->{rpc}->isXACMLEnabled}


sub backup($$$$)
{   $_[0]->{rpc}->backup(string => $_[1], string => $_[2]
      , string => $_[3], string => $_[4]);
}


sub shutdown(;$)
{   my $self = shift;
    $self->{rpc}->shutdown(@_ ? (int => shift) : ());
}


sub sync() { shift->{rpc}->sync }

#-----------------

#T
sub createCollection($;$)
{   my ($self, $coll, $date) = @_;
    my @date = $date ? ($dateTime => $date) : ();
    $self->{rpc}->createCollection(string => $coll, @date);
}


#T
sub configureCollection($$%)
{   my ($self, $coll, $conf, %args) = @_;
    my $format = (exists $args{beautify} ? $args{beautify} : $self->{pp_up})
      ? 1 : 0;
    my $config;

    if(UNIVERSAL::isa($conf, 'XML::LibXML::Document'))
    {   # ready document, hopefully correct
        $config = $conf->toString($format);
    }
    elsif(!ref $conf && $conf =~ m/^\s*\</)
    {   # preformatted xml
        $config = $conf;
    }
    else
    {   $config = $self->schemas->createCollectionConfig($conf, %args);
    }

    $self->{rpc}->configureCollection(string => $coll, string => $config);
}


sub copyCollection($$;$)
{   my ($self, $from, $sec) = (shift, shift, shift);
    my @param = (string => $from, string => $sec);
    push @param, string => shift if @_;
    $self->{rpc}->copyCollection(@param);
}


# the two params version is missing from the interface description, so
# we use a little work-around
sub moveCollection($$;$)
{   my ($self, $from, $tocoll, $subcoll) = @_;
    defined $subcoll
        or ($tocoll, $subcoll) = $tocoll =~ m! ^ (.*) / ([^/]+) $ !x;

    $self->{rpc}->moveCollection(string => $from, string => $tocoll
      , string => $subcoll);
}


#T
sub describeCollection(;$%)
{   my $self = shift;
    my $coll = @_ % 2 ? shift : $self->{repository};
    my %args = @_;
    my ($rc, $data) = $args{documents}
      ? $self->{rpc}->getCollectionDesc(string => $coll)
      : $self->{rpc}->describeCollection(string => $coll);
    $rc==0 or return ($rc, $data);

    my $h = struct_to_hash $data;
    $h->{collections} = [ rpcarray_values $h->{collections} ];
    if(my $docs = $h->{documents})
    {   my %docs;
        foreach (rpcarray_values $docs)
        {   my $h = struct_to_hash $_;
            $docs{$h->{name}} = $h;
        }
        $h->{documents} =\%docs;
    }
    (0, $h);
}


#T
sub subCollections(;$)
{   my ($self, $coll) = @_;
    $coll ||= $self->{repository};
    my ($rc, $data) = $_[0]->describeCollection($coll, documents => 0);
    $rc==0 or return ($rc, $data);
    (0, map { "$data->{name}/$_" } @{$data->{collections} || []});
}


#T
sub collectionCreationDate(;$)
{   my ($self, $coll) = @_;
    $coll ||= $self->{repository};
    $self->{rpc}->getCreationDate(string => $coll);
}


#T
sub listResources(;$)
{   my ($self, $coll) = @_;
    $coll ||= $self->{repository};
    my ($rc, $details)
       = $self->{rpc}->getDocumentListing($coll ? (string => $coll) : ());
    $rc==0 or return ($rc, $details);
    ($rc, rpcarray_values $details);
}


#T
sub reindexCollection($)
{   my ($self, $coll) = @_;
    $self->{rpc}->reindexCollection(string => $coll);
}


#T
sub removeCollection($)
{   my ($self, $coll) = @_;
    $self->{rpc}->removeCollection(string => $coll);
}

#-----------------

#T
sub login($;$)
{   my ($self, $user, $password) = @_;
    $self->{user}     = $user;
    $self->{password} = defined $password ? $password : '';
    $self->{rpc}->headers->header(Authorization => 'Basic '
      . encode_base64("$user:$password", ''));
    (0);
}


#T
sub listGroups()
{   my ($rc, $details) = shift->{rpc}->getGroups;
    $rc==0 or return ($rc, $details);
    (0, rpcarray_values $details);
}


#T
sub describeResourcePermissions($)
{   my ($rc, $details) = $_[0]->{rpc}->getPermissions(string => $_[1]);
    $rc==0 or return ($rc, $details);
    ($rc, struct_to_hash $details);
}


#T
sub listDocumentPermissions($)
{   my ($self, $coll) = @_;
    $coll ||= $self->{repository};
    my ($rc, $details) = $_[0]->{rpc}->listDocumentPermissions(string => $coll);
    $rc==0 or return ($rc, $details);
    my $h = struct_to_hash $details;
    my %h;
    while( my ($k,$v) = each %$h)
    {   $h{$k} = [ rpcarray_values $v ];
    }
    (0, \%h);
}


#T
sub describeUser($)
{   my ($self, $user) = @_;
    my ($rc, $details) = $self->{rpc}->getUser(string => $user);
    $rc==0 or return ($rc, $details);
    my $h = struct_to_hash $details;
    $h->{groups} = [ rpcarray_values $h->{groups} ];
    (0, $h);
}


#T
sub listUsers()
{   my ($rc, $details) = shift->{rpc}->getUsers;
    $rc==0 or return ($rc, $details);
    my %h;
    foreach my $user (rpcarray_values $details)
    {   my $u = struct_to_hash $user;
        $u->{groups} = [ rpcarray_values $u->{groups} ];
        $h{$u->{name}} = $u;
    }
    (0, \%h);
}


#T
sub removeUser($) { $_[0]->{rpc}->removeUser(string => $_[1]) }


sub setPermissions($$;$$)
{   my ($self, $target, $perms, $user, $group) = @_;

    my @chown = ($user && $group) ? (string => $user, string => $group) : ();
    $self->{rpc}->setPermissions(string => $target, @chown
       , ($perms =~ m/\D/ ? 'string' : 'int') => $perms);
}


#T
sub setUser($$$;$)
{   my ($self, $user, $password, $groups, $home) = @_;
    my @groups = ref $groups eq 'ARRAY' ? @$groups : $groups;

    $self->{rpc}->setUser(string => $user
       , string => md5_base64($password)
       , string => md5_hex("$user:exist:$password")
       , rpcarray_from(string => @groups)
       , ($home ? (string => $home) : ())
       );
}


#T
sub describeCollectionPermissions(;$)
{   my ($self, $coll) = @_;
    $coll ||= $self->{repository};
    my ($rc, $data) = $self->{rpc}->listCollectionPermissions(string => $coll);
    $rc==0 or return ($rc, $data);
    my $h = struct_to_hash $data;
    my %p;
    foreach my $relname (keys %$h)
    {  my %perms;
       @perms{ qw/user group mode/ } = rpcarray_values $h->{$relname};
       $p{"$coll/$relname"} = \%perms;
    }
    ($rc, \%p);
}

#-----------------

### need two-arg version?
sub copyResource($$$)
{   my $self = shift;
    $self->{rpc}->copyResource(string=> $_[0], string=> $_[1], string=> $_[2]);
}


#T
sub uniqueResourceName(;$)
{   my ($self, $coll) = @_;
    $coll ||= $self->{repository};
    $self->{rpc}->createResourceId(string => $coll);
}


sub describeResource($)
{   my ($self, $resource) = @_;
    my ($rc, $details) = $self->{rpc}->describeResource(string => $resource);
    $rc==0 or return ($rc, $details);
    ($rc, struct_to_hash $details);
}


#T
sub countResources(;$)
{   my ($self, $coll) = @_;
    $coll ||= $self->{repository};
    $self->{rpc}->getResourceCount(string => $coll);
}


### two-params version needed?
sub moveResource($$$)
{   my $self = shift;
    $self->{rpc}->moveResource(string=> $_[0], string=> $_[1], string=> $_[2]);
}


#T
sub getDocType($)
{   my ($rc, $details) = $_[0]->{rpc}->getDocType(string => $_[1]);
    $rc==0 or return ($rc, $details);
    ($rc, rpcarray_values $details);
}


#T
sub setDocType($$$$)
{   my ($self, $doc, $name, $pub, $sys) = @_;
    $self->{rpc}->setDocType(string => $doc
      , string => $name, string => $pub, string => $sys);
}


sub whoLockedResource($) {$_[0]->{rpc}->hasUserLock(string => $_[1]) }


sub unlockResource($) {$_[0]->{rpc}->unlockResource(string => $_[1]) }


sub lockResource($;$)
{   my ($self, $resource, $user) = @_;
    $user ||= $self->{user}
        or report ERROR => "no default username set nor specified for lock";
    $self->{rpc}->lockResource(string => $resource, string => $user);
}


sub removeResource($) { $_[0]->{rpc}->remove(string => $_[1]) }

#--------------------

#T
sub downloadDocument($@)
{   my $self = shift;
    my ($rc, $chunk) = $self->getDocumentData(@_);
    $rc==0 or return ($rc, $chunk);

    my @data = \$chunk->{data};
    while($rc==0 && $chunk->{offset})
    {   ($rc, $chunk) = $chunk->{'supports-long-offset'}
        ? $self->getNextExtendedChunk($chunk->{handle}, $chunk->{offset})
        : $self->getNextChunk($chunk->{handle}, $chunk->{offset});
        $rc or push @data, \$chunk->{data};
    }
    $rc==0 or return ($rc, $chunk);

    (0, join '', map {$$_} @data);
}

# does this also work for binary resources?


sub listResourceTimestamps($)
{   my ($rc, $vector) = $_[0]->{rpc}->getTimestamps(string => $_[1]);
    $rc==0 or return ($rc, $vector);
    (0, rpcarray_values $vector);
}

#-----------------

#T
sub uploadDocument($$@)
{   my ($self, $resource, undef, %args) = @_;
    my $doc    = $self->_document($_[2]);

    my $chunks = exists $args{chunk_size} ? $args{chunk_size} : $self->{chunks};
    my $compr  = exists $args{compress} ? $args{compress} : $args{compr_upload};
    for ($chunks, $compr) { $_ *= 1024 if defined $_ } 

    my @dates   = _date_options $args{creation_date}, $args{modify_date};
    my $replace = $args{replace};
    my $mime    = $args{mime_type} || 'text/xml';

    # Send file in chunks
    my $to_sent = length $doc;
    my $sent    = 0;
    my $tmp;

    while($sent < $to_sent)
    {   (my $rc, $tmp) = $self->upload($tmp, substr($doc, $sent, $chunks));
        $rc==0 or return ($rc, $tmp);
        $sent += $chunks;
    }
    $self->parseLocal($tmp, $resource, $replace, $mime, @dates);
}


sub downloadBinary($) { $_[0]->{rpc}->getBinaryResource(string => $_[1]) }


sub uploadBinary($$$$;$$)
{   my ($self, $resource, $bytes, $mime, $replace, $created, $modified) = @_;
    
    $self->{rpc}->storeBinary
      ( base64 => (ref $bytes ? $$bytes : $bytes)
      , string => $resource, string => $mime, boolean => $replace
      , _date_options($created, $modified)
      );
}

#-----------------

#T
### compile doesn't return anything
sub compile($@)
{   my ($self, $query) = (shift, shift);
    my ($rc, $details) = $self->{rpc}->compile(base64 => $query
      , $self->_format(@_));
    $rc==0 or return ($rc, $details);
    (0, struct_to_hash $details);
}


#T
# printDiagnostics should accept a base64
sub describeCompile($@)
{   my ($self, $query) = (shift, shift);
    $self->{rpc}->printDiagnostics(string => $query, $self->_format(@_));
}


sub execute($@)
{   my ($self, $handle) = (shift, shift);
    my ($rc, $details)  = $self->{rpc}->execute(string => $handle
      , $self->_format(@_));
    $rc==0 or return ($rc, $details);
    (0, struct_to_hash $details);
}

#-----------------

sub executeQuery($@)
{   my ($self, $query) = @_;
    my @enc = @_ % 2 ? (string => shift) : ();
    $self->{rpc}->executeQuery(base64 => $query, @enc, $self->_format(@_));
}


sub numberOfResults($) { $_[0]->{rpc}->getHits(int => $_[1]) }


#T
# what does "docid" mean?
sub describeResultSet($)
{   my ($rc, $details) = $_[0]->{rpc}->querySummary(int => $_[1]);
    $rc==0 or return ($rc, $details);
    my $results = struct_to_hash $details;
    if(my $docs = delete $results->{documents})
    {   my @docs;
        foreach my $result (rpcarray_values $docs)
        {   my ($name, $id, $hits) = rpcarray_values $result;
            push @docs, { name => $name, docid => $id, hits => $hits };
        }
        $results->{documents} = \@docs;
    }
    if(my $types = delete $results->{doctypes})
    {   my @types;
        foreach my $result (rpcarray_values $types)
        {   my ($class, $hits) = rpcarray_values $result;
            push @types, { class => $class, hits => $hits };
        }
        $results->{doctypes} = \@types;
    }
    ($rc, $results);
}


#### what kind of params from %args?
#### releaseQueryResult(int $resultid, int $hash)   INT?
sub releaseResultSet($@)
{   my ($self, $results, %args) = @_;
    $self->{rpc}->releaseQueryResult(int => $results, int => 0);
}


sub retrieveResult($$@)
{   my ($self, $set, $pos) = (shift, shift, shift);
    my ($rc, $bytes)
       = $self->{rpc}->retrieve(int => $set, int => $pos, $self->_format(@_));
    $rc==0 or return ($rc, $bytes);
    (0, $self->schemas->decodeXML($bytes));
}


# hitCount where describeResultSet() uses 'hits'
#T
sub retrieveResults($@)
{   my ($self, $set) = (shift, shift);
    my ($rc, $bytes) = $self->{rpc}->retrieveAll(int => $set
      , $self->_format(@_));
    $rc==0 or return ($rc, $bytes);
    (0, $self->schemas->decodeXML($bytes));
}

#-----------------

#T
# Vector query() is given as alternative but does not exist.
sub query($$$@)
{   my ($self, $query, $limit) = (shift, shift, shift);
    my $first = @_ % 2 ? shift : 1;
    my ($rc, $bytes) = $self->{rpc}->query(string => $query, int => $limit
       , int => $first, $self->_format(@_));
    $rc==0 or return ($rc, $bytes);
    (0, $self->schemas->decodeXML($bytes));
}


sub queryXPath($$$@)
{   my ($self, $xpath, $doc, $node) = splice @_, 0, 4;
    my @args = (base64 => $xpath);
    push @args, string => $doc, string => (defined $node ? $node : '')
        if defined $doc;
    my ($rc, $data) = $self->{rpc}->queryP(@args, $self->_format(@_));
    $rc==0 or return ($rc, $data);

    my $h = struct_to_hash $data;
    my @r;
    foreach (rpcarray_values $h->{results})
    {   my ($doc, $loc) = rpcarray_values $_;
        push @r, { document => $doc, node_id => $loc };
    }
    $h->{results} = \@r;

    (0, $h);
}
 
#-----------------

sub retrieveDocumentNode($$@)
{   my $self = shift;
    my ($rc, $chunk) = $self->{rpc}->retrieveFirstChunk(@_);

    my @data = \$chunk->{data};
    while($rc==0 && $chunk->{offset})
    {   ($rc, $chunk) = $chunk->{'supports-long-offset'}
        ? $self->getNextExtendedChunk($chunk->{handle}, $chunk->{offset})
        : $self->getNextChunk($chunk->{handle}, $chunk->{offset});
        $rc or push @data, \$chunk->{data};
    }
    $rc==0 or return ($rc, $chunk);

    (0, $self->schemas->decodeXML(join '', map {$$_} @data));
}

#-----------------

### What does the returned int mean?
sub updateResource($$;$)
{   my ($self, $resource, $xupdate, $encoding) = @_;
    $self->{rpc}->xupdateResource(string => $resource, string => $xupdate
      , ($encoding ? (string => $encoding) : ()));
}

### What does the returned int mean?
### Does this update the collection configuration?

sub updateCollection($$)
{   $_[0]->{rpc}->xupdate(string => $_[1], string => $_[2]);
}

#-----------------

sub scanIndexTerms($$$;$)
{   my $self = shift;
     my ($rc, $details);
    if(@_==4)
    {   my ($coll, $begin, $end, $recurse) = @_;
        ($rc, $details) = $self->{rpc}->scanIndexTerms(string => $coll
          , string => $begin, string => $end, boolean => $recurse);
    }
    else
    {   my ($xpath, $begin, $end) = @_;
### no idea what xpath means here.
        ($rc, $details) = $self->{rpc}->scanIndexTerms(string => $xpath
          , string => $begin, string => $end);
    }

    $rc==0 or return ($rc, $details);
    (0, rpcarray_values $details);
}


sub getIndexedElements($$)
{   my ($self, $coll, $recurse) = @_;
    my ($rc, $details) = $self->{rpc}->getIndexedElements(string => $coll
       , boolean => $recurse);
    $rc==0 or return ($rc, $details);
### cleanup Vector $details. Per element:
#  1. name of the element
#  2. optional namespace URI
#  3. optional namespace prefix
#  4. number of occurrences of this element as an integer value

    (0, rpcarray_values $details);
}


#-----------------

sub schemas()
{   my $self = shift;
    return $self->{schemas} if $self->{schemas};

    # This will load a lot of XML::Compile::* modules. Therefore, we
    # do this lazy: only when needed.
    eval "require XML::eXistDB";
    panic $@ if $@;

    $self->{schemas} = XML::eXistDB->new;
}


sub trace() { shift->{rpc}->trace }

#----------------

#T
sub getCollectionDesc(;$)
{   my ($self, $coll) = @_;
    $coll ||= $self->{repository};
    $self->describeCollection($coll, documents => 1);
}

#---------

sub getDocument($$;$$)
{   my ($self, $resource) = (shift, shift);
    my @args;
    if(@_==3)
    {   my ($enc, $prettyprint, $style) = @_;
        push @args, string => $enc, int => ($prettyprint ? 1 : 0);
        push @args, string => $style if defined $style;
    }
    else
    {   @args = @_;
    }
    $self->{rpc}->getDocument(string => $resource, @args);
}


sub getDocumentAsString($$;$$)
{   my ($self, $resource) = (shift, shift);
    my @args;
    if(@_==3)
    {   my ($enc, $prettyprint, $style) = @_;
        push @args, string => $enc, int => ($prettyprint ? 1 : 0);
        push @args, string => $style if defined $style;
    }
    else
    {   @args = @_;
    }
    $self->{rpc}->getDocumentAsString(string => $resource, @args);
}


sub getDocumentData($@)
{   my ($self, $resource) = (shift, shift);
    my ($rc, $details) = $self->{rpc}->getDocumentData(string => $resource
      , $self->_format(@_));
    $rc==0 or return ($rc, $details);
    (0, struct_to_hash $details);
}


sub getNextChunk($$)
{   my ($self, $handle, $offset) = @_;
    my ($rc, $details)
      = $self->{rpc}->getNextChunk(string => $handle, int => $offset);
    $rc==0 or return ($rc, $details);
    (0, struct_to_hash $details);
}


sub getNextExtendedChunk($$)
{   my ($self, $handle, $offset) = @_;
    my ($rc, $details)
      = $self->{rpc}->getNextChunk(string => $handle, string => $offset);
    $rc==0 or return ($rc, $details);
    (0, struct_to_hash $details);
}

#---------

sub parse($$;$$$)
{   my ($self, $data, $resource, $replace, $created, $modified) = @_;
   
    $self->{rpc}->parse
      ( base64 => $self->_document($data)
      , string => $resource, int => ($replace ? 1 : 0)
      , _date_options($created, $modified)
      );
}


sub parseLocal($$$$;$$)
{   my ($self, $fn, $resource, $replace, $mime, $created, $modified) = @_;
   
    $self->{rpc}->parseLocal
      ( string => $fn, string => $resource, boolean => $replace
      , string => $mime, _date_options($created, $modified)
      );
}


sub parseLocalExt($$$$;$$)
{   my ($self, $fn, $res, $replace, $mime, $is_xml, $created, $modified) = @_;
   
    $self->{rpc}->parseLocal
      ( string => $fn, string => $res, boolean => $replace
      , string => $mime, boolean => $is_xml
      , _date_options($created, $modified)
      );
};


sub upload($;$)
{   my $self = shift;
    my $tmp  = @_ == 2 ? shift : undef;
    $self->{rpc}->upload(string => (defined $tmp ? $tmp : '')
       , base64 => $_[0], int => length($_[0]));
}


sub uploadCompressed($;$)
{   my $self = shift;
    my $tmp  = @_ == 3 ? shift : undef;

### Not sure whether each chunk is compressed separately or the
### data is compressed as a whole.
    $self->{rpc}->uploadCompressed
       ( (defined $tmp ? (string => $tmp) : ())
       , base64 => $_[0], int => length($_[1]));
}


sub storeBinary($$$$;$$) { $_[0]->uploadBinary( @_[2, 1, 3, 4, 5, 6] ) }

#-------

sub retrieveFirstChunk($$@)
{   my $self = shift;
    my @args;
    if($_[0] =~ m/\D/)
    {   my ($docname, $id) = (shift, shift);
        @args = (string => $docname, string => $id);
    }
    else
    {   my ($resultset, $pos) = (shift, shift);
        @args = (int => $resultset, int => $pos);
    }
    my $format = $self->_format(@_);
    my ($rc, $details) = $self->{rpc}->retrieveFirstChunk(@args, $format);
    ($rc, $rc==0 ? $details : struct_to_hash $details);
}

#------------------

sub retrieve($$@)
{   my $self = shift;
    my @args = $_[0] =~ m/\D/
             ? (string => shift, string => shift)
             : (int => shift, int => shift);

    my ($rc, $bytes) = $self->{rpc}->retrieve(@args, $self->_format(@_));
    $rc==0 or return ($rc, $bytes);
    (0, $self->schemas->decodeXML($bytes));
}


sub retrieveAll($$@)
{   my ($self, $set) = (shift, shift);
    my ($rc, $bytes) = $self->{rpc}->retrieveAll(int => $set
      , $self->_format(@_));
    $rc==0 or return ($rc, $bytes);
    (0, $self->schemas->decodeXML($bytes));
}


sub retrieveAllFirstChunk($$@)
{   my ($self, $result) = (shift, shift);
    my ($rc, $details)  = $self->{rpc}->retrieveAllFirstChunk(int => $result
      , $self->_format(@_));
    $rc==0 or return ($rc, $details);
    (0, struct_to_hash $details);
}


sub isValidDocument($)
{   my ($self, $doc) = (shift, shift);
    $self->{rpc}->isValid(string => $doc);
}


sub initiateBackup($)
{   my ($self, $s) = (shift, shift);
    $self->{rpc}->dataBackup($s);
}


sub getDocumentChunked($@)
{   my ($self, $doc) = (shift, shift);
    my ($rc, $data) = $self->{rpc}->getDocumentChunk(string => $doc);
    $rc==0 or return ($rc, $data);
    (0, rpcarray_values $data);
}


sub getDocumentNextChunk($$$)
{   my ($self, $handle, $start, $len) = @_;
    $self->{rpc}->getDocumentChunck(string => $handle
      , int => $start, int => $len);
}


sub retrieveAsString($$@)
{   my ($self, $doc, $node) = (shift, shift, shift);
    $self->{rpc}->retrieveAsString(string => $doc, string => $node
      , $self->_format(@_));
}

#----------------

*createResourceId = \&uniqueResourceName;
*dataBackup = \&initiateBackup;
*getBinaryResource = \&downloadBinary;
*getCreationDate = \&collectionCreationDate;
*getDocumentListing = \&listResources;
*getGroups = \&listGroups;
*getHits = \&numberOfResults;
*getPermissions = \&describeResourcePermissions;
*getResourceCount = \&countResources;
*getTimestamps = \&listResourceTimestamps;
*getUser   = \&describeUser;
*getUsers  = \&listUsers;
*hasUserLock = \&whoLockedResource;
*isValid = \&isValidDocument;
*listCollectionPermissions = \&describeCollectionPermissions;
*printDiagnostics = \&describeCompile;
*querySummary = \&describeResultSet;
*queryP = \&queryXPath;
*releaseQueryResult = \&releaseResultSet;
*remove = \&removeResource;
*xupdate = \&xupdateCollection;
*xupdateResource = \&xupdateResource;

1;
