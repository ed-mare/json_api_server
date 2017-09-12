module FactoryHelper
  def delete_all_records
    Topic.delete_all
    Comment.delete_all
    User.delete_all
    Publisher.delete_all
  end
end
