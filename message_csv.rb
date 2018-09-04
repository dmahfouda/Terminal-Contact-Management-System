require 'CSV'

class Csv_messenger

	def initialize
		@contacts = CSV.read("google.csv")
		
		@given_name_index = @contacts[0].find_index("Given Name")
		@family_name_index = @contacts[0].find_index("Family Name")
		@phone_index = @contacts[0].find_index("Phone 1 - Value")
		@email_index = @contacts[0].find_index("E-mail 1 - Value")
		@group_membership_index = @contacts[0].find_index("Group Membership")

		@contacts_with_phones = []
		@group_names = []
		@contacts_with_phones_in_selected_group = []
		@name_phone_pairs_in_group = []
		@individual_messages_array = []
		@current_contact = []
		@contacts_in_selected_group = []
		
		@message
		@message_mode
		@message_type
		@group_selection
		@command

		get_group_names
		get_contacts_with_phones
		format_phone_numbers
		prompt
	end

	def prompt
		puts "Terminal CMS>"
		@command = gets.chomp
		evaluate_command
	end

	def evaluate_command
		case @command
		when "E","e","Email","email"
			@message_type = "Email"
			get_message_mode
			get_user_group_selection
			compose_messages
		when "i","iMessage","SMS"
			@message_type = "iMessage"	
			get_message_mode
			get_user_group_selection
			compose_messages
		when "q","quit", "Quit"
			exit
		when "u", "U", "update", "Update Contacts"
			puts "Getting new contacts..."
			system 'rm google.csv'
			system 'ruby webdriver_collect_contacts.rb'
			prompt
		else
			puts "That's not a valid command. Please try again."
			@command = gets.chomp
			evaluate_command
		end
	end

	def format_phone_numbers
		@contacts_with_phones.each do |c|
			if c[@phone_index].include?(' ::: ')
				c[@phone_index] = c[@phone_index].split(' ::: ')[0].gsub!(/\D/,'')
			else
				c[@phone_index].gsub!(/\D/,'')
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

	def get_contacts_with_phones
		@contacts.each do |c|
			if c[@phone_index]
				@contacts_with_phones << c
			end
		end
	end

	def get_user_group_selection
		puts "To which group would you like to send a message?"
		puts @group_names.join(", ")
		@group_selection = gets.chomp
		quit_if_quit_selected @group_selection
		validate_group_selection
	end

	def validate_group_selection
		if @group_names.find_index(@group_selection)
			get_and_format_contacts_in_selected_group
			get_contacts_in_selected_group
			put_information_about_selected_group
		else
			puts "That's not a valid group."
			get_user_group_selection
		end
	end

	def get_and_format_contacts_in_selected_group
		@contacts_with_phones.each do |c|
			if c[@group_membership_index].include? @group_selection
				@contacts_with_phones_in_selected_group << c
			end
		end
		build_array_of_name_phone_pairs
	end

	def build_array_of_name_phone_pairs
		@contacts_with_phones_in_selected_group.each do |c|
			@name_phone_pairs_in_group << [c[@given_name_index],c[@phone_index]]
		end
		@name_phone_pairs_in_group
	end

	def get_message_mode
		puts "What kind of messages would you like to send? (G)roup or (I)ndividual?"
		@message_mode = gets.chomp
		quit_if_quit_selected @message_mode
		validate_message_mode
	end

	def get_message_or_email_selection
		puts "Do you want to send an (i)Message or an (E)mail?"
		@message_type = gets.chomp
		quit_if_quit_selected @message_type
		validate_message_type
	end

	def validate_message_type
		if @message_type == "i" || @message_type == "E"
			return
		else
			puts "That's not a valid message type. Please reply 'i' or 'E'."
			@message_type = gets.chomp
			quit_if_quit_selected @message_type
			validate_message_type 
		end
	end

	def validate_message_mode
		if @message_mode == "G" || @message_mode == "I" || "@message_mode" == "Group" || @message_mode == "Individual"  
			return
		else 
			puts "That's not a valid message mode. Please reply 'G' or 'I'."
			@message_mode = gets.chomp
			quit_if_quit_selected @message_mode
			validate_message_mode
		end
	end

	def collect_message
		puts "What message would you like to send?"
		@message = gets.chomp
		quit_if_quit_selected @message
		validate_group_message
	end

	def validate_group_message
		puts "Are you sure this is the message you want to send? Reply 'Yes' or 'No'"
		r = gets.chomp
		quit_if_quit_selected r 
		if r == 'Yes' || r == 'Y' || r == "y"
			send_group_message
		else
			collect_message
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
		if @message_mode == "G" || @message_mode == "Group"
			collect_message
		elsif @message_mode == "I" || @message_mode == "Individual"
			collect_individual_messages
		end 
	end

	def send_group_message
		@contacts_in_selected_group.each do |c|
			if @message_type == "Email"
				system "osascript sendEmail.applescript #{c[@email_index]} \"#{@message}\""
				puts "osascript sendEmail.applescript #{c[@email_index]} \"#{@message}\""		
			elsif @message_type == "iMessage"
				system "osascript sendMessage.applescript #{c[@phone_index]} \"#{@message}\""
				puts "osascript sendMessage.applescript #{c[@phone_index]} \"#{@message}\""
			end		
		end
	end

	def send_individual_message
		if @message_type == "Email"
			system "osascript sendEmail.applescript #{c[@email_index]} \"#{@message}]\""
			puts "osascript sendEmail.applescript #{@current_contact[@email_index]} \"#{@message}]\""
		elsif @message_type == "iMessage"
			system "osascript sendMessage.applescript #{@current_contact[@phone_index]} \"#{@message}\""
			puts "osascript sendMessage.applescript #{@current_contact[@phone_index]} \"#{@message}\""
		end
	end

	def collect_individual_messages
		@contacts_with_phones_in_selected_group.each do |c|
			puts "Message for #{c[@given_name_index]} #{c[@family_name_index]}:"
			@current_contact = c
			@message = gets.chomp
			quit_if_quit_selected @message
			#validate_individual_messages
			send_individual_message
		end
	end

	def quit_if_quit_selected s
		if s == "q" || s == "quit"
			exit
		end
	end
end

cm = Csv_messenger.new