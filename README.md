# SimpleJsonApi

This gem provides tools for building JSON APIs per http://jsonapi.org spec (1.0).
It supports sparse fieldsets, sorting, filtering, pagination, and inclusion of
related resources. Sorting, filtering, and inclusions are whitelisted
so depth/complexity can be controlled.

This library: (1) generates data for sorting, filtering,
inclusions, and pagination, (2) provides serializers and helper classes for
building the response with this data, and (3) handles/renders errors in JSON API format.
Otherwise, you build your APIs as you normally do (i.e, routes, authorization,
caching, etc.).

Use at your own risk. This gem is under development and has not been used
in production yet. Known to work with Ruby 2.3.x and Rails 5.x.
Supports only ActiveRecord at this time.

- **Example app** -> https://github.com/ed-mare/simplejsonapi-example
- **Documentation** -> Install gem rdoc for more documentation.

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

Install gem rdoc for more documentation.

##### 1) Include SimpleJsonApi::Controller::ErrorHandling in your base API controller.

```ruby
# i.e.,
class BaseApiController < ApplicationController
  include SimpleJsonApi::Controller::ErrorHandling
end
```

It provides methods which render errors per http://jsonapi.org/format/#errors:

- `render_400`, `render_401`, `render_404`, `render_409`, `render_422`, `render_500`,
`render_unknown_format`, `render_503`.

It rescues from and renders JSON API errors for:

- StandardError (render_500)
- SimpleJsonApi::BadRequest (render_400)
- ActionController::BadRequest (render_400)
- ActiveRecord::RecordNotFound, ActionController::RoutingError (render_404)
- ActiveRecord::RecordNotUnique (render_409)
- ActionController::RoutingError (render_404)
- ActionController::UrlGenerationError (render_404)
- ActionController::UnknownController (render_404)
- ActionController::UnknownFormat (render_unknown_format 406)

Additionally:

- Use `render_422(object)` in controllers to render validation errors.

Error messages are defined in 'config/locales/en.yml' and can be customized
or redefined.

i.e.,

```ruby
# Given a sandwiches controller...
class Api::V1::SandwichesController < Api::BaseController
    ...
end

# config/locales/en.yml
en:
  simple_json_api:
    controller:
      sandwiches:
        name: 'sandwich'

# messages now become:
# 404 => "This sandwich does not exist."
# 409 => "This sandwich already exists."
```

##### 2) Include SimpleJsonApi::MimeTypes in initializers

Spec: "JSON API requires use of the JSON API media type
(application/vnd.api+json) for exchanging data."

To support this mime type:

```ruby
# config/initializers/mime_types.rb
include SimpleJsonApi::MimeTypes
```
##### 3) Configure the gem

Configure the logger, base URL, serialization options and filter builders.

```ruby
# config/initializers/simple_json_api.rb
SimpleJsonApi.configure do |c|
  c.base_url = 'https://www.something.com'
  c.logger = Rails.logger
  c.serializer_options = {
        escape_mode: :json,
        time: :xmlschema,
        mode: :compat
      }
end
```

Optionally, set this Rails config so '`&`' is not escaped in pagination URLs:

```ruby
# application.rb
config.active_support.escape_html_entities_in_json = false
```

##### 4) Use SimpleJsonApi::Builder to collect data in the controller.

This class handles pagination, sorting, filters, inclusion of
related resources, and sparse fieldsets. It collects the necessary data for the
serializers.

This class uses the following classes. See each class's rdoc for configuration options.

- SimpleJsonApi::Pagination
- SimpleJsonApi::Sort
- SimpleJsonApi::Filter
- SimpleJsonApi::Include
- SimpleJsonApi::Fields

A variety of search capabilities can be configured for model attributes with
`SimpleJsonApi::Filter` - LIKE queries, ILIKE queries (Postgres), IN queries,
comparison queries, range queries, and queries against Postgres jsonb arrays
(case sensitive/insensitive). Plus, custom queries and custom filters can be easily
added.

**Example**:

```ruby
class TopicsController < BaseApiController
  attr_accessor :pagination_options, :sort_options, :filter_options, :include_options

  before_action do |c|
    # Set a limit on the maximum number of records a user can request per page.
    # Set the default number of records per page.
    c.pagination_options = { default_per_page: 10, max_per_page: 60 }

    # Whitelist sortable attributes and set default sort.
    c.sort_options = {
       permitted: [:character, :location, :published],
       default: { id: :desc }
    }

    # Whitelist filters and configure how to perform the query. There are built-in
    # query builder classes and custom classes can be plugged in.
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

  def index
    # collect the data
    builder = SimpleJsonApi::Builder.new(request, Topic.current)
     .add_pagination(pagination_options)
     .add_filter(filter_options)
     .add_include(include_options)
     .add_sort(sort_options)
     .add_fields

   # pass the data to the serializer
   serializer = TopicsSerializer.from_builder(builder)
   render json: serializer.to_json, status: :ok
  end

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
       render_422(topic)  # return validation errors in JSON API format.
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

##### 5) Create Serializers

SimpleJsonApi serializers use the oj gem (https://github.com/ohler55/oj), a fast JSON parser
and Object marshaller. Helper classes
SimpleJsonApi::AttributesBuilder (sparse fieldsets), SimpleJsonApi::RelationshipsBuilder
(relationships/included), SimpleJsonApi::Paginator (pagination), and SimpleJsonApi::MetaBuilder (meta)
 assist with populating serializers.

Caching is not built into the serializers
given the variability of JSON API documents. Low level caching is recommended.

---

All serializers inherit from SimpleJsonApi::BaseSerializer. It creates this structure:

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

Sometimes only part of document is needed, i.e., when embedding one serializer in another.
`as_json` takes an optional hash argument which determines which parts of the document to return.
These options can also be set in SimpleJsonApi::BaseSerializer#as_json_options.

```ruby
serializer.as_json(include: [:data]) # => { data: {...} }
serializer.as_json(include: [:links]) # => { links: {...} }
serializer.as_json(include: [:links, :data]) # =>
# {
#   links: {...},
#   data: {...}
# }
```

---

SimpleJsonApi::ResourceSerializer inherits from SimpleJsonApi::BaseSerializer.
It is intended for a single resource (i.e, comment, author). Instantiate with a
SimpleJsonApi::Builder instance:

**Example**:

```ruby
class TopicSerializer < SimpleJsonApi::ResourceSerializer
  resource_type 'topics'

  def links
    { self: File.join(base_url, "/topics/#{@object.id}") }
  end

  def data
    {
      type: self.class.type,
      id: @object.id,
      attributes: attributes,
      relationships: inclusions.relationships
    }
  end

  def included
    inclusions.included
  end

  protected

  def attributes
    attributes_builder
      .add_multi(@object, 'book', 'author', 'quote', 'character')
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
  def inclusions
    @inclusions ||= begin
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

# instantiate in controller...
builder = SimpleJsonApi::Builder.new(request, Topic.find(params[:id]))
 .add_include(['publisher', 'comments', 'comments.includes'])
 .add_fields
serializer = TopicSerializer.from_builder(builder)
```

Helper methods:

- SimpleJsonApi::ResourceSerializer#attributes_builder -- returns an instance of
SimpleJsonApi::AttributesBuilder for the 'type' specified in `resource_type`.
- SimpleJsonApi::ResourceSerializer#meta_builder -- returns an instance of
SimpleJsonApi::MetaBuilder for building the meta section.
- SimpleJsonApi::ResourceSerializer#relationships_builder -- returns an instance of
SimpleJsonApi::RelationshipsBuilder with whitelisted includes.
- SimpleJsonApi::ResourceSerializer#relationship? -- returns true if relationship is
requested.
- SimpleJsonApi::ResourceSerializer#inclusions? -- returns true if inclusions are
requested.
---

SimpleJsonApi::ResourcesSerializer inherits from SimpleJsonApi::ResourceSerializer.
It serializes a collection of objects with a specified serializer and merges them.
It populates the links section with pagination URLs if SimpleJsonApi::Builder#add_pagination
is called.

**Example**:

```ruby
class TopicSerializer < SimpleJsonApi::ResourceSerializer
  ...
end

class TopicsSerializer < SimpleJsonApi::ResourcesSerializer
  serializer TopicSerializer # serializer for objects
end

builder = SimpleJsonApi::Builder.new(request, Topic.current)
 .add_pagination(pagination_options)
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

- Test against multiple rubies/rails.
- Clean up tests, esp. as_json which are brittle.
- Test against Postgres.
- Support Mongoid.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/ed-mare/simple_json_api. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
