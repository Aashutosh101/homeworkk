module MessengerHelper

	def checkFacebookToken
		verify_token = params["hub.verify_token"]
		if verify_token == "987654321"
    	render text: params['hub.challenge'] and return
  	else
    	render text: "failed" and return
  	end
	end



end

# 134381003642835
