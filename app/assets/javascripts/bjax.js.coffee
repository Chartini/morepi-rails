###
bjax
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
###

$ = jQuery

$.bjax = (batch, settings) ->
  ###
  If batch exists, append the current settings object to the batch for later execution.
  If batch is null, just make a direct ajax request.
  ###
  if batch?
    batch.add(settings)
  else
    if settings.type == 'GET'
      if settings.cache != true #Don't override if cache explicitly set to true
        settings.cache = false
    $.ajax(settings)
  return

$.bjax.batchPath = "/api/0.0/batch/" #This is the default location for the batch method, available for override.

class $.AjaxBatch
  constructor: (@onBatchAdded) ->
    @calls = []
    @onBatchAdded = @onBatchAdded ? (count) ->
    return
  
  getCount: () ->
    return @calls.length
    
  add: (settings) ->
    @calls.push(settings)
    @onBatchAdded(@calls.length)
    return
  
  execute: (@callback, @errorCallback) ->
    if @calls.length == 0
      return false
      
    if not @callback?
      @callback = ->
    
    if not @errorCallback?
      @errorCallback = ->
    
    successCallback = (response) =>
      @callback(response)
      @batchComplete(response)
      
    failureCallback = (response) =>
      @errorCallback(response)
    
    $.ajax({
      url: $.bjax.batchPath,
      type: "POST",
      data: JSON.stringify({"batch":@calls}),
      success: successCallback
      error: failureCallback
    })
    
    return true
  
  batchComplete: (response) ->
    for itemResponse, i in response.responses
      if i >= @calls.length then continue
      
      sourceCall = @calls[i]
      if sourceCall.success?
        sourceCall.success(itemResponse)
      
    return true
