class MessengerController < ApplicationController
	require 'json'
	require 'httparty'
	include MessengerHelper

	def receive_message
		checkFacebookToken()
		$tester = request.raw_post
		#array to keep tack of who got the welcome message
		#variable with all the webhook data
 		$webhook = JSON.parse(request.raw_post)
 		# person who sent the text; id
 		@recipient = $webhook["entry"][0]["messaging"][0]["sender"]["id"]
 		# a list of positve responses to respond with if user doesn't have homework
 		@positiveResponses = ["that's grrrreat", "that's awesome!", "yay! no homework!", "finally, a break from some homework", "awesome, just what i wanted to hear", "yay, some good news today", "that's almost better than harry potter", "time to celebrate, come on!", "ho ho ho! merry christmas!"].shuffle
		# a list of negative responses if user has homework
		@negativeResponses = ["booooo", "what a shame", "ugh, that stinks", "your teacher needs to chill out on the homework", "that's so sad to hear", "that sucks, at least you look good today", "that sucks more than a vacuum", "that's worse than when dumbledore died", "that's too bad, but try not to become a debby downer"].shuffle
		# if user sends a text, but has nothing to do with homework and they're signed up
		@defaultResponses = ["43 percent of statistics are made up", "out of my mind - back in 5 minutes", "borrow money from a pessimist – they don’t expect it back", "why is “abbreviation” such a long word?", "what happens if you get scared half to death twice?", "gravity always gets me down", "give a man a fish and he will eat for a day - teach him how to fish, and he will sit in a boat and drink beer all day", "change is inevitable, except from a vending machine", "the shinbone is a device for finding furniture in a dark room"].shuffle
		# setting variables to false, to know what and if I sent a message
		@sentMessage = false
		@sentKeyWords = false
		@sentConfirmation = false
		$checkKeyWords = nil
		@userText = nil
		@we = false
		# list of all classes that need to be delt with
 		currentClasses = Grouparray.all
 		# random numbe from 0 to seven, to get a random response from the array
 		randomNum = rand(0..8)
		if $webhook["entry"][0]["messaging"][0]["message"]["text"].nil? && $webhook["entry"][0]["messaging"][0]["postback"].nil?
			count = 1
		else
		@ifStart = $webhook["entry"][0]["messaging"][0]["postback"]["payload"].inspect if !$webhook["entry"][0]["messaging"][0]["postback"].nil?
 		# what text the user sent
 		if @ifStart.nil?
 			@userText = $webhook["entry"][0]["messaging"][0]["message"]["text"].downcase unless $webhook["entry"][0]["messaging"][0]["message"].nil?
			@we = true
		end

 		if Rails.env.staging?
 			$page_access_token = "EAAIgtnRF648BABaZCpNurJN2GBzjZC6jQZAZCCdQE90mluLc5jooAfHrFgSxsYT2eTeu9sXVjWWiFc1gZBXn5if7OC2Q4hXsnHwxrSDg7anLuzPnRzUvicPv5R1AXxkjZAS2Xhm7KknwGlx0poBZC7IFNhRyNHnWabn59f7CkwnjAZDZD"
 		else
 			$page_access_token = "EAAZAjj9YZAiZC0BAOFT4SiXhnIqinWdveXxBf8AvDMAGMXamAIQobjfYRIv9Iw85UcZBXOqla4XpWtUJ6fooeBpM4LtB9hUwOYeRsokcOKUa40gM9RpKgtCTxHiFde52R4i3PZAfMijyw3NZACCYILq3hWeCipeq5gCLuyZASBn6gZDZD"
 		end

 		# function that checks if the user exists based on their text id
 		@checkUserExists = Messagehuman.checkUserExists(@recipient)

		if @userText == "help" && @sentMessage == false
 			Messagehuman.sendMessageBubbles(@recipient)
 			sleep(1)
 			Messagehuman.sendHelpButton(@recipient)
 			@sentMessage = true
 		end

		if @we == false
	 			Messagehuman.sendMessageBubbles(@recipient)
		 		sleep(1)
		 		Messagehuman.sendMessage(@recipient, "hey, i'm christopher bot, i really hope you sign up for my awesome services")
		 		sleep(1)
	 			Messagehuman.sendButton(@recipient)
	 			# marking that I did send a messsage
	 			@sentMessage = true
	 		elsif !@ifStart.nil? && @checkUserExists == true && @sentMessage == false
	 			Messagehuman.sendMessageBubbles(@recipient)
				sleep(1.5)
				# sending the default response
				Messagehuman.sendMessage(@recipient, @defaultResponses[randomNum])
				@sentMessage = true
			else
		end
 		# if @checkUserExists return false, then send the sign up button
	 	if @checkUserExists == false && @sentMessage == false
	 		Messagehuman.sendMessageBubbles(@recipient)
	 		sleep(1)
	 		Messagehuman.sendMessage(@recipient, "hey, you haven't signed up yet - just click below")
	 		sleep(1)
 			Messagehuman.sendButton(@recipient)
 			# marking that I did send a messsage
 			@sentMessage = true
 		end

 		if @userText == "pause" && @sentMessage == false
 			@user = User.find_by(conversation_id: @recipient)
 			@user.update(paused: true)
 			if !@user.groups.last.nil?
	 			@user.groups.each do |group|
	 				group.update(paused: true)
	 			end
 			end
 			Messagehuman.sendMessageBubbles(@recipient)
 			sleep(1)
 			Messagehuman.sendPauseDate(@recipient)
 			@sentMessage = true
 		elsif @userText == "unpause" && @sentMessage == false
 			@user = User.find_by(conversation_id: @recipient)
 			@user.update(paused: false)
 			if !@user.groups.last.nil?
	 			@user.groups.each do |group|
	 				group.update(paused: false)
	 			end
 			end
 			Messagehuman.sendMessageBubbles(@recipient)
 			sleep(1)
 			Messagehuman.sendMessage(@recipient, "you have been unpaused, yay")
 			@sentMessage = true
 		end

 		if @sentMessage == false
 			@user = User.find_by(conversation_id: @recipient)
 			if @user.paused == true
 				Messagehuman.sendMessageBubbles(@recipient)
 				sleep(1)
 				Messagehuman.sendMessage(@recipient, "before you can text me, you need to say 'unpause' please")
 				@sentMessage = true
 			end
 		end

 		if @userText == "list" && @sentMessage == false
 			Messagehuman.sendMessageBubbles(@recipient)
 			sleep(1)
 			Messagehuman.sendUserHomework(@recipient)
 			@sentMessage = true
 		end

 		if @userText == "share" && @sentMessage == false
 			Messagehuman.sendShareButton(@recipient)
 			@sentMessage = true
 		end

 		# checking if the user says cancel
		if @userText == "cancel"
			# if true, then delete classes they might have to deal with
			@grouparrays = Grouparray.all.where(conversation_id: @recipient)
			if !@grouparrays.nil? || !@grouparray.empty?
				# each outstanding group to deal with (should just be one)
 				@grouparrays.each do |group|
 					# find the corresponding group, and reset anything to do with that homework
	 				@group = Group.find_by(conversation_id: group.conversation_id, group_name: group.group_name, group_day: group.group_day)
	 				@group.update(homework_assigned: nil, homework_assignment: nil)
	 				# destroy the group array
	 				group.destroy
	 			end
			end
			Messagehuman.sendMessageBubbles(@recipient)
			sleep(1)
			# send a message confirming that you have done the previous
			Messagehuman.sendMessage(@recipient, "ok let me know if you need anything else")
			# market that I did send a message
			@sentMessage = true
		else
			# making sure that groups response is empty/nil
			if !$groupsResponse.nil? && !$groupsResponse.empty? && @sentMessage == false
				@charge = false
				@charge = true if $groupsResponse.include?("8")
				$groupsResponse.delete("8")
				# for each group in group response
				$groupsResponse.each do |group|
					# if the group name matches to group the user said in the text
					if group.group_name == @userText
						# we know that the user has homework for that class
						if @charge == false
						group.update(homework_assigned: true)
						@group = group.as_json # convert the group to json
						@group["id"] = nil # removing the id
						@group.delete("name") # delete name
						# check if there are any outstanding groups, if so, delete them
						checkExistingGroupArray = Grouparray.find_by(conversation_id: group.conversation_id)
						checkExistingGroupArray.destroy if !checkExistingGroupArray.nil?
						# create the new group array and save them
						groupArrayNew = Grouparray.new(@group)
						groupArrayNew.save
						Messagehuman.sendMessageBubbles(@recipient) # send the message bubbles
			 			sleep(1.5) # let the program sleep for 1 second
			 			Messagehuman.sendMessage(@recipient, @negativeResponses[randomNum]) # sending a negative response
			 			Messagehuman.sendMessageBubbles(@recipient) # send more message bubles
			 			sleep(1.5) # let the program sleep for one second
			 			Messagehuman.sendMessage(@recipient, 'what homework do you have for ' + @group["group_name"] + '?')
			 			# markers that I have sent messages
			 			@sentMessage = true
			 			@sentKeyWords = true
			 			else
			 				group.update(homework_assigned: false)
			 				Messagehuman.sendMessageBubbles(@recipient) # send the message bubbles
			 				sleep(1.5) # let the program sleep for 1 second
			 				Messagehuman.sendMessage(@recipient, @positiveResponses[randomNum]) # sending a negative response
			 				@sentMessage = true
			 			end
					end
				end
			end

			# checking for key words (this would only happen if the other stuff above hasn't happend)
			$checkKeyWords = Messagehuman.checkKeyWords(@recipient, @userText) if @sentMessage == false
			if !$checkKeyWords.nil? # if the function doesn't return nil
		 	if $checkKeyWords == true # if true, which means, all keywords were found
		 		Messagehuman.sendMessageBubbles(@recipient) # send message bubbles
					sleep(1) # let the code sleep for 1 second
					Messagehuman.sendMessage(@recipient, @negativeResponses[randomNum]) # send a negative response
					Messagehuman.sendMessageBubbles(@recipient) # send more fricken bubbles
					sleep(1)
					Messagehuman.sendMessage(@recipient, 'what homework do you have for ' + $subject.downcase + '?') # send the question
					# markers that I've sent a message
					@sentKeyWords = true
					@sentMessage = true
				# on the other hand, if the subject hasn't been found
				elsif $checkKeyWords == false && !$possibleSubjects.empty? && @sentConfirmation == false
					Messagehuman.sendMessageBubbles(@recipient)
					sleep(1)
					# send the message of what they meant to type
					Messagehuman.sendGroupConfirmMessage(@recipient, $possibleSubjects, true)
					#setting the gropus response
					$groupsResponse = Array.new
					# setting the markers that I've sent a message
					@sentMessage = true
					@sentKeyWords = true
					@sentConfirmation = true
					# foreach possible subject
					$possibleSubjects.each do |group|
						# find that group
						@group = Group.find_by(group_name: group, conversation_id: @recipient, group_day: 0.hours.ago.strftime("%A").downcase)
						if !@group.nil?
							# push it to the array
							$groupsResponse.push(@group)
						end
					end
				elsif $checkKeyWords == -7 && @sentConfirmation == false
					Messagehuman.sendMessageBubbles(@recipient)
					sleep(1)
					Messagehuman.sendMessage(@recipient, @positiveResponses[randomNum])
					@sentMessage = true
				elsif $checkKeyWords == -12 && @sentConfirmation == false
					Messagehuman.sendGroupConfirmMessage(@recipient, $possibleSubjects, false)
					#setting the gropus response
					$groupsResponse = Array.new
					# setting the markers that I've sent a message
					@sentMessage = true
					$groupsResponse.push("8")
					@sentKeyWords = true
					@sentConfirmation = true
					# foreach possible subject
					$possibleSubjects.each do |group|
						# find that group
						@group = Group.find_by(group_name: group, conversation_id: @recipient, group_day: 0.hours.ago.strftime("%A").downcase)
						if !@group.nil?
							# push it to the array
							$groupsResponse.push(@group)
						end
					end
				else
				end
			end

			if @sentKeyWords == false
			# for every group in the grouparray (ie, and outstaning group)
			currentClasses.each do |group|
				randomNum = rand(0..7)
				# if a group matches who just sent a message
				if group.conversation_id == @recipient
					# if the user has said yes
					if @userText == "yes"
						# find the group, the user was talking about
						@group = Group.find_by(conversation_id: group.conversation_id, group_name: group.group_name, group_day: group.group_day)
						# putsing into the logs the class
						puts "group thing: " + @group.group_name.inspect
						# updating that we do have homework, and also updating the grouparray
						@group.update(homework_assigned: true)
						@grouparray = Grouparray.find_by(id: group.id)
						@grouparray.update(homework_assigned: true)
						Messagehuman.sendMessageBubbles(group.conversation_id) # send the message bubbles
						sleep(2) # sleeping in the code
						Messagehuman.sendMessage(group.conversation_id, @negativeResponses[randomNum]) # send a negative response
						Messagehuman.sendMessageBubbles(group.conversation_id) # send the message bubbles
						sleep(2) # sleeping in the code
						Messagehuman.sendMessage(group.conversation_id, 'what homework do you have?') # asking what homework there is
						@sentMessage = true # marker that I sent a message
					# if the user responds no
					elsif @userText == "no"
						# send the messsage bubbles
						Messagehuman.sendMessageBubbles(group.conversation_id)
						sleep(2) # sleep in the code for 2 secs
						Messagehuman.sendMessage(group.conversation_id, @positiveResponses[randomNum]) # send a positive response
						#find the grouparray and destroy that
						@groupArrayGroup = Grouparray.find_by(id: group.id)
						@groupArrayGroup.destroy
						# find the corresponsing gropu and update that
						@group = Group.find_by(conversation_id: group.conversation_id, group_name: group.group_name, group_day: group.group_day)
						@group.update(homework_assigned: false)
						# marker that I did send a message
						@sentMessage = true
					# if there is homework
					elsif group.homework_assigned == true
						# then update that group of the homework I have
						@group = Group.find_by(conversation_id: group.conversation_id, group_name: group.group_name, group_day: group.group_day)
						# updating the homework
						@group.update(homework_assignment: @userText)
						# find and destroy the group array
						@groupArray = Grouparray.find_by(id: group.id)
						# destroying
						@groupArray.destroy
						Messagehuman.sendMessageBubbles(group.conversation_id) # send more message bubbles
						sleep(1) # sleep for 1 sec
						Messagehuman.sendMessage(group.conversation_id, 'ok, got it!') # send that I have it
						# i sent the message
						@sentMessage = true
					else
					end
					end
				end
			end
			# if there has been no message sent, then send a default response
			if @sentMessage == false
				#send the message bubbles
				Messagehuman.sendMessageBubbles(@recipient)
				sleep(1.5)
				# sending the default response
				Messagehuman.sendMessage(@recipient, @defaultResponses[randomNum])
			end
 		end
	end
 	end

 	# method to check if facebook webhook is authentic
 	def check_token
 		# function to check if webhook is real
 		checkFacebookToken()
 	end

 	# just an inspect page for whatever I watn
 	def webhook_inspect
 	end

end
