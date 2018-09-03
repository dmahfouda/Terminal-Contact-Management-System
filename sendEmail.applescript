on run {recipientAddress, theContent}

	tell application "Mail"
	        --Create the message
	        set theMessage to make new outgoing message with properties {subject:" ", content:theContent, visible:true}

	        --Set a recipient
	        tell theMessage
	                make new to recipient with properties {address:recipientAddress}

	                --Send the Message
	                send
	        end tell
	end tell
end run