class Messagehuman
  require 'json'
  if Rails.env.staging?
    $page_access_token = "EAAIgtnRF648BABaZCpNurJN2GBzjZC6jQZAZCCdQE90mluLc5jooAfHrFgSxsYT2eTeu9sXVjWWiFc1gZBXn5if7OC2Q4hXsnHwxrSDg7anLuzPnRzUvicPv5R1AXxkjZAS2Xhm7KknwGlx0poBZC7IFNhRyNHnWabn59f7CkwnjAZDZD"
  else
    $page_access_token = "EAAZAjj9YZAiZC0BAOFT4SiXhnIqinWdveXxBf8AvDMAGMXamAIQobjfYRIv9Iw85UcZBXOqla4XpWtUJ6fooeBpM4LtB9hUwOYeRsokcOKUa40gM9RpKgtCTxHiFde52R4i3PZAfMijyw3NZACCYILq3hWeCipeq5gCLuyZASBn6gZDZD"
  end
  # method to send string message to user
	def self.sendMessage(recipient, message)
    # pace access token for facebook
		page_access_token = 'EAAZAjj9YZAiZC0BAOFT4SiXhnIqinWdveXxBf8AvDMAGMXamAIQobjfYRIv9Iw85UcZBXOqla4XpWtUJ6fooeBpM4LtB9hUwOYeRsokcOKUa40gM9RpKgtCTxHiFde52R4i3PZAfMijyw3NZACCYILq3hWeCipeq5gCLuyZASBn6gZDZD'
 		body = {
 			recipient: {
   			id: recipient
 			},
 			message: {
   			text: message
 			},
		}.to_json
		response = HTTParty.post(
 			"https://graph.facebook.com/v2.6/me/messages?access_token=#{$page_access_token}",
 			body: body,
 			headers: { 'Content-Type' => 'application/json' }
		)
	end

  def self.string_difference_percent(a, b)
    longer = [a.size, b.size].max
    same = a.each_char.zip(b.each_char).select { |a,b| a == b }.size
    return (longer - same) / a.size.to_f
  end

  def self.sendMessageBubbles(recipient)
    page_access_token = 'EAAZAjj9YZAiZC0BAOFT4SiXhnIqinWdveXxBf8AvDMAGMXamAIQobjfYRIv9Iw85UcZBXOqla4XpWtUJ6fooeBpM4LtB9hUwOYeRsokcOKUa40gM9RpKgtCTxHiFde52R4i3PZAfMijyw3NZACCYILq3hWeCipeq5gCLuyZASBn6gZDZD'
    body = {
      recipient: {
        id: recipient
      },
      sender_action: "typing_on"
    }
    response = HTTParty.post(
      "https://graph.facebook.com/v2.6/me/messages?access_token=#{$page_access_token}",
      body: body,
      headers: { 'Content-Type' => 'application/json' }
    )
  end

	def self.sendBinaryMessage(recipient, message)
		page_access_token = 'EAAZAjj9YZAiZC0BAOFT4SiXhnIqinWdveXxBf8AvDMAGMXamAIQobjfYRIv9Iw85UcZBXOqla4XpWtUJ6fooeBpM4LtB9hUwOYeRsokcOKUa40gM9RpKgtCTxHiFde52R4i3PZAfMijyw3NZACCYILq3hWeCipeq5gCLuyZASBn6gZDZD'
 		body = {
 			recipient: {
   			id: recipient
 			},
 			message: {
   			text: message,
   			quick_replies: [
      	{
        	content_type: "text",
        	title: "yes",
        	payload: 'Yes'
      	},
      	{
        	content_type: "text",
        	title: "no",
        	payload: 'No'
      	}
   			]
 			}
		}.to_json
		response = HTTParty.post(
 			"https://graph.facebook.com/v2.6/me/messages?access_token=#{$page_access_token}",
 			body: body,
 			headers: { 'Content-Type' => 'application/json' }
		)
	end

	def self.checkKeyWords(recipient, userText)
    $subject = nil
    $keyWords = Array.new
    @wordRating = 0
    @user = User.find_by(conversation_id: recipient)
    $userTodayGroups = Array.new
    @user.groups.where("group_day = ?", 0.hours.ago.strftime("%A").downcase).each do |group| $userTodayGroups.push(group.group_name.downcase) end
		$textArray = userText.split(" ")
    $textArray.each do |word|
      @wordRating += 1 if word == "have" || word == "homework"
      @wordRating += 5 if $userTodayGroups.include?(word)
      $subject = word if $userTodayGroups.include?(word)
      @wordRating += -14 if word == "don't" || word == "dont"
    end
    if $subject.nil?
      $possibleSubjects = Array.new
      $textArray.each do |word|
        $userTodayGroups.each do |group|
          if Messagehuman.string_difference_percent(word, group) <= 0.5
            $possibleSubjects.push(group)
          end
        end
      end
    end
    if @wordRating == 7
      @group = Group.find_by(conversation_id: recipient, group_day: 0.hours.ago.strftime("%A").downcase, group_name: $subject.downcase)
      @group.update(homework_assigned: true)
      @group = @group.as_json
      @group["id"] = nil
      @group.delete("name")
      groupArrayNew = Grouparray.new(@group)
      groupArrayNew.save
      return true
    elsif @wordRating == 2 && !$possibleSubjects.empty?
      return false
    elsif @wordRating == -7
      @group = Group.find_by(conversation_id: recipient, group_day: 0.hours.ago.strftime("%A").downcase, group_name: $subject.downcase)
      @group.update(homework_assigned: false, homework_assignment: nil)
      return @wordRating
    elsif @wordRating == -12 && !$possibleSubjects.empty?
      return @wordRating
    else
      return nil
    end
	end


	def self.checkUserExists(recipient)
		if User.find_by(conversation_id: recipient).nil?
      @messageText = false
 		else
 			@messageText = true
 		end
 		return @messageText
 	end

 	def self.sendButton(recipient)
  page_access_token='EAAZAjj9YZAiZC0BAMJmsPEAp8PEhWvOc1DEDrPQFkzZBZBd9BgCx8ZCzRk7LAQHxSkJZARMS9vGiIihyyenuzsZBqkMAeEW7vT3ukxjRRqHRTbBx5BlNauoXtgwy3lR6zosx70CzgiyiLZArTr1mZCQoqZBrsDOZAerirrbBHL2wumq19wZDZD'
 	if Rails.env.staging?
    url = "https://staging-christopherbot.herokuapp.com/users/sign_in?conversation_id=" + recipient
  else
    url = "https://www.christopherbot.co/users/sign_in?conversation_id=" + recipient
  end
  body = {
 		"recipient":{
    	id: recipient
  	},
  	message:{
    	attachment:{
     		type:"template",
     		payload: {
       		template_type:"generic",
        	elements:[
         	{
            title:"Sign Up For Christopher Bot",
           	subtitle:"To keep track of your homework",
           	buttons:[
              			{
                type:"web_url",
               	url:url,
                title:"Sign Up",
                webview_height_ratio:"tall"
              }
            	]
          	}
        	]
      	}
   	}
 	 }
  }.to_json

	response = HTTParty.post(
	 	"https://graph.facebook.com/v2.6/me/messages?access_token=#{$page_access_token}",
	 	body: body,
	 	headers: { 'Content-Type' => 'application/json' }
	)
end

def self.sendSummaryButton(recipient)
  page_access_token='EAAZAjj9YZAiZC0BAMJmsPEAp8PEhWvOc1DEDrPQFkzZBZBd9BgCx8ZCzRk7LAQHxSkJZARMS9vGiIihyyenuzsZBqkMAeEW7vT3ukxjRRqHRTbBx5BlNauoXtgwy3lR6zosx70CzgiyiLZArTr1mZCQoqZBrsDOZAerirrbBHL2wumq19wZDZD'
  body = {
    "recipient":{
      id: recipient
    },
    message:{
      attachment:{
        type:"template",
        payload: {
          template_type:"generic",
          elements:[
          {
            title:"See All Your Homework",
            subtitle:"To see all your homework for the week",
            buttons:[
                    {
                type:"web_url",
                url:"https://www.christopherbot.co/",
                title:"See My Homework",
                webview_height_ratio:"tall"
              }
              ]
            }
          ]
        }
    }
   }
  }.to_json

  response = HTTParty.post(
    "https://graph.facebook.com/v2.6/me/messages?access_token=#{$page_access_token}",
    body: body,
    headers: { 'Content-Type' => 'application/json' }
  )
end

def self.sendGroupConfirmMessage(recipient, possibleClasses, charge)
    if charge == true
      text = "sorry, which class do you have homework for?"
    else
      text = "sorry, which class do you not have homework for?"
    end
    page_access_token = 'EAAZAjj9YZAiZC0BAOFT4SiXhnIqinWdveXxBf8AvDMAGMXamAIQobjfYRIv9Iw85UcZBXOqla4XpWtUJ6fooeBpM4LtB9hUwOYeRsokcOKUa40gM9RpKgtCTxHiFde52R4i3PZAfMijyw3NZACCYILq3hWeCipeq5gCLuyZASBn6gZDZD'
    body = {
      recipient: {
        id: recipient
      },
      message: {
        text: text,
        quick_replies: [
        {
          content_type: "text",
          title: possibleClasses[0].downcase,
          payload: possibleClasses[0].downcase
        }
      ]
      }
    }.to_json
    response = HTTParty.post(
      "https://graph.facebook.com/v2.6/me/messages?access_token=#{$page_access_token}",
      body: body,
      headers: { 'Content-Type' => 'application/json' }
    )
  end

  def self.sendHelpButton(recipient)
    url = "https://www.christopherbot.co/commands"
    body = {
      "recipient":{
        id: recipient
      },
      message:{
        attachment:{
          type:"template",
          payload: {
            template_type:"generic",
            elements:[
            {
              title:"help!",
              subtitle:"forgot what to text me?",
              buttons:[
                      {
                  type:"web_url",
                  url:url,
                  title:"Get Help",
                  webview_height_ratio:"tall"
                }
                ]
              }
            ]
          }
      }
     }
    }.to_json

    response = HTTParty.post(
      "https://graph.facebook.com/v2.6/me/messages?access_token=#{$page_access_token}",
      body: body,
      headers: { 'Content-Type' => 'application/json' }
    )
  end

  def self.sendPauseDate(recipient)
    url = "https://www.christopherbot.co/date_picker?conversation_id="+recipient
    body = {
      "recipient":{
        id: recipient
      },
      message:{
        attachment:{
          type:"template",
          payload: {
            template_type:"generic",
            elements:[
            {
              title:"Select Date",
              subtitle:"what date would you like to unpause?",
              buttons:[
                      {
                  type:"web_url",
                  url:url,
                  title:"Select Date",
                  webview_height_ratio:"tall"
                }
                ]
              }
            ]
          }
      }
     }
    }.to_json

    response = HTTParty.post(
      "https://graph.facebook.com/v2.6/me/messages?access_token=#{$page_access_token}",
      body: body,
      headers: { 'Content-Type' => 'application/json' }
    )
  end

  def self.sendUserHomework(recipient)
    user = User.find_by(conversation_id: recipient)
    homeworkGroups = Array.new
    homeworkGroupsTrue = Group.where("homework_assigned = ?", true).where("group_day = ?", 0.hours.ago.strftime("%A").downcase).where("conversation_id = ?", recipient)
    homeworkGroupsTrue.each do |group|
      homeworkGroups.push(group)
    end
    homeworkGroupsString = String.new
    puts "here"
    counter = 1
    homeworkGroups.each do |group|
      if counter != 1
        homeworkGroupsString = homeworkGroupsString + ", " + group.group_name + ": " + group.homework_assignment + "\n"
      else
        homeworkGroupsString = homeworkGroupsString + group.group_name + ": " + group.homework_assignment + "\n"
      end
    end
    puts 'user send to: ' + user.first_name.to_s
    if !homeworkGroupsString.blank?
      Messagehuman.sendMessage(recipient, 'You have homework for... ' + "\n" + homeworkGroupsString)
    else
      Messagehuman.sendMessage(recipient, 'Yay. You have no homework.')
    end
  end

  def self.sendShareButton(recipient)
    url = "https://www.facebook.com/sharer/sharer.php?u=https://www.christopherbot.co"
    body = {
      "recipient":{
        id: recipient
      },
      message:{
        attachment:{
          type:"template",
          payload: {
            template_type:"generic",
            elements:[
            {
              title:"Do Me A Quick Favor?",
              subtitle:"Tell your friends about me on Facebook (promise I'll only ask you once)?",
              buttons:[
                      {
                  type:"web_url",
                  url:url,
                  title:"Share CB On Facebook",
                  webview_height_ratio:"tall"
                }
                ]
              }
            ]
          }
      }
     }
    }.to_json

    response = HTTParty.post(
      "https://graph.facebook.com/v2.6/me/messages?access_token=#{$page_access_token}",
      body: body,
      headers: { 'Content-Type' => 'application/json' }
    )
  end

  def self.checkOneWord(text)
    textArray = text.split(" ")
    if textArray.include?("serious") || textArray.include?("seriously")
      return "don't be serious; be silly ;-)"
    elsif textArray.include?("why?") || textArray.include?("why")
      return "i'm not good at giving answers :-|"
    elsif textArray.include?("stupid")
      return "woah! don't be rude :-("
    elsif textArray.include?("awesome")
      return "way to be postive...it's impossible for me to be happy because i'm a bot...but now i feel sad thinking about it ;-("
    else
      return "a"
    end
  end



end
