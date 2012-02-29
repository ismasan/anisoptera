# Configurable Rack endpoint for Async image resizing.

In progress.

Borrows heavily from Dragonfly ([https://github.com/markevans/dragonfly](https://github.com/markevans/dragonfly)).

Async mode relies on Thin's async.callback env variable and EventMachine, and ImageMagick for image processing.

See [http_router](/ismasan/anisoptera/blob/master/examples/http_router.ru) example for an intro.

## Usage

You need a rack router of some sort.

```ruby
# image_resizer.ru

require 'http_router'
require 'anisoptera'

Anisoptera[:media].configure do |config|
  # This is where your original image files are
  config.base_path = './'
  # In case of error, resize and serve up this image
  config.error_image = './Error.gif'
  # Run this block in case of error
  config.on_error do |exception, params|
    Airbrake.notify(
        :error_class   => exception.class.name,
        :error_message => exception.message,
        :parameters    => params
      )
  end
end

# Create an app with defined routes

app = HttpRouter.new do

  add('/media/:geometry/:color_mode/:filename').to Anisoptera[:media].endpoint {|image, params|
    image.file(params[:filename]).thumb(params[:geometry])
    image.greyscale if params[:color_mode] == 'grey'
    image.encode('png')
  }
end

# Run the app
run app
```
  
Run with Thin

    $ thin start -R image_resizer.ru -e production -p 5000
    
    
Now you get on-the fly image resizes

    http://some.host/media/100x100/grey/logo.png

Anisoptera returns all the right HTTP headers so if you put this behind a caching proxy such as Varnish it should just work.

## DoS protection

Obviously it's a bad idea to allow people to freely resize images on the fly as it might bring your servers down. You can hash the parameters in the URL with a shared key and secret, something like:

```ruby
get('/media/:hash').to Anisoptera[:media].endpoint {|image, params|
  verify_sha! params[:hash], params[:k]
  
  args = Anisoptera::Serializer.marshal_decode(params[:hash])
  image_path = args[:file_name]
  image.file(image_path).thumb(args[:geometry])
  image.greyscale if args[:grey]
  image.encode('jpg')
}
```

Then you request images with passing a hash of parameters encoded with the shared secret, and a public key to decode it back.

    http://some.host/media/BAh7CToGZiIVMjUzNjctaGVsbWV0LmpwZzoJZ3JleUY6DHNob3BfaWRpAeA6BmciDDIwMHgyMDA?k=6a58f9458425f73
    
Anisoptera::Serializer's encode and decode methods can help you Base64-encode a hash of parameters. This is also good because some ImageMagick geometry strings are not valid URL components.

# LICENSE

Copyright (C) 2011 Ismael Celis

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
of the Software, and to permit persons to whom the Software is furnished to do
so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.