**What is it?**

- MorePi (Mock Rest API) is a simple dynamic RESTful API in Django with server-side in-memory storage.
It is meant for development purposes only.
- The Rails version was adapted from the Django version. I can't promise 100% rubyesque-ness.

**Why use it?**

- You want to focus on developing your client application first and save the back end for later.
- You only need semi-persistent data that you can quickly reset/rework as needed.
- You want to test the same set of data across several browsers or machines.

**What has it got in its pocketses?**

- GET, POST, PUT, DELETE requests.
- All data stored as json.
- Dynamically creates collections on first access.
- Querystring-based property filtering.
- Batch AJAX request processing.
- Reference previous items in a batch: {{{responses.0.author}}}
- Placeholders in your json for automatically assigned identifiers: \_\_\_id\_\_\_
- Sample client in CoffeeScript or JavaScript.

**What's the catch?**

- It's all in memory. Restart Django and the data goes away. Keep all of your good test data in your initialization script.
- It's not for production use. It's just a way to postpone building out your back end until you feel good about your client functionality.

**How do I use it?**

- See the sample application to get a feel for how to use it.
- Add the morepi package to your Django site.
- Add a reference to morepi.urls in your application's main urls.py: (r'^api/0.0/', include('morepi.urls'))
- Add a reference to batchjax.js in your HTML if you want to use the batching functionality.
- Paths should be something like /api/0.0/books/ to access a collection and /api/0.0/books/1/ to access an item.
- Set $.bjax.batchPath to whatever you want the path to your mock API to be (default is /api/0.0/)
- Reference the result of a previous item in a batch with {{{responses.0.attrName}}}.
- Batch references can be either in the request URL or in the data for a batch item.
- Actions:
     - Root (/api/0.0/)
          - GET: return everything.
          - DELETE: delete everything.
     - Collection (/api/0.0/orders/)
          - GET: return collection.
          - DELETE: delete collection.
          - POST: create a new item in the collection and assign it an ID.
     - Item (/api/0.0/orders/1/)
          - GET: return item.
          - DELETE: delete item.
          - POST: partially update the item's fields.
          - PUT: overwrite the item.

**What are the dependencies?**

- Batchjax: jQuery. Only tested on 1.6+
- MorePi: Django 1.3+, simplejson

**What's the license?**

- MIT.

**What other option are there?**

- Mockjax (https://github.com/appendto/jquery-mockjax) works great if you don't need cross-browser or inter-page persistence. You could probably hack something together with Mockjax and HTML5 local storage if you need a little persistence.
