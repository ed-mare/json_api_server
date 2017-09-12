# Model collection serializer. Includes pagination links and meta info about pagination
# and filter params.
class TopicsSerializer < SimpleJsonApi::ResourcesSerializer
  serializer TopicSerializer

  def meta
    meta_builder
      .merge(@paginator.try(:meta_info))
      .merge(@filter.try(:meta_info))
      .meta
  end
end
