use Kelp::Base -strict;
use Kelp::Test;
use Test::More;
use HTTP::Request::Common;
use Whelk;
use YAML::PP;

use lib 't/lib';

my $app = Whelk->new(mode => 'openapi');
my $t = Kelp::Test->new(app => $app);

################################################################################
# This checks if the openapi seems to be generated fine
################################################################################

my $content = do {
	local $/;
	$app->yaml->decode(<DATA>);
};

$t->request(GET '/')
	->code_is(200)
	->yaml_cmp($content);

done_testing;

__DATA__
---
components:
  schemas:
    api_error_with_status:
      properties:
        error:
          type: string
        success:
          default: false
          type: boolean
      required:
      - error
      type: object
    my_boolean:
      type: boolean
    some_entity:
      properties:
        id:
          $ref: '#/components/schemas/some_entity_id'
        name:
          description: Name of the entity
          example: John's entity
          type: string
        value:
          type: integer
          nullable: true
          default: null
      required:
      - id
      - name
      type: object
    some_entity_id:
      description: Internal ID
      example: 1337
      type: integer
      minimum: 1
info:
  contact:
    email: snail@whelk.com
  description: |-
    An API (Application Programming Interface) is a set of protocols, tools, and definitions that allows different software applications to communicate with each other. APIs define the methods and data formats that applications can use to request and exchange information, enabling seamless integration between diverse systems. By providing a standardized way for applications to interact, APIs simplify the development process, allowing developers to leverage existing functionalities without having to build them from scratch. This can significantly enhance the efficiency and scalability of software projects.

    APIs can be designed for various purposes, including web services, operating systems, libraries, and databases. Web APIs, for example, enable web applications to communicate with servers over the internet, often using HTTP/HTTPS protocols. They typically follow REST (Representational State Transfer) or SOAP (Simple Object Access Protocol) architectures, each with its own conventions and best practices. RESTful APIs use standard HTTP methods like GET, POST, PUT, and DELETE, and usually return data in JSON or XML formats. By providing a clear and consistent interface, APIs empower developers to create robust, flexible, and interoperable applications that can easily integrate with other services and platforms.
  title: OpenApi/Swagger integration for Whelk
  version: 1.0.1
openapi: 3.0.3
paths:
  /api/item/{id}:
    get:
      description: Get item by ID
      parameters:
      - description: Internal ID
        in: path
        name: id
        required: true
        schema:
          $ref: '#/components/schemas/some_entity_id'
      responses:
        '200':
          content:
            application/json:
              schema:
                properties:
                  data:
                    items:
                      $ref: '#/components/schemas/some_entity'
                    type: array
                  success:
                    default: true
                    type: boolean
                required:
                - data
                type: object
          description: Success.
        '400':
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/api_error_with_status'
          description: Failure, invalid request data.
        '500':
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/api_error_with_status'
          description: Failure, server error.
      tags:
      - Whelk OpenAPI
  /requests/body:
    post:
      requestBody:
        content:
          application/json:
            schema:
              properties:
                test:
                  type: integer
              required:
              - test
              type: object
          text/yaml:
            schema:
              properties:
                test:
                  type: integer
              required:
              - test
              type: object
      responses:
        '200':
          content:
            application/json:
              schema:
                properties:
                  data:
                    type: boolean
                  success:
                    default: true
                    type: boolean
                required:
                - data
                type: object
          description: Success.
        '400':
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/api_error_with_status'
          description: Failure, invalid request data.
        '500':
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/api_error_with_status'
          description: Failure, server error.
      tags:
      - Requests test
  /requests/cookie:
    get:
      parameters:
      - in: cookie
        name: test1
        required: true
        schema:
          type: integer
      - in: cookie
        name: test2
        required: true
        schema:
          $ref: '#/components/schemas/my_boolean'
      responses:
        '200':
          content:
            application/json:
              schema:
                properties:
                  data:
                    type: boolean
                  success:
                    default: true
                    type: boolean
                required:
                - data
                type: object
          description: Success.
        '400':
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/api_error_with_status'
          description: Failure, invalid request data.
        '500':
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/api_error_with_status'
          description: Failure, server error.
      tags:
      - Requests test
  /requests/header:
    get:
      parameters:
      - in: header
        name: X-Test1
        required: true
        schema:
          type: integer
      - in: header
        name: X-Test2
        required: true
        schema:
          type: boolean
      responses:
        '200':
          content:
            application/json:
              schema:
                properties:
                  data:
                    type: boolean
                  success:
                    default: true
                    type: boolean
                required:
                - data
                type: object
          description: Success.
        '400':
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/api_error_with_status'
          description: Failure, invalid request data.
        '500':
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/api_error_with_status'
          description: Failure, server error.
      tags:
      - Requests test
  /requests/multiheader:
    get:
      parameters:
      - in: header
        name: X-Test
        required: true
        schema:
          items:
            type: integer
          type: array
      responses:
        '200':
          content:
            application/json:
              schema:
                properties:
                  data:
                    type: boolean
                  success:
                    default: true
                    type: boolean
                required:
                - data
                type: object
          description: Success.
        '400':
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/api_error_with_status'
          description: Failure, invalid request data.
        '500':
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/api_error_with_status'
          description: Failure, server error.
      tags:
      - Requests test
  /requests/multiquery:
    get:
      parameters:
      - in: query
        name: test
        required: true
        schema:
          items:
            type: integer
          type: array
      responses:
        '200':
          content:
            application/json:
              schema:
                properties:
                  data:
                    type: boolean
                  success:
                    default: true
                    type: boolean
                required:
                - data
                type: object
          description: Success.
        '400':
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/api_error_with_status'
          description: Failure, invalid request data.
        '500':
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/api_error_with_status'
          description: Failure, server error.
      tags:
      - Requests test
  /requests/path/{test1}:
    get:
      parameters:
      - in: path
        name: test1
        required: true
        schema:
          type: string
      responses:
        '200':
          content:
            application/json:
              schema:
                properties:
                  data:
                    type: boolean
                  success:
                    default: true
                    type: boolean
                required:
                - data
                type: object
          description: Success.
        '400':
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/api_error_with_status'
          description: Failure, invalid request data.
        '500':
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/api_error_with_status'
          description: Failure, server error.
      tags:
      - Requests test
  /requests/path/{test1}/{test2}:
    get:
      parameters:
      - in: path
        name: test1
        required: true
        schema:
          type: number
      - in: path
        name: test2
        required: true
        schema:
          $ref: '#/components/schemas/my_boolean'
      responses:
        '200':
          content:
            application/json:
              schema:
                properties:
                  data:
                    type: boolean
                  success:
                    default: true
                    type: boolean
                required:
                - data
                type: object
          description: Success.
        '400':
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/api_error_with_status'
          description: Failure, invalid request data.
        '500':
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/api_error_with_status'
          description: Failure, server error.
      tags:
      - Requests test
  /requests/query:
    get:
      parameters:
      - in: query
        name: def
        required: false
        schema:
          default: a default
          type: string
      - in: query
        name: test1
        required: true
        schema:
          type: integer
      - in: query
        name: test2
        required: true
        schema:
          type: boolean
      responses:
        '200':
          content:
            application/json:
              schema:
                properties:
                  data:
                    type: boolean
                  success:
                    default: true
                    type: boolean
                required:
                - data
                type: object
          description: Success.
        '400':
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/api_error_with_status'
          description: Failure, invalid request data.
        '500':
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/api_error_with_status'
          description: Failure, server error.
      tags:
      - Requests test
  /t:
    get:
      responses:
        '200':
          content:
            application/json:
              schema:
                properties:
                  data:
                    type: string
                  success:
                    default: true
                    type: boolean
                required:
                - data
                type: object
          description: Success.
        '400':
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/api_error_with_status'
          description: Failure, invalid request data.
        '500':
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/api_error_with_status'
          description: Failure, server error.
      tags:
      - Test
  /t/custom_err:
    post:
      responses:
        '400':
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/api_error_with_status'
          description: Failure, invalid request data.
        '500':
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/api_error_with_status'
          description: Failure, server error.
      tags:
      - Test
  /t/err:
    post:
      responses:
        '400':
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/api_error_with_status'
          description: Failure, invalid request data.
        '500':
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/api_error_with_status'
          description: Failure, server error.
      tags:
      - Test
  /t/nocontent:
    get:
      responses:
        '204':
          description: Success (no content).
        '400':
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/api_error_with_status'
          description: Failure, invalid request data.
        '500':
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/api_error_with_status'
          description: Failure, server error.
      tags:
      - Test
  /t/t1:
    get:
      responses:
        '200':
          content:
            application/json:
              schema:
                properties:
                  data:
                    properties:
                      id:
                        type: integer
                      name:
                        type: string
                    required:
                    - id
                    - name
                    type: object
                  success:
                    default: true
                    type: boolean
                required:
                - data
                type: object
          description: Success.
        '400':
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/api_error_with_status'
          description: Failure, invalid request data.
        '500':
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/api_error_with_status'
          description: Failure, server error.
      tags:
      - Test
servers:
- description: API for Whelk
  url: http://localhost:5000
tags:
- description: Various request routes
  name: Requests test
- description: Testing OpenAPI integration
  name: Whelk OpenAPI
- name: Test

