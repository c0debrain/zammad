# Copyright (C) 2012-2014 Zammad Foundation, http://zammad-foundation.org/

class RecentView < ApplicationModel
  belongs_to :object_lookup,           :class_name => 'ObjectLookup'

  def self.log( object, user )

    # lookups
    object_lookup_id = ObjectLookup.by_name( object.class.to_s )

    # create entry
    record = {
      :o_id              => object.id,
      :object_lookup_id  => object_lookup_id.to_i,
      :created_by_id     => user.id,
    }
    RecentView.create(record)
  end

  def self.log_destroy( requested_object, requested_object_id )
    RecentView.where( :object_lookup_id => ObjectLookup.by_name( requested_object ) ).
    where( :o_id => requested_object_id ).
    destroy_all
  end

  def self.user_log_destroy( user )
    RecentView.where( :created_by_id => user.id ).destroy_all
  end

  def self.list( user, limit = 10 )
    recent_views = RecentView.where( :created_by_id => user.id ).
    order('created_at DESC, id DESC').
    limit(limit)

    list = []
    recent_views.each { |item|
      data = item.attributes
      data['object'] = ObjectLookup.by_id( data['object_lookup_id'] )
      data.delete( 'object_lookup_id' )
      list.push data
    }
    list
  end

  def self.list_fulldata( user, limit = 10 )
    recent_viewed = self.list( user, limit )

    # get related users
    assets = {}
    ticket_ids = []
    recent_viewed.each {|item|

      # get related objects
      require item['object'].to_filename
      record = Kernel.const_get( item['object'] ).find( item['o_id'] )
      assets = record.assets(assets)

    }
    return {
      :recent_viewed => recent_viewed,
      :assets        => assets,
    }
  end
  class Object < ApplicationModel
  end
end