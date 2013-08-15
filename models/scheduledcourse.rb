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

class ScheduledCourse
	include DataMapper::Resource

	property :id,							Serial

	# HAC
	property :teacher,				String

	# Real Schedule
	property :courseid,				Integer
	property :section,			Integer

	#Both
	property :block,					Integer
	property :semester,				Integer

	belongs_to :student

	def students_sharing
		s = students_sharing_from_hac + students_sharing_from_schedule
		s.sort! { |s1, s2| s1.name <=> s2.name }
		s
	end

	def students_sharing_from_hac
		return [] if self.teacher.nil?
		options = {
			teacher: self.teacher,
			block: self.block,
			student: {
				school: self.student.school
			}
		}
		students = ScheduledCourse.all(teacher: self.teacher, block: self.block).collect do |scheduled_course|
			scheduled_course.student if scheduled_course.student.school == self.student.school
		end

		students.delete_if { |x| x.nil? }
	end

	def students_sharing_from_schedule
		return [] if self.courseid.nil?
		students = []
		course_numbers = get_same_courses(self.courseid)

		section_array = [nil, self.section]
		if(self.section.nil?)
			section_array = section_array + [1,2,3,4,5,6,7,8,9]
		end

		students = ScheduledCourse.all(courseid: course_numbers, block: self.block, semester: self.semester, section: section_array).collect do |scheduled_course|
			student = scheduled_course.student if scheduled_course.student.school == self.student.school
			# unless(student.nil?)
			# 	student.name = "#{student.name} (?)" if scheduled_course.section.nil?
			# end
			student
		end
		students.delete_if { |x| x.nil? }

	end

	def course_name
		if self.courseid.nil?
			if self.teacher.nil?
				return "Block #{self.block.to_s}"
			else
				return "#{self.teacher}'s class"
			end
		else
			n = REDIS.get(self.courseid)
			return n.nil? ? "Unknown Course" : n
		end
	end
end