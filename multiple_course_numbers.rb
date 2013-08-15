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

require 'json'

def set_course_numbers_same(course_numbers)
	relationship_key = nil
	course_numbers.each do |course_number|
		possible_relationship_key = REDIS.get("getrelationship_#{course_number}")
		unless(possible_relationship_key.nil?)
			relationship_key = possible_relationship_key
			break
		end
	end

	if(relationship_key.nil?)
		relationship_key = "relationship_#{REDIS.incr("number_of_relationships")}"
		REDIS.set(relationship_key, course_numbers.to_json)
	else
		existing_course_numbers = JSON.parse(REDIS.get(relationship_key))
		relationship_with_new_numbers = (existing_course_numbers + course_numbers).uniq!
		REDIS.set(relationship_key, relationship_with_new_numbers.to_json)
	end

	course_numbers.each do |course_number|
		REDIS.set("getrelationship_#{course_number}", relationship_key)
	end

	true
end

def get_same_courses(course_number)
	relationship_key = REDIS.get("getrelationship_#{course_number}")
	return course_number if relationship_key.nil?

	same_classes = JSON.parse(REDIS.get(relationship_key))

	return same_classes
end