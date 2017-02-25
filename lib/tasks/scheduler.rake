desc "This task is called by the Heroku scheduler add-on"
require 'json'
task :message_task => :environment do
	@groups = Group.all.order("end_time ASC").where("group_day = ?", 0.hours.ago.strftime("%A").downcase).where("extra_class = ?", false).where(paused: [false, nil])
	@t = 0.minutes.from_now.utc.strftime("%H:%M")
	@break = false
	@timeten = 10.minutes.from_now.utc.strftime("%H:%M")
	puts "@t: " + @t.inspect
	puts "@timeten: " + @timeten.inspect


	@groups.each do |group|
		if group.time_zone.to_i < 0
			#puts "end time 1: " + group.end_time.inspect
			group.end_time = group.end_time + (group.time_zone * -1).hours
			#puts "end time 2: " + group.end_time.inspect
		elsif group.time_zone.to_i > 0
			#puts "end_time 1: " + group.end_time.inspect
			group.end_time = group.end_time - group.time_zone.hours
			#puts "end_time 2: " + group.end_time
		elsif group.time_zone.nil?
			@break = true
		else
		end

		break if @break.true?

		if group.end_time.strftime("%H:%M") >= @t && group.end_time.strftime("%H:%M") < @timeten
			#puts "group: " + group.group_name.to_s + " " + group.conversation_id.to_s
			puts 'sending...'
			Messagehuman.sendBinaryMessage(group.conversation_id, 'do you have homework for ' + group.group_name)
			puts 'sent the message.'
			@group = group.as_json
			@group["id"] = nil
			@group.delete("name")
			# check to see if there is an exisiting group
			checkExistingGroupArray = Grouparray.find_by(conversation_id: group.conversation_id)
			# destroy it if there is an exisitng group
			checkExistingGroupArray.destroy if !checkExistingGroupArray.nil?
			# create the new group array
			groupArrayNew = Grouparray.new(@group)
			# save it to the db
			groupArrayNew.save
		end
	end

end

task :check_pause => :environment do
	# grab all the users that have been paused
	@users = User.all.where("paused = ?", true)
	# for each one
	@users.each do |user|
		if user.time_zone <= 0
			# grab their current time in their time zone
			@midnight = 0.minutes.from_now.utc - (user.time_zone * -1).hours
		else
			# grab their current time in their time zone
			@midnight = 0.minutes.from_now.utc + user.time_zone.hours
		end
		# if its equal the puase date and their time zone
		if user.paused_time.to_date.to_s == @midnight.to_date.to_s
			#update that they are not paused
			user.update(paused: false)
			puts "User UNPAUSED: " + user.first_name
			# and for each user unpause their groups
			user.groups.each do |group|
				# unpause the group
				group.update(paused: false)
			end
		end
	end
end

task :reset_classes => :environment do
	# where are the groups are today
	@groups = Group.all.where("group_day = ?", 1.minutes.from_now.strftime("%A").downcase)
	# for each group
	@groups.each do |group|
		if group.time_zone <= 0
			# grab the current timezone of the user
			@midnight = 0.minutes.from_now.utc - (group.time_zone * -1).hours
		else
			# grab the current timezone of the user
			@midnight = 0.minutes.from_now.utc + group.time_zone.hours
		end
		# if its midnight of that user
		if @midnight.strftime("%H:%M") >= "00:00" && @midnight.strftime("%H:%M") <= "00:10"
			# update that it has no homework
			group.update(homework_assigned: nil, homework_assignment: nil)
		end
	end
end

task :reset_user_homework => :environment do
	# all of the users
	@users = User.all
	# for each of those users
	@users.each do |user|
		if user.time_zone <= 0
			# find their current time
			@midnight = 0.minutes.from_now.utc - (user.time_zone * -1).hours
		else
			# find their current time
			@midnight = 0.minutes.from_now.utc + user.time_zone.hours
		end
		# if it is midnight then update they dont have homework
		if @midnight.strftime("%H:%M") >= "00:00" && @midnight.strftime("%H:%M") <= "00:10"
			user.update(sentHomwork: false)
		end
	end
end


task :send_homework => :environment do
	# grab all the users
	@users = User.all
	# for each the users
	@users.each do |user|
		# if the user hasn't ahd their homework sent or it is nil
		if user.sentHomwork == false || user.sentHomwork == nil
			#checking to make sure the user has groups
		if !user.groups.where("group_day = ?", 0.hours.ago.strftime("%A").downcase).nil? && !user.groups.where("group_day = ?", 0.hours.ago.strftime("%A").downcase).order("end_time asc").limit(user.class_number.to_i).last.nil?
			if user.groups.where("group_day = ?", 0.hours.ago.strftime("%A").downcase).order("end_time ASC").limit(user.class_number.to_i).last.homework_assigned != nil
				# create empty array to store homework
				homeworkGroups = Array.new
				# for each group today and that has homework
				homeworkGroupsTrue = Group.where("homework_assigned = ?", true).where("group_day = ?", 0.hours.ago.strftime("%A").downcase).where("conversation_id = ?", user.conversation_id)
				# for each of the positive gruops
				homeworkGroupsTrue.each do |group|
					# push each group to array
					homeworkGroups.push(group)
				end
				# create the empty string
				homeworkGroupsString = String.new
				counter = 1
				if !homeworkGroups.nil?
				homeworkGroups.each do |group|
					if !group.nil? && !group.group_name.nil? && !group.homework_assignment.nil?
						if counter != 1
							homeworkGroupsString = homeworkGroupsString + ", " + group.group_name + ": " + group.homework_assignment + "\n"
						else
							homeworkGroupsString = homeworkGroupsString + group.group_name + ": " + group.homework_assignment + "\n"
						end
					end
				end
			end
				puts 'user send to: ' + user.first_name.to_s
				if !homeworkGroupsString.blank?
					# send their homework
					Messagehuman.sendMessage(user.groups.last.conversation_id, 'you have homework for... ' + "\n" + homeworkGroupsString)
					Messagehuman.sendSummaryButton(user.groups.last.conversation_id)
					# update that they have been sent their homework
					user.update(sentHomwork: true)
				else
					# send their homework
					Messagehuman.sendMessage(user.groups.last.conversation_id, 'yay. you have no homework.')
					# update that they have had their hoemwork sent to them
					user.update(sentHomwork: true)
				end
			end
		end
	end
end
end

task :send_share_button => :environment do
	# all of the users
	@users = User.all
	# for each of those users
	@users.each do |user|
		if user.time_zone.nil? || user.time_zone.blank?
			next
		else
		if user.time_zone <= 0
			# find their current time
			@midnight = 0.minutes.from_now.utc - (user.time_zone * -1).hours
		else
			# find their current time
			@midnight = 0.minutes.from_now.utc + user.time_zone.hours
		end
		# if it is midnight then update they dont have homework
		if (@midnight - 7.days).to_date == user.created_at.to_date && (@midnight.strftime("%H:%M") >= "09:00" && @midnight.strftime("%H:%M") <= "10:00")
			Messagehuman.sendShareButton(user.conversation_id)
		end
	end
	end
end
