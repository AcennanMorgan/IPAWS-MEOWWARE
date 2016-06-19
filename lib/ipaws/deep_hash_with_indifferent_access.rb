require 'thor/core_ext/hash_with_indifferent_access'
# A hash with indifferent access and magic predicates.
#
#   hash = Thor::CoreExt::HashWithIndifferentAccess.new 'foo' => 'bar', 'baz' => 'bee', 'force' => true
#
#   hash[:foo]  #=> 'bar'
#   hash['foo'] #=> 'bar'
#   hash.foo?   #=> true
#
module Ipaws
  class DeepHashWithIndifferentAccess#:nodoc:
    #HashWithIndifferentAccess does not convert the hash deeply so we must do this ourselves :(
    def self.convert_hash(hash)
      # NOTE (cmhobbs) this can be cleaned up with Object#tap
      new_hash = Thor::CoreExt::HashWithIndifferentAccess.new
      hash.each do |key, value|
        if value.is_a? Hash
          new_hash[key] = convert_hash value
        elsif value.is_a? Array
          new_hash[key] = convert_array value
        else
          new_hash[key] = value
        end
      end
      new_hash
    end

    def self.convert_array(arr)
      # NOTE (cmhobbs) this can be cleaned up with Object#tap
      new_array = []
      arr.each do |value|
        if value.is_a? Hash
          new_array << (convert_hash value)
        elsif value.is_a? Array
          new_array << (convert_array value)
        else
          new_array << value
        end
      end
      new_array
    end
  end
end
