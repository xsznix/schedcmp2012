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

class Student
	include DataMapper::Resource

	property :id,         Integer, :required => true, :key => true, :min => 0, :max => 9999999999999999 # Facebook user ID is unique
	property :first_name, String,  :required => true
	property :last_name,  String,  :required => true
	property :token,   String,  :required => true, :length => 256
	property :school,     Enum[WESTWOOD, MCNEIL, ROUNDROCK, STONYPOINT, CEDARRIDGE, INDETERMINATE], :required => true, :default => INDETERMINATE
	property :last_seen,  Date,   :required => true, :default => Date.today
	property :hac_url,		String, :length => 256
	property :referrals,	Integer, :default => 0

	has n, :scheduled_courses

	def name
		"#{self.first_name} #{self.last_name}"
	end

	def avatar
		"http://avatars.io/facebook/#{self.id}"
	end

	def referral_link
		"http://www.schedulecomparinator.com/?ref=#{self.id}"
	end
end