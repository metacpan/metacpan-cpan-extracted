# NAME

WWW::Google::Drive - Used to modify Google Drive data for service account (server-to-server)

# SYNOPSIS

    use WWW::Google::Drive;

    my $gd = WWW::Google::Drive->new( 
        secret_json => 'YourProject.json',

         # Set the Google user to impersonate. 
         # Your Google Business Administrator must have already set up 
         # your Client ID as a trusted app in order to use this successfully.
        user_as => 'name@domain.com' #(optional)
    );
    my $children = $gd->children('/MyDocs');

    foreach my $item (@{$children}){
        print "File name: $item->{name}\n";
    }

# DESCRIPTION

WWW::Google::Drive authenticates with a Google Drive service account (server-to-server) and offers several convenient methods to list, retrieve and modify the data stored in the google drive. 

Refer: https://developers.google.com/identity/protocols/OAuth2ServiceAccount for creating a service account and the client\_secret json file.

Refer: https://developers.google.com/drive/v3/reference/ for list of file properties, response values, query\_params and body\_params.

# METHODS

- **new**

        my $gd = WWW::Google::Drive->new(
                secret_json => "./YourProject.json"
            );

    Parameters can be

        user_as (optional)
            - email id of the account, if set, then all operations will be done in that respective user's space. Respective account should be authenticated using OAuth2.0 mechanism. See Net::Google::Drive::Simple eg/ directory for an example script to do authentication using OAuth2.0

        http_retry_no (default 0)
            - number of time each http requests should be retried if the request is failed

        http_retry_interval (default 5)
            - time interval in seconds after which another attempt will be made for the previously failed http request, this setting is useless when http_retry_no is set to 0

        show_trash_items (default 0)
            - when this value is set, trash files filter will be disabled

        lwp_opts (default {})
            - This will be passed to LWP::UserAgent constructor
            - additionally you can pass an array ref with key as proxy_conf in lwp_opts 
                which will be passed to $user_agent->proxy(@{$proxy_conf});

- **files**

    Params  : $query\_params (optional)
                For list of query\_params refer https://developers.google.com/drive/v3/reference/files/list

    Returns : List of files

    Desc    : Get all files from your drive

    Usage   :

        my $files_at_drive = $gd->files();

- **children**

    Params  : $path, $query\_params (optional), $body\_params (optional)

    Returns : All items under the given path as an array ref

    Desc    : Get children of given directory. Since the directory path is iteratively found for optimization $parent\_id is returned as second argument when calling in array context.

    Usage   :

        my $children = $gd->children('/my_docs' $query_params, $body_params);

        or 

        my ($children, $parent_id) = $gd->children('/my_docs', $query_params, $body_params);

- **children\_by\_folder\_id**

    Params  : $folder\_id, $query\_params (optional), $body\_params (optional)

    Returns : Arrayref of items (files)

    Desc    : Get all the items which has $folder\_id as parent

    Usage   : 

        my $items = $gd->children_by_folder_id($parent_id, { orderBy => 'modifiedTime' });

- **new\_file**

    Params  : $local\_file\_path, $folder\_id, $options (optional key value pairs), $query\_params (optional)

    Returns : new file id, ( and second argument as response data hashref when called in array context )

    Desc    : Uploads a new file ( file at $local\_file\_path ) to the drive in the given folder ( given folder\_id )

    Usage   : 

        my $file_id = $gd->new_file('./testfile', $parent_id, { description => "This is a test file upload" });

- **update\_file**

    Params  : $old\_file\_id, $updated\_local\_file\_path, $body\_params (optional), $query\_params (optional)

    Returns : $file\_id on Successful upload

    Desc    : This will replace the existing file in the drive with new file.

    Usage   : 

        my $file_id = $gd->update_file($old_file_id, "./updated_file");

    NOTE    : If you only want to update file metadata, then send file\_path as undef and $body\_params should have properties.

- **delete**

    Params  : $item\_id (It can be a file\_id or folder\_id), $no\_trash (optional)

    Returns : deleted file id on successful deletion

    Desc    : Deletes an item from google drive.

    Usage   :

        my $deleted_file_id = $gd->delete($file_id);

    NOTE    : If $no\_trash option is set, file will be deleted from google drive permanently.

- **create\_folder**

    Params  : $folder\_name, $parent\_folder\_id

    Returns : $folder\_id (newly created folder Id)
        If called in an array context then second argument will be the http response data

    Desc    : Used to create a new directory in your drive

    Usage   : 

        my $new_folder_id = $gd->create_folder("Test",$parent_id);

- **search**

    Params  : $query string, $query\_params (optional)

    Returns : Result items (files) for the given query

    Desc    : Do search on the google drive using the syntax mentioned in google drive, refer https://developers.google.com/drive/v3/web/search-parameters for list of search parameters and examples

    Usage   :

        my $items = $gd->search("mimeType contains 'image/'",{ corpus => 'user' });

- **download**

    Params  : $file\_id, $local\_file\_path, $acknowledgeAbuse

    Returns : 0/1 when $file\_path is given, otherwise returns the file content

    Desc    : Download file from the drive, when you pass file\_id as a ref this method will try to find the $file\_id->{id} and tries to download that file. When local file name with path is not given, this method will return the content of the file on success download.

    Usage   :

        $gd->download($file_id, $local_file);

        or

        my $file_content = $gd->download($file_id);

- **export\_options**

    Params  : $mimeType or { mimeType => $mime\_type }

    Return  : hashref with key as mimeType name and value as mimeType

    Desc    : Return available export options with its mimeType for the given google docs mimeType

- **export**

    Params  : $file\_id, $mime\_type, $local\_file\_path

    Returns : 0/1 when $local\_file\_path is given, otherwise returns the file content

    Desc    : Download exported file from the drive, when you pass file\_id as a ref, this method will try to find the $file\_id->{id} and tries to download that file. When local file name with path is not given, this method will return the content of the file on success download.

    Usage   :

        $gd->export($file_id, 'application/pdf', $local_file_path);

        or

        my $file_content = $gd->export($file_id, 'application/pdf');

- **metadata**

    Params  : $file\_id, $query\_params

    Returns : hashref of properties on success

    Desc    : Used to get the file metadata. (files.get)

    Usage   :

        my $properties = $gd->metadata($file_id);

- **file\_mime\_type**

    Params  : $local\_file\_path

    Returns : mime type of the given file

    Desc    : Find the MimeType of a file using File::Type

    Usage   : 

        my $mime_type = $gd->file_mime_type("./testfile");

- **remove\_trashed**

    Params  : $items\_arrayref ( return value of files() or children() )

    Returns : $items arrayref

    Desc    : This method will filter out all the files marked as trashed

    Usage   :

        my $items = $gd->children('./MyDocs');

        # do something with the data

        my $live_items = $gd->remove_trashed($items);

- **show\_trash\_items**

    Params  : 0/1

    Returns : NONE

    Desc    : Disable/Enable listing deleted data from your drive

    Usage   :
        $gd->show\_trash\_items(1);
        my $all\_files = $gd->children('/'); # will return all the files including files in trash

    NOTE    : This module will consider an item as trashed if the file's metadata 'trashed' is set to true.

- **add\_req\_file\_fields**

    Params  : file\_properties as list
                Refer: https://developers.google.com/drive/v3/reference/files#resource for list of properties
                Refer: https://developers.google.com/drive/v3/web/performance for fields syntax

    Returns : NONE

    Desc    : Add file fields parameter that will be used in $query\_params 'fields'.

    Usage   :

            $gd->add_req_file_fields('appProperties','spaces','owners/kind');
            $gd->children('/');

    Note    : By Default fields such as 'kind','trashed','id','name' are added.

# Error handling

In case of an error while retrieving information from the Google Drive
API, the methods above will return `undef` and a more detailed error
message can be obtained by calling the `error()` method:

    print "An error occurred: ", $gd->error();
       

# LOGGING/DEBUGGING

WWW::Google::Drive is Log4perl-enabled.
To find out what's going on under the hood, turn on Log4perl:

    use Log::Log4perl qw(:easy);
    Log::Log4perl->easy_init($DEBUG);

# REPOSITORY

[https://github.com/dinesh-it/www-google-drive](https://github.com/dinesh-it/www-google-drive)

# SEE ALSO

Net::Google::Drive::Simple
Net::GoogleDrive

# LICENSE

Copyright 2016 by Dinesh Dharmalingam, all rights reserved. This program is free software, you can redistribute it and/or modify it under the same terms as Perl itself.

# AUTHORS

Dinesh D, &lt;dinesh@exceleron.com>
