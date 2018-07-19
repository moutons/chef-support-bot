class ProcessSlackMessageJob < ApplicationJob
  queue_as :default
  include SuckerPunch::Job
  workers 20

  def perform(event_params)
    ActiveRecord::Base.connection_pool.with_connection do
    # Do something later
    case event_params['type']
    when 'app_mention', 'message'
      if !event_params['text'].nil? 
        process_app_mention(event_params)
      end
    else
      logger.info "We don't handle #{event_params['type']} yet"
    end
  end
  end

  def process_app_mention(mention)
    msg = Slack::Messages::Formatting.unescape(mention['text'])
    keyword, text = message_keyword(msg)

    message = ::MySlack::Commands.process(keyword, text, mention)
    resultmess =  ::MySlack::client.chat_postMessage(message)
    result = resultmess['message']
    puts "OMGH     #{result.inspect}"
    if "#{result['text']}".include?("awaiting confirmation...")
      puts "SLEEEEEEP"
      slack_id = result['text'][/<\@(.*?)>/m, 1]
      ticket_id = result['text'][/tickets\/(.*?)>/m, 1]
      person = Person.where('slack_id like ?', slack_id).first
      
      sleep(5.minutes)
      ticket = Ticket.where(zendesk_id: ticket_id).first
      if !ticket.person_id.nil?
      	 ProcessInteractiveMessageJob.perform_now( { :type => "interactive_message", :actions => [{:name => "unavailable", :value => ticket_id }], :user => { :name => person.slack_handle, :id => slack_id }, 
         :original_message => result, :channel => { :id => resultmess['channel']}, :message_ts => result['ts']  }.as_json)      
      	 puts "AWAKE #{} is ignoring ticket #{ticket_id}"
      else
         puts "NOOOO ROLLLLLL"
      end

    end
    
  end

  def message_keyword(text)
    words = text.split(' ')
    if words.first =~ /@[\w]+/
      words.shift
    end
    [words.shift, words.join(' ')]
  end

  def bot_match(word)
    /@(\w+) #{word}/
  end

  def find_person(id)
  end
end
