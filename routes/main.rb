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

class MyApp < Sinatra::Application
	# use Rack::Flash, :sweep => true

	def get_fb_user(token)
		return nil if token.nil?
		auth = FbGraph::Auth.new APP_ID, APP_SECRET
		FbGraph::User.me(token).fetch
	end

	def get_user
		s = Student.first :id => session[:id], :token => session[:token]
		return s if s.nil?
		# auto logout after 12 hours
		now = Date.today
		if now - s.last_seen > 43200.0
			s = nil
		end
		s
	end

	get "/" do
		@student = get_user
		unless(params[:ref].nil?)
			session[:ref] = params[:ref]
		end
		erb :index
	end

	# post "/register" do
	# 	Student.create(name: params[:name], email: params[:email], password: params[:password])
	# 	"Congratulations young man - you have successfully registered"
	# end

	get "/login" do
		# get info from Facebook
		u = get_fb_user params[:token]
		# try to find an existing student with the same identifier
		student = Student.first :id => u.identifier
		# if there is none, create a new student
		if student.nil?
			student = Student.create(
				:id => u.identifier.to_i,
				:first_name => u.first_name,
				:last_name => u.last_name,
				:token => u.access_token
			)
			unless(session[:ref].nil?)
				student_who_referred = Student.first(:id => session[:ref])
				student_who_referred.referrals = student_who_referred.referrals + 1
				student_who_referred.save
			end
		# if the token is outdated, update it in the database
		elsif student.token != u.access_token
			student.token = u.access_token
		end
		student.save
		# update session
		session[:id] = student.id
		session[:token] = student.token
		# if the student has not specified which school he goes to, go to the new user page
		if student.school == INDETERMINATE
			redirect :newuser
		# if the student has not entered in his schedule, go to the edit page
		else
			redirect :home
		end
	end

	get "/newuser" do
		# authenticate
		@student = get_user
		redirect "/" if @student.nil?

		erb :newuser
	end

	post "/newuser" do
		@student = get_user
		redirect "/" if @student.nil?

		# set the school
		@student.school = params[:school].to_sym
		@student.save

		# check for errors
		unless @student.errors.first.nil?
			@error = @student.errors.first.token
			erb :newuser
		end

		# go to the next step
		redirect :edit
	end

	get "/edit" do
		@student = get_user
		redirect "/" if @student.nil?
		redirect "/newuser" if @student.school == INDETERMINATE

		@hac_url = @student.hac_url.nil? ? "" : Gibberish::AES.new("#qT<W\"K)0hU#HFq1Rt7kB;xqcopTe1H?#=qZ|").dec(@student.hac_url)
		blocks_remaining = [1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16]
		@courses = [] 
		@student.scheduled_courses.each do |scheduled_course|
			block = (scheduled_course.semester == 1) ? scheduled_course.block : scheduled_course.block + 8
			blocks_remaining.delete(block)
			section_text = scheduled_course.section.nil? ? "" : "-#{scheduled_course.section}"
			course_id = "#{scheduled_course.courseid}#{section_text}"
			@courses[block-1] = { block: block, course_id: course_id, real_block: scheduled_course.block }
		end

		blocks_remaining.each do |block|
			real_block = (block - 1) % 8 + 1

			@courses[block-1] = { block: block, course_id: "", real_block: real_block}
		end

		@courses.sort! { |x, y| x[:block] <=> y[:block] }

		puts @courses.inspect
		
		erb :edit
	end

	get "/coursename/:cid" do
		matches = /(\d{4})(?:A|B?)\s?-?\s?(\d)?/i.match(params[:cid].strip)
		puts matches[1].inspect
		REDIS.get(matches[1]).to_s
	end

	post "/submitchange" do
		@student = get_user
		redirect "/" if @student.nil?
		@student.scheduled_courses.destroy

		hac_courses = hac_info(params["hac"])
		#@student.hac_url = Gibberish::AES.new("#qT<W\"K)0hU#HFq1Rt7kB;xqcopTe1H?#=qZ|").enc(params["hac"]) unless params["hac"].strip.empty?
		#@student.save
		# it's 1-16 because every number after 8, the real block becomes block -8 and switches to second semester
		(1..16).each do |block|
			semester = (block <= 8) ? 1 : 2
			real_block = (block <= 8) ? block : block - 8
			options = { :student => @student }
			unless(hac_courses[block].nil?)
				options[:teacher] = hac_courses[block][:teacher]
				options[:block] = real_block
				options[:semester] = semester
			end
			if(params[block.to_s].strip != "")
				matches = /(\d{4})(?:A|B?)\s?-?\s?(\d)?/i.match(params[block.to_s].strip)
				options.merge!(
					courseid: matches[1], # becuase the course has more digits
					section: matches[2],
					block: real_block,
					semester: semester
				)
			end
			unless(!options[:block] || !options[:semester])
				ScheduledCourse.create(options)
			end
		end

		redirect "/home"
	end

	get "/home" do
		@student = get_user
		redirect "/" if @student.nil?
		redirect "/newuser" if @student.school == INDETERMINATE
		redirect "/edit" if @student.scheduled_courses.empty?
		blocks_remaining = [1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16]

		@list_of_students = []
		@student.scheduled_courses.each do |scheduled_course|
			fake_block = (scheduled_course.semester == 1) ? scheduled_course.block : scheduled_course.block + 8
			
			blocks_remaining.delete(fake_block)
			@list_of_students[fake_block] = { 
				name: scheduled_course.course_name, 
				students: scheduled_course.students_sharing,
				semester: scheduled_course.semester,
				block: scheduled_course.block
			}
		end
		
		blocks_remaining.each do |block|
			real_block = (block - 1) % 8 + 1
			semester = (block <= 8) ? 1 : 2
			@list_of_students[block] = { 
				name: "Block #{real_block} (no information entered)", 
				students: [], 
				semester: semester,
				block: real_block 
			}
		end

		#puts @list_of_students.inspect

		erb :home
	end

	get "/logout" do
		session.clear
		redirect "/"
	end

	get "/about" do
		@student = get_user
		erb :about
	end

	get "/counter" do
		halt Student.count.to_s
	end

	get "/search" do
		@student = get_user
		redirect "/" if @student.nil?

		# search results
		unless params[:name].nil?
			split_name = params[:name].split
			# what are we searching for?
			if not /^\d*$/.match(params[:name]).nil?
				# Facebook ID
				match = Student.all :id => params[:name].to_i
				found = !(match.empty?)
			elsif split_name.length == 1
				# first name search
				match = Student.all :first_name => params[:name]
				found = !(match.empty?)
			elsif split_name.length >= 2
				# full name search
				match = Student.all :first_name => split_name[0], :last_name => split_name[1]
				found = !(match.empty?)
			else
				# should never happen
				found = false
			end

			# process search results
			if found
				if match.length > 1
					@result = "Yes, there are #{match.length} students \"#{params[:name]}\" using Schedule Comparinator."
				else
					is_actually_using_text = match[0].scheduled_courses.empty? ? ", but he/she has not put in his/her schedule yet" : ""
					@result =  "Yes, there is a student \"#{params[:name]}\" using Schedule Comparinator#{is_actually_using_text}."
				end
			else
				@result = "No, there is no student \"#{params[:name]}\" using Schedule Comparinator."
			end
		end

		erb :search
	end

	post "/addtogethercourses" do
		halt "Invalid Password." unless params[:password] == "" # insert password here
		course_number_list = params[:numbers].split(",").map! do |course_number|
			course_number.strip.to_i
		end
		set_course_numbers_same(course_number_list)
		"Success."
	end

	get "/addtogethercourses" do
		erb :coursenumbers
	end
end
