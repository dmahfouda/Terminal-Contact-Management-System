require 'CSV'
require 'readline'

class Csv_messenger

	def initialize
		@contacts = CSV.read("google.csv")
		
		@given_name_index = @contacts[0].find_index("Given Name")
		@family_name_index = @contacts[0].find_index("Family Name")
		@phone_index = @contacts[0].find_index("Phone 1 - Value")
		@email_index = @contacts[0].find_index("E-mail 1 - Value")
		@group_membership_index = @contacts[0].find_index("Group Membership")
		
		@group_names = []
		@contacts_in_selected_group = []
		@current_contact = []
		
		@message
		@individual_or_group_mode
		@email_or_imessage
		@group_selection
		@command

		get_group_names
		format_phone_numbers
		prompt
	end

	def prompt
		@command = Readline.readline("Terminal CMS> ", true)
		evaluate_command
	end

	def evaluate_command
		case @command
		when "E","e","Email","email"
			@email_or_imessage = "Email"
			get_individual_or_group_mode
			get_and_validate_group_selection
			quit_if_quit_selected @group_selection
			get_contacts_in_selected_group
			put_information_about_selected_group
			compose_messages
		when "i","iMessage","SMS"
			@email_or_imessage = "iMessage"	
			get_individual_or_group_mode
			get_and_validate_group_selection
			quit_if_quit_selected @group_selection
			get_contacts_in_selected_group
			put_information_about_selected_group
			compose_messages
		when "q","quit", "Quit", "Q"
			exit
		when "u", "U", "update", "Update Contacts"
			puts "Getting new contacts..."
			system 'rm google.csv'
			system 'ruby webdriver_collect_contacts.rb'
			prompt
		when "p","P","prompt","Prompt"
			prompt
		else
			puts "That's not a valid command. Please try again."
			@command = gets.chomp
			evaluate_command
		end
	end

	def get_and_validate_group_selection
		puts "To which group would you like to send a message?"
		puts @group_names.join(", ")
		@group_selection = gets.chomp
		validate_group_selection
	end

	def format_phone_numbers
		@contacts.each do |c|
			if c[@phone_index]
				if c[@phone_index].include?(' ::: ')
					c[@phone_index] = c[@phone_index].split(' ::: ')[0].gsub!(/\D/,'')
				else				
					c[@phone_index].gsub!(/\D/,'')
				end
			end
		end
	end

	def get_contacts_in_selected_group
		@contacts.each do |c|
			if c[@group_membership_index].include? @group_selection 
				@contacts_in_selected_group << c
			end
		end
	end

	def put_information_about_selected_group
		puts "#{@contacts_in_selected_group.length} contacts, #{@contacts_in_selected_group.select{ |c| c[@phone_index] }.length} contacts with phones, #{@contacts_in_selected_group.select{|c| c[@email_index] }.length} contacts with email"
	end

	def get_group_names
		@contacts.each do |c|
			c[@group_membership_index].split(' ::: ').each do |a| 
				@group_names << a
			end
		end
		@group_names = @group_names.uniq.drop(1)
	end

	def get_contacts_with_phones contacts_array
		contacts_with_phones = []
		contacts_array.each do |c|
			if c[@phone_index]
				contacts_with_phones << c
			end
		end
		return contacts_with_phones
	end

	def validate_group_selection
		if !@group_names.find_index(@group_selection)
			puts "That's not a valid group."
			get_group_selection
		end
	end

	def get_individual_or_group_mode
		puts "What kind of messages would you like to send? (G)roup or (I)ndividual?"
		@individual_or_group_mode = gets.chomp
		quit_if_quit_selected @individual_or_group_mode
		validate_message_mode
	end

	def get_message_or_email_selection
		puts "Do you want to send an (i)Message or an (E)mail?"
		@email_or_imessage = gets.chomp
		quit_if_quit_selected @email_or_imessage
		validate_message_type
	end

	def validate_message_type
		if @email_or_imessage == "i" || @email_or_imessage == "E"
			return
		else
			puts "That's not a valid message type. Please reply 'i' or 'E'."
			@email_or_imessage = gets.chomp
			quit_if_quit_selected @email_or_imessage
			validate_message_type 
		end
	end

	def validate_message_mode
		if @individual_or_group_mode == "G" || @individual_or_group_mode == "I" || "@individual_or_group_mode" == "Group" || @individual_or_group_mode == "Individual"  
			return
		else 
			puts "That's not a valid message mode. Please reply 'G' or 'I'."
			@individual_or_group_mode = gets.chomp
			quit_if_quit_selected @individual_or_group_mode
			validate_message_mode
		end
	end

	def collect_and_send_group_message
		puts "What message would you like to send?"
		@message = gets.chomp
		quit_if_quit_selected @message
		validate_group_message
		send_group_message
	end

	def validate_group_message
		puts "Are you sure this is the message you want to send? Reply 'Yes' or 'No'"
		r = gets.chomp
		quit_if_quit_selected r 
		if r == 'Yes' || r == 'Y' || r == "y"
			return
		else
			collect_and_send_group_message
		end
	end

	def validate_individual_messages
		puts "Are you sure this is the message you want to send to #{@current_contact[@given_name_index]} #{@current_contact[@family_name_index]}?"
		r = gets.chomp
		quit_if_quit_selected r 
		if r == "Yes" || r == "Y" || r == "y"
			return
		else
			puts "Ok, what message would you like to send?"
			@message = gets.chomp
			validate_individual_messages
		end
	end

	def compose_messages
		if @individual_or_group_mode == "G" || @individual_or_group_mode == "Group"
			collect_and_send_group_message
		elsif @individual_or_group_mode == "I" || @individual_or_group_mode == "Individual"
			collect_and_send_individual_messages
		end 
	end

	def send_group_message
		@contacts_in_selected_group.each do |c|
			if @email_or_imessage == "Email"
				system "osascript sendEmail.applescript #{c[@email_index]} \"#{@message}\""
				puts "osascript sendEmail.applescript #{c[@email_index]} \"#{@message}\""		
			elsif @email_or_imessage == "iMessage"
				system "osascript sendMessage.applescript #{c[@phone_index]} \"#{@message}\""
				puts "osascript sendMessage.applescript #{c[@phone_index]} \"#{@message}\""
			end		
		end
	end

	def send_individual_message
		if @email_or_imessage == "Email"
			system "osascript sendEmail.applescript #{c[@email_index]} \"#{@message}]\""
			puts "osascript sendEmail.applescript #{@current_contact[@email_index]} \"#{@message}]\""
		elsif @email_or_imessage == "iMessage"
			system "osascript sendMessage.applescript #{@current_contact[@phone_index]} \"#{@message}\""
			puts "osascript sendMessage.applescript #{@current_contact[@phone_index]} \"#{@message}\""
		end
	end

	def collect_and_send_individual_messages
		@contacts_in_selected_group.each do |c|
			if c[@phone_index]
				puts "Message for #{c[@given_name_index]} #{c[@family_name_index]}:"
				@current_contact = c
				@message = Readline.readline('',true)
				quit_if_quit_selected @message
				#validate_individual_messages
				send_individual_message
			end
		end
	end

	def quit_if_quit_selected s
		if s == "q" || s == "quit"
			exit
		end
	end
end

cm = Csv_messenger.new