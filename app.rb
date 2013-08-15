# Copyright (c) 2013, Yash Aggarwal, Max Ciotti, Justin Lai, and Xuming Zeng.
# All rights reserved.
# 
# Redistribution and use in source and binary forms, with or without modification,
# are permitted provided that the following conditions are met:
# 
#   Redistributions of source code must retain the above copyright notice, this
#   list of conditions and the following disclaimer.
# 
#   Redistributions in binary form must reproduce the above copyright notice, this
#   list of conditions and the following disclaimer in the documentation and/or
#   other materials provided with the distribution.
# 
#   Neither the name of the {organization} nor the names of its
#   contributors may be used to endorse or promote products derived from
#   this software without specific prior written permission.
# 
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR
# ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
# ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

require 'bundler/setup'
Bundler.require(:default)

require 'uri'
# disable
require 'net/http'
# require 'rack-flash'
# require 'sinatra/redirect_with_flash'

# constants

# replace the following with your Facebook app ID and secret
APP_ID = ""
APP_SECRET = ""

WESTWOOD = :ww
MCNEIL = :mn
ROUNDROCK = :rr
STONYPOINT = :sp
CEDARRIDGE = :cr
INDETERMINATE = :ind

set :partial_template_engine, :erb
set :dump_errors, true

uri = URI.parse(ENV["REDISTOGO_URL"] || "redis://localhost:6379/" )
REDIS = Redis.new(:host => uri.host, :port => uri.port, :password => uri.password)

class MyApp < Sinatra::Application
	enable :sessions
	# use Rack::Flash, :sweep => true
	use Rack::Static, :urls => ["/public"]

	set :session_secret, 'top secret code here'

end

require_relative 'helpers/init'
require_relative 'models/init'
require_relative 'routes/init'
require_relative 'hacscraper'
require_relative 'load_courses'
require_relative 'multiple_course_numbers'