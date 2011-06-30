module ActsAsTaggableOnPadrino::Taggable
  module Cache
    def self.included(base)
      # Skip adding caching capabilities if table not exists or no cache columns exist
      return unless base.table_exists? && base.tag_types.any? { |context| base.column_names.include?("cached_#{context.to_s.singularize}_list") }

      base.send :include, ActsAsTaggableOnPadrino::Taggable::Cache::InstanceMethods
      base.extend ActsAsTaggableOnPadrino::Taggable::Cache::ClassMethods

      base.class_eval do
        before_save :save_cached_tag_list
      end

      base.initialize_acts_as_taggable_on_cache
    end

    module ClassMethods
      def initialize_acts_as_taggable_on_cache
        tag_types.each do |tag_type|
          class_eval %(
            def self.caching_#{tag_type.to_s.singularize}_list?
              caching_tag_list_on?("#{tag_type}")
            end
          )
        end
      end

      def acts_as_taggable_on(*args)
        super
        initialize_acts_as_taggable_on_cache
      end

      def caching_tag_list_on?(context)
        column_names.include?("cached_#{context.to_s.singularize}_list")
      end
    end

    module InstanceMethods
      def save_cached_tag_list
        tag_types.each do |tag_type|
          tag_type = tag_type.to_s.singularize
          if self.class.send("caching_#{tag_type}_list?")
            if tag_list_cache_set_on(tag_type)
              list = tag_list_cache_on(tag_type).to_a.flatten.compact.join(', ')
              self["cached_#{tag_type}_list"] = list
            end
          end
        end

        true
      end
    end
  end
end
