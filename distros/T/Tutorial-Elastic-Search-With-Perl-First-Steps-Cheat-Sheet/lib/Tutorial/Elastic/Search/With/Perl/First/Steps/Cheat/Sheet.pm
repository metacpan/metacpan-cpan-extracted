package Tutorial::Elastic::Search::With::Perl::First::Steps::Cheat::Sheet;
use strict;
use warnings;

our $VERSION     = '0.02';

=pod

=head1 Elastic Search basics for dummys. With perl examples.

    As i began developing using elastic search, i noticed the documentation lacks a nice cookbook. So i came up with the idea to create this document which can serve as a beta cheatsheet and has the intent of passing the basic knowledge to get your elastic search searches going.
    Elastic search will give you fast searches .. its like google searching facility for you, and you can scale it! isnt it great ?

    First i will give you the commands without perl. And then (on appendix) you can see the same commands using the perl api.

    enjoy this tutorial folks

=head2 More tutorials

Tutorial::Elastic::Search::With::Perl::First::Steps::Cheat::Sheet
Tutorial::Elastic::Search::With::Perl::First::Steps::Cheat::Sheet::Geo::Point::Distance

=head2 Get ElasticSearch

Download elastic search. Use the latest version.

    http://www.elasticsearch.org/download/

=head2 Install ElasticSearch

Install openjdk jre as dependency. And then, decompress the file you downloaded from ElasticSearch.org.  Start the elastic search server

    tar xvf elasticsearch-0.19.2.tar.gz
    cd elasticsearch-0.19.2
    ./bin/elasticsearch.in.sh
    ./bin/elasticsearch.bat  ( *** WINDOWS )

=head2 Test the running server

To test the running server you can analyse the successful response from:

    curl -X GET http://localhost:9200/

If you get any errors, repeat the procedure from the steps before you get outside help.

=head2 Upgrade ElasticSearch

    ATTENTION: If you have an index running, and you need to upgrade, read about the upgrading procedure on your versions webpage, which you can find listed here: http://www.elasticsearch.org/download/
    After reading the documents, you can execute the procedure safely. You have been warned.

=head2 Delete an Index

If you need to delete your index, use with care because there is no data restoration:

    curl -XDELETE http://localhost:9200/myapp

=head2 Create an Object Mapping

Here we create an object mapping called 'myapp'.

    curl -XPUT http://localhost:9200/myapp/ -d '{
        "settings": {
            "analysis": {
                "analyzer": {
                    "index_analyzer": {
                        "tokenizer": "standard",
                        "filter": ["standard", "my_delimiter", "lowercase", "stop", "asciifolding", "porter_stem"]
                    },
                    "search_analyzer": {
                        "tokenizer": "standard",
                        "filter": ["standard", "lowercase", "stop", "asciifolding", "porter_stem"]
                    }
                },
                "filter": {
                    "my_delimiter": {
                        "type": "word_delimiter",
                        "generate_word_parts": true,
                        "catenate_words": true,
                        "catenate_numbers": true,
                        "catenate_all": true,
                        "split_on_case_change": true,
                        "preserve_original": true,
                        "split_on_numerics": true,
                        "stem_english_possessive": true
                    }
                }
            }
        }
    }'

=head2 Create 'product' object mapping inside 'myapp'

    curl -XPUT http://localhost:9200/myapp/product/_mapping/ -d '{
      "product" : {
        "properties": {
          "name": {
            "index": "analyzed",
            "type": "string",
            "index_analyzer": "index_analyzer",
            "search_analyzer": "search_analyzer",
            "store": "yes"
          },
          "category_id": {
            "index": "analyzed",
            "type": "integer",
            "index_analyzer": "index_analyzer",
            "search_analyzer": "search_analyzer",
            "store": "yes"
          },
          "price": {
            "index": "analyzed",
            "type": "double",
            "index_analyzer": "index_analyzer",
            "search_analyzer": "search_analyzer",
            "store": "yes"
          },
          "price_high": {
            "index": "analyzed",
            "index_analyzer": "index_analyzer",
            "search_analyzer": "search_analyzer",
            "type": "double"
          },
          "price_low": {
            "index": "analyzed",
            "index_analyzer": "index_analyzer",
            "search_analyzer": "search_analyzer",
            "type": "double"
          }
        }
      }
    }'

=head2 Insert objects/products into the product object container

    curl -XPUT http://localhost:9200/myapp/product/1 -d '{
        "name" : "Shampoo Biolift with Joy and Ashes",
        "category_id" : "5",
        "price" : "6.3931",
        "price_high" : "12.731",
        "price_low" : "4.91"
    }'
    curl -XPUT http://localhost:9200/myapp/product/2 -d '{
        "name" : "Notebook ASUS 16GB 1TB 17in",
        "category_id" : "2",
        "price" : "1945.3931",
        "price_high" : "2500.61",
        "price_low" : "1800.15"
    }'
    curl -XPUT http://localhost:9200/myapp/product/3 -d '{
        "name" : "Notebook VAIO 8GB 1TB 14in",
        "category_id" : "2",
        "price" : "1045.3931",
        "price_high" : "1765.21",
        "price_low" : "780.66"
    }'
    curl -XPUT http://localhost:9200/myapp/product/4 -d '{
        "name" : "Notebook HP 2GB 500GB 14in",
        "category_id" : "2",
        "price" : "945.3931",
        "price_high" : "1000.6731",
        "price_low" : "645.91"
    }'

=head2 Search product by id

Just pass the id directly on the url.

    curl -XGET http://localhost:9200/myapp/product/4
    curl -XGET http://localhost:9200/myapp/product/3
    curl -XGET http://localhost:9200/myapp/product/2
    curl -XGET http://localhost:9200/myapp/product/1

=head2 Search name containing words

    Search for "notebook":
    curl -XGET http://localhost:9200/myapp/product/_search?q=name:notebook
    Search for "name"
    curl -XGET http://localhost:9200/myapp/product/_search?q=name:asus
    Search for "shampoo"
    curl -XGET http://localhost:9200/myapp/product/_search?q=name:shampoo

=head2 Search price gte 970

    curl -XGET http://localhost:9200/myapp/product/_search?pretty=true -d '{
        "query" : {
            "range" : {
                "price" : {
                    "gte" : "970"
                }
            }
        }
    }'

=head2 Search with name 'Asus'

    echo SEARCH WITH NAME ASUS
    curl -XGET http://localhost:9200/myapp/product/_search -d '{
        "query" : {
            "term" : { "name": "asus" }
        }
    }'

=head2 Search gte 1770 and name =~ asus

    curl -XGET http://localhost:9200/myapp/product/_search -d '{
        "query" : {
            "term" : { "name": "asus" },
            "range" : {
                "price" : {
                    "gte" : "1270"
                }
            }
        }
    }'

=head2 Name asus AND price gte 800

    curl -XGET http://localhost:9200/myapp/product/_search -d '{
        "query" : {
            "bool" : {
                "must" : {
                    "term" : { "name" : "asus" }
                },
                "must" : {
                    "range" : {
                        "price" : {
                            "gte" : "800"
                        }
                    }
                }
            }
        }
    }'

=head2 Search by name
    # Search: asus
    #curl -XGET 'http://127.0.0.1:9200/myapp/product/_search?pretty=1&q=asus'
    # Search: ãsus
    curl -XGET 'http://127.0.0.1:9200/myapp/product/_search?pretty=1&q=name:%C3%A3sus'

=head2 Search proce_low gte 1800.15 AND price_high 2500.61 AND name contains asus. Use 'must' as [] (array)

    curl -XGET http://localhost:9200/myapp/product/_search -d '{
         "query" : {
             "bool" : {
                 "must" : [
                     {
                         "text" : { "name" : "asus" }
                     },
                     {
                         "range" : {
                             "price_low" : {
                                "gte" : 1800.15
                            }
                        }
                     },
                     {
                         "range" : {
                             "price_high" : {
                                 "lte" : 2500.61
                             }
                         }
                     }
                 ]
             }
         }
    }'


=head2 Search price_low gte 1800.15 AND price_high 2500.61 AND name contains asus. The 'must' is {} (hash)

    curl -XGET http://localhost:9200/myapp/product/_search -d '{
         "query" : {
             "bool" : {
                 "must" : {
                     "text" : { "name" : "asus" }
                 },
                 "must" : {
                     "range" : {
                         "price_low" : {
                             "gte" : 1800.15
                         }
                     }
                 },
                 "must" : {
                     "range" : {
                         "price_high" : {
                             "lte" : 2500.61
                         }
                     }
                 }
             }
         }
    }'

=head2 Elastic Search Visual Interface Plugins

Access the plugins page at:

    http://www.elasticsearch.org/guide/appendix/clients.html

Under 'Front Ends' check

    elasticsearch-head: A web front end for an elastic search cluster.

Its very easy to instal.. just do as the plugins readme says:

    cd my-elasticsearch
    ./bin/plugin -install mobz/elasticsearch-head

Then access the plugin webpage:

    http://localhost:9200/_plugin/head/


=head2 APPENDIX - PERL EXAMPLES

    use ElasticSearch;
    my $es = ElasticSearch->new(
        servers      => 'localhost:9200',
        transport    => 'http',
        max_requests => 10_000,
        trace_calls  => 1, # or 'log_file'
        no_refresh   => 0 | 1,
    );

    my $result = $es->delete_index( index => 'myapp',  );
    sleep 1;
    my $result = $es->create_index(
        index      => 'myapp',
    #   type       => 'product',
        "settings" => {
    #       number_of_shards => 3,
    #       number_of_replicas => 1,
            "analysis" => {
                "analyzer" => {
                    "index_analyzer" => {
                        "tokenizer" => "standard",
                        "filter"    => [
    #                       "standard",     "my_delimiter",
    #                        "lowercase",
    #                         "stop",
    #                        "asciifolding", "porter_stem"
                        ]
                    },
                    "search_analyzer" => {
                        "tokenizer" => "standard",
                        "filter"    => [
    #                       "standard",
    #                       "lowercase",
    #                       "stop",     "asciifolding",
    #                       "porter_stem"
                        ]
                    }
                },
                "filter" => {
                    "my_delimiter" => {
    #                   "type"                    => "word_delimiter",
    #                   "generate_word_parts"     => 'true',
    #                   "catenate_words"          => 'true',
    #                   "catenate_numbers"        => 'true',
    #                   "catenate_all"            => 'true',
    #                   "split_on_case_change"    => 'true',
    #                   "preserve_original"       => 'true',
    #                   "split_on_numerics"       => 'true',
    #                   "stem_english_possessive" => 'true',
    #                   auto_create_index         => 1,
                    }
                }
            }
        }
    );
    sleep 1;

    my $result = $es->put_mapping(
        index => 'myapp',
        type  => 'product',
        "mapping" => {
            _source => { compress => 1, },
            "properties" => {
                "id" => {
                    "index" => "analyzed",
                    "type" => "integer",
                    "index_analyzer" => "index_analyzer",
                    "search_analyzer" => "search_analyzer",
                    "store" => "yes"
                },
                "name" => {
                    "index" => "analyzed",
                    "type" => "string",
                    "index_analyzer" => "index_analyzer",
                    "search_analyzer" => "search_analyzer",
                    "store" => "yes"
                },
                "category_id" => {
                    "index" => "analyzed",
                    "type" => "integer",
                    "index_analyzer" => "index_analyzer",
                    "search_analyzer" => "search_analyzer",
                    "store" => "yes"
                },
                "price" => {
                    "index" => "analyzed",
                    "type" => "double",
                    "index_analyzer" => "index_analyzer",
                    "search_analyzer" => "search_analyzer",
                    "store" => "yes"
                },
                "price_high" => {
                    "index" => "analyzed",
                    "index_analyzer" => "index_analyzer",
                    "search_analyzer" => "search_analyzer",
                    "type" => "double"
                },
                "price_low" => {
                    "index" => "analyzed",
                    "index_analyzer" => "index_analyzer",
                    "search_analyzer" => "search_analyzer",
                    "type" => "double"
                }
            }
        }
    );
    sleep 1;

    my $result = $es->create(
        index => 'myapp',
        type  => 'product',
            id => 1,
        data  => {
            "name" => "Shampoo Biolift with Joy and Ashes",
            "category_id" => "5",
            "price" => "6.3931",
            "price_high" => "12.731",
            "price_low" => "4.91"
        }
    );
    sleep 1;
    my $result = $es->create(
        index => 'myapp',
        type  => 'product',
            id => 2,
        data  => {
            "name" => "Notebook ASUS 16GB 1TB 17in",
            "category_id" => "2",
            "price" => "1945.3931",
            "price_high" => "2500.61",
            "price_low" => "1800.15"
        }
    );
    sleep 1;
    my $result = $es->create(
        index => 'myapp',
        type  => 'product',
            id => 3,
        data  => {
            "name" => "Notebook VAIO 8GB 1TB 14in",
            "category_id" => "2",
            "price" => "1045.3931",
            "price_high" => "1765.21",
            "price_low" => "780.66"
        }
    );
    sleep 1;
    my $result = $es->create(
        index => 'myapp',
        type  => 'product',
            id => 4,
        data  => {
            "name" => "Notebook HP 2GB 500GB 14in",
            "category_id" => "2",
            "price" => "945.3931",
            "price_high" => "1000.6731",
            "price_low" => "645.91"
        }
    );
    sleep 1;

    my $result = $es->get(
        index => 'myapp',
        type  => 'product',
        id    => 1,
    );
    sleep 1;

    my $result = $es->get(
        index => 'myapp',
        type  => 'product',
        id    => 2,
    );
    sleep 1;

    my $result = $es->search(
        index => 'myapp',                         #or undef, (all)
        type  => ['product'],                     #or ['user','product']
        query => { text => { name => 'asus' } }
    );
    sleep 1;

    my $result = $es->search(
        index => 'myapp',                            #or undef, (all)
        type  => ['product'],                        #or ['user','product']
        query => { text => { name => 'shampoo' } }
    );
    sleep 1;

    my $item = $es->search(
        {
            index => 'myapp',
            type  => 'product',
            query => { "range" => { "price" => { "gte" => "970" } } }
        }
    );

    my $item = $es->search(
        {
            index => 'myapp',
            type  => 'product',
            query => { "text" => { "name" => "asus" } }
        }
    );
    # my $item = $es->search(
    #     {
    #         index => 'myapp',
    #         type  => 'product',
    #         query => {
    #             "term" => { "name" => "asus" },
    #             "range" => { "price" => { "gte" => "1270" } }
    #         }
    #     }
    # );

    my $item = $es->search(
        {
            index => 'myapp',
            type  => 'product',
            query => {
                "bool" => {
                    "must" => { "term" => { "name" => "asus" } },
                    "must" => { "range" => { "price" => { "gte" => "800" } } }
                }
            }
        }
    );

    my $item = $es->search(
        {
            index => 'myapp',
            type  => 'product',
            query => {
                "bool" => {
                    "must" => [
                        { "text" =>  { "name" => "asus" } },
                        { "range" => { "price_low" => { "gte" => 1800.15 } } },
                        { "range" => { "price_high" => { "lte" => 2500.61 } } }
                    ]
                }
            }
        }
    );

    my $item = $es->search(
        {
            index => 'myapp',
            type  => 'product',
            query => {
                "bool" => {
                    "must" => { "text" =>  { "name" => "asus" } },
                    "must" => { "range" => { "price_low" => { "gte" => 1800.15 } } },
                    "must" => { "range" => { "price_high" => { "lte" => 2500.61 } } }
                }
            }
        }
    );
    die;
    my @results = ();

    for my $i ( @{ $item->{hits}->{hits} } ) {
        push( @results, $i->{_source} );
        warn '--' . $i->{_source}->{name};
    }
    warn @results[0]->{name};
    warn @results[0]->{name};
    warn @results[0]->{name};
    warn @results[0]->{name};
    warn scalar(@results);
    return \@results;


=head2 AUTHOR

    If you liked this article, i am accepting donations at:
    Hernan Lopes  C<< <hernanlopes____gmail.com> >>

=cut

1;
# The preceding line will help the module return a true value

