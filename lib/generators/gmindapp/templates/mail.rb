require 'smtp_tls'

ActionMailer::Base.smtp_settings = {
	:address => "smtp.gmail.com",
	:port => 587,
	:authentication => :plain,
	:domain => "gmail.com",
	:user_name => "sample@gmail.com", # change
	:password => "sample" # change
}
