#!/usr/bin/perl
#
# ePortal - WEB Based daily organizer
# Author - S.Rusakov <rusakov_sa@users.sourceforge.net>
#
# Copyright (c) 2000-2004 Sergey Rusakov.  All rights reserved.
# This program is open source software
#
#----------------------------------------------------------------------------

=head1 NAME

ePortal::Attachment - File attachment for any object

=head1 SYNOPSIS

ePortal::Attachment is used for manipulating file attachments. 

=head2 Database store

Database store is the only method to store big attachments since ePortal 
4.1. 
 
Every attachment is split into several chunks. The size of a chunk is a
New chunk tables are created automatically when the size of current
table reached 2Gb limit. This method guaranteed that any file of any size can
be stored on any OS platform.

=head2 File store

File store is deprecated since ePortal 4.1

=head2 content_type

Content type of a file negotiation is based on Apache internals. During
download a subrequest is made to discover a content_type to use. See
C<mod_mime> Apache module and C<mime>.C<types> file for details.


=head1 METHODS

=cut

package ePortal::Attachment;
    our $VERSION = '4.5';
    use base qw/ePortal::ThePersistent::Support/;

    use ePortal::Utils;
    use ePortal::Global;
    use ePortal::ThePersistent::Tools qw/ table_exists table_size /;

    use Error qw/:try/;
    use ePortal::Exception;
    use Params::Validate qw/:types/;
    use IO::File qw//;
    use File::Path qw//;

    # How deep to do file storage
    our $FILESTORE_NESTING = 2;
    # Files less than DB_UPLOAD_SIZE store in database
    our $DB_UPLOAD_SIZE = 100 * 1024;

    our $CHUNK_SIZE = 512 * 1024;      # Kb
    our $MAX_TABLE_SIZE = 2 * 1024*1024*1024; # 2 Gb

############################################################################
sub initialize  {   #05/31/00 8:50
############################################################################
    my ($self, %p) = @_;

    $p{Attributes}{id} ||= {};
    $p{Attributes}{object_id} ||= {
        dtype => 'VarChar',
        description => 'ref:id syntax',
    };
    $p{Attributes}{filename} ||= {
        dtype => 'VarChar',
    };
    $p{Attributes}{data} ||= {
        dtype => 'VarChar',
        maxlength => 16777215, # MediumBLOB
    };
    $p{Attributes}{ts} ||= {};
    $p{Attributes}{state} ||= {
        values => ['unknown', 'ok'],
        default => 'unknown',
        #description => 'The state of attachment. unknown when actial object is not saved',
    };
    $p{Attributes}{storage} ||= {
        values => ['db', 'file', 'chunk'],
        default => 'chunk',
        #description => 'Where the attachment is stored',
    };
    $p{Attributes}{start_chunk} ||= {
        dtype => 'Number',
        #description => 'A number of first chunk table',
    };
    $p{Attributes}{chunks} ||= {
        dtype => 'Number',
        #description => 'A number of chunks in attachments',
    };
    $p{Attributes}{filesize} ||= {
        dtype => 'Number',
    };

    # Attach the attachment to an object
    if ($p{obj}) {
        $p{Attributes}{object_id}{default} = sprintf("%s=%d", ref($p{obj}), $p{obj}->id);
        delete $p{obj};
    }

    $self->SUPER::initialize(%p);
}##initialize


############################################################################
sub restore_where   {   #06/16/2003 4:55
############################################################################
    my ($self, %p) = @_;

    if ($p{obj}) {
        $p{where} = sprintf "object_id='%s=%d'", ref($p{obj}), $p{obj}->id;
    }
    delete $p{obj};

    # Last added comes first!!! А оно надо? Раньше надо было, чтобы вытесняло старое.
    $p{order_by} = 'id DESC' if ! defined $p{order_by};

    $self->SUPER::restore_where(%p);
}##restore_where


############################################################################
sub delete  {   #06/16/2003 4:58
############################################################################
    my $self = shift;

    # Deprecated!
    if ($self->storage eq 'file') {
        unlink $self->filestore_path . '/' . $self->id;
    }

    # delete chunks
    if ($self->storage eq 'chunk') {
        my $iterator = $self->start_chunk || 1;
        while(1) {
            my $table = $self->chunk_table_name($iterator);
            my $res = $self->dbh->do("DELETE FROM $table WHERE att_id=?", undef, $self->id);
            last if $res == 0;  # No rows deleted
            
            $table = $self->chunk_table_name(++$iterator);
            last if ! table_exists($self->dbh, "$table");
        }    
    }
        
    $self->SUPER::delete;
}##delete



=head2 upload()

Upload a file from client and store it. Returns true is upload was
successful.

Throws C<ePortal::Exception::DataNotValid> if upload is impossible.

=over 4

=item * r

Apache::Request object

=back

=cut

############################################################################
sub upload  {   #06/16/2003 3:01
############################################################################
    my $self = shift;
    my %p = Params::Validate::validate_with( params => \@_, spec => {
        r => { type => OBJECT},
        });

    # Get upload object
    my $upload = $p{r}->upload;
    if (! $upload) {
        return undef;
    }

    # Get filename
    my $filename = $upload->filename;
    $filename =~ s|.*[/\\]||go;
    return undef if ! $filename;

    # Pre-save the attachment
    $self->filename($filename);
    $self->state('unknown');
    $self->storage('chunk');
    $self->insert;
    $self->read_from_fh($upload->fh);

    # Mark the attachment as complete and linked to object
    if ($self->object_id) {
        $self->state('ok');
        $self->update;
    }

    logline('notice', 
        sprintf "User %s has uploaded file %s %d bytes ", 
        $ePortal->username, $filename, $self->filesize);

    return 1;
}##upload



=head2 link_with_object

Make a link between the attachment and some ThePersistent object.
Also mark the attachment as complete.

=cut

############################################################################
sub link_with_object    {   #10/14/2003 3:25
############################################################################
    my $self = shift;
    my $obj = shift;

    $self->object_id( sprintf("%s=%d", ref($obj), $obj->id) );
    $self->state('ok');
    $self->update;
    
}##link_with_object


=head2 filestore_path()

Returns path to directory like

 /$comproot/attachment/1/0

=cut

############################################################################
sub filestore_path  {   #06/16/2003 4:10
############################################################################
    my $self = shift;

    my $filestore_root = $ePortal->comp_root . '/attachment';

    my $subpath;
    foreach my $i (1 .. $FILESTORE_NESTING) {
        $subpath = $subpath . '/' . (0+substr($self->id, - $i, 1));
    }
    return "$filestore_root$subpath";
}##filestore_path

############################################################################
sub fh  {   #06/16/2003 5:30
############################################################################
    my $self = shift;

    return new IO::File "< ". $self->filestore_path . '/' . $self->id;
}##fh






=head2 read_from_fh

Read the content of attachment from FH and create a number of chunks as 
needed 

=over 4
 
=item * fh
 
Filehandle to read from
 
=back
 
=cut 

############################################################################
sub read_from_fh    {   #09/30/2003 4:14
############################################################################
    my $self = shift;
    my $fh = shift;

    my $buffer = undef;
    while(read($fh, $buffer, $CHUNK_SIZE)) {
        $self->add_chunk(\$buffer);
        $buffer = undef;
    }
}##read_from_fh


############################################################################
# Function: read_from_file
# Description:
# Parameters:
# Returns:
#
############################################################################
sub read_from_file  {   #10/01/2003 5:17
############################################################################
    my $self = shift;
    my $filename = shift;

    my $fh = new IO::File $filename, "r";
    throw ePortal::Exception::FileNotFound( -file => $filename)
        if ! $fh;

    my $basename = $filename;
    $basename =~ s|.*[/\\]||go;
    $self->filename($basename);
    $self->read_from_fh($fh);       # this will ->update self
    $fh->close;
}##read_from_file



############################################################################
sub save_to_file    {   #10/06/2003 11:46
############################################################################
    my $self = shift;
    my $filename = shift;

    my $fh = new IO::File $filename, "w";
    throw ePortal::Exception::FileNotFound( -file => $filename)
        if ! $fh;

    $self->get_first_chunk;
    while(my $buffer = $self->get_next_chunk) {
        $fh->write($buffer);
    }
    $fh->close;
}##save_to_file


############################################################################
sub save_to_string {   #10/06/2003 11:46
############################################################################
    my $self = shift;
    my $buffer = undef;

    $self->get_first_chunk;
    while(my $buf = $self->get_next_chunk) {
        $buffer .= $buf;
    }

    return $buffer;
}##save_to_string


############################################################################
# Function: add_chunk
# Description: internal function. Use more high level function like 
#   read_from_fh ...
# 
# Parameters:
# Returns:
#
############################################################################
sub add_chunk   {   #09/30/2003 4:13
############################################################################
    my $self = shift;
    my $chunk_buffer = shift;
    
    $self->{current_table} = $self->allocate_chunk_table($self->{current_table});
    my $table_name = $self->chunk_table_name($self->{current_table});

    my $sth = $self->dbh->prepare("INSERT INTO $table_name (att_id,chunk) VALUES(?,?)");
    $sth->execute($self->id, $$chunk_buffer);
    $sth->finish;
    undef $sth;

    $self->start_chunk($self->{current_table}) if $self->start_chunk == 0;
    $self->chunks( $self->chunks + 1);
    $self->filesize( $self->filesize + length($$chunk_buffer));
    $self->update;
}##add_chunk


############################################################################
# Function: allocate_chunk_table (internal)
# Description: 
#   Create chunk table if not exists
#   Check max size of current chunk table
# Parameters:
# Returns:
#   integer number of current chunk table
#
# show table status like 'tablename'
#  show table status like 'user';
#+------+--------+------------+------+----------------+-------------+-----------------+--------------+-----------+----------------+---------------------+---------------------+------------+----------------+-----------------------------+
#| Name | Type   | Row_format | Rows | Avg_row_length | Data_length | Max_data_length | Index_length | Data_free | Auto_increment | Create_time         | Update_time         | Check_time | Create_options | Comment                     |
#+------+--------+------------+------+----------------+-------------+-----------------+--------------+-----------+----------------+---------------------+---------------------+------------+----------------+-----------------------------+
#| user | MyISAM | Dynamic    |    9 |             59 |         532 |      4294967295 |         2048 |         0 |           NULL | 2003-09-11 13:46:19 | 2003-09-11 13:46:19 | NULL       |                | Users and global privileges |
#+------+--------+------------+------+----------------+-------------+-----------------+--------------+-----------+----------------+---------------------+---------------------+------------+----------------+-----------------------------+
############################################################################
sub allocate_chunk_table    {   #10/01/2003 10:37
############################################################################
    my $self = shift;
    my $start_with = shift || 1;
    my $last_found = 0;

    my $dbh = $self->dbh;
    my $sth = $dbh->prepare("SHOW TABLE STATUS like 'AttChunk%'");
    $sth->execute;
    while(my @ary = $sth->fetchrow_array) {
        # get table parameters
        my ($name,$data_length,$max_data_length,$data_free) = (@ary)[0,5,6,8];
        ($last_found) = ($name =~ /AttChunk(\d\d\d)/o);
        $last_found += 0;       # integerize it

        next if $last_found <= 0;    
#        throw ePortal::Exception::Fatal(-text => "AttChunk table cannot be counted from 0") 
#            if $last_found == 0;

        # skip if before we need
        next if $last_found < $start_with;

        # skip extra big tables
        next if $data_length + $CHUNK_SIZE >= $max_data_length;
        # Skip full tables
        next if $data_length - $data_free + $CHUNK_SIZE >= $MAX_TABLE_SIZE;

        # enough
        return $last_found;
    }
    $sth->finish;

    # Prepare for new table
    $last_found ++;
    $self->create_chunk_table($last_found);
    return $last_found;
}##allocate_chunk_table


############################################################################
sub create_chunk_table  {   #10/01/2003 5:12
############################################################################
    my $self = shift;
    my $chunk_number = shift || 1;

    my $table_name = $self->chunk_table_name($chunk_number);
    my $dbh = $self->dbh;
    $dbh->do("CREATE TABLE $table_name (
                `id` int(11) NOT NULL auto_increment,
                `att_id` int(11) NOT NULL default '0',
                `chunk` mediumblob,
                PRIMARY KEY  (`id`),
                UNIQUE KEY `att_id` (`att_id`,`id`)
                )
    ") if ! table_exists($dbh, $table_name);
    logline('warn', "Created new chunk table for Attachments: $table_name");
}##create_chunk_table


############################################################################
sub chunk_table_name    {   #10/01/2003 10:41
############################################################################
    my $self = shift;
    my $chunk_number = shift;
    return sprintf("AttChunk%03x", 0 + $chunk_number);
}##chunk_table_name





=head2 get_first_chunk,get_next_chunk

Low level functions for content retrieval chunk by chunk.

Returns C<undef> when no chunks to retrieve

 $att->get_first_chunk;
 while(my $buffer = $att->get_next_chunk) {
    # do comthing with $buffer
 }

=cut

############################################################################
sub get_first_chunk {   #10/01/2003 10:37
############################################################################
    my $self = shift;
    
    $self->{cur_chunkid} = 0;
    $self->{cur_chunknum} = 0;
    $self->{cur_table} = $self->start_chunk;

    1;
}##get_first_chunk


############################################################################
sub get_next_chunk  {   #10/01/2003 10:37
############################################################################
    my $self = shift;
    
    return undef if $self->{cur_table} == 0; # TODO DO LOGLINE !!!!!!!!1

    my $table = $self->chunk_table_name($self->{cur_table});
    my ($newid, $chunk) = $self->dbh->selectrow_array(
        "SELECT id,chunk FROM $table WHERE att_id=? and id>? ORDER BY id limit 1", undef,
        $self->id, $self->{cur_chunkid});

    if ($newid) {   # additional chunk exists
        $self->{cur_chunknum} ++;
        $self->{cur_chunkid} = $newid;
        return $chunk;

    } else {        # chunk not found in current table
        if ( $self->{cur_chunknum} >= $self->chunks) { # not more chunks
            return undef;
        } else { # need to look ito next table
            $self->{cur_table} ++;
            $self->{cur_chunkid} = 0;
            return $self->get_next_chunk;
        }
    }    
}##get_next_chunk


############################################################################
sub ObjectDescription   {   #10/16/2003 3:37
############################################################################
    my $self = shift;
    
    return pick_lang(rus => "Присоединенный файл ", eng => "Attached file ") .
        $self->Filename;

}##ObjectDescription

############################################################################
sub LastModified    {   #10/17/2003 3:42
############################################################################
    my $self = shift;
    
    return scalar $self->dbh->selectrow_array(
        "SELECT unix_timestamp(ts) from Attachment WHERE id=?",
        undef, $self->id);
}##LastModified


1;


__END__

=head1 AUTHOR

Sergey Rusakov, E<lt>rusakov_sa@users.sourceforge.netE<gt>

=cut
