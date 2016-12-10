class MessengerController < ApplicationController
	require 'json'
	require 'httparty'
	include MessengerHelper

	def receive_message
		checkFacebookToken()
 		$webhook = JSON.parse(request.raw_post)
 		@recipient = $webhook["entry"][0]["messaging"][0]["sender"]["id"]
 		@userText = $webhook["entry"][0]["messaging"][0]["message"]["text"].downcase unless $webhook["entry"][0]["messaging"][0]["message"].nil?
 		@positiveResponses = ["thats grrrreaat", "Thats Awesome!", "Yay! No Homework!", "Finally, a break from some homework", "Awesome. Just what i needed to hear.", "Yay. Some good news today.", "thats almost better than harry potter", "time to celebrate, come on!"]
		@negativeResponses = ["booooo.", "what a shame." "ugh. That stinks.", "your teacher needs to chill out on the homework", "That's so sad to hear", "that sucks, at least you look good today.", "that sucks more than a vacuum", "thats worse than when Dumbledore died."]
		@defaultResponses = ["Hey! You've already signed up. All you have to do is wait for me to text you"]
		@sentMessage = false
		@sentKeyWords = false
 		currentClasses = Grouparray.all
 		randomNum = rand(0..7)




 			@checkUserExists = Messagehuman.checkUserExists(@recipient)
	 		if @checkUserExists == false
	 			Messagehuman.sendButton(@recipient)
	 			@sentMessage = true
	 		end
 	
	 	$checkKeyWords = Messagehuman.checkKeyWords(@recipient, @userText)
	 	Messagehuman.sendGroupConfirmMessage(@recipient, $possibleSubjects)
	 	if !$checkKeyWords.nil?
		 	if $checkKeyWords == true
		 		Messagehuman.sendMessageBubbles(@recipient)
	 			sleep(2)
	 			Messagehuman.sendMessage(@recipient, @negativeResponses[randomNum])
	 			Messagehuman.sendMessageBubbles(@recipient)
	 			sleep(2)
	 			Messagehuman.sendMessage(@recipient, 'what homework do you have for ' + $subject)
	 			@sentKeyWords = true
	 			@sentMessage = true
	 		end
	 		if $checkKeyWords == false && !$possibleSubjects.empty?
	 			puts "WE ARE HERE"
	 			Messagehuman.sendGroupConfirmMessage(@recipient, $possibleSubjects)
	 			puts "SENT THE MESSAGE"
	 			@sentMessage = true
	 			@sentKeyWords = true
	 		end
 		end

 		if @sentKeyWords == false
 		currentClasses.each do |group|
 			randomNum = rand(0..7)
 			if group.conversation_id == @recipient
 				if @userText == "yes"
 					puts "yes"
 					@group = Group.find_by(conversation_id: group.conversation_id, group_name: group.group_name, group_day: group.group_day)
 					puts "group thing: " + @group.group_name.inspect
 					@group.update(homework_assigned: true)
 					@grouparray = Grouparray.find_by(id: group.id)
 					@grouparray.update(homework_assigned: true)
 					Messagehuman.sendMessageBubbles(group.conversation_id)
 					sleep(2)
 					Messagehuman.sendMessage(group.conversation_id, @negativeResponses[randomNum])
 					Messagehuman.sendMessageBubbles(group.conversation_id)
 					sleep(2)
 					Messagehuman.sendMessage(group.conversation_id, 'what homework do you have?')
 					@sentMessage = true
 				elsif @userText == "no"
 					Messagehuman.sendMessageBubbles(group.conversation_id)
 					sleep(2)
 					Messagehuman.sendMessage(group.conversation_id, @positiveResponses[randomNum])
 					@groupArrayGroup = Grouparray.find_by(id: group.id)
 					@groupArrayGroup.destroy
 					@group = Group.find_by(conversation_id: group.conversation_id, group_name: group.group_name, group_day: group.group_day)
 					@group.update(homework_assigned: false)
 					@sentMessage = true
 				elsif group.homework_assigned == true
 					@group = Group.find_by(conversation_id: group.conversation_id, group_name: group.group_name, group_day: group.group_day)
 					@group.update(homework_assignment: @userText)
 					@groupArray = Grouparray.find_by(id: group.id)
 					@groupArray.destroy
 					Messagehuman.sendMessageBubbles(group.conversation_id)
 					sleep(2)
 					Messagehuman.sendMessage(group.conversation_id, 'Ok Dokey! Got it!')
 					@sentMessage = true
 				else
 				end
 			end
 		end
 	end
 		if @sentMessage == false
 			Messagehuman.sendMessage(@recipient, @defaultResponses[0])
 		end
 	end

 	def check_token
 		checkFacebookToken()
 	end

 	def webhook_inspect
 		@word = Messagehuman.string_difference_percent("math", "mwth")
 	end
 
end