# SimpleJsonApi

This gem provides tools for building a JSON API per http://jsonapi.org spec (1.0).
It supports sparse fieldsets, sorting, filtering, pagination, and inclusion of
related resources. Sorting, filtering, and inclusions are whitelisted
so depth/complexity of the document can be controlled.

This library: (1) generates data for sorting, filtering,
inclusions, and pagination, (2) provides serializers and helper classes for
rendering data, and (3) handles/renders errors in JSON API format (#2 and #3
could be substituted with your own serializers and error handling). Otherwise, you
build APIs as you normally do (i.e, routes, authorization, caching, etc.).

**Use at your own risk.** This gem is under development and has not been used
in production yet. Known to work with Ruby 2.3.x and Rails 5.x.
Supports only ActiveRecord at this time.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'simple_json_api', git: 'https://github.com/ed-mare/simple_json_api.git'
# gem 'simple_json_api' # not published yet
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install simple_json_api

## Usage

**Install gem rdoc for more documentation.**

##### 1) Include SimpleJsonApi::Controller::ErrorHandling in your base API controller.

```ruby
# i.e.,
class BaseApiController < ApplicationController
  include SimpleJsonApi::Controller::ErrorHandling
end
```

Include methods which render errors per http://jsonapi.org/format/#errors:

- `render_400`, `render_401`, `render_404`, `render_409`, `render_422`, `render_500`,
`render_unknown_format`, `render_503`.

It rescues from and renders JSON API errors for:

- StandardError (render_500)
- SimpleJsonApi::BadRequest (render_400)
- ActiveRecord::RecordNotFound, ActionController::RoutingError (render_404)
- ActiveRecord::RecordNotUnique (render_409)
- ActionController::RoutingError (render_404)
- ActionController::UnknownFormat (render_unknown_format 406)

Use `render_422(object)` to render validation errors in controllers.

##### 2) Include SimpleJsonApi::MimeTypes in initializers

From the spec: "JSON API requires use of the JSON API media type
(application/vnd.api+json) for exchanging data." To support this mime type:

```ruby
# can also add this
# Mime::Type.unregister :json

# in config/initializers/mime_types.rb
include SimpleJsonApi::MimeTypes
```

##### 3) Use SimpleJsonApi::Builder to collect data in the controller.

This class integrates JSON API features -- pagination, sorting, filters, inclusion of
related resources, and sparse fieldsets -- in one place. It collects data to be used
by serializers.

It uses these classes to construct the data:

- SimpleJsonApi::Pagination
- SimpleJsonApi::Sort
- SimpleJsonApi::Filter
- SimpleJsonApi::Include
- SimpleJsonApi::Fields

Please see each class's rdoc for configuration options.

**Example**:

```ruby
class TopicsController < BaseApiController
  attr_accessor :pagination_options, :sort_options, :filter_options, :include_options

  before_action do |c|
    # Set limits on max number of records to return.
    c.pagination_options = { default_per_page: 10, max_per_page: 60 }

    # Whitelist sortable attributes and default sort..
    c.sort_options = {
     permitted: [:character, :location, :published],
     default: { id: :desc }
    }

    # Whitelist filters and configure how to perform the query. There are built-in
    # query builder classes; custom classes can be plugged in.
    c.filter_options = [
     { id: { type: 'Integer' } },
     { published: { type: 'Date' } },
     :location,
     { book: { wildcard: :both } }
    ]

    # Whitelist inclusions and optionally configure eagerloading.
    c.include_options = [
                          {'publisher': -> { includes(:publisher) }},
                          {'comments': -> { includes(:comments) }},
                          'comment.author'
                        ]
  end

  # Resources.
  def index
    builder = SimpleJsonApi::Builder.new(request, Topic.current)
     .add_pagination(pagination_options)
     .add_filter(filter_options)
     .add_include(include_options)
     .add_sort(sort_options)
     .add_fields

   serializer = TopicsSerializer.from_builder(builder)
   render json: serializer.to_json, status: :ok
  end

  # A resource.
  def show
    builder = SimpleJsonApi::Builder.new(request, Topic.find(params[:id]))
     .add_include(['publisher', 'comments', 'comments.includes'])
     .add_fields

    serializer = TopicSerializer.from_builder(builder)
    render json: serializer.to_json, status: :ok
  end

  def create
    topic = Topic.new(topic_params)

    if topic.save
     serializer = TopicSerializer.new(topic)
     render json: serializer.to_json, status: :created
   else
     render_422(topic)  # return validation errors as JSON API errors.
   end    
  end

  protected

  def topic_params
    params.require(:data)
          .require(:attributes)
          .permit(:character, :book, :quote, :location, :published,
                  :author, :publisher_id)
  end

end
```

##### 4) Create Serializers

SimpleJsonApi serializers use the oj gem (https://github.com/ohler55/oj), a fast JSON parser
and Object marshaller. These classes provide a skeleton JSON API response which
you fill out in a jbuilder-like way. Helper classes (SimpleJsonApi::AttributesBuilder,
SimpleJsonApi::RelationshipsBuilder, SimpleJsonApi::Paginator, SimpleJsonApi::MetaBuilder)
assist with sparse fieldsets, relationships, pagination and meta information
(http://jsonapi.org/format/#document-meta). No caching is built into the serializers
given the variability of JSON API documents. Low level record caching is more suitable.

---

SimpleJsonApi::BaseSerializer is the base serializer. All inherit from this class. This is the
structure when `as_json` is called (without data added):

```ruby
{
 ":jsonapi": {
   ":version": "1.0"
 },
 ":links": null,
 ":data": null,
 ":included": null,
 ":meta": null
}
```

Sometimes only part of document is needed, for example, when embedding one serializer in another.
`as_json` takes an optional hash argument which determines which parts of the document to return.
These options can also be set in the SimpleJsonApi::BaseSerializer#as_json_options attribute.

```ruby
serializer.as_json(include: [:data]) # => { data: {...} }
serializer.as_json(include: [:links]) # => { links: {...} }
serializer.as_json(jsonapi: false, meta: false, included: false) # =>
# {
#   links: {...},
#   data: {...}
# }

```

---

SimpleJsonApi::ResourceSerializer inherits from SimpleJsonApi::BaseSerializer --
intended for a resource (i.e, comment, topic, author). Instantiate with a
SimpleJsonApi::Builder instance:

**Example**:

```ruby
class TopicSerializer < SimpleJsonApi::ResourceSerializer

  def links
    { self: File.join(base_url, "/topics/#{@object.id}") }
  end

  def data
    {
      type: 'topics',
      id: @object.id,
      attributes: attributes,
      relationships: relationships.relationships
    }
  end

  def included
    relationships.included
  end

  protected

  def attributes
    attributes_builder_for('topics')
      .add('book', @object.book)
      .add('author', @object.author)
      .add('quote', @object.quote)
      .add('character', @object.character)
      .add('location', @object.location)
      .add('published', @object.published)
      .add('created_at', @object.created_at.try(:iso8601, 9))
      .add('updated_at', @object.updated_at.try(:iso8601, 9))
      .attributes
  end

  # Example: provide different ways of accessing the same relationship data:
  #
  # 1) 'comments' puts all data in the relationship (easier to walk the tree).
  # 2) 'comments.includes' puts data in the included section and relationship
  # links to it.
  def relationships
    @relationships ||= begin
      if relationship?('publisher')
        relationships_builder.relate('publisher', publisher_serializer(@object.publisher))
      end
      if relationship?('comments')
        relationships_builder.relate_each('comments', @object.comments) { |c| comment_serializer(c) }
      elsif relationship?('comments.includes')
        relationships_builder.include_each('comments.includes', @object.comments, type: 'comments',
            relate: {include: [:relationship_data]}) { |c| comment_serializer(c) }
      end

      relationships_builder
    end
  end

  # Pass includes and fields to child serializers.
  def publisher_serializer(publisher, as_json_options=nil)
    PublisherSerializer.new(publisher, includes: includes, fields: fields,
      as_json_options: as_json_options || {include: [:data]})
  end

  # Pass includes and fields to child serializers.
  def comment_serializer(comment, as_json_options=nil)
    CommentSerializer.new(comment,  includes: includes, fields: fields,
      as_json_options: as_json_options || {include: [:data]})
  end

end
```

Helper methods:

- SimpleJsonApi::ResourceSerializer#attributes_builder_for -- returns an instance of
SimpleJsonApi::AttributesBuilder for type (i.e., comment, topic, etc.).
- SimpleJsonApi::ResourceSerializer#relationships_builder -- returns an instance of
SimpleJsonApi::RelationshipsBuilder with whitelisted includes.
- SimpleJsonApi::ResourceSerializer#fields_for(type) -- sparse fields requested by user for a type.

---

SimpleJsonApi::ResourcesSerializer inherits from SimpleJsonApi::ResourceSerializer --
intended for a collection of resources (i.e, comments, topics, authors). Serializes
a collection of objects to a specified serializer and merges them into one document.

Generates

**Example**:

```ruby
class TopicSerializer < SimpleJsonApi::ResourceSerializer
  ...
end

class TopicsSerializer < SimpleJsonApi::ResourcesSerializer
  serializer TopicSerializer
end

builder = SimpleJsonApi::Builder.new(request, Topic.current)
 .add_pagination(pagination_options) # populates links section
 .add_filter(filter_options)
 .add_include(include_options)
 .add_sort(sort_options)
 .add_fields

serializer = TopicsSerializer.from_builder(builder)
```

## Development

1. Build the docker image:

```shell
docker-compose build
```

2. Start docker image with an interactive bash shell:

```shell
docker-compose run --rm gem
```

3. Once in bash session, code, run tests, start console, etc.

```shell
# run console with gem loaded
bundle console

# run tests - to be run from root of gem
bundle exec rspec

# generate rdoc
rdoc --main 'README.md' --exclude 'spec' --exclude 'bin' --exclude 'Gemfile' --exclude 'Dockerfile' --exclude 'Rakefile'
```

## Todo

- Test against multiple rubies and rails.
- Clean up tests, esp. as_json which are brittle.
- Test against Postgres.
- Test examples with complex relationships.
- Support Mongoid.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/ed-mare/simple_json_api. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
