module Spree
  class ReadOnlyError < ActiveRecord::ReadOnlyRecord; end

  class Record < ApplicationRecord
    self.abstract_class = true
    connects_to database: { writing: :spree, reading: :spree }

    READ_ONLY_MESSAGE = "Spree::Record data source is read-only".freeze

    class << self
      %i[
        create create! insert insert_all insert_all! upsert upsert_all
        update_all update_counters increment_counter decrement_counter
        touch_all delete delete_all delete_by destroy_all destroy_by
        find_or_create_by find_or_create_by! first_or_create first_or_create!
      ].each do |method_name|
        define_method(method_name) do |*_args, **_kwargs, &_block|
          raise ReadOnlyError, READ_ONLY_MESSAGE
        end
      end
    end

    def readonly?
      true
    end

    def delete(*)
      raise ReadOnlyError, self.class::READ_ONLY_MESSAGE
    end

    def destroy(*)
      raise ReadOnlyError, self.class::READ_ONLY_MESSAGE
    end

    def destroy!(*)
      raise ReadOnlyError, self.class::READ_ONLY_MESSAGE
    end

    def touch(*)
      raise ReadOnlyError, self.class::READ_ONLY_MESSAGE
    end

    def update_columns(*)
      raise ReadOnlyError, self.class::READ_ONLY_MESSAGE
    end

    def increment!(*)
      raise ReadOnlyError, self.class::READ_ONLY_MESSAGE
    end

    def decrement!(*)
      raise ReadOnlyError, self.class::READ_ONLY_MESSAGE
    end

    def toggle!(*)
      raise ReadOnlyError, self.class::READ_ONLY_MESSAGE
    end
  end
end
