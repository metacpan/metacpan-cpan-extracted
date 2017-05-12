# NAME
     Web::Sitemap - Simple way to generate sitemap files with paging support

# SYNOPSIS
     Each instance of the class Web::Sitemap is manage of one index file.
     Now it always use Gzip compress.


     use Web::Sitemap;
 
     my $sm = Web::Sitemap->new(
            output_dir => '/path/for/sitemap',
        
            ### Options ###

            temp_dir    => '/path/to/tmp',
            loc_prefix  => 'http://my_doamin.com',
            index_name  => 'sitemap',
            file_prefix => 'sitemap.',
        
            # mark for grouping urls
            default_tag => 'my_tag',
        
        
            # add <mobile:mobile/> inside <url>, and appropriate namespace (Google standard)
            mobile      => 1,
        
            # add appropriate namespace (Google standard)
            images      => 1,
        
            # additional namespaces (scalar or array ref) for <urlset>
            namespace   => 'xmlns:some_namespace_name="..."',
        
            # location prefix for files-parts of the sitemap (default is loc_prefix value)
            file_loc_prefix  => 'http://my_doamin.com',

            # specify data input charset
            charset => 'utf8',

            move_from_temp_action => sub { 
                    my ($temp_file_name, $public_file_name) = @_;
        
                    # ...some action...
                    #
                    # default behavior is
                    # File::Copy::move($temp_file_name, $public_file_name);
            }

     );

     $sm->add(\@url_list);
 

     # When adding a new portion of URL, you can specify a label for the file in which these will be URL
 
     $sm->add(\@url_list1, tag => 'articles');
     $sm->add(\@url_list2, tag => 'users');
 

     # If in the process of filling the file number of URL's will exceed the limit of 50 000 URL or the file size is larger than 10MB, the file will be rotate

     $sm->add(\@url_list3, tag => 'articles');

 
     # After calling finish() method will create an index file, which will link to files with URL's

     $sm->finish;

# DESCRIPTION
    Also support for Google images format:

            my @img_urls = (
                
                    # Foramt 1
                    { 
                            loc => 'http://test1.ru/', 
                            images => { 
                                    caption_format => sub { 
                                            my ($iterator_value) = @_; 
                                            return sprintf('Vasya - foto %d', $iterator_value); 
                                    },
                                    loc_list => [
                                            'http://img1.ru/', 
                                            'http://img2.ru'
                                    ] 
                            } 
                    },

                    # Foramt 2
                    { 
                            loc => 'http://test11.ru/', 
                            images => { 
                                    caption_format_simple => 'Vasya - foto',
                                    loc_list => ['http://img11.ru/', 'http://img21.ru'] 
                            } 
                    },

                    # Format 3
                    { 
                            loc => 'http://test122.ru/', 
                            images => { 
                                    loc_list => [
                                            { loc => 'http://img122.ru/', caption => 'image #1' },
                                            { loc => 'http://img133.ru/', caption => 'image #2' },
                                            { loc => 'http://img144.ru/', caption => 'image #3' },
                                            { loc => 'http://img222.ru', caption => 'image #4' }
                                    ] 
                            } 
                    }
            );


            # Result:

            <?xml version="1.0" encoding="UTF-8"?>
            <urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
            <url>
                    <loc>http://test1.ru/</loc>
                    <image:image>
                            <loc>http://img1.ru/</loc>
                            <caption><![CDATA[Vasya - foto 1]]></caption>
                    </image:image>
                    <image:image>
                            <loc>http://img2.ru</loc>
                            <caption><![CDATA[Vasya - foto 2]]></caption>
                    </image:image>
            </url>
            <url>
                    <loc>http://test11.ru/</loc>
                    <image:image>
                            <loc>http://img11.ru/</loc>
                            <caption><![CDATA[Vasya - foto 1]]></caption>
                    </image:image>
                    <image:image>
                            <loc>http://img21.ru</loc>
                            <caption><![CDATA[Vasya - foto 2]]></caption>
                    </image:image>
            </url>
            <url>
                    <loc>http://test122.ru/</loc>
                    <image:image>
                            <loc>http://img122.ru/</loc>
                            <caption><![CDATA[image #1]]></caption>
                    </image:image>
                    <image:image>
                            <loc>http://img133.ru/</loc>
                            <caption><![CDATA[image #2]]></caption>
                    </image:image>
                    <image:image>
                            <loc>http://img144.ru/</loc>
                            <caption><![CDATA[image #3]]></caption>
                    </image:image>
                    <image:image>
                            <loc>http://img222.ru</loc>
                            <caption><![CDATA[image #4]]></caption>
                    </image:image>
            </url>
            </urlset>

#AUTHOR
    Mikhail N Bogdanov "<mbogdanov at cpan.org >"

