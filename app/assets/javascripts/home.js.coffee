###
MorePi Mock RESTful API example application script
Copyright (c) 2011 Jason Stehle

Permission is hereby granted, free of charge, to any person obtaining 
a copy of this software and associated documentation files (the 
"Software"), to deal in the Software without restriction, including 
without limitation the rights to use, copy, modify, merge, publish, 
distribute, sublicense, and/or sell copies of the Software, and to 
permit persons to whom the Software is furnished to do so, subject to 
the following conditions:

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, 
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF 
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND 
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE 
LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION 
OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION 
WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

Dependencies:
jQuery (http://jquery.com/)
Milk (https://github.com/pvande/Milk/)
###

App = {}

### BEGIN MorePi population ###

Mocks = {}

# Initial author list, with pre-assigned IDs.
Mocks.initialAuthors = [
  {"id":"0", "name":"Alfred Bester"},
  {"id":"1", "name":"Orson Scott Card"},
  {"id":"2", "name":"George RR Martin"},
  {"id":"3", "name":"Richard K Morgan"},
  {"id":"4", "name":"Chris Moriarty"},
  {"id":"5", "name":"Tim Powers"},
]

# Initial book list, with dynamically assigned IDs. "___id___" is replaced by the assigned ID during item creation.
Mocks.initialBooks = [
  {"id":"___id___", "name":"The Stars My Destination", "author":"0"},
  {"id":"___id___", "name":"The Demolished Man", "author":"0"},
  {"id":"___id___", "name":"Spin State", "author":"4"},
  {"id":"___id___", "name":"Spin Control", "author":"4"},
  {"id":"___id___", "name":"Altered Carbon", "author":"3"},
  {"id":"___id___", "name":"Broken Angels", "author":"3"},
  {"id":"___id___", "name":"Woken Furies", "author":"3"},
  {"id":"___id___", "name":"The Anubis Gates", "author":"5"},
  {"id":"___id___", "name":"Last Call", "author":"5"},
  {"id":"___id___", "name":"Ender's Game", "author":"1"},
]

# Deletes any existing mock data on the back end and generates the starter data.
App.resetData = () ->
  batch = new $.AjaxBatch()
  
  # Purge existing data from the back end.
  $.bjax(batch, {
      url: "/api/0.0/",
      type: "DELETE",
    })
  
  # Create a book entry for each book in the initialBooks collection.
  for book in Mocks.initialBooks
    $.bjax(batch, {
      url: "/api/0.0/books/",
      type: "POST",
      data: JSON.stringify(book)
    })
  
  requestCount = batch.getCount()
  
  # Add chapters for each book just created
  for i in [1...requestCount] by 1
    for c in [0..i] #for a variable number of chapters.
      $.bjax(batch, {
        url: "/api/0.0/books/{{{responses.#{i}.message}}}/chapters/", #References the returned ID from the previously created books
        type: "POST",
        data: JSON.stringify({"id":"___id___", "name":"Chapter #{c + 1}"}) # "___id___" is replaced by the assigned ID during item creation.
      })
  
  # Add authors
  for author in Mocks.initialAuthors
    $.bjax(batch, {
      url: "/api/0.0/authors/#{author.id}/",
      type: "PUT",
      data: JSON.stringify(author)
    })
  
  batch.execute(App.resetView)
  return

### END MorePi population ###


App.loadMustacheTemplates = (templatesHtml) -> #Loads templates into master dictionary
  parts = templatesHtml.split("~~~~");
  templates = {}
  key = null
  for i in [0...parts.length] by 1
    if i == 0
      continue
    if i % 2 == 1
      key = parts[i]
    else
      templates[key] = parts[i]
      
  Milk.partials = templates
  return


App.templates = '
~~~~books_list~~~~
<h2>Books</h2>
{{>book_table}}


~~~~book_table~~~~
{{#books.length}}
  <table>
  {{#books}}
    <tr>
    <td><span class="get get-book" data-id="{{id}}" title="{{id}}">{{name}}</span></td>
    <td><button class="edit-book" data-id="{{id}}">Edit</button></td>
    <td><button class="delete-book" data-id="{{id}}">Delete</button></td>
    </tr>
  {{/books}}
  </table>
{{/books.length}}
{{^books.length}}
  <p>No books.</p>
{{/books.length}}


~~~~book_view~~~~
<h2 title="{{id}}">{{name}}</h2>

<p><button class="edit-book" data-id="{{id}}">Edit</button></p>

{{#authors}}
  <p>By <span class="get get-author" data-id="{{id}}" title="{{id}}">{{name}}</span></p>
{{/authors}}

{{#chapters.length}}
  <h3>Chapters</h3>
  <table>
  {{#chapters}}
    <tr>
    <td title="{{id}}">{{name}}</td>
    <td><button class="edit-chapter" data-id="{{id}}" data-book-id="{{bookId}}">Edit</button></td>
    <td><button class="delete-chapter" data-id="{{id}}" data-book-id="{{bookId}}">Delete</button></td>
    </tr>
  {{/chapters}}
  </table>
{{/chapters.length}}


~~~~authors_list~~~~
<h2>Authors</h2>
<button class="add-author">Add author</button><br/>
{{#authors.length}}
  <table>
  {{#authors}}
    <tr>
    <td><span class="get get-author" data-id="{{id}}" title="{{id}}">{{name}}</span></td>
    <td><button class="edit-author" data-id="{{id}}">Edit</button></td>
    </tr>
  {{/authors}}
  </table>
{{/authors.length}}
{{^authors.length}}
  <p>No authors.</p>
{{/authors.length}}


~~~~author_view~~~~
<h2 title="{{id}}">{{name}} <button class="edit-author" data-id="{{id}}">Edit</button></h2>

<h3>Books</h3>
{{>book_table}}
'


App.renderTemplate = (templateName, data) ->
  result = Milk.render(Milk.partials[templateName], data)
  $("#main").html(result)
  return


App.compareByName = (a, b) ->
  if a.name > b.name
    return 1
  else if a.name < b.name
    return -1
  else
    return 0


App.displayBooksList = (response) ->
  response.books.sort(App.compareByName)
  App.renderTemplate("books_list", response)


App.getBooksList = (batch) ->
  App.currentView = "getBooksList"
  # Get the books
  $.bjax(batch, {
    url: "/api/0.0/books/",
    type: "GET",
    success: App.displayBooksList,
  })


App.editBook = (id) ->
  name = prompt("Please enter the book's name:")
  if name?
    batch = new $.AjaxBatch()
    $.bjax(batch, {
      url: "/api/0.0/books/#{id}/",
      type: "POST",
      data: JSON.stringify({"name": name})
    })
    batch.execute(App.refreshView)


App.editChapter = (id, bookId) ->
  name = prompt("Please enter the chapter's name:")
  if name?
    batch = new $.AjaxBatch()
    $.bjax(batch, {
      url: "/api/0.0/books/#{bookId}/chapters/#{id}/",
      type: "POST",
      data: JSON.stringify({"name": name})
    })
    batch.execute(App.refreshView)


App.deleteChapter = (id, bookId) ->
  batch = new $.AjaxBatch()
  $.bjax(batch, {
    url: "/api/0.0/books/#{bookId}/chapters/#{id}/",
    type: "DELETE",
  })
  batch.execute(App.refreshView)


App.deleteBook = (id) ->
  batch = new $.AjaxBatch()
  $.bjax(batch, {
    url: "/api/0.0/books/#{id}/",
    type: "DELETE",
  })
  batch.execute(App.refreshView)


App.displayBook = (response) ->
  if response.responses.length > 2 
    book = response.responses[response.responses.length - 3]
    book.chapters = response.responses[response.responses.length - 2].chapters
    book.authors = response.responses[response.responses.length - 1]
    
    book.chapters.sort(App.compareByName)
    book.bookId = book.id
    App.renderTemplate("book_view", book)
  

App.getBook = (id) ->
  App.currentView = "getBook|#{id}"

  batch = new $.AjaxBatch()
  
  # Get the book
  $.bjax(batch, {
    url: "/api/0.0/books/#{id}/",
    type: "GET",
  })
  
  # Get the book's chapters
  $.bjax(batch, {
    url: "/api/0.0/books/#{id}/chapters/",
    type: "GET",
  })
  
  # Get the book's author
  $.bjax(batch, {
    url: "/api/0.0/authors/{{{responses.0.author}}}/", #Fetch the author based on the author property of the book.
    type: "GET",
  })
  
  batch.execute(App.displayBook)
  return


App.displayAuthorsList = (response) ->
  response.authors.sort(App.compareByName)
  App.renderTemplate("authors_list", response)
  
  
App.getAuthorsList = () ->
  App.currentView = "getAuthorsList"
  $.bjax(null, {
    url: "/api/0.0/authors/",
    type: "GET",
    success: App.displayAuthorsList,
  })


App.addAuthor = () ->
  name = prompt("Please enter the author's name:")
  if name?
    batch = new $.AjaxBatch()
    $.bjax(batch, {
      url: "/api/0.0/authors/",
      type: "POST",
      data: JSON.stringify({"id":"___id___", "name":name}), # "___id___" is replaced by the assigned ID during item creation.
    })
    batch.execute(App.refreshView)


App.editAuthor = (id) ->
  name = prompt("Please enter the author's name:")
  if name?
    batch = new $.AjaxBatch()
    $.bjax(batch, {
      url: "/api/0.0/authors/#{id}/",
      type: "POST",
      data: JSON.stringify({"name": name})
    })
    batch.execute(App.refreshView)
  
  return


App.displayAuthor = (response) ->
  if response.responses.length == 2
    author = response.responses[0]
    author.books = response.responses[1].books
    App.renderTemplate("author_view", author)


App.getAuthor = (id) ->
  App.currentView = "getAuthor|#{id}"
  
  batch = new $.AjaxBatch()
  
  # Get the author
  $.bjax(batch, {
    url: "/api/0.0/authors/#{id}/",
    type: "GET",
  })
  
  # Get the author's books
  $.bjax(batch, {
    url: "/api/0.0/books/?author=#{id}",
    type: "GET",
  })
  
  batch.execute(App.displayAuthor)
  return false


App.refreshView = () ->
  parts = App.currentView.split('|')
  func = parts.shift()
  App[func].apply(App, parts)
  return


App.resetView = () ->
  App.getBooksList()


App.ajaxSetup = () ->
  $.ajaxSetup({
    beforeSend: (xhr, settings) ->
      if (!(/^http:.*/.test(settings.url) || /^https:.*/.test(settings.url)))
        csrf = $("input[name=csrfmiddlewaretoken]").val()
        if csrf? then xhr.setRequestHeader("X-CSRFToken", csrf)
  })


App.init = () ->
  App.ajaxSetup()
  App.loadMustacheTemplates(App.templates)
  
  $(document.body)
    .delegate('.add-author', 'click', (e) -> App.addAuthor())
    
    .delegate('.get-books-list', 'click', (e) -> App.getBooksList())
    .delegate('.get-authors-list', 'click', (e) -> App.getAuthorsList())
  
    .delegate('.get-book', 'click', (e) -> App.getBook($(this).data("id")))
    .delegate('.get-author', 'click', (e) -> App.getAuthor($(this).data("id")))
  
    .delegate('.edit-book', 'click', (e) -> App.editBook($(this).data("id")))
    .delegate('.edit-author', 'click', (e) -> App.editAuthor($(this).data("id")))
    .delegate('.edit-chapter', 'click', (e) -> App.editChapter($(this).data("id"), $(this).data("bookId")))
    .delegate('.delete-chapter', 'click', (e) -> App.deleteChapter($(this).data("id"), $(this).data("bookId")))
  
    .delegate('.delete-book', 'click', (e) -> App.deleteBook($(this).data("id")))
    
    .delegate('#reset-button', 'click', (e) -> App.resetData())
  
  App.resetView()
  
  return

$ ->
  App.init()
  return