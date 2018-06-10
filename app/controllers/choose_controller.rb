class ChooseController < ApplicationController

	def index
		# Return the Chosen Course List

		myhash = {:auth_token => request.headers['HTTP_AUTHORIZATION']}
		@user = User.find_by_authentication_token(myhash[:auth_token])

		if @user
			@user_id = @user.schoolid
			@chosen_courses_with_order = Course.find_by_sql([
				'SELECT courses.* 
			 	 FROM courses, chooses 
				 WHERE is_chosen = 1 and student_id = ? and chooses.course_id = subject_id and chosen_order > 0 ORDER BY chosen_order ASC', @user_id])
			@chosen_courses_no_order = Course.find_by_sql([
				'SELECT courses.* 
			 	 FROM courses, chooses 
				 WHERE is_chosen = 1 and student_id = ? and chooses.course_id = subject_id and chosen_order IS NULL', @user_id])


			if @chosen_courses_with_order.empty? and @chosen_courses_no_order.empty?
				render :json => {:message => "No Courses."}
			else
				render :json => {:chosen_courses_list => @chosen_courses_with_order + @chosen_courses_no_order, :message => 'OK'}
			end
		else
			render :json => {:message => 'Invalid user'}
		end
	end



	def update
		### Set the is_chosen field to opposite value

		myhash = {:id => params['id'], :auth_token => request.headers['HTTP_AUTHORIZATION']}
		@user = User.find_by_authentication_token(myhash[:auth_token])

		if @user
			@user_id = @user.schoolid
			@course_id = myhash[:id]

			choose = Choose.find_by(cs_id: @course_id + @user_id)
			if choose != nil
				if choose.is_chosen == '1'
					# put it back to tracking list
					choose.is_chosen = '0'
					choose.chosen_order = nil
				else
					# put it into selected list
					choose.is_chosen = '1'
				end

				choose.save

				@chosen_courses = Course.find_by_sql([
					'SELECT courses.* 
					 FROM courses, chooses 
					 WHERE is_chosen = 1 and student_id = ? and chooses.course_id = subject_id', @user_id])

				render :json => {:chosen_courses_list => @chosen_courses, :message => 'OK'}
			else
				render :json => {:message => 'Invalid course.'}
			end
		else
			render :json => {:message => 'Invalid user.'}
		end
	end



	def setorder
		myhash = {:id => params['id'], :order => params['order'], :auth_token => request.headers['HTTP_AUTHORIZATION']}
		
		@user = User.find_by_authentication_token(myhash[:auth_token])
		
		if @user
			@user_id = @user.schoolid
			@course_id = myhash[:id]
			@order = Integer(myhash[:order])

			# check if the input order is duplicate
			@orders = Choose.find_by_sql([
				'SELECT * 
				 FROM chooses 
				 WHERE is_chosen = 1 and student_id = ?', @user_id])

			@orders.each {
				|c|
				if c.chosen_order == @order
					render :json => {:message => 'Duplicate order'}
					return
				end
			}
			

			choose = Choose.find_by(cs_id: @course_id + @user_id)
			if choose != nil and choose.is_chosen == '1'
				choose.chosen_order = @order
				choose.save
				
				render :json => {:message => 'Order has been set.'}

			else
				render :json => {:message => 'The course is not in selected list.'}
			end
		else
			render :json => {:message => 'Invalid user.'}
		end
	end
end
