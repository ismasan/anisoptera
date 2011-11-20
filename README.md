# Configurable Rack endpoint for Async image resizing.

In progress.

Borrows heavily from Dragonfly ([https://github.com/markevans/dragonfly](https://github.com/markevans/dragonfly)).

Async mode relies on Thin's async.callback env variable and EventMachine.

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