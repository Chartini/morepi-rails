=begin
MorePi - Mock RESTful API
Copyright (c) 2011 Jason Stehle

Permission is hereby granted, free of charge, to any person obtaining 
a copy of this software and associated documentation files (the 
"Software"), to deal in the Software without restriction, including 
without limitation the rights to use, copy, modify, merge, publish, 
distribute, sublicense, and/or sell copies of the Software, and to 
permit persons to whom the Software is furnished to do so, subject to 
the following conditions:

The above copyright notice and this permission notice shall be 
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, 
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF 
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND 
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE 
LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION 
OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION 
WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
=end

class KeyItem
  attr_accessor :key
  attr_accessor :collection
  attr_accessor :item_id
  
  def initialize(key, collection, item_id)
    @key = key
    @collection = collection
    @item_id = item_id
  end
  
  def to_s()
    return {"key"=>key, "collection"=>collection, "item_id"=>item_id}
  end
end

class RequestBody
  attr_accessor :read
end

class BatchRequest
  attr_accessor :method
  attr_accessor :body
  attr_accessor :GET
  
  def initialize()
    @body = RequestBody.new()
  end
end

class MorepiController < ApplicationController

  def initialize()
    if not $mock_dict
      $mock_dict = {}
    end
  end
  
  def status_message(success, message)
    return {"success"=>success, "message"=>message}
  end

  def get_req_properties(req, raw_path)
    """Get the mock_dict_key for the item collection, and the item key from the URL where available."""
    if raw_path == ""
      return KeyItem.new('', '', '')
    end
    
    if not raw_path =~ /\/$/ then raw_path += '/' end
    
    if raw_path.count('/') % 2 == 0 #It's an item: collection/id/
      parts = raw_path.split('/')
      collection_name = parts[parts.length - 2]
      
      divider_slash = raw_path.rindex('/', -2)
      key = raw_path[0..divider_slash]
      item = raw_path[(divider_slash + 1)..-2]
      
      return KeyItem.new(key, collection_name, item)
    else #It's a collection
      parts = raw_path.split('/')
      collection_name = parts[parts.length - 1]
      return KeyItem.new(raw_path, collection_name, nil)
    end
  end

  def get_collection(rp)
    """Get the item collection based on the provided req properties."""
    if not $mock_dict.include? rp.key
      $mock_dict[rp.key] = {"next_id"=> 0, "items"=> {}}
    end
    return $mock_dict[rp.key]
  end

  def get_item(ki)
    """Get the item from the item collection based on the provided req properties."""
    collection = get_collection(ki)
    if not collection["items"].include? ki.item_id
      return nil
    else
      return collection["items"][ki.item_id]
    end
  end

  def list_filter(item, key, value)
    """Filter the list of items by the given key and value. Absence of the key is a miss."""
    return (item.include? key) ? item[key] == value : false
  end

  def mock_get(req, raw_path)
    """Get an item or collection."""
    rp = get_req_properties(req, raw_path)
    
    if rp.item_id != nil #It's an item, look it up and return it if you can.
      item = get_item(rp)
      if item != nil
        return item
      else
        return status_message(false, "Item #{rp.item_id} does not exist in #{rp.key}.")
      end
    else #It's a collection, return the items for this key.
      collection_holder = {}
      filtered_items = get_collection(rp)["items"].values()
      
      #Apply any filters to the list.
      for filter_key in req.GET.keys()
        if filter_key != '_' #Ignore jQuery cache argument
          filter_value = req.GET[filter_key]
          filtered_items = filtered_items.select{|item| list_filter(item, filter_key, filter_value) }.collect{|item| item}
        end
      end
      collection_holder[rp.collection] = filtered_items
    
      return collection_holder
    end
  end

  def mock_post(req, raw_path)
    """Either update an individual item or create a new item."""
    rp = get_req_properties(req, raw_path)
    collection = get_collection(rp)
  
    if rp.item_id != nil #It's an item, overlay passed values.
      if collection["items"].include? rp.item_id 
        collection["items"][rp.item_id].update(ActiveSupport::JSON.decode(req.body.read))
      else
        collection["items"][rp.item_id] = ActiveSupport::JSON.decode(req.body.read)
      end
      return status_message(true, "Item #{rp.item_id} saved to #{rp.key}.")

    else #It's a collection, create item
      next_id = collection["next_id"].to_s()
      collection["next_id"] += 1
      item_json = req.body.read.sub('___id___', next_id) #Replace the embedded id placeholder with the actual ID.
      collection["items"][next_id] = ActiveSupport::JSON.decode(item_json)
      return status_message(true, next_id)
    end
  end

  def mock_put(req, raw_path)
    """Replace or create an individual item at a specific key."""
    rp = get_req_properties(req, raw_path)
    collection = get_collection(rp)
  
    if rp.item_id != nil #It's an item, overwrite it
      collection["items"][rp.item_id] = ActiveSupport::JSON.decode(req.body.read)
      collection["next_id"] += 1
      return status_message(true, "Item #{rp.item_id} saved to #{rp.key}.")
    end
    return status_message(false, "Operation undefined.")
  end

  def mock_delete(req, raw_path)
    """Delete an item or collection."""
    rp = get_req_properties(req, raw_path)
    collection = get_collection(rp)
  
    if rp.item_id != nil #It's an item, delete existing item
      if collection["items"].include? rp.item_id
        collection["items"].delete(rp.item_id)
      end
      return status_message(true, "Item #{rp.item_id} deleted from #{rp.key}.")
    else #It's a collection, delete the collection
      if $mock_dict.include? rp.key
        $mock_dict.delete(rp.key)
      end
      return status_message(true, "Deleted collection.")
    end
  end

  def mock_req_processor(req, raw_path)
    """Handle a normal API call."""
    if raw_path == "" or raw_path == nil
      return mock_req_root(req, raw_path)
    end
  
    if req.method == 'GET'
      return mock_get(req, raw_path)
    elsif req.method == 'POST'
      return mock_post(req, raw_path)
    elsif req.method == 'PUT'
      return mock_put(req, raw_path)
    elsif req.method == 'DELETE'
      return mock_delete(req, raw_path)
    else
      return status_message(false, "Baffled by req method #{req.method}!")
    end
  end

  def batch_substitute(raw_path, responses)
    """Replace placeholder tokens with values from previous batch responses."""
    i= 0
    searchPattern = /\{\{\{([^\}]+)/
    subPattern = /\{\{\{([^\}]+)\}\}\}/
  
    while true
      res = raw_path.match(searchPattern) #re.search(searchPattern, raw_path)
      if res != nil
        extraction = res[1]
        parts = extraction.split(".")
        #reference = parts[0] #should always be "responses" for now.
        position = Integer(parts[1])
        key = parts[2]
        value = responses[position][key]
        raw_path = raw_path.sub(subPattern, value.to_s())   #re.sub(subPattern, str(value), raw_path, 1) # sub(pattern, repl, string, count)
      else
        break
      end
    
      i += 1
      if i > 20
        logger.info "Too many batch substitution loops."
        break
      end
    end
    return raw_path
  end

  def mock_req_batch(req, raw_path)
    """Handle a req batch."""
  
    base_api_url = req.path.sub(raw_path, "")
    batch_items = ActiveSupport::JSON.decode(req.body.read)
    responses = []
    for item in batch_items["batch"]
      batch_req = BatchRequest.new() #Mock a req object for each batch item.
      batch_req.method = item["type"]
    
      if item.include? "data"
        batch_req.body.read = batch_substitute(item["data"], responses)
      else
        batch_req.body.read = "" #it quacks like a duck
      end
      
      base_url = batch_substitute(item["url"], responses)
      
      logger.info "Batch item: " + item["type"] + " " + base_url + " (" + item["url"] + ")"
      
      batch_item_path = base_url.sub(base_api_url, "")
      batch_req.GET = {}
      query_delim_loc = batch_item_path.index('?')
      
      if query_delim_loc != nil
        query_start = query_delim_loc + 1
        batch_req.GET = Rack::Utils.parse_nested_query(batch_item_path[query_start..-1])
        batch_item_path = batch_item_path[0..query_delim_loc - 1]
      end
    
      responses.push(mock_req_processor(batch_req, batch_item_path))
    end
    return {"responses"=>responses, "success"=>true}
  end

  def purge_everything()
    """Clear the mock dictionary and any collection properties."""
    $mock_dict = {}
  end

  def mock_req_root(req, raw_path)
    """Handle an API call to the root."""
    if req.method == 'GET' #Return the entire database
      return $mock_dict
    elsif req.method == 'DELETE' #Wipe everything
      purge_everything()
      return status_message(true, "Deleted all collections and properties.")
    else
      return status_message(false, "Baffled by #{req.method}!")
    end
  end
  
  def api
    raw_path = params[:path]
    req = request

    begin
      if raw_path == "batch"
        render :json => mock_req_batch(req, raw_path)
      else
        render :json => mock_req_processor(req, raw_path)
      end
    rescue Exception => exc
        render :json => status_message(false, exc.message)
    end
  end
end
